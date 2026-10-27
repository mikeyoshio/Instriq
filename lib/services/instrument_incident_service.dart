import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/instrument_incident.dart';
import 'profile_service.dart';

/// Gestión de incidencias de un instrumento (catálogo global o instrumento
/// personalizado), como flujo CAPA real (ISO 9001 10.2): reportar -> resolver
/// (causa raíz + acción correctiva) -> verificar (efectividad confirmada por
/// alguien distinto de quien resolvió). Todas las escrituras van vía función
/// `security definer` (ver supabase/schema_v55_instrument_incidents_capa.sql)
/// -- igual criterio que `TrayPreparationService`/`TeamService`: la
/// validación de permiso y el registro de auditoría viven en un único sitio
/// de confianza, no aquí ni en RLS directa.
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

  /// Todas las incidencias de la organización actual (cola CAPA agregada,
  /// EPIC ISO 9001) -- la política de select ya es transparente a nivel de
  /// organización, así que esto es un select directo, no un RPC. Excluye
  /// `verified` por defecto: la cola se piensa para lo todavía accionable.
  Future<List<InstrumentIncident>> fetchForOrganization({bool includeVerified = false}) async {
    final organizationId = ProfileService.instance.organizationId;
    if (organizationId == null) return [];
    var query = _client.from('instrument_incidents').select().eq('organization_id', organizationId);
    if (!includeVerified) {
      query = query.neq('status', IncidentStatus.verified.dbValue);
    }
    final rows = await query.order('created_at', ascending: false);
    return (rows as List<dynamic>).map((r) => InstrumentIncident.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// [workspaceId] nulo reporta la incidencia a nivel de organización (no de
  /// un espacio concreto) -- el RPC solo exige rol de espacio (`editor`+)
  /// cuando [workspaceId] no es nulo, igual que la antigua política de
  /// insert. [trayPreparationSessionId] enlaza la incidencia a la sesión de
  /// preparación de bandeja que la originó, cuando aplica (p. ej. un QC
  /// fallido) -- opcional, una incidencia también puede reportarse sin este
  /// enlace desde la ficha de un instrumento.
  Future<InstrumentIncident> report({
    required String refType,
    required String refId,
    String? workspaceId,
    required IncidentSeverity severity,
    required String description,
    String? trayPreparationSessionId,
  }) async {
    final row = await _client.rpc('report_instrument_incident', params: {
      'p_instrument_ref_type': refType,
      'p_instrument_ref_id': refId,
      'p_severity': severity.dbValue,
      'p_description': description,
      'p_workspace_id': workspaceId,
      'p_tray_preparation_session_id': trayPreparationSessionId,
    });
    return InstrumentIncident.fromRow(row as Map<String, dynamic>);
  }

  /// Exige causa raíz y acción correctiva (ISO 9001 10.2) -- el RPC rechaza
  /// una resolución sin ambos campos, y exige `approver`/`administrator` de
  /// espacio o admin de organización (el fix real del bug de RLS anterior).
  Future<InstrumentIncident> resolve(
    String incidentId, {
    required String rootCause,
    required String correctiveAction,
    String? resolutionNotes,
  }) async {
    final row = await _client.rpc('resolve_instrument_incident', params: {
      'p_incident_id': incidentId,
      'p_root_cause': rootCause,
      'p_corrective_action': correctiveAction,
      'p_resolution_notes': resolutionNotes,
    });
    return InstrumentIncident.fromRow(row as Map<String, dynamic>);
  }

  /// Cierra el ciclo CAPA confirmando que la acción correctiva fue efectiva.
  /// El RPC rechaza que quien resolvió también verifique (separación de
  /// funciones).
  Future<InstrumentIncident> verify(String incidentId, {String? verificationNotes}) async {
    final row = await _client.rpc('verify_instrument_incident', params: {
      'p_incident_id': incidentId,
      'p_verification_notes': verificationNotes,
    });
    return InstrumentIncident.fromRow(row as Map<String, dynamic>);
  }
}
