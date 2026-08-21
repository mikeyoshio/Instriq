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
import '../widgets/clinical_data_form_sheet.dart';
import '../widgets/instrument_incident_label.dart';
import '../widgets/offline_banner.dart';
import '../widgets/sterilization_method_label.dart';
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
      builder: (ctx) => ClinicalDataFormSheet(
        refType: _refType,
        refId: widget.instrument.id,
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
  /// reportar una, resolverla exige `approver`/`administrator` de espacio o
  /// admin de organización -- ver `instrument_incidents_update` en
  /// schema_v32_cssd_workspace.sql, la autoridad real. `isAdmin` solo no
  /// bastaba: una incidencia es un asunto operativo de la organización (igual
  /// que aprobar una técnica o una bandeja), no una edición del catálogo
  /// global, así que sigue el mismo criterio que `canApproveAnyWorkspace` en
  /// app_shell.dart en vez del gate de "quién puede editar esterilización/
  /// ficha técnica" del botón del AppBar.
  Widget _buildIncidentsSection(BuildContext context, AppLocalizations l10n) {
    final canReport = AuthService.instance.currentUser != null && ProfileService.instance.organizationId != null;
    final canResolve = ProfileService.instance.isAdmin || ProfileService.instance.canApproveAnyWorkspace;
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
