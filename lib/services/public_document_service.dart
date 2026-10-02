import '../models/group_document.dart' show DocumentKindLabel, DocumentKind;
import '../models/public_document.dart';
import 'connectivity_service.dart';
import 'offline_cache_service.dart';
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

  /// true si el darrer [fetchPublished] s'ha servit d'[OfflineCacheService]
  /// en comptes de xarxa (sense connexió, o la petició ha fallat per un
  /// problema de xarxa) -- la UI ho llegeix just després per mostrar l'avís
  /// offline, mateix patró que [GroupDocumentService].
  bool lastFetchFromCache = false;
  DateTime? lastFetchCachedAt;

  /// Documents publicats, agrupats per `kind` -- llista pública, llegible
  /// sense sessió (RLS: `public_documents_select` és `using (true)`).
  Future<List<PublicDocument>> fetchPublished(DocumentKind kind) async {
    Future<List<PublicDocument>> fallbackToCache() async {
      final cached = await OfflineCacheService.instance.getCachedPublicDocuments(kind.dbValue);
      lastFetchFromCache = true;
      lastFetchCachedAt = cached?.cachedAt;
      return cached?.data ?? [];
    }

    if (!ConnectivityService.instance.isOnline.value) return fallbackToCache();
    try {
      final rows = await client
          .from('public_documents')
          .select('*, published_version:public_document_versions!published_version_id(*)')
          .eq('kind', kind.dbValue)
          .not('published_version_id', 'is', null)
          .order('created_at', ascending: false);
      final fetched = (rows as List).map((r) => PublicDocument.fromRow((r as Map).cast<String, dynamic>())).toList();
      lastFetchFromCache = false;
      lastFetchCachedAt = null;
      await OfflineCacheService.instance.cachePublicDocuments(kind.dbValue, fetched);
      return fetched;
    } catch (e) {
      if (!ConnectivityService.isNetworkError(e)) rethrow;
      return fallbackToCache();
    }
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

  /// Totes les variants d'idioma d'"el mateix" document (mateix
  /// `translation_group_id`) -- inclou l'actual. Sense sessió: nomes es
  /// veuen les que ja tenen versió publicada, mateix criteri de
  /// `fetchPublished`.
  Future<List<PublicDocument>> fetchTranslations(String translationGroupId) async {
    final rows = await client
        .from('public_documents')
        .select('*, published_version:public_document_versions!published_version_id(*)')
        .eq('translation_group_id', translationGroupId)
        .not('published_version_id', 'is', null);
    return (rows as List).map((r) => PublicDocument.fromRow((r as Map).cast<String, dynamic>())).toList();
  }

  /// Proposa una traducció a `locale` a partir de la versió PUBLICADA de
  /// `sourceDocumentId` -- mai traducció automàtica (`propose_document_
  /// translation`, schema_v50): crea un document nou (mateix
  /// `translation_group_id`) amb un primer esborrany ja precarregat amb el
  /// contingut d'origen, perquè qui tradueix parteixi d'un text real i no
  /// d'una pàgina en blanc. Retorna l'id del document nou.
  Future<String> proposeTranslation(String sourceDocumentId, String locale) async {
    final result = await client.rpc('propose_document_translation', params: {
      'p_source_document_id': sourceDocumentId,
      'p_locale': locale,
    });
    return result as String;
  }
}
