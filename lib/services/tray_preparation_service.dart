import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/tray_preparation_session.dart';

/// Sesiones reales de preparación de una safata (montaje físico tras el
/// lavado/esterilización) y su control de calidad/validación — EPIC 4.
/// Va vía funciones `security definer` (ver
/// supabase/schema_v25_tray_preparation.sql) para que la validación de rol
/// y el registro de auditoría vivan en un único sitio de confianza, mismo
/// criterio que [TrayService]/[GroupDocumentService].
class TrayPreparationService {
  TrayPreparationService._();
  static final TrayPreparationService instance = TrayPreparationService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// `prepared_by`/`qc_by` referencian `auth.users`, no `profiles`, así que
  /// PostgREST no puede embeber el nombre directamente: se resuelve aparte y
  /// se combina en memoria (mismo patrón que `AuditService.fetchAuditLog`).
  Future<List<TrayPreparationSession>> fetchSessions(String trayId) async {
    final rows = await _client
        .from('tray_preparation_sessions')
        .select()
        .eq('tray_id', trayId)
        .order('prepared_at', ascending: false);
    final sessions =
        (rows as List<dynamic>).map((r) => TrayPreparationSession.fromRow(r as Map<String, dynamic>)).toList();

    final userIds = {
      ...sessions.map((s) => s.preparedBy).whereType<String>(),
      ...sessions.map((s) => s.qcBy).whereType<String>(),
    }.toList();
    if (userIds.isEmpty) return sessions;

    final profileRows = await _client.from('profiles').select('id, display_name').inFilter('id', userIds);
    final namesById = <String, String?>{
      for (final r in (profileRows as List<dynamic>))
        (r as Map<String, dynamic>)['id'] as String: r['display_name'] as String?,
    };

    return sessions
        .map((s) => s.copyWith(
              preparedByName: s.preparedBy != null ? namesById[s.preparedBy] : null,
              qcByName: s.qcBy != null ? namesById[s.qcBy] : null,
            ))
        .toList();
  }

  Future<String> createSession(String trayId, List<TrayPreparationItemResult> itemResults) async {
    final id = await _client.rpc('create_tray_preparation_session', params: {
      'p_tray_id': trayId,
      'p_item_results': itemResults.map((i) => i.toJson()).toList(),
    });
    return id as String;
  }

  Future<void> qcSession(String sessionId, {required bool passed, String? notes}) async {
    await _client.rpc('qc_tray_preparation_session', params: {
      'p_session_id': sessionId,
      'p_passed': passed,
      'p_notes': notes,
    });
  }
}
