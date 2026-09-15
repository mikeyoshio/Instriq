import 'package:cross_file/cross_file.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/custom_instrument.dart';
import '../models/group_document_version.dart';
import 'auth_service.dart';

/// CRUD y workflow (borrador -> en revisión -> publicada -> archivada) del
/// instrumental personalizado de un equipo. Calcado de [TrayService] (ver
/// supabase/schema_v39_custom_instrument_versioning.sql) — las variantes
/// (nombre/foto/nota) viven dentro de la versión como jsonb, igual que los
/// items de una bandeja: editarlas exige un borrador nuevo, no un CRUD aparte
/// como antes de esta migración (ver docs/ADR_004_VERSIONING.md §5).
///
/// A diferencia de [TrayService]/[GroupDocumentService], no pasa por
/// [SyncQueueService]/[OfflineCacheService]: el modo sin conexión no se pidió
/// para esta 4a instancia (ver docs/BACKLOG.md) — se puede generalizar más
/// adelante si el uso real lo pide, siguiendo el mismo patrón ya probado en
/// los otros 3 servicios.
class CustomInstrumentService {
  CustomInstrumentService._();
  static final CustomInstrumentService instance = CustomInstrumentService._();

  SupabaseClient get _client => Supabase.instance.client;

  static const _bucket = 'custom-instrument-photos';
  static const _publishedJoin = '*, published_version:published_version_id(*)';

  List<CustomInstrument> _instruments = [];

  List<CustomInstrument> get instruments => List.unmodifiable(_instruments);

  /// Limpia el caché en memoria. Debe llamarse al cambiar de grupo o cerrar
  /// sesión: si no, instrumental de un workspace anterior puede quedar visible.
  void clear() {
    _instruments = [];
  }

  Future<void> fetchForWorkspace(String workspaceId) async {
    final rows = await _client.from('custom_instruments').select(_publishedJoin).eq('workspace_id', workspaceId);
    final fetched = (rows as List<dynamic>).map((r) => CustomInstrument.fromRow(r as Map<String, dynamic>)).toList();
    fetched.sort((a, b) => a.name.compareTo(b.name));
    _instruments = [
      ..._instruments.where((i) => i.workspaceId != workspaceId),
      ...fetched,
    ];
  }

  CustomInstrument? byId(String id) {
    for (final i in _instruments) {
      if (i.id == id) return i;
    }
    return null;
  }

  /// Fetch puntual por id (con la versión publicada resuelta), sin pasar por
  /// el caché de workspace — usado por [RecentActivityService]/
  /// [FavoritesService] para resolver un ref a título humano, y para
  /// refrescar la ficha tras editar/aprobar.
  Future<CustomInstrument> fetchById(String id) async {
    final row = await _client.from('custom_instruments').select(_publishedJoin).eq('id', id).single();
    return CustomInstrument.fromRow(row);
  }

  Future<List<CustomInstrumentVersion>> fetchVersionHistory(String instrumentId) async {
    final rows = await _client
        .from('custom_instrument_versions')
        .select()
        .eq('custom_instrument_id', instrumentId)
        .order('version_number', ascending: false);
    return (rows as List<dynamic>).map((r) => CustomInstrumentVersion.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// Crea un instrumento nuevo con su primera versión en borrador.
  Future<CustomInstrumentVersion> create(String workspaceId) async {
    final versionRow = await _client.rpc('create_custom_instrument', params: {'p_workspace_id': workspaceId});
    return CustomInstrumentVersion.fromRow(versionRow as Map<String, dynamic>);
  }

  /// Devuelve el borrador propio en curso para [instrument] si existe, o crea
  /// uno nuevo a partir de la versión publicada.
  Future<CustomInstrumentVersion> startEditing(CustomInstrument instrument) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      throw StateError('Tu usuario no pertenece a ningún grupo todavía.');
    }
    final existing = await _client
        .from('custom_instrument_versions')
        .select()
        .eq('custom_instrument_id', instrument.id)
        .eq('author_id', userId)
        .inFilter('status', ['draft', 'in_review'])
        .order('version_number', ascending: false)
        .limit(1)
        .maybeSingle();
    if (existing != null) {
      final version = CustomInstrumentVersion.fromRow(existing);
      // Ver la nota equivalente en TrayService.startEditing: una versión en
      // revisión no es continuable (la política de UPDATE exige
      // status = 'draft'), así que hay que avisar aquí, no dejar que falle
      // al guardar con un error de Postgres críptico.
      if (version.status == GroupDocumentVersionStatus.inReview) {
        throw StateError(
            'Ya tienes una versión enviada a revisión: no se puede editar hasta que se apruebe, se rechace o se retire.');
      }
      return version;
    }

    final published = instrument.publishedVersion;
    if (published == null) {
      throw StateError('Este instrumento todavía no tiene una versión publicada.');
    }
    final versions = await fetchVersionHistory(instrument.id);
    final nextVersionNumber =
        versions.isEmpty ? 1 : versions.map((v) => v.versionNumber).reduce((a, b) => a > b ? a : b) + 1;

    final versionRow = await _client
        .from('custom_instrument_versions')
        .insert({
          'custom_instrument_id': instrument.id,
          'version_number': nextVersionNumber,
          'status': GroupDocumentVersionStatus.draft.dbValue,
          'name': published.name,
          'category': published.category,
          'specialty_id': published.specialtyId,
          'description': published.description,
          'use_text': published.useText,
          'tip': published.tip,
          'variants': published.variants.map((v) => v.toJson()).toList(),
          'author_id': userId,
          'based_on_version_id': published.id,
        })
        .select()
        .single();
    return CustomInstrumentVersion.fromRow(versionRow);
  }

  /// Crea un instrumento nuevo en el mismo espacio a partir del contenido
  /// PUBLICADO de [instrumentId] (ver `duplicate_custom_instrument` en
  /// schema_v40_duplicate_content.sql). Devuelve el borrador (versión 1) ya
  /// listo para editar -- las variantes se copian, pero nunca su foto (una
  /// variante duplicada es un punto de partida nuevo, no el mismo objeto
  /// físico fotografiado).
  Future<CustomInstrumentVersion> duplicate(String instrumentId) async {
    final versionRow = await _client.rpc('duplicate_custom_instrument', params: {'p_instrument_id': instrumentId});
    return CustomInstrumentVersion.fromRow(versionRow as Map<String, dynamic>);
  }

  Future<CustomInstrumentVersion> saveDraft(CustomInstrumentVersion version) async {
    final row =
        await _client.from('custom_instrument_versions').update(version.toRow()).eq('id', version.id).select().single();
    return CustomInstrumentVersion.fromRow(row);
  }

  Future<void> submitForReview(String versionId) async {
    await _client.rpc('submit_custom_instrument_version_for_review', params: {'p_version_id': versionId});
  }

  Future<void> approve(String versionId, {String? comment}) async {
    await _client.rpc('approve_custom_instrument_version', params: {
      'p_version_id': versionId,
      'p_review_comment': comment,
    });
  }

  Future<void> reject(String versionId, {String? comment}) async {
    await _client.rpc('reject_custom_instrument_version', params: {
      'p_version_id': versionId,
      'p_review_comment': comment,
    });
  }

  Future<String> restore(String versionId) async {
    final newId = await _client.rpc('restore_custom_instrument_version', params: {'p_version_id': versionId});
    return newId as String;
  }

  /// Versiones en revisión de todo el grupo, para la cola de aprobación.
  Future<List<CustomInstrumentVersion>> fetchReviewQueue() async {
    final rows = await _client
        .from('custom_instrument_versions')
        .select()
        .eq('status', GroupDocumentVersionStatus.inReview.dbValue)
        .order('created_at');
    return (rows as List<dynamic>).map((r) => CustomInstrumentVersion.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// Nombre del espacio de cada instrumento, para mostrar contexto en la cola
  /// de revisión (mismo patrón que [TrayService.fetchWorkspaceNamesForTrays]).
  Future<Map<String, String>> fetchWorkspaceNamesForInstruments(List<String> instrumentIds) async {
    if (instrumentIds.isEmpty) return {};
    final rows =
        await _client.from('custom_instruments').select('id, workspaces(name)').inFilter('id', instrumentIds);
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

  Future<void> delete(String id) async {
    await _client.rpc('delete_custom_instrument', params: {'p_instrument_id': id});
    _instruments.removeWhere((i) => i.id == id);
  }

  /// Sube una foto de variante al bucket privado `custom-instrument-photos`,
  /// con un nombre de archivo único por subida (timestamp, no
  /// `{variant_id}.ext` fijo como antes de esta migración) para que una foto
  /// nueva de un borrador nunca pise la que ya se muestra en la versión
  /// publicada mientras se aprueba — mismo criterio que
  /// [TrayService.uploadPhoto]. Devuelve el path guardado, que hay que
  /// asignar a [CustomInstrumentVariant.photoPath] y persistir con
  /// [saveDraft].
  ///
  /// Recibe un [XFile] y sube sus bytes con `uploadBinary` en vez de
  /// envolverlo en un `dart:io.File` y usar `upload` -- en Flutter Web,
  /// `XFile.path` es una blob: URL, no una ruta de disco real, así que un
  /// `File` construido a partir de ella no servía para nada (bug real que
  /// rompía esta subida en Web, encontrado al construir el escaneo OCR, ver
  /// `OcrService`).
  Future<String> uploadVariantPhoto({
    required String organizationId,
    required String workspaceId,
    required String instrumentId,
    required XFile file,
  }) async {
    // file.name (no file.path): en Web, path es una blob: URL sin extensión.
    final ext = _extensionOf(file.name);
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.$ext';
    final path = '$organizationId/$workspaceId/$instrumentId/$fileName';
    final bytes = await file.readAsBytes();
    await _client.storage.from(_bucket).uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
    return path;
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return 'jpg';
    return path.substring(dot + 1).toLowerCase();
  }

  /// El bucket es privado, así que la foto solo se puede mostrar con una URL
  /// firmada de vida corta — se resuelve cada vez que se necesita mostrar,
  /// no se guarda en ningún sitio.
  Future<String> getVariantPhotoUrl(String photoPath) {
    return _client.storage.from(_bucket).createSignedUrl(photoPath, 3600);
  }

  Future<void> deleteVariantPhoto(String photoPath) async {
    await _client.storage.from(_bucket).remove([photoPath]);
  }
}
