import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/workspace.dart';
import '../models/workspace_member.dart';
import '../models/workspace_role.dart';
import '../services/workspace_service.dart';

/// Solo accesible para admin/owner (gateado además por RLS de
/// workspace_members). Asigna el rol de cada miembro del hospital dentro de
/// este espacio concreto: Reader, Editor o Approver, o "Sin acceso".
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageMembersTitle(widget.workspace.name))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(member.displayName?.isNotEmpty == true ? member.displayName! : l10n.noName),
                        subtitle: member.isHospitalAdmin ? Text(l10n.manageMembersAdminLabel) : null,
                        trailing: member.isHospitalAdmin
                            ? Chip(label: Text(l10n.manageMembersFullAccess))
                            : DropdownButton<WorkspaceRole?>(
                                value: member.role,
                                hint: Text(l10n.manageMembersNoAccess),
                                items: [
                                  DropdownMenuItem<WorkspaceRole?>(
                                    value: null,
                                    child: Text(l10n.manageMembersNoAccess),
                                  ),
                                  ...WorkspaceRole.values
                                      .where((r) => r != WorkspaceRole.administrator)
                                      .map((r) => DropdownMenuItem<WorkspaceRole?>(
                                            value: r,
                                            child: Text(r.label),
                                          )),
                                ],
                                onChanged: (role) => _changeRole(member, role),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
