import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/tray.dart';
import '../models/tray_preparation_session.dart';
import '../models/workspace_role.dart';
import '../services/tray_preparation_service.dart';

/// Historial de sesiones de preparación real de una safata: quién la montó,
/// qué encontró item a item, y el control de calidad/validación de otra
/// persona (o la misma) sobre esa sesión concreta (EPIC 4 · Bandejas 2.0).
class TrayPreparationSessionsScreen extends StatefulWidget {
  final Tray tray;
  final WorkspaceRole? myRole;

  const TrayPreparationSessionsScreen({super.key, required this.tray, required this.myRole});

  @override
  State<TrayPreparationSessionsScreen> createState() => _TrayPreparationSessionsScreenState();
}

class _TrayPreparationSessionsScreenState extends State<TrayPreparationSessionsScreen> {
  List<TrayPreparationSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sessions = await TrayPreparationService.instance.fetchSessions(widget.tray.id);
    if (!mounted) return;
    setState(() {
      _sessions = sessions;
      _loading = false;
    });
  }

  Color _statusColor(TrayPreparationStatus status) {
    switch (status) {
      case TrayPreparationStatus.prepared:
        return Colors.orange;
      case TrayPreparationStatus.qcPassed:
        return Colors.green;
      case TrayPreparationStatus.qcFailed:
        return Colors.red;
    }
  }

  String _when(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  String _statusLabel(AppLocalizations l10n, TrayPreparationStatus status) {
    switch (status) {
      case TrayPreparationStatus.prepared:
        return l10n.trayPreparationStatusPrepared;
      case TrayPreparationStatus.qcPassed:
        return l10n.trayPreparationStatusQcPassed;
      case TrayPreparationStatus.qcFailed:
        return l10n.trayPreparationStatusQcFailed;
    }
  }

  Future<void> _qc(TrayPreparationSession session) async {
    final l10n = AppLocalizations.of(context)!;
    final notesController = TextEditingController();
    final passed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.qcSessionTitle),
        content: TextField(
          controller: notesController,
          decoration: InputDecoration(labelText: l10n.qcNotesLabel, border: const OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.qcFailAction, style: const TextStyle(color: Colors.red)),
          ),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.qcPassAction)),
        ],
      ),
    );
    if (passed == null) return;
    await TrayPreparationService.instance.qcSession(
      session.id,
      passed: passed,
      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canQc = widget.myRole?.canApprove ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.trayPreparationHistoryLabel)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noPreparationSessionsYet)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final missing = session.itemResults.where((r) => !r.present).length;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _statusColor(session.status),
                          child: const Icon(Icons.inventory_2_outlined, color: Colors.white),
                        ),
                        title: Text(_statusLabel(l10n, session.status)),
                        subtitle: Text(
                          [
                            '${l10n.preparedByLabel}: ${session.preparedByName ?? l10n.unknownPerson} · '
                                '${_when(session.preparedAt)}',
                            if (missing > 0) '${l10n.missingItemsLabel}: $missing',
                            if (session.qcByName != null) '${l10n.qcByLabel}: ${session.qcByName}',
                            if (session.qcNotes != null && session.qcNotes!.isNotEmpty) session.qcNotes!,
                          ].join(' · '),
                        ),
                        trailing: canQc && session.status == TrayPreparationStatus.prepared
                            ? TextButton(onPressed: () => _qc(session), child: Text(l10n.qcAction))
                            : null,
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}
