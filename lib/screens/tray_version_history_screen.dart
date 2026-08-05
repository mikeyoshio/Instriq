import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../design_system/components/instriq_version_history.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/group_document_version.dart' show GroupDocumentVersionStatusLabel;
import '../models/tray.dart';
import '../models/workspace_role.dart';
import '../services/custom_instrument_service.dart';
import '../services/tray_service.dart';
import 'tray_diff_screen.dart';

/// Historial de versiones de una bandeja, con opción de restaurar una
/// antigua. Delgado wrapper sobre [InstriqVersionHistory] — calcado de
/// [GroupDocumentVersionHistoryScreen]/[PreferenceCardVersionHistoryScreen].
class TrayVersionHistoryScreen extends StatefulWidget {
  final Tray tray;
  final WorkspaceRole? myRole;

  const TrayVersionHistoryScreen({super.key, required this.tray, required this.myRole});

  @override
  State<TrayVersionHistoryScreen> createState() => _TrayVersionHistoryScreenState();
}

class _TrayVersionHistoryScreenState extends State<TrayVersionHistoryScreen> {
  List<CustomInstrument> _customInstruments = [];
  Map<String, String> _authorNames = {};

  Future<List<TrayVersion>> _load() async {
    await CustomInstrumentService.instance.fetchForWorkspace(widget.tray.workspaceId);
    _customInstruments = CustomInstrumentService.instance.instruments;
    final versions = await TrayService.instance.fetchVersionHistory(widget.tray.id);
    await _resolveAuthorNames(versions.map((v) => v.authorId).whereType<String>().toSet());
    return versions;
  }

  /// Mismo patrón de resolución de perfil que [AuditService.fetchAuditLog]:
  /// una sola consulta por lote a `profiles`, combinada en memoria (no hay
  /// FK directa entre `author_id` y `profiles` que PostgREST pueda embeber
  /// aquí sin duplicar la consulta de versiones).
  Future<void> _resolveAuthorNames(Set<String> authorIds) async {
    if (authorIds.isEmpty) return;
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select('id, display_name')
          .inFilter('id', authorIds.toList());
      _authorNames = {
        for (final r in (rows as List<dynamic>))
          (r as Map<String, dynamic>)['id'] as String: (r['display_name'] as String?) ?? (r['id'] as String),
      };
    } catch (_) {
      // Metadato accesorio: si falla, el nombre cae al id crudo (fallback ya
      // manejado por InstriqVersionHistory.resolveAuthorName).
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canRestore = widget.myRole?.canEdit ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.versionHistoryTitle)),
      body: InstriqVersionHistory<TrayVersion>(
        fetchHistory: _load,
        titleOf: (v) => v.name,
        statusOf: (v) => v.status,
        statusLabelOf: (s) => s.label,
        versionNumberOf: (v) => v.versionNumber,
        authorIdOf: (v) => v.authorId,
        createdAtOf: (v) => v.createdAt,
        commentOf: (v) => v.comment,
        resolveAuthorName: (id) => _authorNames[id] ?? id,
        canRestore: (_) => canRestore,
        onRestore: (v) async {
          await TrayService.instance.restore(v.id);
        },
        compareBase: widget.tray.publishedVersion,
        diffBuilder: (older, newer) => TrayDiffScreen(
          oldVersion: older,
          newVersion: newer,
          customInstruments: _customInstruments,
        ),
        loadErrorMessage: (e) => l10n.versionHistoryLoadError(e.toString()),
        retryLabel: l10n.retry,
        versionLabelOf: (versionNumber, title) => l10n.versionNumberTitle(versionNumber, title),
        compareLabel: l10n.compareWithPublished,
        restoreLabel: l10n.restore,
        cancelLabel: l10n.cancel,
        restoreDialogTitle: l10n.restoreVersionTitle,
        restoreDialogBody: (versionNumber) => l10n.restoreVersionBody(versionNumber),
        restoreSuccessMessage: l10n.restoreSuccessSnackbar,
        restoreErrorMessage: (e) => l10n.restoreError(e.toString()),
      ),
    );
  }
}
