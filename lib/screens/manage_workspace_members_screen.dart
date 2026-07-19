import 'package:flutter/material.dart';

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _members = await WorkspaceService.instance.fetchMembers(widget.workspace.id);
    } catch (e) {
      _error = 'No se pudieron cargar los miembros: $e';
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Miembros de ${widget.workspace.name}')),
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
                        title: Text(member.displayName?.isNotEmpty == true ? member.displayName! : 'Sin nombre'),
                        subtitle: member.isHospitalAdmin ? const Text('Administradora/or del grupo') : null,
                        trailing: member.isHospitalAdmin
                            ? const Chip(label: Text('Acceso total'))
                            : DropdownButton<WorkspaceRole?>(
                                value: member.role,
                                hint: const Text('Sin acceso'),
                                items: [
                                  const DropdownMenuItem<WorkspaceRole?>(
                                    value: null,
                                    child: Text('Sin acceso'),
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
