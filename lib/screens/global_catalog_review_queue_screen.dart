import 'package:flutter/material.dart';

import '../design_system/components/instriq_review_queue.dart';
import '../l10n/app_localizations.dart';
import '../models/catalog_content_report.dart';
import '../models/instrument_sterilization.dart';
import '../services/catalog_content_report_service.dart';
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
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.globalCatalogReviewQueueTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.sterilizationMethodsTabTitle),
              Tab(text: l10n.technicalInfoTabTitle),
              Tab(text: l10n.catalogContentReportsTabTitle),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GlobalMethodReviewQueue(),
            _GlobalTechnicalInfoReviewQueue(),
            _CatalogContentReportsQueue(),
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

/// Cola de reportes de error de contenido (schema_v39). Más simple que las
/// dos colas de arriba: no hay versión/diff que comparar, solo "esto está
/// mal" (descripción libre) + resolver, mismo patrón que
/// `_buildIncidentCard`/`_openResolveIncidentDialog` de
/// [InstrumentDetailScreen] pero a nivel de catálogo global en vez de por
/// instrumento.
class _CatalogContentReportsQueue extends StatefulWidget {
  const _CatalogContentReportsQueue();

  @override
  State<_CatalogContentReportsQueue> createState() => _CatalogContentReportsQueueState();
}

class _CatalogContentReportsQueueState extends State<_CatalogContentReportsQueue> {
  bool _loading = true;
  String? _error;
  List<CatalogContentReport> _reports = [];
  Map<String, String> _instrumentNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reports = await CatalogContentReportService.instance.fetchOpenQueue();
      final names = await resolveInstrumentNames(reports.map((r) => SterilizationHeaderInfo(
            id: r.id ?? '',
            organizationId: null,
            instrumentRefType: r.instrumentRefType,
            instrumentRefId: r.instrumentRefId,
            workspaceName: null,
          )));
      if (!mounted) return;
      setState(() {
        _reports = reports;
        _instrumentNames = names;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openResolveDialog(CatalogContentReport report) async {
    final l10n = AppLocalizations.of(context)!;
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resolveContentReportDialogTitle),
        content: TextField(
          controller: notesController,
          autofocus: true,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l10n.resolutionNotesLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.resolveContentReportAction)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final notes = notesController.text.trim();
      await CatalogContentReportService.instance.resolve(report.id!, resolutionNotes: notes.isEmpty ? null : notes);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.reviewQueueLoadError(_error!)),
              const SizedBox(height: 12),
              OutlinedButton(onPressed: _load, child: Text(l10n.retry)),
            ],
          ),
        ),
      );
    }
    if (_reports.isEmpty) {
      return Center(
          child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.catalogContentReportsEmptyState)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        final name = _instrumentNames[report.instrumentRefId] ?? report.instrumentRefId;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(report.description, style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => _openResolveDialog(report),
                    child: Text(l10n.resolveContentReportAction),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
