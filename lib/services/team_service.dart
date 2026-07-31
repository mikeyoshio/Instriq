import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/team.dart';
import '../models/workspace_role.dart';
import 'profile_service.dart';

/// Equipos de la organización actual y sus roles de espacio (ver
/// supabase/schema_v21_teams_and_login_audit.sql). Toda escritura va vía
/// función `security definer` (igual que [WorkspaceService.setMemberRole]),
/// nunca un insert/update/delete directo, para que el cambio quede
/// registrado en el log de auditoría y la validación de permisos viva en un
/// único sitio de confianza.
class TeamService {
  TeamService._();
  static final TeamService instance = TeamService._();

  SupabaseClient get _client => Supabase.instance.client;

  List<Team> _teams = [];

  List<Team> get teams => List.unmodifiable(_teams);

  /// Limpia el caché en memoria. Debe llamarse al cambiar de grupo o cerrar
  /// sesión: si no, un equipo de un grupo anterior puede quedar cacheado.
  void clear() {
    _teams = [];
  }

  Future<List<Team>> fetchTeams() async {
    final organizationId = ProfileService.instance.organizationId;
    if (organizationId == null) {
      _teams = [];
      return _teams;
    }
    final rows =
        await _client.from('teams').select().eq('organization_id', organizationId).order('name');
    _teams = (rows as List<dynamic>).map((r) => Team.fromRow(r as Map<String, dynamic>)).toList();
    return _teams;
  }

  /// Miembros de un equipo, con su nombre para mostrar (join de
  /// `team_members` + `profiles`, mismo patrón que [WorkspaceService.fetchMembers]).
  Future<List<TeamMember>> fetchTeamMembers(String teamId) async {
    final rows = await _client
        .from('team_members')
        .select('user_id, profiles(display_name)')
        .eq('team_id', teamId);
    return (rows as List<dynamic>).map((r) {
      final row = r as Map<String, dynamic>;
      final profileRow = row['profiles'] as Map<String, dynamic>?;
      return TeamMember(
        userId: row['user_id'] as String,
        displayName: profileRow?['display_name'] as String?,
      );
    }).toList();
  }

  Future<Team> createTeam(String name) async {
    final row = await _client.rpc('create_team', params: {'p_name': name});
    final team = Team.fromRow(row as Map<String, dynamic>);
    _teams = [..._teams, team]..sort((a, b) => a.name.compareTo(b.name));
    return team;
  }

  Future<void> deleteTeam(String teamId) async {
    await _client.rpc('delete_team', params: {'p_team_id': teamId});
    _teams.removeWhere((t) => t.id == teamId);
  }

  Future<void> addTeamMember(String teamId, String userId) async {
    await _client.rpc('add_team_member', params: {'p_team_id': teamId, 'p_user_id': userId});
  }

  Future<void> removeTeamMember(String teamId, String userId) async {
    await _client.rpc('remove_team_member', params: {'p_team_id': teamId, 'p_user_id': userId});
  }

  /// Roles de espacio asignados a equipos (no a personas), para mostrar junto
  /// a los roles individuales en [ManageWorkspaceMembersScreen].
  Future<List<({Team team, WorkspaceRole role})>> fetchWorkspaceTeamRoles(String workspaceId) async {
    final rows = await _client
        .from('workspace_team_roles')
        .select('role, teams(id, organization_id, name, created_at)')
        .eq('workspace_id', workspaceId);
    final result = <({Team team, WorkspaceRole role})>[];
    for (final r in (rows as List<dynamic>)) {
      final row = r as Map<String, dynamic>;
      final teamRow = row['teams'] as Map<String, dynamic>?;
      final role = WorkspaceRoleLabel.fromDb(row['role'] as String?);
      if (teamRow == null || role == null) continue;
      result.add((team: Team.fromRow(teamRow), role: role));
    }
    result.sort((a, b) => a.team.name.compareTo(b.team.name));
    return result;
  }

  Future<void> setWorkspaceTeamRole(String workspaceId, String teamId, WorkspaceRole role) async {
    if (role == WorkspaceRole.administrator) {
      throw ArgumentError('El rol de administrador no se asigna por espacio.');
    }
    await _client.rpc('set_workspace_team_role', params: {
      'p_workspace_id': workspaceId,
      'p_team_id': teamId,
      'p_role': role.dbValue,
    });
  }

  Future<void> removeWorkspaceTeamRole(String workspaceId, String teamId) async {
    await _client.rpc('remove_workspace_team_role', params: {
      'p_workspace_id': workspaceId,
      'p_team_id': teamId,
    });
  }
}
