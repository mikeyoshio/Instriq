import 'package:flutter/material.dart';

import '../models/group_document.dart';
import '../models/group_document_version.dart';
import '../services/group_document_service.dart';
import '../services/profile_service.dart';
import 'group_document_diff_screen.dart';

class GroupDocumentVersionHistoryScreen extends StatefulWidget {
  final GroupDocument document;

  const GroupDocumentVersionHistoryScreen({super.key, required this.document});

  @override
  State<GroupDocumentVersionHistoryScreen> createState() => _GroupDocumentVersionHistoryScreenState();
}

class _GroupDocumentVersionHistoryScreenState extends State<GroupDocumentVersionHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<GroupDocumentVersion> _versions = [];

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
      _versions = await GroupDocumentService.instance.fetchVersionHistory(widget.document.id);
    } catch (e) {
      _error = 'No se pudo cargar el historial: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Color _statusColor(GroupDocumentVersionStatus status, BuildContext context) {
    switch (status) {
      case GroupDocumentVersionStatus.draft:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
      case GroupDocumentVersionStatus.inReview:
        return Theme.of(context).colorScheme.tertiaryContainer;
      case GroupDocumentVersionStatus.published:
        return Theme.of(context).colorScheme.primaryContainer;
      case GroupDocumentVersionStatus.archived:
        return Theme.of(context).colorScheme.surfaceContainerHighest;
    }
  }

  Future<void> _restore(GroupDocumentVersion version) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurar versión'),
        content: Text(
          'Se creará un nuevo borrador con el contenido de la versión ${version.versionNumber}. '
          'No se pierde el historial existente.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restaurar')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await GroupDocumentService.instance.restore(version.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se creó un borrador nuevo a partir de esta versión')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al restaurar: $e')));
      }
    }
  }

  void _openDiff(GroupDocumentVersion version) {
    final published = widget.document.publishedVersion;
    if (published == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GroupDocumentDiffScreen(oldVersion: published, newVersion: version),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canRestore = ProfileService.instance.isAdmin;
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de versiones')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _versions.length,
                  itemBuilder: (context, index) {
                    final version = _versions[index];
                    return Card(
                      color: _statusColor(version.status, context),
                      child: ListTile(
                        title: Text('Versión ${version.versionNumber} · ${version.title}'),
                        subtitle: Text(
                          '${version.status.label}'
                          '${version.comment != null ? ' — ${version.comment}' : ''}',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'diff') _openDiff(version);
                            if (value == 'restore') _restore(version);
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'diff', child: Text('Comparar con la publicada')),
                            if (canRestore)
                              const PopupMenuItem(value: 'restore', child: Text('Restaurar')),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
