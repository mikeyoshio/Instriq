import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_document.dart';
import '../models/group_document_version.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';
import 'offline_cache_service.dart';
import 'profile_service.dart';
import 'sync_queue_service.dart';

/// CRUD y workflow (borrador -> en revisión -> publicada -> archivada) de
/// técnicas quirúrgicas y protocolos. Cada edición crea una [GroupDocumentVersion]
/// nueva en vez de sobrescribir el contenido; publicar/rechazar/restaurar se
/// hace a través de funciones `security definer` en Supabase (ver
/// supabase/schema_v5_group_document_versions.sql) para que la validación de
/// permisos viva en un único sitio de confianza, no repartida en el cliente.
class GroupDocumentService {
  GroupDocumentService._();
  static final GroupDocumentService instance = GroupDocumentService._();

  SupabaseClient get _client => Supabase.instance.client;

  static const _publishedJoin = '*, published_version:published_version_id(*)';

  List<GroupDocument> _documents = [];

  /// true si el último [fetchDocuments] sirvió de [OfflineCacheService] en
  /// vez de red (sin conexión, o la petición falló por un problema de red).
  /// La UI la lee justo después para decidir si mostrar el aviso offline.
  bool documentsFromCache = false;
  DateTime? documentsCachedAt;

  /// Limpia el caché en memoria. Debe llamarse al cambiar de grupo o cerrar
  /// sesión: si no, un documento de un grupo anterior puede quedar cacheado.
  void clear() {
    _documents = [];
  }

  List<GroupDocument> documentsOfKind(DocumentKind kind, String workspaceId) =>
      _documents.where((d) => d.kind == kind && d.workspaceId == workspaceId).toList();

  Future<void> fetchDocuments(DocumentKind kind, String workspaceId) async {
    Future<void> fallbackToCache() async {
      final cached = await OfflineCacheService.instance.getCachedDocuments(workspaceId);
      documentsFromCache = true;
      documentsCachedAt = cached?.cachedAt;
      final fetched = (cached?.data ?? []).where((d) => d.kind == kind).toList();
      _documents = [
        ..._documents.where((d) => !(d.kind == kind && d.workspaceId == workspaceId)),
        ...fetched,
      ];
    }

    if (!ConnectivityService.instance.isOnline.value) {
      await fallbackToCache();
      return;
    }
    try {
      final rows = await _client
          .from('group_documents')
          .select(_publishedJoin)
          .eq('kind', kind.dbValue)
          .eq('workspace_id', workspaceId);
      final fetched = (rows as List<dynamic>)
          .map((r) => GroupDocument.fromRow(r as Map<String, dynamic>))
          .toList();
      fetched.sort((a, b) => (a.publishedVersion?.title ?? '').compareTo(b.publishedVersion?.title ?? ''));
      documentsFromCache = false;
      documentsCachedAt = null;
      _documents = [
        ..._documents.where((d) => !(d.kind == kind && d.workspaceId == workspaceId)),
        ...fetched,
      ];
      // Se cachea la lista completa del workspace (ambos tipos de documento
      // que ya están en memoria), no solo el kind recién traído.
      await OfflineCacheService.instance
          .cacheDocuments(workspaceId, _documents.where((d) => d.workspaceId == workspaceId).toList());
    } catch (e) {
      if (!ConnectivityService.isNetworkError(e)) rethrow;
      await fallbackToCache();
    }
  }

  GroupDocument? documentById(String id) {
    for (final d in _documents) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<GroupDocument> fetchDocument(String id) async {
    if (ConnectivityService.instance.isOnline.value) {
      try {
        final row = await _client.from('group_documents').select(_publishedJoin).eq('id', id).single();
        return GroupDocument.fromRow(row);
      } catch (e) {
        if (!ConnectivityService.isNetworkError(e)) rethrow;
      }
    }
    final cached = documentById(id);
    if (cached != null) return cached;
    throw StateError('Sin conexión y sin datos cacheados para este documento.');
  }

  Future<List<GroupDocumentVersion>> fetchVersionHistory(String documentId) async {
    if (ConnectivityService.instance.isOnline.value) {
      try {
        final rows = await _client
            .from('group_document_versions')
            .select()
            .eq('document_id', documentId)
            .order('version_number', ascending: false);
        final versions = (rows as List<dynamic>)
            .map((r) => GroupDocumentVersion.fromRow(r as Map<String, dynamic>))
            .toList();
        await OfflineCacheService.instance.cacheVersionHistory(documentId, versions);
        return versions;
      } catch (e) {
        if (!ConnectivityService.isNetworkError(e)) rethrow;
      }
    }
    final cached = await OfflineCacheService.instance.getCachedVersionHistory(documentId);
    return cached?.data ?? [];
  }

  /// Crea un documento nuevo con su primera versión en borrador. Va vía
  /// función `security definer` (ver supabase/schema_v10_audit.sql) para que
  /// la creación quede registrada en el log de auditoría.
  Future<GroupDocumentVersion> createDocument(DocumentKind kind, String workspaceId) async {
    if (!ConnectivityService.instance.isOnline.value) {
      return SyncQueueService.instance.queueCreateDocument(kind, workspaceId);
    }
    final organizationId = ProfileService.instance.organizationId;
    final userId = AuthService.instance.currentUser?.id;
    if (organizationId == null || userId == null) {
      throw StateError('Tu usuario no pertenece a ningún grupo todavía.');
    }
    final versionRow = await _client.rpc('create_group_document', params: {
      'p_kind': kind.dbValue,
      'p_workspace_id': workspaceId,
    });
    return GroupDocumentVersion.fromRow(versionRow as Map<String, dynamic>);
  }

  /// Devuelve el borrador propio en curso para [document] si existe, o crea
  /// uno nuevo a partir de la versión publicada.
  Future<GroupDocumentVersion> startEditing(GroupDocument document) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      throw StateError('Tu usuario no pertenece a ningún grupo todavía.');
    }
    final existing = await _client
        .from('group_document_versions')
        .select()
        .eq('document_id', document.id)
        .eq('author_id', userId)
        .inFilter('status', ['draft', 'in_review'])
        .order('version_number', ascending: false)
        .limit(1)
        .maybeSingle();
    if (existing != null) {
      final version = GroupDocumentVersion.fromRow(existing);
      // Una versión en revisión ya no es "continuable": la política de
      // UPDATE en Supabase solo permite escribir sobre status = 'draft'
      // (ver schema_v5_group_document_versions.sql). Devolverla aquí como si
      // se pudiera seguir editando llevaría a un error de Postgres críptico
      // al guardar -- mejor avisar claro y aquí mismo, antes de abrir el
      // formulario.
      if (version.status == GroupDocumentVersionStatus.inReview) {
        throw StateError('Ya tienes una versión enviada a revisión: no se puede editar hasta que se apruebe, se rechace o se retire.');
      }
      return version;
    }

    final published = document.publishedVersion;
    if (published == null) {
      throw StateError('Este documento todavía no tiene una versión publicada.');
    }
    final versions = await fetchVersionHistory(document.id);
    final nextVersionNumber =
        versions.isEmpty ? 1 : versions.map((v) => v.versionNumber).reduce((a, b) => a > b ? a : b) + 1;

    final versionRow = await _client
        .from('group_document_versions')
        .insert({
          'document_id': document.id,
          'version_number': nextVersionNumber,
          'status': GroupDocumentVersionStatus.draft.dbValue,
          'title': published.title,
          'specialty_id': published.specialtyId,
          'content': published.content,
          'steps': published.steps.map((s) => s.toJson()).toList(),
          'related_instrument_ids': published.relatedInstrumentIds,
          'related_tray_ids': published.relatedTrayIds,
          'author_id': userId,
          'based_on_version_id': published.id,
        })
        .select()
        .single();
    return GroupDocumentVersion.fromRow(versionRow);
  }

  Future<GroupDocumentVersion> saveDraft(GroupDocumentVersion version) async {
    if (!ConnectivityService.instance.isOnline.value || SyncQueueService.instance.isPendingLocalId(version.id)) {
      // Un id "local_..." significa que ni el documento llegó a crearse en
      // el servidor todavía (createDocument también está en cola): no hay
      // fila real que actualizar, así que esto también se encola.
      return SyncQueueService.instance.queueSaveDraft(version);
    }
    try {
      final row = await _client
          .from('group_document_versions')
          .update(version.toRow())
          .eq('id', version.id)
          .select()
          .single();
      return GroupDocumentVersion.fromRow(row);
    } catch (e) {
      if (!ConnectivityService.isNetworkError(e)) rethrow;
      return SyncQueueService.instance.queueSaveDraft(version);
    }
  }

  Future<void> submitForReview(String versionId) async {
    if (!ConnectivityService.instance.isOnline.value || SyncQueueService.instance.isPendingLocalId(versionId)) {
      return SyncQueueService.instance.queueSubmitForReview(versionId);
    }
    try {
      await _client.rpc('submit_group_document_version_for_review', params: {'p_version_id': versionId});
    } catch (e) {
      if (!ConnectivityService.isNetworkError(e)) rethrow;
      await SyncQueueService.instance.queueSubmitForReview(versionId);
    }
  }

  Future<void> approve(String versionId, {String? comment}) async {
    await _client.rpc('approve_group_document_version', params: {
      'p_version_id': versionId,
      'p_review_comment': comment,
    });
  }

  Future<void> reject(String versionId, {String? comment}) async {
    await _client.rpc('reject_group_document_version', params: {
      'p_version_id': versionId,
      'p_review_comment': comment,
    });
  }

  Future<String> restore(String versionId) async {
    final newId = await _client.rpc('restore_group_document_version', params: {'p_version_id': versionId});
    return newId as String;
  }

  /// Versiones en revisión de todo el grupo, para la cola de aprobación.
  Future<List<GroupDocumentVersion>> fetchReviewQueue() async {
    final rows = await _client
        .from('group_document_versions')
        .select()
        .eq('status', GroupDocumentVersionStatus.inReview.dbValue)
        .order('created_at');
    return (rows as List<dynamic>)
        .map((r) => GroupDocumentVersion.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  /// Nombre del espacio de cada documento, para mostrar contexto en la cola de revisión.
  Future<Map<String, String>> fetchWorkspaceNamesForDocuments(List<String> documentIds) async {
    if (documentIds.isEmpty) return {};
    final rows = await _client
        .from('group_documents')
        .select('id, workspaces(name)')
        .inFilter('id', documentIds);
    final result = <String, String>{};
    for (final r in (rows as List<dynamic>)) {
      final row = r as Map<String, dynamic>;
      final workspaceRow = row['workspaces'] as Map<String, dynamic>?;
      if (workspaceRow?['name'] != null) {
        result[row['id'] as String] = workspaceRow!['name'] as String;
      }
    }
    return result;
  }

  /// Va vía función `security definer` para que el borrado quede registrado
  /// en el log de auditoría.
  Future<void> deleteDocument(String id) async {
    await _client.rpc('delete_group_document', params: {'p_document_id': id});
    _documents.removeWhere((d) => d.id == id);
  }
}
