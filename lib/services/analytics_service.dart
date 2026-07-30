import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/hospital_content_stats.dart';

/// Cobertura de conocimiento documentado por especialidad (Fase E, version
/// minima/realista). Deliberadamente NO es un dashboard de uso/engagement:
/// el progreso de aprendizaje de cada usuaria/o (flashcards/quiz) vive hoy
/// solo en shared_preferences local del dispositivo (ver
/// lib/services/progress_service.dart), no hay ningun tracking server-side
/// de que se consulta o aprende mas. Lo que si se puede medir de forma
/// honesta con datos que ya existen en Supabase es cuanto contenido tiene
/// documentado el hospital: ver supabase/schema_v11_analytics.sql.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<HospitalContentStats> fetchHospitalContentStats(String organizationId) async {
    // RPC name + 'p_hospital_id' param key are unchanged tech debt: the SQL
    // function still literally has that signature, only its meaning changed
    // (hospital -> organization). Do not rename either.
    final result = await _client.rpc('hospital_content_stats', params: {'p_hospital_id': organizationId});
    return HospitalContentStats.fromJson(result as Map<String, dynamic>);
  }
}
