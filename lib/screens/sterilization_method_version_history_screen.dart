import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../design_system/components/instriq_version_history.dart';
import '../l10n/app_localizations.dart';
import '../models/group_document_version.dart' show GroupDocumentVersionStatusLabel;
import '../models/instrument_sterilization.dart';
import '../services/sterilization_service.dart';
import '../widgets/sterilization_method_label.dart';
import 'sterilization_method_diff_screen.dart';

/// Historial de versiones de un método de esterilización de un instrumento,
/// con opción de restaurar una antigua. Delgado wrapper sobre
/// [InstriqVersionHistory] — calcado de [TrayVersionHistoryScreen].
class SterilizationMethodVersionHistoryScreen extends StatefulWidget {
  final SterilizationMethodEntry method;
  final bool canRestore;

  const SterilizationMethodVersionHistoryScreen({
    super.key,
    required this.method,
    required this.canRestore,
  });

  @override
  State<SterilizationMethodVersionHistoryScreen> createState() =>
      _SterilizationMethodVersionHistoryScreenState();
}

class _SterilizationMethodVersionHistoryScreenState extends State<SterilizationMethodVersionHistoryScreen> {
  Map<String, String> _authorNames = {};

  Future<List<SterilizationMethodVersion>> _load() async {
    final versions = await SterilizationService.instance.fetchMethodVersionHistory(widget.method.id!);
    await _resolveAuthorNames(versions.map((v) => v.authorId).whereType<String>().toSet());
    return versions;
  }

  /// Mismo patrón de resolución de perfil que [TrayVersionHistoryScreen]: una
  /// sola consulta por lote a `profiles`, combinada en memoria.
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
      // Metadato accesorio: si falla, el nombre cae al id crudo.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.versionHistoryTitle)),
      body: InstriqVersionHistory<SterilizationMethodVersion>(
        fetchHistory: _load,
        titleOf: (v) => sterilizationMethodValueLabel(l10n, v.method),
        statusOf: (v) => v.status,
        statusLabelOf: (s) => s.label,
        versionNumberOf: (v) => v.versionNumber,
        authorIdOf: (v) => v.authorId,
        createdAtOf: (v) => v.createdAt,
        commentOf: (v) => v.comment,
        resolveAuthorName: (id) => _authorNames[id] ?? id,
        canRestore: (_) => widget.canRestore,
        onRestore: (v) async {
          await SterilizationService.instance.restoreMethodVersion(v.id);
        },
        compareBase: widget.method.publishedVersion,
        diffBuilder: (older, newer) => SterilizationMethodDiffScreen(oldVersion: older, newVersion: newer),
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
