import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design_system/components/instriq_badge.dart';
import '../l10n/app_localizations.dart';
import '../models/catalog_community_photo.dart';
import '../models/group_document.dart';
import '../models/group_document_version.dart' show GroupDocumentVersionStatus;
import '../models/instrument.dart';
import '../models/instrument_incident.dart';
import '../models/instrument_sterilization.dart';
import '../models/manufacturer.dart';
import '../models/reference_document.dart';
import '../models/tag.dart';
import '../models/tray.dart';
import '../models/work_mode.dart';
import '../services/auth_service.dart';
import '../services/catalog_community_photo_service.dart';
import '../services/connectivity_service.dart';
import '../services/favorites_service.dart';
import '../services/group_document_service.dart';
import '../services/instrument_incident_service.dart';
import '../services/knowledge_link_service.dart';
import '../services/manufacturer_service.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import '../services/recent_activity_service.dart';
import '../services/reference_document_service.dart';
import '../services/sterilization_service.dart';
import '../services/tag_service.dart';
import '../services/tray_service.dart';
import '../services/usage_analytics_service.dart';
import '../widgets/category_icon.dart';
import '../widgets/instrument_incident_label.dart';
import '../widgets/offline_banner.dart';
import '../widgets/sterilization_method_label.dart';
import '../widgets/tag_picker.dart';
import 'group_document_detail_screen.dart';
import 'manufacturer_detail_screen.dart';
import 'review_session_screen.dart';
import 'sterilization_method_version_history_screen.dart';
import 'tag_detail_screen.dart';
import 'technical_info_version_history_screen.dart';
import 'tray_detail_screen.dart';

class InstrumentDetailScreen extends StatefulWidget {
  final Instrument instrument;

  const InstrumentDetailScreen({super.key, required this.instrument});

  @override
  State<InstrumentDetailScreen> createState() => _InstrumentDetailScreenState();
}

class _InstrumentDetailScreenState extends State<InstrumentDetailScreen> {
  static const String _refType = 'catalog';

  bool _loadingClinicalData = true;
  List<SterilizationMethodEntry> _methods = [];
  InstrumentTechnicalInfo? _technicalInfo;
  Manufacturer? _manufacturer;
  ReferenceDocument? _ifuDocument;
  List<Tag> _tags = [];
  List<GroupDocument> _usedInDocuments = [];
  List<Tray> _usedInTrays = [];

  /// Borrador/en revisión propio más reciente entre todos los métodos de
  /// esterilización del instrumento, si hay alguno -- mismo patrón que
  /// `_ownPendingDraft` de [TrayDetailScreen], adaptado a que aquí puede haber
  /// varias cabeceras en vez de una sola.
  SterilizationMethodVersion? _ownPendingMethodDraft;
  InstrumentTechnicalInfoVersion? _ownPendingInfoDraft;

  bool _loadingCommunityPhoto = true;
  CatalogCommunityPhoto? _approvedCommunityPhoto;
  CatalogCommunityPhoto? _ownPendingPhoto;

  bool _loadingIncidents = true;
  List<InstrumentIncident> _incidents = [];

  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadClinicalData();
    _loadIncidents();
    if (widget.instrument.image == null) {
      _loadCommunityPhotoState();
    } else {
      _loadingCommunityPhoto = false;
    }
    if (AuthService.instance.currentUser != null) {
      // Fire-and-forget: no debe bloquear ni fallar visiblemente si el
      // usuario es invitado o la RLS lo deniega (ver FavoritesService).
      RecentActivityService.instance.recordView(_refType, widget.instrument.id);
      UsageAnalyticsService.instance.recordView(_refType, widget.instrument.id);
      _loadFavoriteState();
    }
  }

  Future<void> _loadFavoriteState() async {
    final isFavorite = await FavoritesService.instance.isFavorite(_refType, widget.instrument.id);
    if (!mounted) return;
    setState(() => _isFavorite = isFavorite);
  }

  Future<void> _toggleFavorite() async {
    await FavoritesService.instance.toggleFavorite(_refType, widget.instrument.id);
    if (!mounted) return;
    setState(() => _isFavorite = !_isFavorite);
  }

  Future<void> _loadCommunityPhotoState() async {
    try {
      final approved =
          await CatalogCommunityPhotoService.instance.fetchApprovedPhoto(_refType, widget.instrument.id);
      final ownPending =
          await CatalogCommunityPhotoService.instance.fetchOwnPendingPhoto(_refType, widget.instrument.id);
      if (!mounted) return;
      setState(() {
        _approvedCommunityPhoto = approved;
        _ownPendingPhoto = ownPending;
        _loadingCommunityPhoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingCommunityPhoto = false);
    }
  }

  Future<void> _openUploadCommunityPhotoSheet() async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _CommunityPhotoUploadSheet(
        refType: _refType,
        refId: widget.instrument.id,
      ),
    );
    if (submitted == true) {
      setState(() => _loadingCommunityPhoto = true);
      await _loadCommunityPhotoState();
    }
  }

  Future<void> _loadClinicalData() async {
    try {
      final methods = await SterilizationService.instance.fetchMethods(_refType, widget.instrument.id);
      final technicalInfo =
          await SterilizationService.instance.fetchTechnicalInfo(_refType, widget.instrument.id);
      Manufacturer? manufacturer;
      final manufacturerId = technicalInfo?.publishedVersion?.manufacturerId;
      if (manufacturerId != null) {
        final all = await ManufacturerService.instance.fetchAll();
        for (final m in all) {
          if (m.id == manufacturerId) {
            manufacturer = m;
            break;
          }
        }
      }
      ReferenceDocument? ifuDocument;
      final ifuDocumentId = technicalInfo?.publishedVersion?.ifuDocumentId;
      if (ifuDocumentId != null) {
        ifuDocument = await ReferenceDocumentService.instance.fetchById(ifuDocumentId);
      }
      final tags = await TagService.instance.fetchTagsFor(_refType, widget.instrument.id);
      final usedInDocuments = <GroupDocument>[];
      final usedInTrays = <Tray>[];
      try {
        final links = await KnowledgeLinkService.instance.fetchRelatedTo(_refType, widget.instrument.id);
        for (final link in links) {
          if (link.fromType == 'group_document') {
            try {
              usedInDocuments.add(await GroupDocumentService.instance.fetchDocument(link.fromId));
            } catch (_) {
              // Enlace obsoleto (documento borrado sin limpiar a tiempo): se omite.
            }
          } else if (link.fromType == 'tray') {
            try {
              usedInTrays.add(await TrayService.instance.fetchTray(link.fromId));
            } catch (_) {
              // Enlace obsoleto (safata borrada sin limpiar a tiempo): se omite.
            }
          }
        }
      } catch (_) {
        // Grafo de conocimiento es metadato accesorio: no bloquea el resto de la ficha.
      }

      // Borrador/en revisión propio pendiente: mismo criterio que
      // `_ownPendingDraft` de [TrayDetailScreen], pero mirando todas las
      // cabeceras de método (puede haber varias por instrumento) más la
      // ficha técnica (una sola). No bloquea el resto de la ficha si falla.
      SterilizationMethodVersion? ownPendingMethodDraft;
      InstrumentTechnicalInfoVersion? ownPendingInfoDraft;
      final userId = AuthService.instance.currentUser?.id;
      if (userId != null) {
        for (final method in methods) {
          final methodId = method.id;
          if (methodId == null) continue;
          try {
            final versions = await SterilizationService.instance.fetchMethodVersionHistory(methodId);
            final mine = versions.where(
              (v) =>
                  v.authorId == userId &&
                  (v.status == GroupDocumentVersionStatus.draft || v.status == GroupDocumentVersionStatus.inReview),
            );
            if (mine.isNotEmpty) {
              ownPendingMethodDraft = mine.first;
              break;
            }
          } catch (_) {
            // Metadato accesorio: no bloquea el resto de la ficha.
          }
        }
        final infoId = technicalInfo?.id;
        if (infoId != null) {
          try {
            final versions = await SterilizationService.instance.fetchTechnicalInfoVersionHistory(infoId);
            final mine = versions.where(
              (v) =>
                  v.authorId == userId &&
                  (v.status == GroupDocumentVersionStatus.draft || v.status == GroupDocumentVersionStatus.inReview),
            );
            if (mine.isNotEmpty) ownPendingInfoDraft = mine.first;
          } catch (_) {
            // Metadato accesorio: no bloquea el resto de la ficha.
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _methods = methods;
        _technicalInfo = technicalInfo;
        _manufacturer = manufacturer;
        _ifuDocument = ifuDocument;
        _tags = tags;
        _usedInDocuments = usedInDocuments;
        _usedInTrays = usedInTrays;
        _ownPendingMethodDraft = ownPendingMethodDraft;
        _ownPendingInfoDraft = ownPendingInfoDraft;
        _loadingClinicalData = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingClinicalData = false);
    }
  }

  Future<void> _loadIncidents() async {
    try {
      final incidents = await InstrumentIncidentService.instance.fetchForInstrument(_refType, widget.instrument.id);
      if (!mounted) return;
      setState(() {
        _incidents = incidents;
        _loadingIncidents = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingIncidents = false);
    }
  }

  Future<void> _openEditClinicalDataSheet() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ClinicalDataFormSheet(
        instrument: widget.instrument,
        methods: _methods,
        technicalInfo: _technicalInfo,
      ),
    );
    if (saved == true) {
      setState(() => _loadingClinicalData = true);
      await _loadClinicalData();
    }
  }

  Future<void> _openMethodHistory(SterilizationMethodEntry method) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SterilizationMethodVersionHistoryScreen(
          method: method,
          canRestore: ProfileService.instance.isAdmin,
        ),
      ),
    );
    await _loadClinicalData();
  }

  Future<void> _openTechnicalInfoHistory(InstrumentTechnicalInfo info) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TechnicalInfoVersionHistoryScreen(
          info: info,
          canRestore: ProfileService.instance.isAdmin,
        ),
      ),
    );
    await _loadClinicalData();
  }

  Future<void> _openReportIncidentDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final descriptionController = TextEditingController();
    IncidentSeverity severity = IncidentSeverity.low;
    final reported = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.reportIncidentDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: descriptionController,
                autofocus: true,
                maxLines: 3,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.incidentDescriptionLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.incidentSeverityLabel, style: Theme.of(ctx).textTheme.labelMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: IncidentSeverity.values
                    .map((s) => ChoiceChip(
                          label: Text(incidentSeverityValueLabel(l10n, s)),
                          selected: severity == s,
                          onSelected: (_) => setDialogState(() => severity = s),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: descriptionController.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: Text(l10n.reportIncidentAction),
            ),
          ],
        ),
      ),
    );
    if (reported != true || !mounted) return;
    final description = descriptionController.text.trim();
    if (description.isEmpty) return;
    try {
      await InstrumentIncidentService.instance.report(
        refType: _refType,
        refId: widget.instrument.id,
        severity: severity,
        description: description,
      );
      if (mounted) {
        setState(() => _loadingIncidents = true);
        await _loadIncidents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
      }
    }
  }

  Future<void> _openResolveIncidentDialog(InstrumentIncident incident) async {
    final l10n = AppLocalizations.of(context)!;
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.resolveIncidentDialogTitle),
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
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.resolveIncidentAction)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      final notes = notesController.text.trim();
      await InstrumentIncidentService.instance.resolve(incident.id!, resolutionNotes: notes.isEmpty ? null : notes);
      if (mounted) {
        setState(() => _loadingIncidents = true);
        await _loadIncidents();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final instrument = widget.instrument;

    final builders = <String, Widget Function(BuildContext)>{
      'photo': _buildPhotoSection,
      'specialty': _buildSpecialtySection,
      'aliases': (context) => _buildAliasesSection(context, l10n),
      'description': (context) => _buildDescriptionSection(context, l10n),
      'use': (context) => _buildUseSection(context, l10n),
      'tip': _buildTipSection,
      'sterilization': (context) => _buildSterilizationSection(context, l10n),
      'technical': (context) => _buildTechnicalSection(context, l10n),
      'usedIn': (context) => _buildUsedInSection(context, l10n),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(instrument.name),
        actions: [
          if (AuthService.instance.currentUser != null)
            IconButton(
              icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
              tooltip: l10n.favoriteToggleTooltip,
              onPressed: _toggleFavorite,
            ),
          if (ProfileService.instance.isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: l10n.editClinicalDataTooltip,
              onPressed: _openEditClinicalDataSheet,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_ownPendingMethodDraft != null || _ownPendingInfoDraft != null) ...[
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: ListTile(
                  leading: const Icon(Icons.pending_actions),
                  title: Text(
                    (_ownPendingMethodDraft?.status == GroupDocumentVersionStatus.inReview ||
                            _ownPendingInfoDraft?.status == GroupDocumentVersionStatus.inReview)
                        ? l10n.pendingReviewTitle
                        : l10n.pendingDraftTitle,
                  ),
                  subtitle: Text(l10n.pendingDraftSubtitle),
                  trailing: (_ownPendingMethodDraft?.pendingSync == true || _ownPendingInfoDraft?.pendingSync == true)
                      ? const PendingSyncChip()
                      : null,
                  onTap: _openEditClinicalDataSheet,
                ),
              ),
              const SizedBox(height: 16),
            ],
            // Reactivo al ValueNotifier: si el usuario cambia de modo de
            // trabajo desde la capçalera mientras tiene esta ficha abierta,
            // el orden de secciones se reordena a l'instant.
            ValueListenableBuilder<WorkMode?>(
              valueListenable: ProfileService.instance.activeWorkModeNotifier,
              builder: (context, mode, _) {
                final order = sectionPriorityOrder(mode);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final key in order) builders[key]!(context),
                  ],
                );
              },
            ),
            _buildIncidentsSection(context, l10n),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: Icon(
                  ProgressService.instance.isLearned(instrument.id)
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                ),
                label: Text(
                  ProgressService.instance.isLearned(instrument.id) ? l10n.learned : l10n.markAsLearned,
                ),
                onPressed: () async {
                  await ProgressService.instance.toggleLearned(instrument.id);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.replay),
                label: Text(l10n.startReviewSessionAction),
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ReviewSessionScreen(instrument: instrument),
                    ),
                  );
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final instrument = widget.instrument;

    if (instrument.image != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                instrument.image!.url,
                height: 200,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: InstrumentIcon(iconKey: instrument.icon, category: instrument.category, size: 120),
                    ),
                  );
                },
                errorBuilder: (context, error, stack) =>
                    InstrumentIcon(iconKey: instrument.icon, category: instrument.category, size: 120),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: GestureDetector(
              onTap: () => launchUrl(Uri.parse(instrument.image!.sourceUrl)),
              child: Text(
                l10n.photoAttribution(instrument.image!.attribution, instrument.image!.license),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
    }

    if (_loadingCommunityPhoto) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final approved = _approvedCommunityPhoto;
    if (approved != null) {
      final creditName =
          (approved.creditName == null || approved.creditName!.trim().isEmpty)
              ? l10n.communityPhotoDefaultCredit
              : approved.creditName!;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                CatalogCommunityPhotoService.instance.getPublicUrl(approved.photoPath),
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stack) =>
                    InstrumentIcon(iconKey: instrument.icon, category: instrument.category, size: 120),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              l10n.communityPhotoCreditLabel(creditName),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: InstrumentIcon(iconKey: instrument.icon, category: instrument.category, size: 120),
        ),
        if (AuthService.instance.currentUser != null) ...[
          const SizedBox(height: 10),
          Center(
            child: _ownPendingPhoto != null
                ? Text(
                    l10n.communityPhotoAlreadyPending,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  )
                : OutlinedButton.icon(
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: Text(l10n.uploadPhotoButtonLabel),
                    onPressed: _openUploadCommunityPhotoSheet,
                  ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSpecialtySection(BuildContext context) {
    final instrument = widget.instrument;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        children: [
          Chip(label: Text(instrument.specialty.label)),
          Chip(label: Text(instrument.category.label)),
        ],
      ),
    );
  }

  Widget _buildAliasesSection(BuildContext context, AppLocalizations l10n) {
    final instrument = widget.instrument;
    if (instrument.aliases.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.alsoKnownAs, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(instrument.aliases.join(', ')),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context, AppLocalizations l10n) {
    final instrument = widget.instrument;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.descriptionLabel, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(instrument.description.forLanguageCode(languageCode), style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildUseSection(BuildContext context, AppLocalizations l10n) {
    final instrument = widget.instrument;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.mainUseLabel, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(instrument.use.forLanguageCode(languageCode), style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildTipSection(BuildContext context) {
    final instrument = widget.instrument;
    if (instrument.tip == null) return const SizedBox.shrink();
    final languageCode = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline),
              const SizedBox(width: 8),
              Expanded(child: Text(instrument.tip!.forLanguageCode(languageCode))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSterilizationSection(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.sterilizationSectionTitle, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          if (_loadingClinicalData)
            const Center(child: CircularProgressIndicator())
          else if (_methods.isEmpty)
            Text(l10n.sterilizationEmptyState, style: Theme.of(context).textTheme.bodyMedium)
          else
            ..._methods.map((method) => _buildMethodCard(context, l10n, method)),
        ],
      ),
    );
  }

  Widget _buildMethodCard(BuildContext context, AppLocalizations l10n, SterilizationMethodEntry method) {
    final published = method.publishedVersion;
    final details = <String>[
      if (published?.temperature != null && published!.temperature!.isNotEmpty)
        '${l10n.sterilizationTemperatureLabel}: ${published.temperature}',
      if (published?.timeMinutes != null && published!.timeMinutes!.isNotEmpty)
        '${l10n.sterilizationTimeLabel}: ${published.timeMinutes}',
      if (published?.pressure != null && published!.pressure!.isNotEmpty)
        '${l10n.sterilizationPressureLabel}: ${published.pressure}',
      if (published?.drying != null && published!.drying!.isNotEmpty)
        '${l10n.sterilizationDryingLabel}: ${published.drying}',
      if (published?.recommendedCycle != null && published!.recommendedCycle!.isNotEmpty)
        '${l10n.sterilizationRecommendedCycleLabel}: ${published.recommendedCycle}',
      if (published?.compatibilityNotes != null && published!.compatibilityNotes!.isNotEmpty)
        '${l10n.sterilizationCompatibilityLabel}: ${published.compatibilityNotes}',
      if (published?.restrictions != null && published!.restrictions!.isNotEmpty)
        '${l10n.sterilizationRestrictionsLabel}: ${published.restrictions}',
      if (published?.observations != null && published!.observations!.isNotEmpty)
        '${l10n.sterilizationObservationsLabel}: ${sterilizationObservationsText(l10n, published.observations!)}',
      if (published?.lubricationRequired == true) ...[
        if (published?.lubricationType != null && published!.lubricationType!.isNotEmpty)
          '${l10n.lubricationTypeLabel}: ${published.lubricationType}',
        if (published?.lubricationNotes != null && published!.lubricationNotes!.isNotEmpty)
          '${l10n.lubricationNotesLabel}: ${published.lubricationNotes}',
      ],
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    published != null
                        ? sterilizationMethodValueLabel(l10n, published.method)
                        : l10n.sterilizationUnpublishedMethodLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.history, size: 20),
                  tooltip: l10n.historyTooltip,
                  onPressed: () => _openMethodHistory(method),
                ),
              ],
            ),
            for (final line in details) ...[
              const SizedBox(height: 4),
              Text(line, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Widget _buildTechnicalSection(BuildContext context, AppLocalizations l10n) {
    final info = _technicalInfo;
    final published = info?.publishedVersion;
    final lines = <String>[
      if (published?.maintenanceNotes != null && published!.maintenanceNotes!.isNotEmpty)
        '${l10n.technicalMaintenanceLabel}: ${published.maintenanceNotes}',
      if (published?.inspectionNotes != null && published!.inspectionNotes!.isNotEmpty)
        '${l10n.technicalInspectionLabel}: ${published.inspectionNotes}',
      if (published?.usefulLifeNotes != null && published!.usefulLifeNotes!.isNotEmpty)
        '${l10n.technicalUsefulLifeLabel}: ${published.usefulLifeNotes}',
      if (published?.maintenanceIntervalDays != null)
        '${l10n.technicalMaintenanceIntervalLabel}: ${published!.maintenanceIntervalDays}',
      if (published?.lastMaintenanceAt != null)
        '${l10n.technicalLastMaintenanceLabel}: ${_formatShortDate(published!.lastMaintenanceAt!)}',
    ];
    final manufacturer = _manufacturer;
    final ifuDocument = _ifuDocument;
    final hasAnything = lines.isNotEmpty || manufacturer != null || ifuDocument != null || _tags.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.technicalInfoSectionTitle, style: Theme.of(context).textTheme.labelLarge),
              ),
              if (info != null)
                IconButton(
                  icon: const Icon(Icons.history, size: 20),
                  tooltip: l10n.historyTooltip,
                  onPressed: () => _openTechnicalInfoHistory(info),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingClinicalData)
            const Center(child: CircularProgressIndicator())
          else if (!hasAnything)
            Text(l10n.technicalInfoEmptyState, style: Theme.of(context).textTheme.bodyMedium)
          else ...[
            if (manufacturer != null) ...[
              InputChip(
                avatar: const Icon(Icons.precision_manufacturing_outlined, size: 18),
                label: Text('${l10n.technicalManufacturerLabel}: ${manufacturer.name}'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ManufacturerDetailScreen(manufacturer: manufacturer)),
                ),
              ),
              const SizedBox(height: 8),
            ],
            for (final line in lines) ...[
              Text(line, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
            ],
            if (ifuDocument != null)
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(ifuDocument.url)),
                child: Text(
                  '${l10n.technicalIfuLabel}: ${ifuDocument.title}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(decoration: TextDecoration.underline),
                ),
              ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _tags
                    .map((tag) => InputChip(
                          label: Text(tag.name),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => TagDetailScreen(tag: tag)),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Relación inversa del grafo de conocimiento (EPIC 1): técnicas/protocolos
  /// y safates que enlazan a este instrumento, resuelta a partir de
  /// `knowledge_links` (ver supabase/schema_v24_knowledge_links.sql).
  Widget _buildUsedInSection(BuildContext context, AppLocalizations l10n) {
    final hasAnything = _usedInDocuments.isNotEmpty || _usedInTrays.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.knowledgeGraphUsedInTitle, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          if (_loadingClinicalData)
            const Center(child: CircularProgressIndicator())
          else if (!hasAnything)
            Text(l10n.knowledgeGraphUsedInEmptyState, style: Theme.of(context).textTheme.bodyMedium)
          else ...[
            ..._usedInDocuments.map((doc) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: Text(doc.publishedVersion?.title ?? doc.id),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => GroupDocumentDetailScreen(document: doc, myRole: null)),
                    ),
                  ),
                )),
            ..._usedInTrays.map((tray) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: Text(tray.publishedVersion?.name ?? tray.id),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => TrayDetailScreen(tray: tray, myRole: null)),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  /// Incidencias operativas del instrumento (EPIC 3 · CSSD Workspace): sin
  /// versionado, cualquier miembro autenticado de la organización puede
  /// reportar una, resolverla exige el mismo rol que el resto de acciones
  /// sensibles de esta ficha (ver [ProfileService.isAdmin] en el botón de
  /// editar esterilización/ficha técnica del AppBar) -- la RLS de
  /// `instrument_incidents` es la autoridad real, esto solo evita mostrar un
  /// botón que la base de datos rechazaría.
  Widget _buildIncidentsSection(BuildContext context, AppLocalizations l10n) {
    final canReport = AuthService.instance.currentUser != null && ProfileService.instance.organizationId != null;
    final canResolve = ProfileService.instance.isAdmin;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(l10n.incidentsSectionTitle, style: Theme.of(context).textTheme.labelLarge),
              ),
              if (canReport)
                TextButton.icon(
                  onPressed: _openReportIncidentDialog,
                  icon: const Icon(Icons.report_gmailerrorred_outlined, size: 18),
                  label: Text(l10n.reportIncidentAction),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingIncidents)
            const Center(child: CircularProgressIndicator())
          else if (_incidents.isEmpty)
            Text(l10n.incidentsEmptyState, style: Theme.of(context).textTheme.bodyMedium)
          else
            ..._incidents.map((incident) => _buildIncidentCard(context, l10n, incident, canResolve)),
        ],
      ),
    );
  }

  Widget _buildIncidentCard(
    BuildContext context,
    AppLocalizations l10n,
    InstrumentIncident incident,
    bool canResolve,
  ) {
    final severityColor = switch (incident.severity) {
      IncidentSeverity.low => Colors.green,
      IncidentSeverity.medium => Colors.orange,
      IncidentSeverity.high => Colors.red,
    };
    final statusColor =
        incident.status == IncidentStatus.open ? Theme.of(context).colorScheme.error : Colors.green;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                InstriqBadge(label: incidentSeverityValueLabel(l10n, incident.severity), color: severityColor),
                InstriqBadge(label: incidentStatusValueLabel(l10n, incident.status), color: statusColor),
                if (incident.createdAt != null)
                  Text(_formatShortDate(incident.createdAt!), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 6),
            Text(incident.description, style: Theme.of(context).textTheme.bodyMedium),
            if (incident.resolutionNotes != null && incident.resolutionNotes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '${l10n.resolutionNotesLabel}: ${incident.resolutionNotes}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (canResolve && incident.status == IncidentStatus.open) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _openResolveIncidentDialog(incident),
                  child: Text(l10n.resolveIncidentAction),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Formulario de esterilización/ficha técnica de un instrumento del catálogo
/// global. Solo visible para admins (ver botón en el AppBar de
/// [InstrumentDetailScreen]). A diferencia de la versión anterior (escritura
/// directa), cada método de esterilización y la ficha técnica son ahora
/// pares cabecera+versiones (ver supabase/schema_v32_cssd_workspace.sql):
/// este sheet nunca edita la versión publicada directamente, siempre pide-o-
/// crea el borrador propio (`startEditingMethod`/`startEditingTechnicalInfo`,
/// mismo patrón que [PreferenceCardService.startEditing]) y separa "Desa com
/// a esborrany" de "Envia a revisió" (mismo patrón `_saveDraft({bool
/// andSubmit})` que [TrayFormScreen]).
class _ClinicalDataFormSheet extends StatefulWidget {
  final Instrument instrument;
  final List<SterilizationMethodEntry> methods;
  final InstrumentTechnicalInfo? technicalInfo;

  const _ClinicalDataFormSheet({
    required this.instrument,
    required this.methods,
    required this.technicalInfo,
  });

  @override
  State<_ClinicalDataFormSheet> createState() => _ClinicalDataFormSheetState();
}

class _ClinicalDataFormSheetState extends State<_ClinicalDataFormSheet> {
  static const String _refType = 'catalog';

  // Copia local mutable: al crear una cabecera de método nueva se añade aquí
  // para que el selector de chips la vea sin recargar todo el sheet desde
  // el padre.
  late List<SterilizationMethodEntry> _methods;

  // `null` significa "nueva fila" (se creará al guardar vía
  // `createSterilizationMethod`); si no, es el `id` de una de `_methods` que
  // se está editando. Ver bug independent 6 del plan de refactor original:
  // antes el sheet solo leía/escribía `methods.first`, dejando invisibles el
  // resto de filas cuando un instrumento tenía 2+ métodos registrados.
  String? _selectedMethodId;
  SterilizationMethodVersion? _methodDraft;
  bool _loadingMethodDraft = false;

  SterilizationMethod _method = SterilizationMethod.vapor;
  late final TextEditingController _temperatureController;
  late final TextEditingController _timeController;
  late final TextEditingController _pressureController;
  late final TextEditingController _dryingController;
  late final TextEditingController _cycleController;
  late final TextEditingController _compatibilityController;
  late final TextEditingController _restrictionsController;
  late final TextEditingController _observationsController;
  bool _lubricationRequired = false;
  late final TextEditingController _lubricationTypeController;
  late final TextEditingController _lubricationNotesController;
  late final TextEditingController _methodCommentController;

  InstrumentTechnicalInfoVersion? _infoDraft;
  bool _loadingInfoDraft = false;

  // Texto libre "espejo" del campo de autocompletar de fabricante — mismo
  // patrón que `preference_card_form_screen.dart` para el cirujano.
  final TextEditingController _manufacturerFieldController = TextEditingController();
  String? _selectedManufacturerId;
  late final TextEditingController _ifuTitleController;
  late final TextEditingController _ifuUrlController;
  late final TextEditingController _maintenanceController;
  late final TextEditingController _inspectionController;
  late final TextEditingController _usefulLifeController;
  late final TextEditingController _maintenanceIntervalController;
  DateTime? _lastMaintenanceAt;
  late final TextEditingController _infoCommentController;

  final _tagPickerKey = GlobalKey<TagPickerState>();

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _methods = List.of(widget.methods);

    _temperatureController = TextEditingController();
    _timeController = TextEditingController();
    _pressureController = TextEditingController();
    _dryingController = TextEditingController();
    _cycleController = TextEditingController();
    _compatibilityController = TextEditingController();
    _restrictionsController = TextEditingController();
    _observationsController = TextEditingController();
    _lubricationTypeController = TextEditingController();
    _lubricationNotesController = TextEditingController();
    _methodCommentController = TextEditingController();

    _ifuTitleController = TextEditingController();
    _ifuUrlController = TextEditingController();
    _maintenanceController = TextEditingController();
    _inspectionController = TextEditingController();
    _usefulLifeController = TextEditingController();
    _maintenanceIntervalController = TextEditingController();
    _infoCommentController = TextEditingController();

    final firstMethod = _methods.isNotEmpty ? _methods.first : null;
    _selectedMethodId = firstMethod?.id;
    _loadMethodDraft(firstMethod?.id);
    _loadInfoDraft();
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _timeController.dispose();
    _pressureController.dispose();
    _dryingController.dispose();
    _cycleController.dispose();
    _compatibilityController.dispose();
    _restrictionsController.dispose();
    _observationsController.dispose();
    _lubricationTypeController.dispose();
    _lubricationNotesController.dispose();
    _methodCommentController.dispose();
    _manufacturerFieldController.dispose();
    _ifuTitleController.dispose();
    _ifuUrlController.dispose();
    _maintenanceController.dispose();
    _inspectionController.dispose();
    _usefulLifeController.dispose();
    _maintenanceIntervalController.dispose();
    _infoCommentController.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String value) => value.trim().isEmpty ? null : value.trim();

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  void _applyMethodFields(SterilizationMethodVersion? draft) {
    _method = draft?.method ?? SterilizationMethod.vapor;
    _temperatureController.text = draft?.temperature ?? '';
    _timeController.text = draft?.timeMinutes ?? '';
    _pressureController.text = draft?.pressure ?? '';
    _dryingController.text = draft?.drying ?? '';
    _cycleController.text = draft?.recommendedCycle ?? '';
    _compatibilityController.text = draft?.compatibilityNotes ?? '';
    _restrictionsController.text = draft?.restrictions ?? '';
    _observationsController.text = draft?.observations ?? '';
    _lubricationRequired = draft?.lubricationRequired ?? false;
    _lubricationTypeController.text = draft?.lubricationType ?? '';
    _lubricationNotesController.text = draft?.lubricationNotes ?? '';
    _methodCommentController.text = '';
  }

  /// Cambia qué cabecera de `_methods` se está editando (o pasa a "nueva
  /// fila" si [headerId] es `null`): pide-o-crea el borrador propio del
  /// método seleccionado -- nunca se edita la versión publicada directamente.
  Future<void> _loadMethodDraft(String? headerId) async {
    setState(() {
      _selectedMethodId = headerId;
      _loadingMethodDraft = true;
    });
    try {
      if (headerId == null) {
        _methodDraft = null;
        _applyMethodFields(null);
      } else {
        final draft = await SterilizationService.instance.startEditingMethod(headerId);
        _methodDraft = draft;
        _applyMethodFields(draft);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loadingMethodDraft = false);
    }
  }

  Future<void> _loadInfoDraft() async {
    setState(() => _loadingInfoDraft = true);
    try {
      // Fetch auxiliar para el autocompletar de fabricante -- se aísla en su
      // propio try/catch (mismo criterio que TrayFormScreen._init) para que
      // un fallo de red aquí NO tumbe la carga del borrador real de más
      // abajo, que sí es la llamada que importa. Sin red se sigue con lo que
      // ya hubiera en memoria (o vacío si es la primera carga de la sesión).
      try {
        await ManufacturerService.instance.fetchAll();
      } catch (e) {
        if (!ConnectivityService.isNetworkError(e)) rethrow;
      }
      final infoId = widget.technicalInfo?.id;
      final draft =
          infoId == null ? null : await SterilizationService.instance.startEditingTechnicalInfo(infoId);
      _infoDraft = draft;
      _selectedManufacturerId = draft?.manufacturerId;
      final manufacturerId = draft?.manufacturerId;
      if (manufacturerId != null) {
        final existing = ManufacturerService.instance.byId(manufacturerId);
        if (existing != null) _manufacturerFieldController.text = existing.name;
      }
      final ifuDocumentId = draft?.ifuDocumentId;
      if (ifuDocumentId != null) {
        // Otro fetch auxiliar (título/URL de la IFU para rellenar el
        // formulario) -- ReferenceDocumentService no cachea nada en memoria,
        // así que sin red simplemente se deja el campo vacío en vez de
        // abortar la carga del resto del borrador.
        try {
          final doc = await ReferenceDocumentService.instance.fetchById(ifuDocumentId);
          if (doc != null) {
            _ifuTitleController.text = doc.title;
            _ifuUrlController.text = doc.url;
          }
        } catch (e) {
          if (!ConnectivityService.isNetworkError(e)) rethrow;
        }
      }
      _maintenanceController.text = draft?.maintenanceNotes ?? '';
      _inspectionController.text = draft?.inspectionNotes ?? '';
      _usefulLifeController.text = draft?.usefulLifeNotes ?? '';
      _maintenanceIntervalController.text = draft?.maintenanceIntervalDays?.toString() ?? '';
      _lastMaintenanceAt = draft?.lastMaintenanceAt;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loadingInfoDraft = false);
    }
  }

  Future<void> _pickLastMaintenanceDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastMaintenanceAt ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) setState(() => _lastMaintenanceAt = picked);
  }

  /// Crea la cabecera (si `_methodDraft` es `null`, o sea "nueva fila") o
  /// actualiza el borrador existente con los valores actuales del formulario.
  /// Devuelve la versión guardada, para poder encadenar el envío a revisión.
  Future<SterilizationMethodVersion> _persistMethodDraft() async {
    var draft = _methodDraft;
    draft ??= await SterilizationService.instance.createSterilizationMethod(
      refType: _refType,
      refId: widget.instrument.id,
      method: _method,
    );

    final temperature = _nullIfEmpty(_temperatureController.text);
    final timeMinutes = _nullIfEmpty(_timeController.text);
    final pressure = _nullIfEmpty(_pressureController.text);
    final drying = _nullIfEmpty(_dryingController.text);
    final recommendedCycle = _nullIfEmpty(_cycleController.text);
    final compatibilityNotes = _nullIfEmpty(_compatibilityController.text);
    final restrictions = _nullIfEmpty(_restrictionsController.text);
    final observations = _nullIfEmpty(_observationsController.text);
    final lubricationType = _nullIfEmpty(_lubricationTypeController.text);
    final lubricationNotes = _nullIfEmpty(_lubricationNotesController.text);

    final updated = draft.copyWith(
      method: _method,
      temperature: temperature,
      clearTemperature: temperature == null,
      timeMinutes: timeMinutes,
      clearTimeMinutes: timeMinutes == null,
      pressure: pressure,
      clearPressure: pressure == null,
      drying: drying,
      clearDrying: drying == null,
      recommendedCycle: recommendedCycle,
      clearRecommendedCycle: recommendedCycle == null,
      compatibilityNotes: compatibilityNotes,
      clearCompatibilityNotes: compatibilityNotes == null,
      restrictions: restrictions,
      clearRestrictions: restrictions == null,
      observations: observations,
      clearObservations: observations == null,
      lubricationRequired: _lubricationRequired,
      lubricationType: lubricationType,
      clearLubricationType: lubricationType == null,
      lubricationNotes: lubricationNotes,
      clearLubricationNotes: lubricationNotes == null,
      comment: _nullIfEmpty(_methodCommentController.text),
    );
    final saved = await SterilizationService.instance.saveMethodDraft(updated);
    _methodDraft = saved;
    _selectedMethodId = saved.methodId;
    if (!_methods.any((m) => m.id == saved.methodId)) {
      _methods = [
        ..._methods,
        SterilizationMethodEntry(
          id: saved.methodId,
          instrumentRefType: _refType,
          instrumentRefId: widget.instrument.id,
        ),
      ];
    }
    return saved;
  }

  /// Ver [_persistMethodDraft] -- mismo criterio, entidad distinta (la ficha
  /// técnica es una cabecera única por instrumento, no una lista).
  Future<InstrumentTechnicalInfoVersion> _persistInfoDraft() async {
    var draft = _infoDraft;
    draft ??= await SterilizationService.instance.createTechnicalInfo(
      refType: _refType,
      refId: widget.instrument.id,
    );

    final manufacturerName = _manufacturerFieldController.text.trim();
    String? manufacturerId = draft.manufacturerId;
    if (manufacturerName.isNotEmpty) {
      final cached =
          _selectedManufacturerId == null ? null : ManufacturerService.instance.byId(_selectedManufacturerId!);
      if (cached != null && cached.name == manufacturerName) {
        manufacturerId = cached.id;
      } else {
        // Dar de alta un fabricante NUEVO exige conexión (igual que abrir una
        // cabecera nueva, ver doc de SterilizationService) -- pero si falla
        // por estar offline no debe tumbar el resto del guardado, que sí se
        // encola vía saveTechnicalInfoDraft más abajo. Se conserva el
        // fabricante que ya tuviera el borrador.
        try {
          manufacturerId = (await ManufacturerService.instance.createOrGet(manufacturerName)).id;
        } catch (e) {
          if (!ConnectivityService.isNetworkError(e)) rethrow;
        }
      }
    } else {
      manufacturerId = null;
    }

    final ifuTitle = _ifuTitleController.text.trim();
    final ifuUrl = _ifuUrlController.text.trim();
    String? ifuDocumentId = draft.ifuDocumentId;
    if (ifuTitle.isNotEmpty && ifuUrl.isNotEmpty) {
      // Catálogo global: la IFU también es global (organizationId null),
      // igual que el resto de la ficha técnica de un instrumento 'catalog'.
      // ReferenceDocumentService.createOrGet SIEMPRE inserta (no dedup, ver
      // su doc) así que esto corre en CADA guardado con IFU rellenada -- de
      // ahí que aislarlo importe tanto: sin este try/catch, un guardado
      // offline de campos que no tienen nada que ver con la IFU (notas de
      // mantenimiento, etc.) se abortaría entero antes de llegar a
      // saveTechnicalInfoDraft, que es la llamada que sí sabe encolarse.
      try {
        final doc = await ReferenceDocumentService.instance.createOrGet(
          ifuTitle,
          ifuUrl,
          docType: 'ifu',
          manufacturerId: manufacturerId,
        );
        ifuDocumentId = doc.id;
      } catch (e) {
        if (!ConnectivityService.isNetworkError(e)) rethrow;
      }
    } else if (ifuTitle.isEmpty && ifuUrl.isEmpty) {
      ifuDocumentId = null;
    }

    final maintenanceNotes = _nullIfEmpty(_maintenanceController.text);
    final inspectionNotes = _nullIfEmpty(_inspectionController.text);
    final usefulLifeNotes = _nullIfEmpty(_usefulLifeController.text);
    final maintenanceIntervalDays = int.tryParse(_maintenanceIntervalController.text.trim());

    final updated = draft.copyWith(
      manufacturerId: manufacturerId,
      clearManufacturerId: manufacturerId == null,
      ifuDocumentId: ifuDocumentId,
      clearIfuDocumentId: ifuDocumentId == null,
      maintenanceNotes: maintenanceNotes,
      clearMaintenanceNotes: maintenanceNotes == null,
      inspectionNotes: inspectionNotes,
      clearInspectionNotes: inspectionNotes == null,
      usefulLifeNotes: usefulLifeNotes,
      clearUsefulLifeNotes: usefulLifeNotes == null,
      maintenanceIntervalDays: maintenanceIntervalDays,
      clearMaintenanceIntervalDays: maintenanceIntervalDays == null,
      lastMaintenanceAt: _lastMaintenanceAt,
      clearLastMaintenanceAt: _lastMaintenanceAt == null,
      comment: _nullIfEmpty(_infoCommentController.text),
    );
    final saved = await SterilizationService.instance.saveTechnicalInfoDraft(updated);
    _infoDraft = saved;
    return saved;
  }

  /// Guarda ambos borradores (método + ficha técnica) y, si [submit] es
  /// `true`, los envía a revisión a continuación -- mismo patrón
  /// `_saveDraft({bool andSubmit})` que [TrayFormScreen._saveDraft].
  Future<void> _save({required bool submit}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final savedMethod = await _persistMethodDraft();
      if (submit) {
        await SterilizationService.instance.submitMethodVersionForReview(savedMethod.id);
      }
      final savedInfo = await _persistInfoDraft();
      if (submit) {
        await SterilizationService.instance.submitTechnicalInfoVersionForReview(savedInfo.id);
      }
      await _tagPickerKey.currentState?.save();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.saveError(e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Selector de qué cabecera de `_methods` se edita en el formulario de
  /// esterilización (o "añadir nuevo método" para insertar una fila más).
  /// Si el instrumento no tiene ninguna fila registrada todavía, no hay nada
  /// que elegir: el formulario ya arranca en modo "nuevo" y este selector no
  /// se muestra. Ver bug independent 6 del plan de refactor original.
  Widget _buildMethodSelector(BuildContext context, AppLocalizations l10n) {
    if (_methods.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.sterilizationSelectMethodToEditLabel, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _methods)
                ChoiceChip(
                  label: Text(
                    entry.publishedVersion != null
                        ? sterilizationMethodValueLabel(l10n, entry.publishedVersion!.method)
                        : l10n.sterilizationUnpublishedMethodLabel,
                  ),
                  selected: _selectedMethodId == entry.id,
                  onSelected: (_) => _loadMethodDraft(entry.id),
                ),
              ChoiceChip(
                label: Text(l10n.sterilizationAddNewMethodOption),
                avatar: const Icon(Icons.add, size: 18),
                selected: _selectedMethodId == null,
                onSelected: (_) => _loadMethodDraft(null),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loadingDraft = _loadingMethodDraft || _loadingInfoDraft;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.editClinicalDataTooltip, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Text(l10n.sterilizationSectionTitle, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              _buildMethodSelector(context, l10n),
              DropdownButtonFormField<SterilizationMethod>(
                key: ValueKey('method-dropdown-${_selectedMethodId ?? 'new'}'),
                initialValue: _method,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationMethodLabel,
                  border: const OutlineInputBorder(),
                ),
                items: SterilizationMethod.values
                    .map((m) => DropdownMenuItem(value: m, child: Text(sterilizationMethodValueLabel(l10n, m))))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _temperatureController,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationTemperatureLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationTimeLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pressureController,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationPressureLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dryingController,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationDryingLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cycleController,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationRecommendedCycleLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _compatibilityController,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationCompatibilityLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _restrictionsController,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationRestrictionsLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _observationsController,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationObservationsLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _lubricationRequired,
                onChanged: (value) => setState(() => _lubricationRequired = value),
                title: Text(l10n.lubricationRequiredLabel),
              ),
              if (_lubricationRequired) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _lubricationTypeController,
                  decoration: InputDecoration(
                    labelText: l10n.lubricationTypeLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lubricationNotesController,
                  decoration: InputDecoration(
                    labelText: l10n.lubricationNotesLabel,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _methodCommentController,
                decoration: InputDecoration(
                  labelText: l10n.changeCommentLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const Divider(height: 32),
              Text(l10n.technicalInfoSectionTitle, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Autocomplete<Manufacturer>(
                optionsBuilder: (value) {
                  if (value.text.trim().isEmpty) return const Iterable<Manufacturer>.empty();
                  return ManufacturerService.instance.searchByName(value.text);
                },
                displayStringForOption: (m) => m.name,
                initialValue: TextEditingValue(text: _manufacturerFieldController.text),
                onSelected: (m) {
                  _selectedManufacturerId = m.id;
                  _manufacturerFieldController.text = m.name;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: l10n.technicalManufacturerLabel,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _manufacturerFieldController.text = value;
                      final cached = _selectedManufacturerId == null
                          ? null
                          : ManufacturerService.instance.byId(_selectedManufacturerId!);
                      if (cached != null && cached.name != value) {
                        _selectedManufacturerId = null;
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ifuTitleController,
                decoration: InputDecoration(
                  labelText: l10n.technicalIfuTitleLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ifuUrlController,
                decoration: InputDecoration(
                  labelText: l10n.technicalIfuUrlLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maintenanceController,
                decoration: InputDecoration(
                  labelText: l10n.technicalMaintenanceLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _inspectionController,
                decoration: InputDecoration(
                  labelText: l10n.technicalInspectionLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usefulLifeController,
                decoration: InputDecoration(
                  labelText: l10n.technicalUsefulLifeLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maintenanceIntervalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.technicalMaintenanceIntervalLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickLastMaintenanceDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.technicalLastMaintenanceLabel,
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(_lastMaintenanceAt == null ? '—' : _formatDate(_lastMaintenanceAt!)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _infoCommentController,
                decoration: InputDecoration(
                  labelText: l10n.changeCommentLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const Divider(height: 32),
              Text(l10n.tagsLabel, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TagPicker(
                key: _tagPickerKey,
                refType: _refType,
                refId: widget.instrument.id,
                organizationId: null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: (_saving || loadingDraft) ? null : () => _save(submit: true),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.submitForReview),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: (_saving || loadingDraft) ? null : () => _save(submit: false),
                child: Text(l10n.saveAsDraft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hoja de subida de una foto de la comunidad para un instrumento del
/// catálogo sin foto verificada. Exige aceptar explícitamente el aviso de
/// consentimiento (checkbox) antes de habilitar el envío — ver
/// supabase/schema_v16_community_photos.sql (consent_accepted obligatorio a
/// nivel de tabla y de RLS).
class _CommunityPhotoUploadSheet extends StatefulWidget {
  final String refType;
  final String refId;

  const _CommunityPhotoUploadSheet({required this.refType, required this.refId});

  @override
  State<_CommunityPhotoUploadSheet> createState() => _CommunityPhotoUploadSheetState();
}

class _CommunityPhotoUploadSheetState extends State<_CommunityPhotoUploadSheet> {
  File? _pickedPhoto;
  bool _consentAccepted = false;
  bool _submitting = false;
  bool _submitted = false;
  String? _error;

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.pickFromGalleryLabel),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.pickFromCameraLabel),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (picked != null) {
      setState(() => _pickedPhoto = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_pickedPhoto == null || !_consentAccepted) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await CatalogCommunityPhotoService.instance.submitPhoto(
        refType: widget.refType,
        refId: widget.refId,
        file: _pickedPhoto!,
        consentAccepted: _consentAccepted,
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.communityPhotoDialogTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              if (_submitted) ...[
                Text(l10n.communityPhotoSubmitSuccess),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.save),
                ),
              ] else ...[
                if (_pickedPhoto != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_pickedPhoto!, height: 160, fit: BoxFit.contain),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.photo_outlined),
                  label: Text(l10n.uploadPhotoButtonLabel),
                  onPressed: _pickPhoto,
                ),
                const SizedBox(height: 16),
                Text(l10n.communityPhotoConsentText, style: Theme.of(context).textTheme.bodySmall),
                CheckboxListTile(
                  value: _consentAccepted,
                  onChanged: (value) => setState(() => _consentAccepted = value ?? false),
                  title: Text(l10n.communityPhotoConsentCheckbox),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.communityPhotoSubmitError(_error!),
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: (_pickedPhoto != null && _consentAccepted && !_submitting) ? _submit : null,
                  icon: _submitting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: Text(l10n.communityPhotoSubmit),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
