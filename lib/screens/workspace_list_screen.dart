import 'package:flutter/material.dart';

import '../models/workspace.dart';
import '../services/profile_service.dart';
import '../services/workspace_service.dart';
import 'workspace_detail_screen.dart';

/// Espacios de trabajo del grupo (p. ej. Traumatología, Neurocirugía,
/// Formación). Cada espacio agrupa sus propias técnicas, protocolos y
/// tarjetas de preferencia.
class WorkspaceListScreen extends StatefulWidget {
  const WorkspaceListScreen({super.key});

  @override
  State<WorkspaceListScreen> createState() => _WorkspaceListScreenState();
}

class _WorkspaceListScreenState extends State<WorkspaceListScreen> {
  bool _loading = true;
  String? _error;

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
      await WorkspaceService.instance.fetchWorkspaces();
    } catch (e) {
      _error = 'No se pudieron cargar los espacios: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _createWorkspace() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nuevo espacio'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'p. ej. Traumatología, Formación...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Crear'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await WorkspaceService.instance.createWorkspace(name);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al crear: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canManage = ProfileService.instance.isAdmin;
    return Scaffold(
      appBar: AppBar(title: const Text('Espacios')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _createWorkspace,
              icon: const Icon(Icons.add),
              label: const Text('Nuevo espacio'),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: WorkspaceService.instance.workspaces.length,
                  itemBuilder: (context, index) {
                    final Workspace workspace = WorkspaceService.instance.workspaces[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.workspaces_outlined),
                        title: Text(workspace.name),
                        subtitle: workspace.description != null ? Text(workspace.description!) : null,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => WorkspaceDetailScreen(workspace: workspace)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
