import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_document_version.dart';
import '../models/tray.dart';
import 'auth_service.dart';
import 'profile_service.dart';

/// CRUD y workflow (borrador -> en revisión -> publicada -> archivada) de
/// bandejas de instrumental. Calcado de [GroupDocumentService], vía
/// funciones `security definer` en Supabase (ver
/// supabase/schema_v15_clinical_knowledge_model.sql) para que la validación
/// de permisos viva en un único sitio de confianza.
///
/// A diferencia de [GroupDocumentService], esta primera ronda NO cae a
/// caché/cola offline: se ha priorizado tener el flujo completo (formulario
/// con dos orígenes de instrumental + fotos + workflow de aprobación)
/// funcionando online antes de sumarle la complejidad de
/// [OfflineCacheService]/[SyncQueueService]. Queda para una ronda futura si
/// se ve necesario en el uso real.
class TrayService {
  TrayService._();
  static final TrayService instance = TrayService._();

  SupabaseClient get _client => Supabase.instance.client;

  static const _bucket = 'tray-photos';
  static const _publishedJoin = '*, published_version:published_version_id(*)';

  List<Tray> _trays = [];

  void clear() {
    _trays = [];
  }

  List<Tray> traysOfWorkspace(String workspaceId) =>
      _trays.where((t) => t.workspaceId == workspaceId).toList();

  Future<void> fetchTrays(String workspaceId) async {
    final rows = await _client.from('trays').select(_publishedJoin).eq('workspace_id', workspaceId);
    final fetched = (rows as List<dynamic>).map((r) => Tray.fromRow(r as Map<String, dynamic>)).toList();
    fetched.sort((a, b) => (a.publishedVersion?.name ?? '').compareTo(b.publishedVersion?.name ?? ''));
    _trays = [
      ..._trays.where((t) => t.workspaceId != workspaceId),
      ...fetched,
    ];
  }

  Tray? trayById(String id) {
    for (final t in _trays) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<Tray> fetchTray(String id) async {
    final row = await _client.from('trays').select(_publishedJoin).eq('id', id).single();
    return Tray.fromRow(row);
  }

  Future<List<TrayVersion>> fetchVersionHistory(String trayId) async {
    final rows = await _client
        .from('tray_versions')
        .select()
        .eq('tray_id', trayId)
        .order('version_number', ascending: false);
    return (rows as List<dynamic>).map((r) => TrayVersion.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// Crea una bandeja nueva con su primera versión en borrador.
  Future<TrayVersion> createTray(String workspaceId) async {
    final versionRow = await _client.rpc('create_tray', params: {'p_workspace_id': workspaceId});
    return TrayVersion.fromRow(versionRow as Map<String, dynamic>);
  }

  /// Devuelve el borrador propio en curso para [tray] si existe, o crea uno
  /// nuevo a partir de la versión publicada.
  Future<TrayVersion> startEditing(Tray tray) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      throw StateError('Tu usuario no pertenece a ningún grupo todavía.');
    }
    final existing = await _client
        .from('tray_versions')
        .select()
        .eq('tray_id', tray.id)
        .eq('author_id', userId)
        .inFilter('status', ['draft', 'in_review'])
        .order('version_number', ascending: false)
        .limit(1)
        .maybeSingle();
    if (existing != null) {
      return TrayVersion.fromRow(existing);
    }

    final published = tray.publishedVersion;
    if (published == null) {
      throw StateError('Esta bandeja todavía no tiene una versión publicada.');
    }
    final versions = await fetchVersionHistory(tray.id);
    final nextVersionNumber =
        versions.isEmpty ? 1 : versions.map((v) => v.versionNumber).reduce((a, b) => a > b ? a : b) + 1;

    final versionRow = await _client
        .from('tray_versions')
        .insert({
          'tray_id': tray.id,
          'version_number': nextVersionNumber,
          'status': GroupDocumentVersionStatus.draft.dbValue,
          'name': published.name,
          'specialty_id': published.specialtyId,
          'description': published.description,
          'photo_paths': published.photoPaths,
          'items': published.items.map((i) => i.toJson()).toList(),
          'observations': published.observations,
          'author_id': userId,
          'based_on_version_id': published.id,
        })
        .select()
        .single();
    return TrayVersion.fromRow(versionRow);
  }

  Future<TrayVersion> saveDraft(TrayVersion version) async {
    final row =
        await _client.from('tray_versions').update(version.toRow()).eq('id', version.id).select().single();
    return TrayVersion.fromRow(row);
  }

  Future<void> submitForReview(String versionId) async {
    await _client.rpc('submit_tray_version_for_review', params: {'p_version_id': versionId});
  }

  Future<void> approve(String versionId, {String? comment}) async {
    await _client.rpc('approve_tray_version', params: {
      'p_version_id': versionId,
      'p_review_comment': comment,
    });
  }

  Future<void> reject(String versionId, {String? comment}) async {
    await _client.rpc('reject_tray_version', params: {
      'p_version_id': versionId,
      'p_review_comment': comment,
    });
  }

  Future<String> restore(String versionId) async {
    final newId = await _client.rpc('restore_tray_version', params: {'p_version_id': versionId});
    return newId as String;
  }

  /// Versiones en revisión de todo el grupo, para la cola de aprobación.
  Future<List<TrayVersion>> fetchReviewQueue() async {
    final rows = await _client
        .from('tray_versions')
        .select()
        .eq('status', GroupDocumentVersionStatus.inReview.dbValue)
        .order('created_at');
    return (rows as List<dynamic>).map((r) => TrayVersion.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// Nombre del espacio de cada bandeja, para mostrar contexto en la cola de revisión.
  Future<Map<String, String>> fetchWorkspaceNamesForTrays(List<String> trayIds) async {
    if (trayIds.isEmpty) return {};
    final rows = await _client.from('trays').select('id, workspaces(name)').inFilter('id', trayIds);
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

  /// Duplica la definición publicada de [trayId] en una bandeja nueva, como
  /// primer borrador — no copia fotos (viven en Storage atadas al tray_id
  /// original, fuera de alcance de EPIC 4 · Bandejas 2.0).
  Future<TrayVersion> duplicateTray(String trayId) async {
    final versionRow = await _client.rpc('duplicate_tray', params: {'p_tray_id': trayId});
    return TrayVersion.fromRow(versionRow as Map<String, dynamic>);
  }

  Future<void> deleteTray(String id) async {
    await _client.from('trays').delete().eq('id', id);
    _trays.removeWhere((t) => t.id == id);
  }

  /// Sube una foto de la bandeja al bucket privado `tray-photos`, con la ruta
  /// convenida `{organization_id}/{workspace_id}/{tray_id}/{filename}` (ver
  /// schema_v15 / can_access_tray_photo). Devuelve el path guardado, que hay
  /// que añadir a [TrayVersion.photoPaths] y persistir con [saveDraft].
  Future<String> uploadPhoto({
    required String trayId,
    required String workspaceId,
    required File file,
  }) async {
    final organizationId = ProfileService.instance.organizationId;
    if (organizationId == null) {
      throw StateError('Tu usuario no pertenece a ningún grupo todavía.');
    }
    final ext = _extensionOf(file.path);
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.$ext';
    final path = '$organizationId/$workspaceId/$trayId/$fileName';
    await _client.storage.from(_bucket).upload(path, file, fileOptions: const FileOptions(upsert: true));
    return path;
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return 'jpg';
    return path.substring(dot + 1).toLowerCase();
  }

  /// El bucket es privado: la foto se muestra con una URL firmada de vida
  /// corta, resuelta cada vez que se necesita (mismo patrón que
  /// [CustomInstrumentService.getVariantPhotoUrl]).
  Future<String> getPhotoUrl(String photoPath) {
    return _client.storage.from(_bucket).createSignedUrl(photoPath, 3600);
  }

  Future<void> deletePhoto(String photoPath) async {
    await _client.storage.from(_bucket).remove([photoPath]);
  }
}
