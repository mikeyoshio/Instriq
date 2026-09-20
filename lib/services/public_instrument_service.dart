import 'package:cross_file/cross_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/public_instrument.dart';
import 'public_versioned_content_service.dart';

class PublicInstrumentService extends PublicVersionedContentService<PublicInstrumentVersion> {
  PublicInstrumentService._();
  static final PublicInstrumentService instance = PublicInstrumentService._();

  static const _bucket = 'public-instrument-photos';

  @override
  String get versionTable => 'public_instrument_versions';
  @override
  String get submitRpcName => 'submit_public_instrument_version_for_review';
  @override
  String get approveRpcName => 'approve_public_instrument_version';
  @override
  String get rejectRpcName => 'reject_public_instrument_version';

  @override
  PublicInstrumentVersion versionFromRow(Map<String, dynamic> row) => PublicInstrumentVersion.fromRow(row);

  /// Instruments publicats -- llista pública, llegible sense sessió (RLS:
  /// `public_instruments_select` és `using (true)`).
  Future<List<PublicInstrument>> fetchPublished() async {
    final rows = await client
        .from('public_instruments')
        .select('*, published_version:public_instrument_versions!published_version_id(*)')
        .not('published_version_id', 'is', null)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => PublicInstrument.fromRow((r as Map).cast<String, dynamic>())).toList();
  }

  Future<PublicInstrument> fetchInstrument(String id) async {
    final row = await client
        .from('public_instruments')
        .select('*, published_version:public_instrument_versions!published_version_id(*)')
        .eq('id', id)
        .single();
    return PublicInstrument.fromRow(row);
  }

  Future<List<PublicInstrumentVersion>> fetchVersionHistory(String instrumentId) async {
    final rows = await client
        .from('public_instrument_versions')
        .select()
        .eq('instrument_id', instrumentId)
        .order('version_number', ascending: false);
    return (rows as List).map((r) => PublicInstrumentVersion.fromRow((r as Map).cast<String, dynamic>())).toList();
  }

  /// Crea la proposta (capçalera + primer esborrany) i retorna l'id de
  /// l'instrument -- mateix patró que `create_public_tray`.
  Future<String> createDraft() async {
    final result = await client.rpc('create_public_instrument');
    return result as String;
  }

  /// La primera versió (`version_number = 1`) creada per `create_public_instrument`.
  Future<PublicInstrumentVersion> fetchDraftVersion(String instrumentId) async {
    final row = await client
        .from('public_instrument_versions')
        .select()
        .eq('instrument_id', instrumentId)
        .eq('status', 'draft')
        .order('version_number', ascending: false)
        .limit(1)
        .single();
    return PublicInstrumentVersion.fromRow(row);
  }

  Future<void> saveDraft(String versionId, PublicInstrumentVersion draft) async {
    await client.from('public_instrument_versions').update(draft.toRow()).eq('id', versionId);
  }

  /// Bucket públic (a diferència de `custom-instrument-photos`, que és
  /// privat): la ruta és `{user_id}/{fitxer}`, no cal `workspace_id` perquè
  /// la Biblioteca Pública és ortogonal al model d'organitzacions.
  Future<String> uploadPhoto({required String userId, required XFile file}) async {
    final ext = _extensionOf(file.name);
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.$ext';
    final path = '$userId/$fileName';
    final bytes = await file.readAsBytes();
    await client.storage.from(_bucket).uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
    return path;
  }

  /// Bucket públic: URL directa i permanent, sense signar (a diferència de
  /// `CustomInstrumentService.photoUrl`, que necessita `createSignedUrl`
  /// perquè el seu bucket és privat).
  String photoUrl(String photoPath) => client.storage.from(_bucket).getPublicUrl(photoPath);

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return 'jpg';
    return path.substring(dot + 1).toLowerCase();
  }
}
