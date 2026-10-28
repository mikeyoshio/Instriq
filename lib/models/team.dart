/// Un equipo con nombre dentro de la organización (ver supabase/
/// schema_v21_teams_and_login_audit.sql). Permite asignar un rol de espacio
/// a todo un grupo de personas de una vez (`workspace_team_roles`) en vez de
/// repetir la asignación usuario por usuario.
class Team {
  final String id;
  final String organizationId;
  final String name;
  final DateTime? createdAt;

  const Team({
    required this.id,
    required this.organizationId,
    required this.name,
    this.createdAt,
  });

  factory Team.fromRow(Map<String, dynamic> row) {
    return Team(
      id: row['id'] as String,
      organizationId: row['organization_id'] as String,
      name: row['name'] as String? ?? '',
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
    );
  }
}

/// Una persona del grupo, vista desde dentro de un equipo concreto (join de
/// `team_members` + `profiles`, ver [TeamService.fetchTeamMembers]).
class TeamMember {
  final String userId;
  final String? displayName;

  const TeamMember({required this.userId, this.displayName});
}

/// Progreso de aprendizaje de una persona de un equipo, visto por quien
/// supervisa (modo Docente) — ver [TeamService.fetchTeamMemberProgress] y la
/// función `team_learning_progress` (schema_v54_team_learning_progress.sql).
/// Mismas magnitudes que [ProgressService] expone para el propio usuario
/// (aprendidos, repasos pendientes, mejores puntuaciones de quiz), pero aquí
/// para otra persona -- de ahí que venga de un RPC con su propio chequeo de
/// permisos, no de una lectura RLS directa como el resto de `learning_progress`.
class TeamMemberProgress {
  final String userId;
  final String? displayName;
  final int learnedCount;
  final int dueCount;
  final Map<String, int> quizBestScores;

  const TeamMemberProgress({
    required this.userId,
    this.displayName,
    required this.learnedCount,
    required this.dueCount,
    required this.quizBestScores,
  });

  factory TeamMemberProgress.fromRow(Map<String, dynamic> row) {
    final rawScores = (row['quiz_best_scores'] as Map<String, dynamic>?) ?? const {};
    return TeamMemberProgress(
      userId: row['user_id'] as String,
      displayName: row['display_name'] as String?,
      learnedCount: (row['learned_count'] as num?)?.toInt() ?? 0,
      dueCount: (row['due_count'] as num?)?.toInt() ?? 0,
      quizBestScores: {for (final entry in rawScores.entries) entry.key: (entry.value as num).toInt()},
    );
  }
}

/// Cuestionario configurado por un supervisor/docente para su equipo (ver
/// supabase/schema_v60_team_quizzes.sql) -- pool fijo de instrumentos de
/// catálogo en vez de las 10 preguntas aleatorias de siempre. [scopeKey] es
/// la clave bajo la que [ProgressService.saveQuizResult]/[quizBestScore]
/// guardan la mejor puntuación: con ese mismo prefijo, `team_learning_progress`
/// ya la expone al supervisor sin ningún cambio en esa función.
class TeamQuiz {
  final String id;
  final String teamId;
  final String title;
  final List<String> instrumentIds;
  final String? createdBy;
  final DateTime? createdAt;

  const TeamQuiz({
    required this.id,
    required this.teamId,
    required this.title,
    required this.instrumentIds,
    this.createdBy,
    this.createdAt,
  });

  String get scopeKey => 'team_quiz:$id';

  factory TeamQuiz.fromRow(Map<String, dynamic> row) {
    return TeamQuiz(
      id: row['id'] as String,
      teamId: row['team_id'] as String,
      title: row['title'] as String? ?? '',
      instrumentIds: (row['instrument_ids'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      createdBy: row['created_by'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
    );
  }
}
