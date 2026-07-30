import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/favorite_entry.dart';
import 'auth_service.dart';

/// Actividad reciente personal (ver
/// supabase/schema_v18_work_mode_favorites_recent.sql): igual que
/// [FavoritesService], estrictamente por usuario y no auditable. A
/// diferencia de favoritos, no hay delete (RLS no lo permite): cada visita
/// actualiza `viewed_at` en la fila existente vía upsert.
class RecentActivityService {
  RecentActivityService._();
  static final RecentActivityService instance = RecentActivityService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Fire-and-forget a propósito: los llamantes (initState de las fichas de
  /// detalle) no deben esperar ni mostrar error si esto falla — es un rastro
  /// de conveniencia, no una acción que el usuario haya pedido explícitamente
  /// (mismo criterio que `_bootstrap()` en app_root.dart).
  Future<void> recordView(String refType, String refId) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    try {
      await _client.from('recent_views').upsert(
        {
          'user_id': userId,
          'ref_type': refType,
          'ref_id': refId,
          'viewed_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,ref_type,ref_id',
      );
    } catch (_) {
      // Silencioso: ver comentario de la clase.
    }
  }

  Future<List<RecentViewEntry>> fetchRecent({int limit = 8}) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return [];
    final rows = await _client
        .from('recent_views')
        .select('ref_type, ref_id, viewed_at')
        .eq('user_id', userId)
        .order('viewed_at', ascending: false)
        .limit(limit);
    return (rows as List<dynamic>)
        .map((r) => RecentViewEntry.fromRow(r as Map<String, dynamic>))
        .toList();
  }
}
