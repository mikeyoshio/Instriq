import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/instrument_incident.dart';
import 'auth_service.dart';
import 'profile_service.dart';

/// CRUD de incidencias de un instrumento (catálogo global o instrumento
/// personalizado). Sin RPC ni versionado -- es un registro operativo, mismo
/// criterio que `favorites`/`taggings`, no una decisión editorial que
/// necesite pasar por borrador/revisión/aprobación (ver
/// supabase/schema_v32_cssd_workspace.sql §3). Resolver una incidencia sí
/// exige `approver`/`administrator` (RLS de update), pero eso lo comprueba
/// la base de datos -- este servicio deja que la excepción de Supabase
/// llegue tal cual a quien llama, sin comprobación de rol duplicada aquí.
class InstrumentIncidentService {
  InstrumentIncidentService._();
  static final InstrumentIncidentService instance = InstrumentIncidentService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<InstrumentIncident>> fetchForInstrument(String refType, String refId) async {
    final rows = await _client
        .from('instrument_incidents')
        .select()
        .eq('instrument_ref_type', refType)
        .eq('instrument_ref_id', refId)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>).map((r) => InstrumentIncident.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// [workspaceId] nulo reporta la incidencia a nivel de organización (no de
  /// un espacio concreto) -- ver RLS insert de `instrument_incidents`, que
  /// solo exige rol de espacio (`editor`+) cuando [workspaceId] no es nulo.
  Future<InstrumentIncident> report({
    required String refType,
    required String refId,
    String? workspaceId,
    required IncidentSeverity severity,
    required String description,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    final organizationId = ProfileService.instance.organizationId;
    if (userId == null || organizationId == null) {
      throw StateError('Tu usuario no pertenece a ningún grupo todavía.');
    }
    final row = await _client
        .from('instrument_incidents')
        .insert({
          'instrument_ref_type': refType,
          'instrument_ref_id': refId,
          'organization_id': organizationId,
          'workspace_id': workspaceId,
          'severity': severity.dbValue,
          'status': IncidentStatus.open.dbValue,
          'description': description,
          'reported_by': userId,
        })
        .select()
        .single();
    return InstrumentIncident.fromRow(row);
  }

  Future<InstrumentIncident> resolve(String incidentId, {String? resolutionNotes}) async {
    final userId = AuthService.instance.currentUser?.id;
    final row = await _client
        .from('instrument_incidents')
        .update({
          'status': IncidentStatus.resolved.dbValue,
          'resolved_by': userId,
          'resolved_at': DateTime.now().toIso8601String(),
          'resolution_notes': resolutionNotes,
        })
        .eq('id', incidentId)
        .select()
        .single();
    return InstrumentIncident.fromRow(row);
  }
}
