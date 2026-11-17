import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/surgical_slot.dart';
import 'supabase_config.dart';

/// Huecos de agenda quirúrgica por espacio y el feed `.ics` suscribible de
/// cada cirujano. Va vía funciones `security definer` (ver
/// supabase/schema_v64_surgical_agenda.sql) para que la validación de rol y
/// el registro de auditoría vivan en un único sitio de confianza, mismo
/// criterio que [TrayPreparationService].
class SurgicalSlotService {
  SurgicalSlotService._();
  static final SurgicalSlotService instance = SurgicalSlotService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<SurgicalSlot>> fetchForWorkspace(String workspaceId, {bool includePast = false}) async {
    var query = _client.from('surgical_slots').select().eq('workspace_id', workspaceId);
    if (!includePast) {
      final cutoff = DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
      query = query.gte('starts_at', cutoff);
    }
    final rows = await query.order('starts_at');
    return (rows as List<dynamic>).map((r) => SurgicalSlot.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// Cites del dia local de [day] a tots els espais visibles de la meva
  /// organització, ordenades per hora. El filtre explícit per organització
  /// és defensa en profunditat: no depèn que la RLS de `surgical_slots` estigui
  /// ben acotada (no ho va estar fins a schema_v69).
  Future<List<SurgicalSlot>> fetchForDay(DateTime day, {required String organizationId}) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    final rows = await _client
        .from('surgical_slots')
        .select()
        .eq('organization_id', organizationId)
        .eq('status', SurgicalSlotStatus.scheduled.dbValue)
        .gte('starts_at', start.toUtc().toIso8601String())
        .lt('starts_at', end.toUtc().toIso8601String())
        .order('starts_at');
    return (rows as List<dynamic>).map((r) => SurgicalSlot.fromRow(r as Map<String, dynamic>)).toList();
  }

  Future<SurgicalSlot> createSlot({
    required String workspaceId,
    required String surgeonId,
    required DateTime startsAt,
    required DateTime endsAt,
    String? preferenceCardId,
    String? documentId,
    String? trayId,
    String? procedureName,
    String? location,
    String? notes,
    String? procedureId,
  }) async {
    final row = await _client.rpc('create_surgical_slot', params: {
      'p_workspace_id': workspaceId,
      'p_surgeon_id': surgeonId,
      'p_starts_at': startsAt.toIso8601String(),
      'p_ends_at': endsAt.toIso8601String(),
      'p_preference_card_id': preferenceCardId,
      'p_document_id': documentId,
      'p_tray_id': trayId,
      'p_procedure_name': procedureName,
      'p_location': location,
      'p_notes': notes,
      'p_procedure_id': procedureId,
    });
    return SurgicalSlot.fromRow(row as Map<String, dynamic>);
  }

  Future<SurgicalSlot> updateSlot({
    required String slotId,
    required String surgeonId,
    required DateTime startsAt,
    required DateTime endsAt,
    String? preferenceCardId,
    String? documentId,
    String? trayId,
    String? procedureName,
    String? location,
    String? notes,
    String? procedureId,
  }) async {
    final row = await _client.rpc('update_surgical_slot', params: {
      'p_slot_id': slotId,
      'p_surgeon_id': surgeonId,
      'p_starts_at': startsAt.toIso8601String(),
      'p_ends_at': endsAt.toIso8601String(),
      'p_preference_card_id': preferenceCardId,
      'p_document_id': documentId,
      'p_tray_id': trayId,
      'p_procedure_name': procedureName,
      'p_location': location,
      'p_notes': notes,
      'p_procedure_id': procedureId,
    });
    return SurgicalSlot.fromRow(row as Map<String, dynamic>);
  }

  Future<void> cancelSlot(String slotId, {String? reason}) async {
    await _client.rpc('cancel_surgical_slot', params: {'p_slot_id': slotId, 'p_reason': reason});
  }

  Future<String> getIcsToken(String surgeonId) async {
    final token = await _client.rpc('surgical_agenda_ics_token', params: {'p_surgeon_id': surgeonId});
    return token as String;
  }

  Future<String> regenerateIcsToken(String surgeonId) async {
    final token = await _client.rpc('regenerate_surgical_agenda_ics_token', params: {'p_surgeon_id': surgeonId});
    return token as String;
  }

  /// Apple (Calendario de iPhone) y Outlook entienden `webcal://` nativo y lo
  /// abren directo en el flujo de suscripción; se expone también
  /// [httpsIcsUrl] porque Google Calendar históricamente pide `https://` en
  /// "Añadir por URL" y no reconoce el esquema `webcal://`.
  String webcalUrl(String token) => _icsBase(token).replaceFirst(RegExp(r'^https?://'), 'webcal://');

  String httpsIcsUrl(String token) => _icsBase(token);

  String _icsBase(String token) => '$supabaseUrl/functions/v1/surgical-agenda-ics?token=$token';
}
