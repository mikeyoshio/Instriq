import 'package:flutter/material.dart';

import '../../models/group_document_version.dart';
import '../tokens.dart';
import 'instriq_async_view.dart';
import 'instriq_badge.dart';

/// Historial de versiones genérico (bandeja/documento/tarjeta): fila con
/// estado, título, autor+fecha y acciones de comparar/restaurar.
///
/// Sustituye 3 copias casi idénticas que tenían dos bugs:
/// - `_statusColor` propio de cada pantalla pintaba `draft` y `archived` con
///   el mismo color (`surfaceContainerHighest`). Aquí se usa
///   [InstriqBadge.status], que ya resuelve los 4 colores vía
///   `InstriqColors.status*`.
/// - El botón de comparar siempre llamaba a `diffBuilder` con
///   `oldVersion: <versión publicada>` sin mirar si la versión tocada era en
///   realidad más antigua o más nueva. Aquí se decide comparando
///   [versionNumberOf] de la versión tocada contra [compareBase].
///
/// No conoce `AppLocalizations`: todos los textos llegan como parámetros
/// (mismo patrón que [InstriqAsyncView.errorMessage]/`retryLabel`) — el
/// punto de crida es quien tiene acceso al contexto de l10n.
class InstriqVersionHistory<T> extends StatefulWidget {
  final Future<List<T>> Function() fetchHistory;
  final String Function(T version) titleOf;
  final GroupDocumentVersionStatus Function(T version) statusOf;
  final String Function(GroupDocumentVersionStatus status) statusLabelOf;
  final int Function(T version) versionNumberOf;
  final String? Function(T version) authorIdOf;
  final DateTime? Function(T version) createdAtOf;
  final String? Function(T version)? commentOf;

  /// Resuelve un id de autor a un nombre para mostrar. Si no se provee, o si
  /// no encuentra el id, se muestra el id crudo (fallback deliberado en vez
  /// de bloquear la construcción de este componente en nueva infraestructura
  /// de resolución de perfiles).
  final String Function(String authorId)? resolveAuthorName;

  final bool Function(T version) canRestore;
  final Future<void> Function(T version) onRestore;

  /// Versión contra la que se compara (típicamente la publicada). Si es
  /// `null`, la acción de comparar queda deshabilitada — igual que antes,
  /// cuando no había versión publicada.
  final T? compareBase;

  /// Recibe siempre `(older, newer)` en el orden cronológico correcto,
  /// independientemente de cuál de las dos sea [compareBase].
  final Widget Function(T older, T newer) diffBuilder;

  final String Function(Object error) loadErrorMessage;
  final String retryLabel;
  final String Function(int versionNumber, String title) versionLabelOf;
  final String compareLabel;
  final String restoreLabel;
  final String cancelLabel;
  final String restoreDialogTitle;
  final String Function(int versionNumber) restoreDialogBody;
  final String restoreSuccessMessage;
  final String Function(Object error) restoreErrorMessage;

  const InstriqVersionHistory({
    super.key,
    required this.fetchHistory,
    required this.titleOf,
    required this.statusOf,
    required this.statusLabelOf,
    required this.versionNumberOf,
    required this.authorIdOf,
    required this.createdAtOf,
    this.commentOf,
    this.resolveAuthorName,
    required this.canRestore,
    required this.onRestore,
    required this.compareBase,
    required this.diffBuilder,
    required this.loadErrorMessage,
    required this.retryLabel,
    required this.versionLabelOf,
    required this.compareLabel,
    required this.restoreLabel,
    required this.cancelLabel,
    required this.restoreDialogTitle,
    required this.restoreDialogBody,
    required this.restoreSuccessMessage,
    required this.restoreErrorMessage,
  });

  @override
  State<InstriqVersionHistory<T>> createState() => _InstriqVersionHistoryState<T>();
}

class _InstriqVersionHistoryState<T> extends State<InstriqVersionHistory<T>> {
  final GlobalKey<InstriqAsyncViewState<List<T>>> _asyncKey = GlobalKey<InstriqAsyncViewState<List<T>>>();

  InstriqStatus _toInstriqStatus(GroupDocumentVersionStatus status) {
    switch (status) {
      case GroupDocumentVersionStatus.draft:
        return InstriqStatus.draft;
      case GroupDocumentVersionStatus.inReview:
        return InstriqStatus.inReview;
      case GroupDocumentVersionStatus.published:
        return InstriqStatus.published;
      case GroupDocumentVersionStatus.archived:
        return InstriqStatus.archived;
    }
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _restore(BuildContext context, T version) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.restoreDialogTitle),
        content: Text(widget.restoreDialogBody(widget.versionNumberOf(version))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(widget.cancelLabel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(widget.restoreLabel)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.onRestore(version);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.restoreSuccessMessage)));
      }
      _asyncKey.currentState?.reload();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(widget.restoreErrorMessage(e))));
      }
    }
  }

  void _openDiff(BuildContext context, T version) {
    final base = widget.compareBase;
    if (base == null) return;
    final tappedNumber = widget.versionNumberOf(version);
    final baseNumber = widget.versionNumberOf(base);
    final T older = tappedNumber <= baseNumber ? version : base;
    final T newer = tappedNumber <= baseNumber ? base : version;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => widget.diffBuilder(older, newer)));
  }

  @override
  Widget build(BuildContext context) {
    return InstriqAsyncView<List<T>>(
      key: _asyncKey,
      load: widget.fetchHistory,
      errorMessage: widget.loadErrorMessage,
      retryLabel: widget.retryLabel,
      builder: (context, versions) => ListView.builder(
        padding: const EdgeInsets.all(InstriqSpacing.md),
        itemCount: versions.length,
        itemBuilder: (context, index) => _buildRow(context, versions[index]),
      ),
    );
  }

  Widget _buildRow(BuildContext context, T version) {
    final status = widget.statusOf(version);
    final authorId = widget.authorIdOf(version);
    final authorName = authorId == null ? null : (widget.resolveAuthorName?.call(authorId) ?? authorId);
    final createdAt = widget.createdAtOf(version);
    final comment = widget.commentOf?.call(version);
    final canRestore = widget.canRestore(version);

    return Card(
      margin: const EdgeInsets.only(bottom: InstriqSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(InstriqSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InstriqBadge.status(_toInstriqStatus(status), widget.statusLabelOf(status)),
                const SizedBox(width: InstriqSpacing.sm),
                Expanded(
                  child: Text(
                    widget.versionLabelOf(widget.versionNumberOf(version), widget.titleOf(version)),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'diff') _openDiff(context, version);
                    if (value == 'restore') _restore(context, version);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'diff', child: Text(widget.compareLabel)),
                    if (canRestore) PopupMenuItem(value: 'restore', child: Text(widget.restoreLabel)),
                  ],
                ),
              ],
            ),
            if (authorName != null || createdAt != null) ...[
              const SizedBox(height: InstriqSpacing.xs),
              Text(
                [
                  if (authorName != null) authorName,
                  if (createdAt != null) _formatDate(createdAt),
                ].join(' · '),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (comment != null && comment.isNotEmpty) ...[
              const SizedBox(height: InstriqSpacing.xs),
              Text(comment, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
