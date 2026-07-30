import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/group_document_version.dart'
    show GroupDocumentVersionStatus, GroupDocumentVersionStatusLabel;
import '../models/tray.dart';
import '../models/workspace_role.dart';
import '../services/custom_instrument_service.dart';
import '../services/tray_service.dart';
import 'tray_diff_screen.dart';

/// Historial de versiones de una bandeja, con opción de restaurar una
/// antigua. Calcado de [GroupDocumentVersionHistoryScreen].
class TrayVersionHistoryScreen extends StatefulWidget {
  final Tray tray;
  final WorkspaceRole? myRole;

  const TrayVersionHistoryScreen({super.key, required this.tray, required this.myRole});

  @override
  State<TrayVersionHistoryScreen> createState() => _TrayVersionHistoryScreenState();
}

class _TrayVersionHistoryScreenState extends State<TrayVersionHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<TrayVersion> _versions = [];
  List<CustomInstrument> _customInstruments = [];

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
      await CustomInstrumentService.instance.fetchForWorkspace(widget.tray.workspaceId);
      _customInstruments = CustomInstrumentService.instance.instruments;
      _versions = await TrayService.instance.fetchVersionHistory(widget.tray.id);
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

  Future<void> _restore(TrayVersion version) async {
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
      await TrayService.instance.restore(version.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.restoreSuccessSnackbar)));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.restoreError(e.toString()))));
      }
    }
  }

  void _openDiff(TrayVersion version) {
    final published = widget.tray.publishedVersion;
    if (published == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TrayDiffScreen(
          oldVersion: published,
          newVersion: version,
          customInstruments: _customInstruments,
        ),
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
                        title: Text(l10n.versionNumberTitle(version.versionNumber, version.name)),
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
                            if (canRestore) PopupMenuItem(value: 'restore', child: Text(l10n.restore)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
