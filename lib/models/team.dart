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
