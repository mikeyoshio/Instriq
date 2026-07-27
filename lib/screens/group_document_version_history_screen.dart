import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/group_document.dart';
import '../models/group_document_version.dart';
import '../models/workspace_role.dart';
import '../services/group_document_service.dart';
import 'group_document_diff_screen.dart';

class GroupDocumentVersionHistoryScreen extends StatefulWidget {
  final GroupDocument document;
  final WorkspaceRole? myRole;

  const GroupDocumentVersionHistoryScreen({super.key, required this.document, required this.myRole});

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
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _versions = await GroupDocumentService.instance.fetchVersionHistory(widget.document.id);
    } catch (e) {
      _error = l10n.versionHistoryLoadError(e.toString());
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
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.restoreVersionTitle),
        content: Text(l10n.restoreVersionBody(version.versionNumber)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.restore)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await GroupDocumentService.instance.restore(version.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.restoreSuccessSnackbar)),
        );
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.restoreError(e.toString()))));
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
    final l10n = AppLocalizations.of(context)!;
    final canRestore = widget.myRole?.canEdit ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.versionHistoryTitle)),
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
                        title: Text(l10n.versionNumberTitle(version.versionNumber, version.title)),
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
                            PopupMenuItem(value: 'diff', child: Text(l10n.compareWithPublished)),
                            if (canRestore)
                              PopupMenuItem(value: 'restore', child: Text(l10n.restore)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
