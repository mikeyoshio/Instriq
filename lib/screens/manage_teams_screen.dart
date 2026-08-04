import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/hospital.dart';
import '../models/team.dart';
import '../services/profile_service.dart';
import '../services/team_service.dart';

/// Solo accesible para admin/owner (gateado además por RLS de `teams`).
/// Lista los equipos de la organización, con alta/baja y gestión de
/// miembros — calcado en estilo de [ManageWorkspaceMembersScreen] (Card +
/// ListTile, sin widgets nuevos de lista).
class ManageTeamsScreen extends StatefulWidget {
  const ManageTeamsScreen({super.key});

  @override
  State<ManageTeamsScreen> createState() => _ManageTeamsScreenState();
}

class _ManageTeamsScreenState extends State<ManageTeamsScreen> {
  bool _loading = true;
  String? _error;
  List<Team> _teams = [];
  final Map<String, int> _memberCounts = {};

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
      _teams = await TeamService.instance.fetchTeams();
      final counts = await Future.wait(_teams.map((t) async {
        final members = await TeamService.instance.fetchTeamMembers(t.id);
        return MapEntry(t.id, members.length);
      }));
      _memberCounts
        ..clear()
        ..addEntries(counts);
    } catch (e) {
      _error = l10n.teamsLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createTeam() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newTeamLabel),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.teamNameLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.addAction),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await TeamService.instance.createTeam(name);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.genericError(e.toString()))));
      }
    }
  }

  Future<void> _deleteTeam(Team team) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteTeamTitle),
        content: Text(l10n.deleteTeamConfirmBody(team.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.deleteAction)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await TeamService.instance.deleteTeam(team.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.genericError(e.toString()))));
      }
    }
  }

  Future<void> _openMembers(Team team) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _TeamMembersScreen(team: team)),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageTeamsTitle)),
      floatingActionButton: FloatingActionButton(onPressed: _createTeam, child: const Icon(Icons.add)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _teams.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noTeamsYet)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _teams.length,
                      itemBuilder: (context, index) {
                        final team = _teams[index];
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.groups_outlined),
                            title: Text(team.name),
                            subtitle: Text(l10n.teamMembersCountTitle(_memberCounts[team.id] ?? 0)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline),
                              tooltip: l10n.deleteTeamTooltip,
                              onPressed: () => _deleteTeam(team),
                            ),
                            onTap: () => _openMembers(team),
                          ),
                        );
                      },
                    ),
    );
  }
}

/// Alta/baja de miembros de un equipo: cada fila es una persona del grupo
/// (mismo listado que [ManageHospitalScreen], vía [ProfileService.fetchMembers])
/// con un checkbox que refleja si ya pertenece a este equipo.
class _TeamMembersScreen extends StatefulWidget {
  final Team team;

  const _TeamMembersScreen({required this.team});

  @override
  State<_TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends State<_TeamMembersScreen> {
  bool _loading = true;
  String? _error;
  List<HospitalMember> _orgMembers = [];
  Set<String> _memberIds = {};
  final Set<String> _pending = {};

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
      _orgMembers = await ProfileService.instance.fetchMembers();
      final teamMembers = await TeamService.instance.fetchTeamMembers(widget.team.id);
      _memberIds = teamMembers.map((m) => m.userId).toSet();
    } catch (e) {
      _error = l10n.manageMembersLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _toggle(HospitalMember member, bool value) async {
    setState(() => _pending.add(member.id));
    try {
      if (value) {
        await TeamService.instance.addTeamMember(widget.team.id, member.id);
        _memberIds.add(member.id);
      } else {
        await TeamService.instance.removeTeamMember(widget.team.id, member.id);
        _memberIds.remove(member.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.genericError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _pending.remove(member.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageMembersTitle(widget.team.name))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _orgMembers.length,
                  itemBuilder: (context, index) {
                    final member = _orgMembers[index];
                    final checked = _memberIds.contains(member.id);
                    return Card(
                      child: CheckboxListTile(
                        secondary: const Icon(Icons.person),
                        title: Text(member.displayName?.isNotEmpty == true ? member.displayName! : l10n.noName),
                        value: checked,
                        onChanged: _pending.contains(member.id)
                            ? null
                            : (value) => _toggle(member, value ?? false),
                      ),
                    );
                  },
                ),
    );
  }
}
