import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/group_document_version.dart';
import '../models/tray.dart';
import '../services/custom_instrument_service.dart';
import '../services/group_document_service.dart';
import '../services/tray_service.dart';
import 'group_document_diff_screen.dart';
import 'tray_diff_screen.dart';

/// Cola de aprobación de todo el grupo: versiones en revisión, visible solo
/// para administradores (hacen de aprobador hasta que exista el rol
/// Approver dedicado, previsto para la Fase B). Dos pestañas: técnicas/
/// protocolos y bandejas de instrumental — ambas comparten el mismo
/// workflow de aprobación (`in_review` -> aprobar/rechazar), así que se
/// generaliza esta pantalla en vez de duplicarla.
class ReviewQueueScreen extends StatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.reviewQueueTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: '${l10n.techniquesTitle} / ${l10n.protocolsTitle}'),
              Tab(text: l10n.traysTitle),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DocumentReviewQueue(),
            _TrayReviewQueue(),
          ],
        ),
      ),
    );
  }
}

class _DocumentReviewQueue extends StatefulWidget {
  const _DocumentReviewQueue();

  @override
  State<_DocumentReviewQueue> createState() => _DocumentReviewQueueState();
}

class _DocumentReviewQueueState extends State<_DocumentReviewQueue> {
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    }
    if (_queue.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noPendingReviews)));
    }
    return ListView.builder(
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
                  Text(_workspaceNames[version.documentId]!, style: Theme.of(context).textTheme.labelMedium),
                ],
                if (version.comment != null) ...[
                  const SizedBox(height: 4),
                  Text(version.comment!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(onPressed: () => _openDiff(version), child: Text(l10n.compare)),
                    const Spacer(),
                    TextButton(onPressed: () => _reject(version), child: Text(l10n.reject)),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: () => _approve(version), child: Text(l10n.approve)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TrayReviewQueue extends StatefulWidget {
  const _TrayReviewQueue();

  @override
  State<_TrayReviewQueue> createState() => _TrayReviewQueueState();
}

class _TrayReviewQueueState extends State<_TrayReviewQueue> {
  bool _loading = true;
  String? _error;
  List<TrayVersion> _queue = [];
  Map<String, String> _workspaceNames = {};
  final Map<String, List<CustomInstrument>> _customInstrumentsByWorkspace = {};

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
      _queue = await TrayService.instance.fetchReviewQueue();
      _workspaceNames =
          await TrayService.instance.fetchWorkspaceNamesForTrays(_queue.map((v) => v.trayId).toSet().toList());
    } catch (e) {
      _error = l10n.reviewQueueLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<List<CustomInstrument>> _customInstrumentsFor(String workspaceId) async {
    final cached = _customInstrumentsByWorkspace[workspaceId];
    if (cached != null) return cached;
    await CustomInstrumentService.instance.fetchForWorkspace(workspaceId);
    final list = CustomInstrumentService.instance.instruments;
    _customInstrumentsByWorkspace[workspaceId] = list;
    return list;
  }

  Future<void> _openDiff(TrayVersion version) async {
    try {
      final tray = await TrayService.instance.fetchTray(version.trayId);
      final published = tray.publishedVersion;
      if (published == null || !mounted) return;
      final customInstruments = await _customInstrumentsFor(tray.workspaceId);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrayDiffScreen(
            oldVersion: published,
            newVersion: version,
            customInstruments: customInstruments,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.compareLoadError(e.toString()))));
      }
    }
  }

  Future<void> _approve(TrayVersion version) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await TrayService.instance.approve(version.id);
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

  Future<void> _reject(TrayVersion version) async {
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
      await TrayService.instance.reject(version.id, comment: comment.isEmpty ? null : comment);
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
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)));
    }
    if (_queue.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noPendingReviews)));
    }
    return ListView.builder(
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
                Text(version.name, style: Theme.of(context).textTheme.titleMedium),
                if (_workspaceNames[version.trayId] != null) ...[
                  const SizedBox(height: 2),
                  Text(_workspaceNames[version.trayId]!, style: Theme.of(context).textTheme.labelMedium),
                ],
                if (version.comment != null) ...[
                  const SizedBox(height: 4),
                  Text(version.comment!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(onPressed: () => _openDiff(version), child: Text(l10n.compare)),
                    const Spacer(),
                    TextButton(onPressed: () => _reject(version), child: Text(l10n.reject)),
                    const SizedBox(width: 8),
                    FilledButton(onPressed: () => _approve(version), child: Text(l10n.approve)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
