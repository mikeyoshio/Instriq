import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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

  // Evita reempujar WorkspaceDetailScreen en cada rebuild: la colapsión de
  // abajo (single workspace -> salto directo) solo se dispara una vez, justo
  // al terminar la carga que la detecta, no desde build().
  bool _autoNavigated = false;

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
      if (mounted) _error = AppLocalizations.of(context)!.workspaceListLoadError(e.toString());
    }
    if (!mounted) return;
    final workspaces = WorkspaceService.instance.workspaces;
    if (_error == null && workspaces.length == 1 && !_autoNavigated) {
      _autoNavigated = true;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => WorkspaceDetailScreen(workspace: workspaces.first)),
      );
      return;
    }
    setState(() => _loading = false);
  }

  Future<void> _renameWorkspace(Workspace workspace) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: workspace.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.workspaceRenameTitle),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty || name == workspace.name) return;
    try {
      await WorkspaceService.instance.renameWorkspace(workspace.id, name);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.workspaceRenameError(e.toString()))));
      }
    }
  }

  Future<void> _createWorkspace() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.workspaceNewTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.workspaceOrgHint,
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.workspaceNameHint),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.create),
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.workspaceCreateError(e.toString()))));
      }
    }
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspaces_outlined, size: 56),
            const SizedBox(height: 16),
            Text(
              l10n.workspaceEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.workspaceEmptyBody,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canManage = ProfileService.instance.isAdmin;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.spacesTitle)),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _createWorkspace,
              icon: const Icon(Icons.add),
              label: Text(l10n.workspaceNewTitle),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : WorkspaceService.instance.workspaces.isEmpty
                  ? _buildEmptyState(context, l10n)
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
                        trailing: canManage
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: l10n.workspaceRenameTooltip,
                                    onPressed: () => _renameWorkspace(workspace),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              )
                            : const Icon(Icons.chevron_right),
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
