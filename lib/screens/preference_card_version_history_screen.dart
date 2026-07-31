import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/group_document_version.dart'
    show GroupDocumentVersionStatus, GroupDocumentVersionStatusLabel;
import '../models/preference_card.dart';
import '../models/surgeon.dart';
import '../models/workspace_role.dart';
import '../services/preference_card_service.dart';
import '../services/surgeon_service.dart';
import 'preference_card_diff_screen.dart';

/// Historial de versiones de una tarjeta de preferencia, con opción de
/// restaurar una antigua. Calcado de [TrayVersionHistoryScreen].
class PreferenceCardVersionHistoryScreen extends StatefulWidget {
  final PreferenceCard card;
  final WorkspaceRole? myRole;

  const PreferenceCardVersionHistoryScreen({super.key, required this.card, required this.myRole});

  @override
  State<PreferenceCardVersionHistoryScreen> createState() => _PreferenceCardVersionHistoryScreenState();
}

class _PreferenceCardVersionHistoryScreenState extends State<PreferenceCardVersionHistoryScreen> {
  bool _loading = true;
  String? _error;
  List<PreferenceCardVersion> _versions = [];
  List<Surgeon> _surgeons = [];

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
      _surgeons = await SurgeonService.instance.fetchForOrganization();
      _versions = await PreferenceCardService.instance.fetchVersionHistory(widget.card.id);
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

  Future<void> _restore(PreferenceCardVersion version) async {
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
      await PreferenceCardService.instance.restore(version.id);
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

  void _openDiff(PreferenceCardVersion version) {
    final published = widget.card.publishedVersion;
    if (published == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreferenceCardDiffScreen(oldVersion: published, newVersion: version, surgeons: _surgeons),
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
                        title: Text(l10n.versionNumberTitle(version.versionNumber, version.procedureName)),
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
