import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/audit_entry.dart';

/// Consulta el log de auditoría (`audit_log`). Solo admin/owner del hospital
/// ven filas (la RLS de `audit_log` lo garantiza en el servidor, ver
/// supabase/schema_v10_audit.sql); nadie inserta/edita/borra desde el
/// cliente, esas filas las crean únicamente las funciones `security definer`.
class AuditService {
  AuditService._();
  static final AuditService instance = AuditService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Trae las entradas del log, más recientes primero. `actor_id` referencia
  /// a `auth.users`, no a `profiles`, así que PostgREST no puede embeber el
  /// nombre del autor directamente: se resuelve aparte con una consulta a
  /// `profiles` y se combina en memoria (mismo patrón que
  /// WorkspaceService.fetchMembers).
  Future<List<AuditEntry>> fetchAuditLog({
    String? hospitalId,
    String? workspaceId,
    DateTime? since,
  }) async {
    var query = _client.from('audit_log').select('*, workspaces(name)');
    if (hospitalId != null) {
      query = query.eq('hospital_id', hospitalId);
    }
    if (workspaceId != null) {
      query = query.eq('workspace_id', workspaceId);
    }
    if (since != null) {
      query = query.gte('created_at', since.toIso8601String());
    }
    final rows = await query.order('created_at', ascending: false);
    final entries = (rows as List<dynamic>)
        .map((r) => AuditEntry.fromRow(r as Map<String, dynamic>))
        .toList();

    final actorIds = entries.map((e) => e.actorId).whereType<String>().toSet().toList();
    if (actorIds.isEmpty) {
      return entries;
    }

    final profileRows = await _client.from('profiles').select('id, display_name').inFilter('id', actorIds);
    final namesByActor = <String, String?>{
      for (final r in (profileRows as List<dynamic>))
        (r as Map<String, dynamic>)['id'] as String: r['display_name'] as String?,
    };

    return entries
        .map((e) => e.copyWith(actorDisplayName: e.actorId != null ? namesByActor[e.actorId] : null))
        .toList();
  }
}
