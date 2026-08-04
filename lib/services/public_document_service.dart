import '../models/group_document.dart' show DocumentKindLabel, DocumentKind;
import '../models/public_document.dart';
import 'public_versioned_content_service.dart';

class PublicDocumentService extends PublicVersionedContentService<PublicDocumentVersion> {
  PublicDocumentService._();
  static final PublicDocumentService instance = PublicDocumentService._();

  @override
  String get versionTable => 'public_document_versions';
  @override
  String get submitRpcName => 'submit_public_document_version_for_review';
  @override
  String get approveRpcName => 'approve_public_document_version';
  @override
  String get rejectRpcName => 'reject_public_document_version';

  @override
  PublicDocumentVersion versionFromRow(Map<String, dynamic> row) => PublicDocumentVersion.fromRow(row);

  /// Documents publicats, agrupats per `kind` -- llista pública, llegible
  /// sense sessió (RLS: `public_documents_select` és `using (true)`).
  Future<List<PublicDocument>> fetchPublished(DocumentKind kind) async {
    final rows = await client
        .from('public_documents')
        .select('*, published_version:public_document_versions!published_version_id(*)')
        .eq('kind', kind.dbValue)
        .not('published_version_id', 'is', null)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => PublicDocument.fromRow((r as Map).cast<String, dynamic>())).toList();
  }

  Future<PublicDocument> fetchDocument(String id) async {
    final row = await client
        .from('public_documents')
        .select('*, published_version:public_document_versions!published_version_id(*)')
        .eq('id', id)
        .single();
    return PublicDocument.fromRow(row);
  }

  Future<List<PublicDocumentVersion>> fetchVersionHistory(String documentId) async {
    final rows = await client
        .from('public_document_versions')
        .select()
        .eq('document_id', documentId)
        .order('version_number', ascending: false);
    return (rows as List).map((r) => PublicDocumentVersion.fromRow((r as Map).cast<String, dynamic>())).toList();
  }

  /// Crea la proposta (capçalera + primer esborrany) i retorna l'id del
  /// document -- mateix patró que `create_group_document`.
  Future<String> createDraft(DocumentKind kind) async {
    final result = await client.rpc('create_public_document', params: {'p_kind': kind.dbValue});
    return result as String;
  }

  /// La primera versió (`version_number = 1`) creada per `create_public_document`.
  Future<PublicDocumentVersion> fetchDraftVersion(String documentId) async {
    final row = await client
        .from('public_document_versions')
        .select()
        .eq('document_id', documentId)
        .eq('status', 'draft')
        .order('version_number', ascending: false)
        .limit(1)
        .single();
    return PublicDocumentVersion.fromRow(row);
  }

  Future<void> saveDraft(String versionId, PublicDocumentVersion draft) async {
    await client.from('public_document_versions').update(draft.toRow()).eq('id', versionId);
  }
}
