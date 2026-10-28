import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/team.dart';

/// Cuestionarios configurables de equipo (ver
/// supabase/schema_v60_team_quizzes.sql). Sin flujo de aprobación ni RPC: es
/// config ligera, escritura directa vía RLS -- mismo criterio que
/// [TeamService] para lo que no toca auditoría.
class TeamQuizService {
  TeamQuizService._();
  static final TeamQuizService instance = TeamQuizService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<TeamQuiz>> fetchForTeam(String teamId) async {
    final rows = await _client
        .from('team_quizzes')
        .select()
        .eq('team_id', teamId)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>).map((r) => TeamQuiz.fromRow(r as Map<String, dynamic>)).toList();
  }

  Future<TeamQuiz> create(String teamId, String title, List<String> instrumentIds) async {
    final userId = _client.auth.currentUser?.id;
    final row = await _client
        .from('team_quizzes')
        .insert({
          'team_id': teamId,
          'title': title,
          'instrument_ids': instrumentIds,
          'created_by': userId,
        })
        .select()
        .single();
    return TeamQuiz.fromRow(row);
  }

  Future<void> delete(String quizId) async {
    await _client.from('team_quizzes').delete().eq('id', quizId);
  }
}
