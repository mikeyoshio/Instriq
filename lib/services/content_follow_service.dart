import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';

/// Seguimiento de contenido (ver supabase/schema_v59_content_follows.sql):
/// a diferencia de [FavoritesService] (acceso rápido), esto dispara un push
/// real cuando se publica una versión nueva del contenido seguido (ver la
/// extensión de supabase/functions/send-push/index.ts). Calcado del mismo
/// servicio: estrictamente por usuario, sin RPC.
class ContentFollowService {
  ContentFollowService._();
  static final ContentFollowService instance = ContentFollowService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<bool> isFollowing(String refType, String refId) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return false;
    final row = await _client
        .from('content_follows')
        .select('id')
        .eq('user_id', userId)
        .eq('ref_type', refType)
        .eq('ref_id', refId)
        .maybeSingle();
    return row != null;
  }

  Future<void> toggleFollow(String refType, String refId) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    final already = await isFollowing(refType, refId);
    if (already) {
      await _client
          .from('content_follows')
          .delete()
          .eq('user_id', userId)
          .eq('ref_type', refType)
          .eq('ref_id', refId);
    } else {
      await _client.from('content_follows').insert({
        'user_id': userId,
        'ref_type': refType,
        'ref_id': refId,
      });
    }
  }
}
