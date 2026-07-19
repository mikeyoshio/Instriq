import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_document.dart';
import '../models/group_document_version.dart';
import 'auth_service.dart';
import 'profile_service.dart';

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

  List<GroupDocument> documentsOfKind(DocumentKind kind) =>
      _documents.where((d) => d.kind == kind).toList();

  Future<void> fetchDocuments(DocumentKind kind) async {
    final rows = await _client
        .from('group_documents')
        .select(_publishedJoin)
        .eq('kind', kind.dbValue);
    final fetched = (rows as List<dynamic>)
        .map((r) => GroupDocument.fromRow(r as Map<String, dynamic>))
        .toList();
    fetched.sort((a, b) => (a.publishedVersion?.title ?? '').compareTo(b.publishedVersion?.title ?? ''));
    _documents = [..._documents.where((d) => d.kind != kind), ...fetched];
  }

  GroupDocument? documentById(String id) {
    for (final d in _documents) {
      if (d.id == id) return d;
    }
    return null;
  }

  Future<GroupDocument> fetchDocument(String id) async {
    final row = await _client.from('group_documents').select(_publishedJoin).eq('id', id).single();
    return GroupDocument.fromRow(row);
  }

  Future<List<GroupDocumentVersion>> fetchVersionHistory(String documentId) async {
    final rows = await _client
        .from('group_document_versions')
        .select()
        .eq('document_id', documentId)
        .order('version_number', ascending: false);
    return (rows as List<dynamic>)
        .map((r) => GroupDocumentVersion.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  /// Crea un documento nuevo con su primera versión en borrador.
  Future<GroupDocumentVersion> createDocument(DocumentKind kind) async {
    final hospitalId = ProfileService.instance.hospitalId;
    final userId = AuthService.instance.currentUser?.id;
    if (hospitalId == null || userId == null) {
      throw StateError('Tu usuario no pertenece a ningún grupo todavía.');
    }
    final document = GroupDocument(id: '', kind: kind);
    final savedDocument = await _client
        .from('group_documents')
        .insert(document.toRow(hospitalId: hospitalId))
        .select()
        .single();
    final documentId = savedDocument['id'] as String;

    final versionRow = await _client
        .from('group_document_versions')
        .insert({
          'document_id': documentId,
          'version_number': 1,
          'status': GroupDocumentVersionStatus.draft.dbValue,
          'title': '',
          'author_id': userId,
        })
        .select()
        .single();
    return GroupDocumentVersion.fromRow(versionRow);
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
      return GroupDocumentVersion.fromRow(existing);
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
          'specialty': published.specialty,
          'content': published.content,
          'steps': published.steps,
          'related_instrument_ids': published.relatedInstrumentIds,
          'author_id': userId,
          'based_on_version_id': published.id,
        })
        .select()
        .single();
    return GroupDocumentVersion.fromRow(versionRow);
  }

  Future<GroupDocumentVersion> saveDraft(GroupDocumentVersion version) async {
    final row = await _client
        .from('group_document_versions')
        .update(version.toRow())
        .eq('id', version.id)
        .select()
        .single();
    return GroupDocumentVersion.fromRow(row);
  }

  Future<void> submitForReview(String versionId) async {
    await _client.rpc('submit_group_document_version_for_review', params: {'p_version_id': versionId});
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

  Future<void> deleteDocument(String id) async {
    await _client.from('group_documents').delete().eq('id', id);
    _documents.removeWhere((d) => d.id == id);
  }
}
