import 'package:flutter/material.dart';

import '../design_system/components/instriq_badge.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/group_document.dart';
import '../models/group_document_version.dart' show GroupDocumentVersionStatus;
import '../models/instrument_incident.dart';
import '../models/instrument_sterilization.dart';
import '../models/manufacturer.dart';
import '../models/reference_document.dart';
import '../models/specialty_entity.dart';
import '../models/tag.dart';
import '../models/tray.dart';
import '../models/workspace_role.dart';
import '../services/auth_service.dart';
import '../services/custom_instrument_service.dart';
import '../services/favorites_service.dart';
import '../services/group_document_service.dart';
import '../services/instrument_incident_service.dart';
import '../services/knowledge_link_service.dart';
import '../services/manufacturer_service.dart';
import '../services/profile_service.dart';
import '../services/recent_activity_service.dart';
import '../services/reference_document_service.dart';
import '../services/specialty_service.dart';
import '../services/sterilization_service.dart';
import '../services/tag_service.dart';
import '../services/tray_service.dart';
import '../services/usage_analytics_service.dart';
import '../widgets/clinical_data_form_sheet.dart';
import '../widgets/instrument_incident_label.dart';
import '../widgets/offline_banner.dart';
import '../widgets/sterilization_method_label.dart';
import 'custom_instrument_form_screen.dart';
import 'group_document_detail_screen.dart';
import 'specialty_detail_screen.dart';
import 'sterilization_method_version_history_screen.dart';
import 'tag_detail_screen.dart';
import 'technical_info_version_history_screen.dart';
import 'tray_detail_screen.dart';

/// Vista de lectura de un instrumento personalizado: sus variantes con foto
/// (vía signed URL, el bucket es privado) y el disclaimer de licencia
/// SIEMPRE visible junto a cada foto — nunca opcional ni escondido.
class CustomInstrumentDetailScreen extends StatefulWidget {
  final CustomInstrument instrument;
  final WorkspaceRole? myRole;

  const CustomInstrumentDetailScreen({super.key, required this.instrument, required this.myRole});

  @override
  State<CustomInstrumentDetailScreen> createState() => _CustomInstrumentDetailScreenState();
}

class _CustomInstrumentDetailScreenState extends State<CustomInstrumentDetailScreen> {
  static const String _refType = 'custom';

  late CustomInstrument _instrument;
  final Map<String, String> _photoUrls = {};
  bool _loadingPhotos = true;
  bool _isFavorite = false;
  SpecialtyEntity? _specialty;
  List<Tag> _tags = [];
  List<GroupDocument> _usedInDocuments = [];
  List<Tray> _usedInTrays = [];

  // Esterilització/fitxa tècnica (EPIC 3 · CSSD Workspace): el backend
  // (schema_v32) ja accepta `instrument_ref_type = 'custom'` des del
  // principi, però fins ara només `instrument_detail_screen.dart` (catàleg
  // global) tenia la UI corresponent. Mateix patró que allà, adaptat: aquí
  // no hi ha reordenació per mode de treball (aquesta pantalla no la tenia
  // abans) i els tags ja es mostren a dalt (`_tags`), no es repeteixen aquí.
  bool _loadingClinicalData = true;
  List<SterilizationMethodEntry> _methods = [];
  InstrumentTechnicalInfo? _technicalInfo;
  Manufacturer? _manufacturer;
  ReferenceDocument? _ifuDocument;
  SterilizationMethodVersion? _ownPendingMethodDraft;
  InstrumentTechnicalInfoVersion? _ownPendingInfoDraft;

  bool _loadingIncidents = true;
  List<InstrumentIncident> _incidents = [];

  @override
  void initState() {
    super.initState();
    _instrument = widget.instrument;
    _loadPhotos();
    _loadSpecialty();
    _loadTags();
    _loadUsedIn();
    _loadClinicalData();
    _loadIncidents();
    if (AuthService.instance.currentUser != null) {
      RecentActivityService.instance.recordView(_refType, _instrument.id);
      UsageAnalyticsService.instance.recordView(_refType, _instrument.id);
      _loadFavoriteState();
    }
  }

  Future<void> _loadClinicalData() async {
    try {
      final methods = await SterilizationService.instance.fetchMethods(_refType, _instrument.id);
      final technicalInfo = await SterilizationService.instance.fetchTechnicalInfo(_refType, _instrument.id);
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

      // Borrador/en revisión propio pendiente: mismo criterio que
      // instrument_detail_screen.dart, mirando todas las cabeceras de
      // método (puede haber varias por instrumento) más la ficha técnica.
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
      final incidents = await InstrumentIncidentService.instance.fetchForInstrument(_refType, _instrument.id);
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
        refId: _instrument.id,
        organizationId: _instrument.organizationId,
        workspaceId: _instrument.workspaceId,
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
          canRestore: widget.myRole?.canApprove ?? false,
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
          canRestore: widget.myRole?.canApprove ?? false,
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
        refId: _instrument.id,
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

  String _formatShortDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  Future<void> _loadSpecialty() async {
    final specialtyId = _instrument.specialtyId;
    if (specialtyId == null) return;
    final specialties = await SpecialtyService.instance.fetchAll();
    if (!mounted) return;
    SpecialtyEntity? found;
    for (final s in specialties) {
      if (s.id == specialtyId) {
        found = s;
        break;
      }
    }
    setState(() => _specialty = found);
  }

  Future<void> _loadTags() async {
    try {
      final tags = await TagService.instance.fetchTagsFor(_refType, _instrument.id);
      if (!mounted) return;
      setState(() => _tags = tags);
    } catch (_) {
      // Sin bloquear la ficha si falla: las etiquetas son metadato accesorio.
    }
  }

  Future<void> _loadUsedIn() async {
    try {
      final links = await KnowledgeLinkService.instance.fetchRelatedTo(_refType, _instrument.id);
      final usedInDocuments = <GroupDocument>[];
      final usedInTrays = <Tray>[];
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
      if (!mounted) return;
      setState(() {
        _usedInDocuments = usedInDocuments;
        _usedInTrays = usedInTrays;
      });
    } catch (_) {
      // Grafo de conocimiento es metadato accesorio: no bloquea el resto de la ficha.
    }
  }

  Future<void> _loadFavoriteState() async {
    final isFavorite = await FavoritesService.instance.isFavorite(_refType, _instrument.id);
    if (!mounted) return;
    setState(() => _isFavorite = isFavorite);
  }

  Future<void> _toggleFavorite() async {
    await FavoritesService.instance.toggleFavorite(_refType, _instrument.id);
    if (!mounted) return;
    setState(() => _isFavorite = !_isFavorite);
  }

  Future<void> _loadPhotos() async {
    for (final variant in _instrument.variants) {
      final path = variant.photoPath;
      if (path == null) continue;
      try {
        _photoUrls[variant.id] = await CustomInstrumentService.instance.getVariantPhotoUrl(path);
      } catch (_) {
        // Sin foto disponible (p.ej. sin conexión) — se muestra sin imagen.
      }
    }
    if (mounted) setState(() => _loadingPhotos = false);
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCustomInstrumentTitle),
        content: Text(l10n.deleteCustomInstrumentConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.deleteAction)),
        ],
      ),
    );
    if (confirmed != true) return;
    await CustomInstrumentService.instance.delete(_instrument.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canEdit = widget.myRole?.canEdit ?? false;
    final canDelete = widget.myRole?.canApprove ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(_instrument.name),
        actions: [
          if (AuthService.instance.currentUser != null)
            IconButton(
              icon: Icon(_isFavorite ? Icons.star : Icons.star_border),
              tooltip: l10n.favoriteToggleTooltip,
              onPressed: _toggleFavorite,
            ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.editTooltip,
              onPressed: () async {
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => CustomInstrumentFormScreen(
                      workspaceId: _instrument.workspaceId,
                      existingInstrument: _instrument,
                    ),
                  ),
                );
                if (saved == true) {
                  final refreshed = CustomInstrumentService.instance.byId(_instrument.id);
                  if (refreshed != null && mounted) {
                    setState(() {
                      _instrument = refreshed;
                      _loadingPhotos = true;
                    });
                    _loadPhotos();
                    _loadSpecialty();
                  }
                }
              },
            ),
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: l10n.editClinicalDataTooltip,
              onPressed: _openEditClinicalDataSheet,
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.deleteTooltip,
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
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
            if (_instrument.category != null || _specialty != null || _instrument.specialty != null)
              Wrap(
                spacing: 8,
                children: [
                  if (_instrument.category != null) Chip(label: Text(_instrument.category!)),
                  if (_specialty != null)
                    InputChip(
                      label: Text(_specialty!.label),
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SpecialtyDetailScreen(specialty: _specialty!)),
                      ),
                    )
                  else if (_instrument.specialty != null)
                    Chip(label: Text(_instrument.specialty!)),
                ],
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
            const SizedBox(height: 12),
            if (_instrument.description != null) ...[
              Text(_instrument.description!, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
            ],
            if (_instrument.useText != null) ...[
              Text(l10n.customInstrumentUseLabel, style: Theme.of(context).textTheme.titleSmall),
              Text(_instrument.useText!),
              const SizedBox(height: 12),
            ],
            if (_instrument.tip != null) ...[
              Text(l10n.customInstrumentTipLabel, style: Theme.of(context).textTheme.titleSmall),
              Text(_instrument.tip!),
              const SizedBox(height: 12),
            ],
            const Divider(height: 32),
            Text(l10n.customInstrumentVariantsTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (_instrument.variants.isEmpty)
              Padding(padding: const EdgeInsets.all(12), child: Text(l10n.noVariantsYet))
            else
              ..._instrument.variants.map((variant) => _VariantTile(
                    variant: variant,
                    photoUrl: _photoUrls[variant.id],
                    loading: _loadingPhotos,
                  )),
            const Divider(height: 32),
            _buildSterilizationSection(context, l10n),
            const SizedBox(height: 8),
            _buildTechnicalSection(context, l10n),
            if (_usedInDocuments.isNotEmpty || _usedInTrays.isNotEmpty) ...[
              const Divider(height: 32),
              Text(l10n.knowledgeGraphUsedInTitle, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._usedInDocuments.map((doc) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.description_outlined),
                      title: Text(doc.publishedVersion?.title ?? doc.id),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GroupDocumentDetailScreen(document: doc, myRole: widget.myRole),
                        ),
                      ),
                    ),
                  )),
              ..._usedInTrays.map((tray) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.inventory_2_outlined),
                      title: Text(tray.publishedVersion?.name ?? tray.id),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => TrayDetailScreen(tray: tray, myRole: widget.myRole)),
                      ),
                    ),
                  )),
            ],
            const Divider(height: 32),
            _buildIncidentsSection(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildSterilizationSection(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
    final hasAnything = lines.isNotEmpty || manufacturer != null || ifuDocument != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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
              ),
              const SizedBox(height: 8),
            ],
            for (final line in lines) ...[
              Text(line, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
            ],
            if (ifuDocument != null)
              Text(
                '${l10n.technicalIfuLabel}: ${ifuDocument.title}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
          ],
        ],
      ),
    );
  }

  /// Ver [InstrumentDetailScreen._buildIncidentsSection] -- mateix criteri.
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

class _VariantTile extends StatelessWidget {
  final CustomInstrumentVariant variant;
  final String? photoUrl;
  final bool loading;

  const _VariantTile({required this.variant, required this.photoUrl, required this.loading});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasPhoto = variant.photoPath != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (hasPhoto)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: loading
                        ? const SizedBox(
                            width: 72,
                            height: 72,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : (photoUrl != null
                            ? Image.network(
                                photoUrl!,
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              )
                            : const SizedBox(
                                width: 72,
                                height: 72,
                                child: Icon(Icons.image_not_supported_outlined),
                              )),
                  )
                else
                  const CircleAvatar(radius: 36, child: Icon(Icons.build_circle_outlined)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(variant.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (variant.note != null) Text(variant.note!),
                    ],
                  ),
                ),
              ],
            ),
            if (hasPhoto) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.customPhotoDisclaimer,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
