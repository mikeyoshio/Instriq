import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/team.dart';
import '../models/workspace.dart';
import '../models/workspace_member.dart';
import '../models/workspace_role.dart';
import '../services/team_service.dart';
import '../services/workspace_service.dart';

/// Solo accesible para admin/owner (gateado además por RLS de
/// workspace_members). Asigna el rol de cada miembro del hospital dentro de
/// este espacio concreto: Reader, Editor o Approver, o "Sin acceso" — y,
/// debajo, el mismo rol pero asignado a equipos enteros (ver
/// supabase/schema_v21_teams_and_login_audit.sql).
class ManageWorkspaceMembersScreen extends StatefulWidget {
  final Workspace workspace;

  const ManageWorkspaceMembersScreen({super.key, required this.workspace});

  @override
  State<ManageWorkspaceMembersScreen> createState() => _ManageWorkspaceMembersScreenState();
}

class _ManageWorkspaceMembersScreenState extends State<ManageWorkspaceMembersScreen> {
  bool _loading = true;
  String? _error;
  List<WorkspaceMember> _members = [];
  List<Team> _teams = [];
  Map<String, WorkspaceRole> _teamRoles = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _members = await WorkspaceService.instance.fetchMembers(widget.workspace.id);
      _teams = await TeamService.instance.fetchTeams();
      final assigned = await TeamService.instance.fetchWorkspaceTeamRoles(widget.workspace.id);
      _teamRoles = {for (final a in assigned) a.team.id: a.role};
    } catch (e) {
      _error = l10n.manageMembersLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _changeRole(WorkspaceMember member, WorkspaceRole? newRole) async {
    try {
      if (newRole == null) {
        await WorkspaceService.instance.removeMemberRole(widget.workspace.id, member.userId);
      } else {
        await WorkspaceService.instance.setMemberRole(widget.workspace.id, member.userId, newRole);
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.genericError(e.toString()))));
      }
    }
  }

  Future<void> _changeTeamRole(Team team, WorkspaceRole? newRole) async {
    try {
      if (newRole == null) {
        await TeamService.instance.removeWorkspaceTeamRole(widget.workspace.id, team.id);
      } else {
        await TeamService.instance.setWorkspaceTeamRole(widget.workspace.id, team.id, newRole);
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.genericError(e.toString()))));
      }
    }
  }

  /// Mismo dropdown de rol para filas de persona y de equipo — factorizado
  /// para no duplicar la lista de items entre ambas.
  Widget _roleDropdown(AppLocalizations l10n, WorkspaceRole? value, ValueChanged<WorkspaceRole?> onChanged) {
    return DropdownButton<WorkspaceRole?>(
      value: value,
      hint: Text(l10n.manageMembersNoAccess),
      items: [
        DropdownMenuItem<WorkspaceRole?>(value: null, child: Text(l10n.manageMembersNoAccess)),
        ...WorkspaceRole.values
            .where((r) => r != WorkspaceRole.administrator)
            .map((r) => DropdownMenuItem<WorkspaceRole?>(value: r, child: Text(r.label))),
      ],
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageMembersTitle(widget.workspace.name))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    ..._members.map((member) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(
                                member.displayName?.isNotEmpty == true ? member.displayName! : l10n.noName),
                            subtitle: member.isHospitalAdmin ? Text(l10n.manageMembersAdminLabel) : null,
                            trailing: member.isHospitalAdmin
                                ? Chip(label: Text(l10n.manageMembersFullAccess))
                                : _roleDropdown(l10n, member.role, (role) => _changeRole(member, role)),
                          ),
                        )),
                    if (_teams.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(l10n.teamsSectionHeader, style: Theme.of(context).textTheme.titleMedium),
                      ),
                      const SizedBox(height: 4),
                      ..._teams.map((team) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.groups_outlined),
                              title: Text(team.name),
                              trailing: _roleDropdown(
                                  l10n, _teamRoles[team.id], (role) => _changeTeamRole(team, role)),
                            ),
                          )),
                    ],
                  ],
                ),
    );
  }
}
