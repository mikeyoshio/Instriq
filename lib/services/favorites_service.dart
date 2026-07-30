import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/favorite_entry.dart';
import 'auth_service.dart';

/// Favoritos personales (ver supabase/schema_v18_work_mode_favorites_recent.sql):
/// estrictamente por usuario, `auth.uid() = user_id` en RLS, nunca ligados a
/// un workspace ni auditables. Calcado del estilo de otros servicios del
/// proyecto (p.ej. [TrayService]): singleton + cliente Supabase directo.
class FavoritesService {
  FavoritesService._();
  static final FavoritesService instance = FavoritesService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<bool> isFavorite(String refType, String refId) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return false;
    final row = await _client
        .from('favorites')
        .select('id')
        .eq('user_id', userId)
        .eq('ref_type', refType)
        .eq('ref_id', refId)
        .maybeSingle();
    return row != null;
  }

  /// Alterna el estado: si ya era favorito lo quita, si no lo añade. Se
  /// resuelve con un select previo (en vez de upsert+delete) porque aquí
  /// necesitamos saber en qué estado quedó para poder devolverlo a la UI.
  Future<void> toggleFavorite(String refType, String refId) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    final already = await isFavorite(refType, refId);
    if (already) {
      await _client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('ref_type', refType)
          .eq('ref_id', refId);
    } else {
      await _client.from('favorites').insert({
        'user_id': userId,
        'ref_type': refType,
        'ref_id': refId,
      });
    }
  }

  Future<List<FavoriteEntry>> fetchFavorites() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return [];
    final rows = await _client
        .from('favorites')
        .select('ref_type, ref_id')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((r) => FavoriteEntry.fromRow(r as Map<String, dynamic>))
        .toList();
  }
}
