import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/procedure.dart';

/// Procediments per espai de treball (schema_v68). Lectura directa amb RLS;
/// escriptura només via RPC `security definer`, que valida rol i pertinença
/// al mateix espai i registra l'auditoria -- mateix criteri que
/// [SurgicalSlotService]. Les escriptures exigeixen connexió (punt de
/// coordinació, criteri ADR-003): no passen per la cua offline.
class ProcedureService {
  ProcedureService._();
  static final ProcedureService instance = ProcedureService._();

  SupabaseClient get _client => Supabase.instance.client;

  static const _select = '*, procedure_items(item_type, item_id, position)';

  Future<List<Procedure>> fetchForWorkspace(String workspaceId) async {
    final rows = await _client
        .from('procedures')
        .select(_select)
        .eq('workspace_id', workspaceId)
        .isFilter('archived_at', null)
        .order('name');
    return (rows as List<dynamic>).map((r) => Procedure.fromRow(r as Map<String, dynamic>)).toList();
  }

  Future<Procedure?> fetchById(String id) async {
    final row = await _client.from('procedures').select(_select).eq('id', id).maybeSingle();
    return row == null ? null : Procedure.fromRow(row);
  }

  /// [id] null crea un procediment nou; si no, l'actualitza (mai el mou d'espai).
  Future<Procedure> upsert({
    String? id,
    required String workspaceId,
    required String name,
    String? specialtyId,
    String? description,
  }) async {
    final row = await _client.rpc('upsert_procedure', params: {
      'p_id': id,
      'p_workspace_id': workspaceId,
      'p_name': name,
      'p_specialty_id': specialtyId,
      'p_description': description,
    });
    return Procedure.fromRow(row as Map<String, dynamic>);
  }

  /// Substitueix la llista sencera d'elements, en l'ordre donat.
  Future<void> setItems(String procedureId, List<ProcedureItem> items) async {
    await _client.rpc('set_procedure_items', params: {
      'p_procedure_id': procedureId,
      'p_items': items.map((i) => i.toRpc()).toList(),
    });
  }

  Future<void> archive(String procedureId) async {
    await _client.rpc('archive_procedure', params: {'p_procedure_id': procedureId});
  }
}
