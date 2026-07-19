import 'package:flutter/material.dart';

import '../models/group_document_version.dart';
import '../services/group_document_service.dart';
import 'group_document_diff_screen.dart';

/// Cola de aprobación: versiones en revisión de todo el grupo, visible solo
/// para administradores (hacen de aprobador hasta que exista el rol Approver
/// dedicado, previsto para la Fase B).
class GroupDocumentReviewQueueScreen extends StatefulWidget {
  const GroupDocumentReviewQueueScreen({super.key});

  @override
  State<GroupDocumentReviewQueueScreen> createState() => _GroupDocumentReviewQueueScreenState();
}

class _GroupDocumentReviewQueueScreenState extends State<GroupDocumentReviewQueueScreen> {
  bool _loading = true;
  String? _error;
  List<GroupDocumentVersion> _queue = [];

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
      _queue = await GroupDocumentService.instance.fetchReviewQueue();
    } catch (e) {
      _error = 'No se pudo cargar la cola de revisión: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openDiff(GroupDocumentVersion version) async {
    try {
      final document = await GroupDocumentService.instance.fetchDocument(version.documentId);
      final published = document.publishedVersion;
      if (published == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GroupDocumentDiffScreen(oldVersion: published, newVersion: version),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo comparar: $e')));
      }
    }
  }

  Future<void> _approve(GroupDocumentVersion version) async {
    try {
      await GroupDocumentService.instance.approve(version.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cambio aprobado y publicado')));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al aprobar: $e')));
      }
    }
  }

  Future<void> _reject(GroupDocumentVersion version) async {
    final controller = TextEditingController();
    final comment = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rechazar cambio'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Motivo (visible para el autor)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Rechazar')),
        ],
      ),
    );
    if (comment == null) return;
    try {
      await GroupDocumentService.instance.reject(version.id, comment: comment.isEmpty ? null : comment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cambio devuelto al autor')));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al rechazar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cambios pendientes de revisión')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _queue.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('No hay cambios pendientes de revisión.'),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _queue.length,
                      itemBuilder: (context, index) {
                        final version = _queue[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(version.title, style: Theme.of(context).textTheme.titleMedium),
                                if (version.comment != null) ...[
                                  const SizedBox(height: 4),
                                  Text(version.comment!, style: Theme.of(context).textTheme.bodyMedium),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () => _openDiff(version),
                                      child: const Text('Comparar'),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () => _reject(version),
                                      child: const Text('Rechazar'),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      onPressed: () => _approve(version),
                                      child: const Text('Aprobar'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
