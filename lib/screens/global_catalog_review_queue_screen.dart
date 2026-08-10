import 'package:flutter/material.dart';

import '../design_system/components/instriq_review_queue.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument_sterilization.dart';
import '../services/sterilization_service.dart';
import '../widgets/sterilization_method_label.dart';
import 'sterilization_method_diff_screen.dart';
import 'sterilization_review_queue_support.dart';
import 'technical_info_diff_screen.dart';

/// Cola de revisión del catálogo global (`organization_id` nulo) de métodos
/// de esterilización y fichas técnicas, solo para el Editorial Board
/// (`ContributorService.instance.isEditorialBoard`, comprobado antes de
/// abrir esta pantalla desde `ProfileHubScreen`). Las filas de organización
/// se aprueban donde ya se aprueba el resto de contenido de espacio, en
/// `ReviewQueueScreen` (ver EPIC 3 · Bloc B) -- no aquí, mismo criterio de
/// separación que `PublicLibraryReviewQueueScreen` frente a `ReviewQueueScreen`.
class GlobalCatalogReviewQueueScreen extends StatelessWidget {
  const GlobalCatalogReviewQueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.globalCatalogReviewQueueTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.sterilizationMethodsTabTitle),
              Tab(text: l10n.technicalInfoTabTitle),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GlobalMethodReviewQueue(),
            _GlobalTechnicalInfoReviewQueue(),
          ],
        ),
      ),
    );
  }
}

class _GlobalMethodReviewQueue extends StatefulWidget {
  const _GlobalMethodReviewQueue();

  @override
  State<_GlobalMethodReviewQueue> createState() => _GlobalMethodReviewQueueState();
}

class _GlobalMethodReviewQueueState extends State<_GlobalMethodReviewQueue> {
  Map<String, SterilizationHeaderInfo> _headers = {};
  Map<String, String> _instrumentNames = {};

  Future<List<SterilizationMethodVersion>> _load() async {
    final queue = await SterilizationService.instance.fetchMethodReviewQueue();
    _headers = await fetchMethodHeaders(queue.map((v) => v.methodId).toSet().toList());
    _instrumentNames = await resolveInstrumentNames(_headers.values);
    return queue.where((v) => _headers[v.methodId]?.isGlobal ?? false).toList();
  }

  String _titleOf(SterilizationMethodVersion v) {
    final header = _headers[v.methodId];
    if (header == null) return v.methodId;
    return _instrumentNames[header.instrumentRefId] ?? header.instrumentRefId;
  }

  Future<void> _openDiff(SterilizationMethodVersion version) async {
    try {
      final entry = await fetchMethodEntryWithPublished(version.methodId);
      final published = entry.publishedVersion;
      if (published == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SterilizationMethodDiffScreen(oldVersion: published, newVersion: version),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                AppLocalizations.of(context)!.compareLoadError(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InstriqReviewQueue<SterilizationMethodVersion>.inline(
      load: _load,
      titleOf: _titleOf,
      secondaryLineOf: (v) => sterilizationMethodValueLabel(l10n, v.method),
      commentOf: (v) => v.comment,
      onCompare: _openDiff,
      compareLabel: l10n.compare,
      onApprove: (v) => SterilizationService.instance.approveMethodVersion(v.id),
      approveLabel: l10n.approve,
      onReject: (v, comment) =>
          SterilizationService.instance.rejectMethodVersion(v.id, comment: comment),
      rejectLabel: l10n.reject,
      rejectDialogTitle: l10n.rejectChangeTitle,
      rejectReasonLabel: l10n.rejectReasonLabel,
      cancelLabel: l10n.cancel,
      approveSuccessMessage: l10n.changeApprovedSnackbar,
      rejectSuccessMessage: l10n.changeReturnedSnackbar,
      approveErrorMessage: (e) => l10n.approveError(e.toString()),
      rejectErrorMessage: (e) => l10n.rejectError(e.toString()),
      errorMessage: (e) => l10n.reviewQueueLoadError(e.toString()),
      retryLabel: l10n.retry,
      emptyBuilder: (_) => Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.noPendingReviews))),
    );
  }
}

class _GlobalTechnicalInfoReviewQueue extends StatefulWidget {
  const _GlobalTechnicalInfoReviewQueue();

  @override
  State<_GlobalTechnicalInfoReviewQueue> createState() => _GlobalTechnicalInfoReviewQueueState();
}

class _GlobalTechnicalInfoReviewQueueState extends State<_GlobalTechnicalInfoReviewQueue> {
  Map<String, SterilizationHeaderInfo> _headers = {};
  Map<String, String> _instrumentNames = {};

  Future<List<InstrumentTechnicalInfoVersion>> _load() async {
    final queue = await SterilizationService.instance.fetchTechnicalInfoReviewQueue();
    _headers = await fetchTechnicalInfoHeaders(queue.map((v) => v.infoId).toSet().toList());
    _instrumentNames = await resolveInstrumentNames(_headers.values);
    return queue.where((v) => _headers[v.infoId]?.isGlobal ?? false).toList();
  }

  String _titleOf(InstrumentTechnicalInfoVersion v) {
    final header = _headers[v.infoId];
    if (header == null) return v.infoId;
    return _instrumentNames[header.instrumentRefId] ?? header.instrumentRefId;
  }

  Future<void> _openDiff(InstrumentTechnicalInfoVersion version) async {
    try {
      final info = await fetchTechnicalInfoWithPublished(version.infoId);
      final published = info.publishedVersion;
      if (published == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TechnicalInfoDiffScreen(oldVersion: published, newVersion: version),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                AppLocalizations.of(context)!.compareLoadError(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InstriqReviewQueue<InstrumentTechnicalInfoVersion>.inline(
      load: _load,
      titleOf: _titleOf,
      commentOf: (v) => v.comment,
      onCompare: _openDiff,
      compareLabel: l10n.compare,
      onApprove: (v) => SterilizationService.instance.approveTechnicalInfoVersion(v.id),
      approveLabel: l10n.approve,
      onReject: (v, comment) =>
          SterilizationService.instance.rejectTechnicalInfoVersion(v.id, comment: comment),
      rejectLabel: l10n.reject,
      rejectDialogTitle: l10n.rejectChangeTitle,
      rejectReasonLabel: l10n.rejectReasonLabel,
      cancelLabel: l10n.cancel,
      approveSuccessMessage: l10n.changeApprovedSnackbar,
      rejectSuccessMessage: l10n.changeReturnedSnackbar,
      approveErrorMessage: (e) => l10n.approveError(e.toString()),
      rejectErrorMessage: (e) => l10n.rejectError(e.toString()),
      errorMessage: (e) => l10n.reviewQueueLoadError(e.toString()),
      retryLabel: l10n.retry,
      emptyBuilder: (_) => Center(
          child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.noPendingReviews))),
    );
  }
}
