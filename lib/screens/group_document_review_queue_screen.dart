import 'package:flutter/material.dart';

import '../design_system/components/instriq_review_queue.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/group_document_version.dart';
import '../models/instrument_sterilization.dart';
import '../models/preference_card.dart';
import '../models/tray.dart';
import '../services/custom_instrument_service.dart';
import '../services/group_document_service.dart';
import '../services/preference_card_service.dart';
import '../services/sterilization_service.dart';
import '../services/surgeon_service.dart';
import '../services/tray_service.dart';
import '../widgets/sterilization_method_label.dart';
import 'group_document_diff_screen.dart';
import 'preference_card_diff_screen.dart';
import 'sterilization_method_diff_screen.dart';
import 'sterilization_review_queue_support.dart';
import 'technical_info_diff_screen.dart';
import 'tray_diff_screen.dart';

/// Cola de aprobación de todo el grupo: versiones en revisión, visible solo
/// para administradores (hacen de aprobador hasta que exista el rol
/// Approver dedicado, previsto para la Fase B). Cinco pestañas: técnicas/
/// protocolos, bandejas de instrumental, tarjetas de preferencia, métodos de
/// esterilización y fichas técnicas — todas comparten el mismo workflow de
/// aprobación (`in_review` -> aprobar/rechazar), así que se generaliza esta
/// pantalla en vez de duplicarla. Las dos últimas solo muestran filas de
/// organización (`organization_id` no nulo); las globales del catálogo las
/// aprueba el Editorial Board en `GlobalCatalogReviewQueueScreen`.
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
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.reviewQueueTitle),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: '${l10n.techniquesTitle} / ${l10n.protocolsTitle}'),
              Tab(text: l10n.traysTitle),
              Tab(text: l10n.preferenceCardsTitle),
              Tab(text: l10n.sterilizationMethodsTabTitle),
              Tab(text: l10n.technicalInfoTabTitle),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DocumentReviewQueue(),
            _TrayReviewQueue(),
            _PreferenceCardReviewQueue(),
            _SterilizationMethodReviewQueue(),
            _TechnicalInfoReviewQueue(),
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
  Map<String, String> _workspaceNames = {};

  Future<List<GroupDocumentVersion>> _load() async {
    final queue = await GroupDocumentService.instance.fetchReviewQueue();
    _workspaceNames = await GroupDocumentService.instance
        .fetchWorkspaceNamesForDocuments(
            queue.map((v) => v.documentId).toSet().toList());
    return queue;
  }

  Future<void> _openDiff(GroupDocumentVersion version) async {
    try {
      final document =
          await GroupDocumentService.instance.fetchDocument(version.documentId);
      final published = document.publishedVersion;
      if (published == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => GroupDocumentDiffScreen(
              oldVersion: published, newVersion: version),
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
    return InstriqReviewQueue<GroupDocumentVersion>.inline(
      load: _load,
      titleOf: (v) => v.title,
      secondaryLineOf: (v) => _workspaceNames[v.documentId],
      commentOf: (v) => v.comment,
      onCompare: _openDiff,
      compareLabel: l10n.compare,
      onApprove: (v) => GroupDocumentService.instance.approve(v.id),
      approveLabel: l10n.approve,
      onReject: (v, comment) =>
          GroupDocumentService.instance.reject(v.id, comment: comment),
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

class _TrayReviewQueue extends StatefulWidget {
  const _TrayReviewQueue();

  @override
  State<_TrayReviewQueue> createState() => _TrayReviewQueueState();
}

class _TrayReviewQueueState extends State<_TrayReviewQueue> {
  Map<String, String> _workspaceNames = {};
  final Map<String, List<CustomInstrument>> _customInstrumentsByWorkspace = {};

  Future<List<TrayVersion>> _load() async {
    final queue = await TrayService.instance.fetchReviewQueue();
    _workspaceNames = await TrayService.instance.fetchWorkspaceNamesForTrays(
        queue.map((v) => v.trayId).toSet().toList());
    return queue;
  }

  Future<List<CustomInstrument>> _customInstrumentsFor(
      String workspaceId) async {
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                AppLocalizations.of(context)!.compareLoadError(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InstriqReviewQueue<TrayVersion>.inline(
      load: _load,
      titleOf: (v) => v.name,
      secondaryLineOf: (v) => _workspaceNames[v.trayId],
      commentOf: (v) => v.comment,
      onCompare: _openDiff,
      compareLabel: l10n.compare,
      onApprove: (v) => TrayService.instance.approve(v.id),
      approveLabel: l10n.approve,
      onReject: (v, comment) =>
          TrayService.instance.reject(v.id, comment: comment),
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

class _PreferenceCardReviewQueue extends StatefulWidget {
  const _PreferenceCardReviewQueue();

  @override
  State<_PreferenceCardReviewQueue> createState() =>
      _PreferenceCardReviewQueueState();
}

class _PreferenceCardReviewQueueState
    extends State<_PreferenceCardReviewQueue> {
  Map<String, String> _workspaceNames = {};

  Future<List<PreferenceCardVersion>> _load() async {
    await SurgeonService.instance.fetchForOrganization();
    final queue = await PreferenceCardService.instance.fetchReviewQueue();
    _workspaceNames = await PreferenceCardService.instance
        .fetchWorkspaceNamesForCards(
            queue.map((v) => v.cardId).toSet().toList());
    return queue;
  }

  Future<void> _openDiff(PreferenceCardVersion version) async {
    try {
      final card =
          await PreferenceCardService.instance.fetchCard(version.cardId);
      final published = card.publishedVersion;
      if (published == null || !mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PreferenceCardDiffScreen(
            oldVersion: published,
            newVersion: version,
            surgeons: SurgeonService.instance.surgeons,
          ),
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
    return InstriqReviewQueue<PreferenceCardVersion>.inline(
      load: _load,
      titleOf: (v) => v.procedureName,
      secondaryLineOf: (v) => _workspaceNames[v.cardId],
      commentOf: (v) => v.comment,
      onCompare: _openDiff,
      compareLabel: l10n.compare,
      onApprove: (v) => PreferenceCardService.instance.approve(v.id),
      approveLabel: l10n.approve,
      onReject: (v, comment) =>
          PreferenceCardService.instance.reject(v.id, comment: comment),
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

/// Métodos de esterilización de organización (`organization_id` no nulo) --
/// los globales (catálogo) los aprueba el Editorial Board en
/// `GlobalCatalogReviewQueueScreen`, no aquí (ver EPIC 3 · Bloc B).
class _SterilizationMethodReviewQueue extends StatefulWidget {
  const _SterilizationMethodReviewQueue();

  @override
  State<_SterilizationMethodReviewQueue> createState() => _SterilizationMethodReviewQueueState();
}

class _SterilizationMethodReviewQueueState extends State<_SterilizationMethodReviewQueue> {
  Map<String, SterilizationHeaderInfo> _headers = {};
  Map<String, String> _instrumentNames = {};

  Future<List<SterilizationMethodVersion>> _load() async {
    final queue = await SterilizationService.instance.fetchMethodReviewQueue();
    _headers = await fetchMethodHeaders(queue.map((v) => v.methodId).toSet().toList());
    _instrumentNames = await resolveInstrumentNames(_headers.values);
    return queue.where((v) => _headers[v.methodId]?.organizationId != null).toList();
  }

  String _titleOf(SterilizationMethodVersion v) {
    final header = _headers[v.methodId];
    if (header == null) return v.methodId;
    return _instrumentNames[header.instrumentRefId] ?? header.instrumentRefId;
  }

  String? _secondaryLineOf(AppLocalizations l10n, SterilizationMethodVersion v) {
    final header = _headers[v.methodId];
    final parts = <String>[sterilizationMethodValueLabel(l10n, v.method)];
    final workspaceName = header?.workspaceName;
    if (workspaceName != null) parts.add(workspaceName);
    return parts.join(' · ');
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
      secondaryLineOf: (v) => _secondaryLineOf(l10n, v),
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

/// Fichas técnicas de organización (`organization_id` no nulo) -- ver
/// [_SterilizationMethodReviewQueue].
class _TechnicalInfoReviewQueue extends StatefulWidget {
  const _TechnicalInfoReviewQueue();

  @override
  State<_TechnicalInfoReviewQueue> createState() => _TechnicalInfoReviewQueueState();
}

class _TechnicalInfoReviewQueueState extends State<_TechnicalInfoReviewQueue> {
  Map<String, SterilizationHeaderInfo> _headers = {};
  Map<String, String> _instrumentNames = {};

  Future<List<InstrumentTechnicalInfoVersion>> _load() async {
    final queue = await SterilizationService.instance.fetchTechnicalInfoReviewQueue();
    _headers = await fetchTechnicalInfoHeaders(queue.map((v) => v.infoId).toSet().toList());
    _instrumentNames = await resolveInstrumentNames(_headers.values);
    return queue.where((v) => _headers[v.infoId]?.organizationId != null).toList();
  }

  String _titleOf(InstrumentTechnicalInfoVersion v) {
    final header = _headers[v.infoId];
    if (header == null) return v.infoId;
    return _instrumentNames[header.instrumentRefId] ?? header.instrumentRefId;
  }

  String? _secondaryLineOf(InstrumentTechnicalInfoVersion v) => _headers[v.infoId]?.workspaceName;

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
      secondaryLineOf: _secondaryLineOf,
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
