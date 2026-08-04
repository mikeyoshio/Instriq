import 'package:supabase_flutter/supabase_flutter.dart';

/// Base compartida per al flux de treball (submit/approve/reject) de
/// contingut versionat de la Biblioteca Pública -- decisió d'ADR-004 §3
/// (docs/ADR_004_VERSIONING.md): a diferència de SQL (on cada taula manté
/// el seu propi RPC), a Dart sí que compensa una base compartida quan es
/// construeixen diverses instàncies noves alhora (aquí: documents + safates
/// públiques) -- els 3 serveis privats existents (`GroupDocumentService`/
/// `TrayService`/`PreferenceCardService`) NO es toquen ni es migren a
/// aquesta base, per no refactoritzar codi ja provat sense necessitat.
abstract class PublicVersionedContentService<TVersion> {
  SupabaseClient get client => Supabase.instance.client;

  /// Nom de la taula de versions (`public_document_versions`/`public_tray_versions`).
  String get versionTable;

  /// Nom de les 3 RPC de flux (`submit_public_document_version_for_review`, etc.).
  String get submitRpcName;
  String get approveRpcName;
  String get rejectRpcName;

  TVersion versionFromRow(Map<String, dynamic> row);

  Future<List<TVersion>> fetchReviewQueue() async {
    final rows = await client.from(versionTable).select().eq('status', 'in_review').order('created_at');
    return (rows as List).map((r) => versionFromRow((r as Map).cast<String, dynamic>())).toList();
  }

  Future<void> submitForReview(String versionId) async {
    await client.rpc(submitRpcName, params: {'p_version_id': versionId});
  }

  Future<void> approve(String versionId, {String? comment}) async {
    await client.rpc(approveRpcName, params: {'p_version_id': versionId, 'p_review_comment': comment});
  }

  Future<void> reject(String versionId, {String? comment}) async {
    await client.rpc(rejectRpcName, params: {'p_version_id': versionId, 'p_review_comment': comment});
  }
}
