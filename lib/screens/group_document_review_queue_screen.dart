import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
  Map<String, String> _workspaceNames = {};

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
      _queue = await GroupDocumentService.instance.fetchReviewQueue();
      _workspaceNames = await GroupDocumentService.instance
          .fetchWorkspaceNamesForDocuments(_queue.map((v) => v.documentId).toSet().toList());
    } catch (e) {
      _error = l10n.reviewQueueLoadError(e.toString());
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.compareLoadError(e.toString()))));
      }
    }
  }

  Future<void> _approve(GroupDocumentVersion version) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await GroupDocumentService.instance.approve(version.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.changeApprovedSnackbar)));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.approveError(e.toString()))));
      }
    }
  }

  Future<void> _reject(GroupDocumentVersion version) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final comment = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.rejectChangeTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(labelText: l10n.rejectReasonLabel),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(l10n.reject)),
        ],
      ),
    );
    if (comment == null) return;
    try {
      await GroupDocumentService.instance.reject(version.id, comment: comment.isEmpty ? null : comment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.changeReturnedSnackbar)));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.rejectError(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reviewQueueTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _queue.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(l10n.noPendingReviews),
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
                                if (_workspaceNames[version.documentId] != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _workspaceNames[version.documentId]!,
                                    style: Theme.of(context).textTheme.labelMedium,
                                  ),
                                ],
                                if (version.comment != null) ...[
                                  const SizedBox(height: 4),
                                  Text(version.comment!, style: Theme.of(context).textTheme.bodyMedium),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () => _openDiff(version),
                                      child: Text(l10n.compare),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () => _reject(version),
                                      child: Text(l10n.reject),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      onPressed: () => _approve(version),
                                      child: Text(l10n.approve),
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
