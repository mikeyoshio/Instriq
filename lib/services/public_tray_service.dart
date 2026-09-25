import '../models/public_tray.dart';
import 'public_versioned_content_service.dart';

class PublicTrayService extends PublicVersionedContentService<PublicTrayVersion> {
  PublicTrayService._();
  static final PublicTrayService instance = PublicTrayService._();

  @override
  String get versionTable => 'public_tray_versions';
  @override
  String get submitRpcName => 'submit_public_tray_version_for_review';
  @override
  String get approveRpcName => 'approve_public_tray_version';
  @override
  String get rejectRpcName => 'reject_public_tray_version';

  @override
  PublicTrayVersion versionFromRow(Map<String, dynamic> row) => PublicTrayVersion.fromRow(row);

  /// Safates publicades -- llista pública, llegible sense sessió (RLS:
  /// `public_trays_select` és `using (true)`).
  Future<List<PublicTray>> fetchPublished() async {
    final rows = await client
        .from('public_trays')
        .select('*, published_version:public_tray_versions!published_version_id(*)')
        .not('published_version_id', 'is', null)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => PublicTray.fromRow((r as Map).cast<String, dynamic>())).toList();
  }

  Future<PublicTray> fetchTray(String id) async {
    final row = await client
        .from('public_trays')
        .select('*, published_version:public_tray_versions!published_version_id(*)')
        .eq('id', id)
        .single();
    return PublicTray.fromRow(row);
  }

  /// Safates recomanades per a una especialitat (wizard de creació d'espai,
  /// `starter_sets` -- ver schema_v49_workspace_wizard.sql), ordenades pel
  /// `sort_order` curat pel Consell Editorial. Llista buida si encara no hi
  /// ha cap curació per a aquesta especialitat -- cas normal mentre la
  /// Biblioteca Pública tingui poc contingut publicat, no un error.
  Future<List<PublicTray>> fetchStarterSet(String specialtyId) async {
    final rows = await client
        .from('starter_sets')
        .select('public_trays(*, published_version:public_tray_versions!published_version_id(*))')
        .eq('specialty_id', specialtyId)
        .order('sort_order');
    return (rows as List)
        .map((r) => (r as Map)['public_trays'] as Map<String, dynamic>?)
        .where((t) => t != null)
        .map((t) => PublicTray.fromRow(t!))
        .toList();
  }

  Future<List<PublicTrayVersion>> fetchVersionHistory(String trayId) async {
    final rows = await client
        .from('public_tray_versions')
        .select()
        .eq('tray_id', trayId)
        .order('version_number', ascending: false);
    return (rows as List).map((r) => PublicTrayVersion.fromRow((r as Map).cast<String, dynamic>())).toList();
  }

  Future<String> createDraft() async {
    final result = await client.rpc('create_public_tray');
    return result as String;
  }

  Future<PublicTrayVersion> fetchDraftVersion(String trayId) async {
    final row = await client
        .from('public_tray_versions')
        .select()
        .eq('tray_id', trayId)
        .eq('status', 'draft')
        .order('version_number', ascending: false)
        .limit(1)
        .single();
    return PublicTrayVersion.fromRow(row);
  }

  Future<void> saveDraft(String versionId, PublicTrayVersion draft) async {
    await client.from('public_tray_versions').update(draft.toRow()).eq('id', versionId);
  }
}
