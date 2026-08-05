import 'package:flutter/material.dart';

import '../tokens.dart';
import 'instriq_async_view.dart';

/// Modo de interacción de cada fila de la cola. Ver `docs/` Nivell 1,
/// Component 4: 4 de las 5 colas de revisión (documento/bandeja/tarjeta de
/// grupo + candidaturas de colaborador) son homogéneas — tarjeta con
/// Comparar/Rechazar/Aprobar directos ([inline]). La 5a (biblioteca
/// pública) navega a un hilo de comentarios persistente propio
/// ([navigate]) en vez de actuar en la fila.
enum InstriqReviewQueueMode { inline, navigate }

/// Xasis genèric per a les 5 cues de revisió de contingut pendent
/// d'aprovació. Combina `InstriqAsyncView` (càrrega/buit/error-amb-reintent)
/// amb una targeta per ítem. Cap model (`GroupDocumentVersion`/`TrayVersion`/
/// `PreferenceCardVersion`/`ContributorApplication`/...) implementa cap
/// interfície compartida — tots els descriptors es passen des del punt de
/// crida (consistent amb ADR-004).
class InstriqReviewQueue<T> extends StatefulWidget {
  /// Recarrega la llista sencera; es torna a cridar automàticament després
  /// d'un `onApprove`/`onReject` reeixit i des del botó de reintent en error.
  final Future<List<T>> Function() load;
  final String Function(T item) titleOf;
  final String? Function(T item)? secondaryLineOf;
  final String? Function(T item)? commentOf;
  final InstriqReviewQueueMode mode;

  // --- Mode `inline` ---
  /// Omès (`null`) per a cues sense diff (candidatures de colaborador).
  final Future<void> Function(T item)? onCompare;
  final Future<void> Function(T item)? onApprove;
  final Future<void> Function(T item, String? comment)? onReject;
  final String? compareLabel;
  final String? rejectLabel;
  final String? approveLabel;
  final String? rejectDialogTitle;
  final String? rejectReasonLabel;
  final String? cancelLabel;
  final String? approveSuccessMessage;
  final String? rejectSuccessMessage;
  final String Function(Object error)? approveErrorMessage;
  final String Function(Object error)? rejectErrorMessage;

  // --- Mode `navigate` ---
  /// Delegació completa del tap (p.ex. obrir `_EditorialCommentsScreen`) —
  /// el component no en sap res del contingut de la navegació, només recarrega
  /// la llista quan el `Future` retorna (p.ex. en tornar de la pantalla de
  /// comentaris, per si l'estat ha canviat).
  final Future<void> Function(BuildContext context, T item)? onTap;

  // --- Plumbing d'`InstriqAsyncView` ---
  final String Function(Object error) errorMessage;
  final String retryLabel;
  final WidgetBuilder emptyBuilder;

  const InstriqReviewQueue.inline({
    super.key,
    required this.load,
    required this.titleOf,
    this.secondaryLineOf,
    this.commentOf,
    this.onCompare,
    this.compareLabel,
    required this.onApprove,
    required this.approveLabel,
    required this.onReject,
    required this.rejectLabel,
    required this.rejectDialogTitle,
    required this.rejectReasonLabel,
    required this.cancelLabel,
    required this.approveSuccessMessage,
    required this.rejectSuccessMessage,
    required this.approveErrorMessage,
    required this.rejectErrorMessage,
    required this.errorMessage,
    required this.retryLabel,
    required this.emptyBuilder,
  })  : mode = InstriqReviewQueueMode.inline,
        onTap = null;

  const InstriqReviewQueue.navigate({
    super.key,
    required this.load,
    required this.titleOf,
    this.secondaryLineOf,
    this.commentOf,
    required this.onTap,
    required this.errorMessage,
    required this.retryLabel,
    required this.emptyBuilder,
  })  : mode = InstriqReviewQueueMode.navigate,
        onCompare = null,
        compareLabel = null,
        onApprove = null,
        approveLabel = null,
        onReject = null,
        rejectLabel = null,
        rejectDialogTitle = null,
        rejectReasonLabel = null,
        cancelLabel = null,
        approveSuccessMessage = null,
        rejectSuccessMessage = null,
        approveErrorMessage = null,
        rejectErrorMessage = null;

  @override
  State<InstriqReviewQueue<T>> createState() => _InstriqReviewQueueState<T>();
}

class _InstriqReviewQueueState<T> extends State<InstriqReviewQueue<T>> {
  final _asyncViewKey = GlobalKey<InstriqAsyncViewState<List<T>>>();

  Future<void> _handleApprove(T item) async {
    try {
      await widget.onApprove!(item);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.approveSuccessMessage!)));
      }
      _asyncViewKey.currentState?.reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.approveErrorMessage!(e))));
      }
    }
  }

  Future<void> _handleReject(T item) async {
    final controller = TextEditingController();
    final comment = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.rejectDialogTitle!),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(labelText: widget.rejectReasonLabel!),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(widget.cancelLabel!)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(widget.rejectLabel!)),
        ],
      ),
    );
    if (!mounted || comment == null) return;
    try {
      await widget.onReject!(item, comment.isEmpty ? null : comment);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.rejectSuccessMessage!)));
      }
      _asyncViewKey.currentState?.reload();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.rejectErrorMessage!(e))));
      }
    }
  }

  Widget _buildRow(T item) {
    if (widget.mode == InstriqReviewQueueMode.navigate) {
      return Card(
        child: ListTile(
          title: Text(widget.titleOf(item)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            await widget.onTap!(context, item);
            if (mounted) _asyncViewKey.currentState?.reload();
          },
        ),
      );
    }
    final secondary = widget.secondaryLineOf?.call(item);
    final comment = widget.commentOf?.call(item);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(InstriqSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.titleOf(item),
                style: Theme.of(context).textTheme.titleMedium),
            if (secondary != null) ...[
              const SizedBox(height: 2),
              Text(secondary, style: Theme.of(context).textTheme.labelMedium),
            ],
            if (comment != null) ...[
              const SizedBox(height: InstriqSpacing.xs),
              Text(comment, style: Theme.of(context).textTheme.bodyMedium),
            ],
            const SizedBox(height: InstriqSpacing.sm),
            Row(
              children: [
                if (widget.onCompare != null)
                  TextButton(
                      onPressed: () => widget.onCompare!(item),
                      child: Text(widget.compareLabel!)),
                const Spacer(),
                TextButton(
                    onPressed: () => _handleReject(item),
                    child: Text(widget.rejectLabel!)),
                const SizedBox(width: InstriqSpacing.sm),
                FilledButton(
                    onPressed: () => _handleApprove(item),
                    child: Text(widget.approveLabel!)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InstriqAsyncView<List<T>>(
      key: _asyncViewKey,
      load: widget.load,
      errorMessage: widget.errorMessage,
      retryLabel: widget.retryLabel,
      isEmpty: (data) => data.isEmpty,
      emptyBuilder: widget.emptyBuilder,
      builder: (_, items) => ListView.builder(
        padding: const EdgeInsets.all(InstriqSpacing.md),
        itemCount: items.length,
        itemBuilder: (_, index) => _buildRow(items[index]),
      ),
    );
  }
}
