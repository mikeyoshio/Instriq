import 'package:flutter/material.dart';

import '../design_system/components/instriq_review_queue.dart';
import '../l10n/app_localizations.dart';
import '../models/editorial_comment.dart';
import '../models/public_document.dart';
import '../models/public_tray.dart';
import '../services/editorial_comment_service.dart';
import '../services/public_document_service.dart';
import '../services/public_tray_service.dart';

/// Cua de revisio de la Biblioteca Publica, nomes per a reviewer/editorial
/// board (`ContributorService.instance.isEditorialBoard`, comprovat abans
/// d'obrir aquesta pantalla a `PublicLibraryScreen`). Dues pestanyes,
/// mateix patro que `ReviewQueueScreen` -- pero amb fil de comentaris
/// multi-ronda (capacitat nova, EPIC 9 segon tram) en comptes d'un unic
/// camp `comment` sobreescrivible.
class PublicLibraryReviewQueueScreen extends StatelessWidget {
  const PublicLibraryReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.publicLibraryReviewQueueTitle),
          bottom: TabBar(tabs: [Tab(text: l10n.techniquesTitle), Tab(text: l10n.traysTitle)]),
        ),
        body: const TabBarView(children: [_DocumentReviewQueue(), _TrayReviewQueue()]),
      ),
    );
  }
}

class _DocumentReviewQueue extends StatelessWidget {
  const _DocumentReviewQueue();

  Future<void> _openComments(BuildContext context, PublicDocumentVersion version) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _EditorialCommentsScreen(
          refType: 'public_document_version',
          refId: version.id,
          title: version.title ?? '',
          onApprove: () => PublicDocumentService.instance.approve(version.id),
          onReject: (comment) => PublicDocumentService.instance.reject(version.id, comment: comment),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InstriqReviewQueue<PublicDocumentVersion>.navigate(
      load: PublicDocumentService.instance.fetchReviewQueue,
      titleOf: (v) => v.title ?? l10n.auditDocumentUntitledLabel,
      onTap: _openComments,
      errorMessage: (e) => l10n.reviewQueueLoadError(e.toString()),
      retryLabel: l10n.retry,
      emptyBuilder: (_) =>
          Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noPendingReviews))),
    );
  }
}

class _TrayReviewQueue extends StatelessWidget {
  const _TrayReviewQueue();

  Future<void> _openComments(BuildContext context, PublicTrayVersion version) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _EditorialCommentsScreen(
          refType: 'public_tray_version',
          refId: version.id,
          title: version.name ?? '',
          onApprove: () => PublicTrayService.instance.approve(version.id),
          onReject: (comment) => PublicTrayService.instance.reject(version.id, comment: comment),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InstriqReviewQueue<PublicTrayVersion>.navigate(
      load: PublicTrayService.instance.fetchReviewQueue,
      titleOf: (v) => v.name ?? l10n.auditDocumentUntitledLabel,
      onTap: _openComments,
      errorMessage: (e) => l10n.reviewQueueLoadError(e.toString()),
      retryLabel: l10n.retry,
      emptyBuilder: (_) =>
          Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.noPendingReviews))),
    );
  }
}

/// Fil de comentaris + aprovar/rebutjar, compartit entre documents i
/// safates (el ref_type/callbacks varien, la pantalla no).
class _EditorialCommentsScreen extends StatefulWidget {
  final String refType;
  final String refId;
  final String title;
  final Future<void> Function() onApprove;
  final Future<void> Function(String? comment) onReject;

  const _EditorialCommentsScreen({
    required this.refType,
    required this.refId,
    required this.title,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<_EditorialCommentsScreen> createState() => _EditorialCommentsScreenState();
}

class _EditorialCommentsScreenState extends State<_EditorialCommentsScreen> {
  bool _loading = true;
  List<EditorialComment> _comments = [];
  final _newCommentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newCommentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _comments = await EditorialCommentService.instance.fetchFor(widget.refType, widget.refId);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _addComment() async {
    final text = _newCommentController.text.trim();
    if (text.isEmpty) return;
    await EditorialCommentService.instance.addComment(widget.refType, widget.refId, text);
    _newCommentController.clear();
    _load();
  }

  Future<void> _approve() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await widget.onApprove();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.changeApprovedSnackbar)));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.approveError(e.toString()))));
    }
  }

  Future<void> _reject() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await widget.onReject(_newCommentController.text.trim().isEmpty ? null : _newCommentController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.changeReturnedSnackbar)));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.rejectError(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _comments.isEmpty
                      ? Center(child: Text(l10n.editorialCommentsEmptyState))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _comments.length,
                          itemBuilder: (context, index) {
                            final comment = _comments[index];
                            return ListTile(
                              leading: const Icon(Icons.comment_outlined),
                              title: Text(comment.body),
                              subtitle: Text(comment.authorDisplayName ?? l10n.deletedUserLabel),
                            );
                          },
                        ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _newCommentController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.editorialCommentHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  TextButton(onPressed: _addComment, child: Text(l10n.editorialCommentSendAction)),
                  const Spacer(),
                  TextButton(onPressed: _reject, child: Text(l10n.reject)),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: _approve, child: Text(l10n.approve)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
