import 'package:flutter/material.dart';

import '../design_system/components/instriq_review_queue.dart';
import '../l10n/app_localizations.dart';
import '../models/contributor_application.dart';
import '../services/contributor_service.dart';

/// Cola de revisió de candidatures de col·laborador, visible nomes per
/// l'Editorial Board (`ContributorService.instance.isEditorialBoard`).
/// Cap candidatura s'aprova automàticament (docs/EPIC_COMMUNITY_GOVERNANCE.md §1).
class ContributorReviewQueueScreen extends StatefulWidget {
  const ContributorReviewQueueScreen({super.key});

  @override
  State<ContributorReviewQueueScreen> createState() =>
      _ContributorReviewQueueScreenState();
}

class _ContributorReviewQueueScreenState
    extends State<ContributorReviewQueueScreen> {
  /// `ContributorService.reviewApplication` es un sol mètode amb flag
  /// `approved` (no dos RPC separats com als altres 3 serveis) — s'adapta
  /// aquí a la parella `onApprove`/`onReject` que espera el component genèric.
  Future<void> _decide(
      ContributorApplication application, bool approved, String? comment) {
    return ContributorService.instance
        .reviewApplication(application.id, approved, notes: comment);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.contributorReviewQueueTitle)),
      body: InstriqReviewQueue<ContributorApplication>.inline(
        load: ContributorService.instance.fetchPendingApplications,
        titleOf: (a) => a.fullName,
        secondaryLineOf: (a) => a.professionalRole == null
            ? a.email
            : '${a.email} · ${a.professionalRole}',
        commentOf: (a) => a.motivationLetter,
        onApprove: (a) => _decide(a, true, null),
        approveLabel: l10n.approve,
        onReject: (a, comment) => _decide(a, false, comment),
        rejectLabel: l10n.reject,
        rejectDialogTitle: l10n.rejectChangeTitle,
        rejectReasonLabel: l10n.rejectReasonLabel,
        cancelLabel: l10n.cancel,
        approveSuccessMessage: l10n.contributorApplicationApprovedSnackbar,
        rejectSuccessMessage: l10n.contributorApplicationRejectedSnackbar,
        approveErrorMessage: (e) => l10n.approveError(e.toString()),
        rejectErrorMessage: (e) => l10n.rejectError(e.toString()),
        errorMessage: (e) => l10n.reviewQueueLoadError(e.toString()),
        retryLabel: l10n.retry,
        emptyBuilder: (_) => Center(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.noPendingReviews))),
      ),
    );
  }
}
