import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/usage_stats.dart';

/// Analítica de uso real (ver supabase/schema_v23_usage_analytics.sql):
/// a diferencia de [AnalyticsService] (cobertura de contenido documentado),
/// esto registra qué se consulta, qué se busca y qué búsqueda no encuentra
/// nada. Mismo criterio fire-and-forget que [RecentActivityService]: registrar
/// uso no debe fallar nunca el flujo de quien lo dispara.
class UsageAnalyticsService {
  UsageAnalyticsService._();
  static final UsageAnalyticsService instance = UsageAnalyticsService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> recordView(String refType, String refId) async {
    try {
      await _client.rpc('record_usage_event', params: {
        'p_event_type': 'view',
        'p_ref_type': refType,
        'p_ref_id': refId,
      });
    } catch (_) {
      // Silencioso: ver comentario de la clase.
    }
  }

  Future<void> recordSearch(String query) async {
    try {
      await _client.rpc('record_usage_event', params: {
        'p_event_type': 'search',
        'p_query': query,
      });
    } catch (_) {
      // Silencioso: ver comentario de la clase.
    }
  }

  Future<void> recordZeroResultSearch(String query) async {
    try {
      await _client.rpc('record_usage_event', params: {
        'p_event_type': 'search_zero_results',
        'p_query': query,
      });
    } catch (_) {
      // Silencioso: ver comentario de la clase.
    }
  }

  /// A diferencia de record*, esto sí propaga el error: quien lo llama
  /// (dashboard admin) necesita mostrar un estado de error, no tragárselo.
  Future<UsageStats> fetchStats(String organizationId) async {
    final result =
        await _client.rpc('organization_usage_stats', params: {'p_organization_id': organizationId});
    return UsageStats.fromJson(result as Map<String, dynamic>);
  }
}
