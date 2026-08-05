import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/catalog_community_photo.dart';
import '../models/group_document.dart';
import '../models/instrument.dart';
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
import '../widgets/sterilization_method_label.dart';
import '../widgets/tag_picker.dart';
import 'group_document_detail_screen.dart';
import 'manufacturer_detail_screen.dart';
import 'review_session_screen.dart';
import 'tag_detail_screen.dart';
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

  bool _loadingCommunityPhoto = true;
  CatalogCommunityPhoto? _approvedCommunityPhoto;
  CatalogCommunityPhoto? _ownPendingPhoto;

  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadClinicalData();
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
      final manufacturerId = technicalInfo?.manufacturerId;
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
      final ifuDocumentId = technicalInfo?.ifuDocumentId;
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
      if (!mounted) return;
      setState(() {
        _methods = methods;
        _technicalInfo = technicalInfo;
        _manufacturer = manufacturer;
        _ifuDocument = ifuDocument;
        _tags = tags;
        _usedInDocuments = usedInDocuments;
        _usedInTrays = usedInTrays;
        _loadingClinicalData = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingClinicalData = false);
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
    final details = <String>[
      if (method.temperature != null && method.temperature!.isNotEmpty)
        '${l10n.sterilizationTemperatureLabel}: ${method.temperature}',
      if (method.timeMinutes != null && method.timeMinutes!.isNotEmpty)
        '${l10n.sterilizationTimeLabel}: ${method.timeMinutes}',
      if (method.pressure != null && method.pressure!.isNotEmpty)
        '${l10n.sterilizationPressureLabel}: ${method.pressure}',
      if (method.drying != null && method.drying!.isNotEmpty)
        '${l10n.sterilizationDryingLabel}: ${method.drying}',
      if (method.recommendedCycle != null && method.recommendedCycle!.isNotEmpty)
        '${l10n.sterilizationRecommendedCycleLabel}: ${method.recommendedCycle}',
      if (method.compatibilityNotes != null && method.compatibilityNotes!.isNotEmpty)
        '${l10n.sterilizationCompatibilityLabel}: ${method.compatibilityNotes}',
      if (method.restrictions != null && method.restrictions!.isNotEmpty)
        '${l10n.sterilizationRestrictionsLabel}: ${method.restrictions}',
      if (method.observations != null && method.observations!.isNotEmpty)
        '${l10n.sterilizationObservationsLabel}: ${sterilizationObservationsText(l10n, method.observations!)}',
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sterilizationMethodValueLabel(l10n, method.method), style: Theme.of(context).textTheme.titleSmall),
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
    final lines = <String>[
      if (info?.maintenanceNotes != null && info!.maintenanceNotes!.isNotEmpty)
        '${l10n.technicalMaintenanceLabel}: ${info.maintenanceNotes}',
      if (info?.inspectionNotes != null && info!.inspectionNotes!.isNotEmpty)
        '${l10n.technicalInspectionLabel}: ${info.inspectionNotes}',
      if (info?.usefulLifeNotes != null && info!.usefulLifeNotes!.isNotEmpty)
        '${l10n.technicalUsefulLifeLabel}: ${info.usefulLifeNotes}',
    ];
    final manufacturer = _manufacturer;
    final ifuDocument = _ifuDocument;
    final hasAnything = lines.isNotEmpty || manufacturer != null || ifuDocument != null || _tags.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.technicalInfoSectionTitle, style: Theme.of(context).textTheme.labelLarge),
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
}

/// Formulario simple para dar de alta/editar un método de esterilización y la
/// ficha técnica de un instrumento del catálogo global. Solo visible para
/// admins (ver botón en el AppBar de [InstrumentDetailScreen]).
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

  // `null` significa "nueva fila" (se insertará vía `upsertMethod` con
  // `id: null`); si no, es el `id` de una de `widget.methods` que se está
  // editando. Ver bug independent 6 del plan: antes el sheet solo leía/
  // escribía `methods.first`, dejando invisibles el resto de filas cuando
  // un instrumento tenía 2+ métodos registrados.
  String? _selectedMethodId;
  SterilizationMethod _method = SterilizationMethod.vapor;
  late final TextEditingController _temperatureController;
  late final TextEditingController _timeController;
  late final TextEditingController _pressureController;
  late final TextEditingController _dryingController;
  late final TextEditingController _cycleController;
  late final TextEditingController _compatibilityController;
  late final TextEditingController _restrictionsController;
  late final TextEditingController _observationsController;

  // Texto libre "espejo" del campo de autocompletar de fabricante — mismo
  // patrón que `preference_card_form_screen.dart` para el cirujano.
  final TextEditingController _manufacturerFieldController = TextEditingController();
  String? _selectedManufacturerId;
  late final TextEditingController _ifuTitleController;
  late final TextEditingController _ifuUrlController;
  late final TextEditingController _maintenanceController;
  late final TextEditingController _inspectionController;
  late final TextEditingController _usefulLifeController;
  final _tagPickerKey = GlobalKey<TagPickerState>();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existingMethod = widget.methods.isNotEmpty ? widget.methods.first : null;
    _selectedMethodId = existingMethod?.id;
    _method = existingMethod?.method ?? SterilizationMethod.vapor;
    _temperatureController = TextEditingController(text: existingMethod?.temperature ?? '');
    _timeController = TextEditingController(text: existingMethod?.timeMinutes ?? '');
    _pressureController = TextEditingController(text: existingMethod?.pressure ?? '');
    _dryingController = TextEditingController(text: existingMethod?.drying ?? '');
    _cycleController = TextEditingController(text: existingMethod?.recommendedCycle ?? '');
    _compatibilityController = TextEditingController(text: existingMethod?.compatibilityNotes ?? '');
    _restrictionsController = TextEditingController(text: existingMethod?.restrictions ?? '');
    _observationsController = TextEditingController(text: existingMethod?.observations ?? '');

    final info = widget.technicalInfo;
    _selectedManufacturerId = info?.manufacturerId;
    _ifuTitleController = TextEditingController();
    _ifuUrlController = TextEditingController();
    _maintenanceController = TextEditingController(text: info?.maintenanceNotes ?? '');
    _inspectionController = TextEditingController(text: info?.inspectionNotes ?? '');
    _usefulLifeController = TextEditingController(text: info?.usefulLifeNotes ?? '');
    _loadManufacturerAndIfu();
  }

  Future<void> _loadManufacturerAndIfu() async {
    await ManufacturerService.instance.fetchAll();
    if (mounted) {
      final manufacturerId = _selectedManufacturerId;
      if (manufacturerId != null) {
        final existing = ManufacturerService.instance.byId(manufacturerId);
        if (existing != null) _manufacturerFieldController.text = existing.name;
      }
    }
    final ifuDocumentId = widget.technicalInfo?.ifuDocumentId;
    if (ifuDocumentId == null) return;
    final doc = await ReferenceDocumentService.instance.fetchById(ifuDocumentId);
    if (!mounted || doc == null) return;
    setState(() {
      _ifuTitleController.text = doc.title;
      _ifuUrlController.text = doc.url;
    });
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
    _manufacturerFieldController.dispose();
    _ifuTitleController.dispose();
    _ifuUrlController.dispose();
    _maintenanceController.dispose();
    _inspectionController.dispose();
    _usefulLifeController.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String value) => value.trim().isEmpty ? null : value.trim();

  /// Cambia qué fila de `widget.methods` se está editando en el formulario
  /// de esterilización (o pasa a "nueva fila" si [entry] es `null`). El resto
  /// del sheet (ficha técnica, tags) no depende de esta selección.
  void _selectMethod(SterilizationMethodEntry? entry) {
    setState(() {
      _selectedMethodId = entry?.id;
      _method = entry?.method ?? SterilizationMethod.vapor;
      _temperatureController.text = entry?.temperature ?? '';
      _timeController.text = entry?.timeMinutes ?? '';
      _pressureController.text = entry?.pressure ?? '';
      _dryingController.text = entry?.drying ?? '';
      _cycleController.text = entry?.recommendedCycle ?? '';
      _compatibilityController.text = entry?.compatibilityNotes ?? '';
      _restrictionsController.text = entry?.restrictions ?? '';
      _observationsController.text = entry?.observations ?? '';
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      SterilizationMethodEntry? existingMethod;
      final selectedId = _selectedMethodId;
      if (selectedId != null) {
        for (final m in widget.methods) {
          if (m.id == selectedId) {
            existingMethod = m;
            break;
          }
        }
      }
      await SterilizationService.instance.upsertMethod(
        SterilizationMethodEntry(
          id: existingMethod?.id,
          instrumentRefType: _refType,
          instrumentRefId: widget.instrument.id,
          method: _method,
          temperature: _nullIfEmpty(_temperatureController.text),
          timeMinutes: _nullIfEmpty(_timeController.text),
          pressure: _nullIfEmpty(_pressureController.text),
          drying: _nullIfEmpty(_dryingController.text),
          recommendedCycle: _nullIfEmpty(_cycleController.text),
          compatibilityNotes: _nullIfEmpty(_compatibilityController.text),
          restrictions: _nullIfEmpty(_restrictionsController.text),
          observations: _nullIfEmpty(_observationsController.text),
        ),
      );

      final manufacturerName = _manufacturerFieldController.text.trim();
      String? manufacturerId;
      if (manufacturerName.isNotEmpty) {
        final cached =
            _selectedManufacturerId == null ? null : ManufacturerService.instance.byId(_selectedManufacturerId!);
        manufacturerId = (cached != null && cached.name == manufacturerName)
            ? cached.id
            : (await ManufacturerService.instance.createOrGet(manufacturerName)).id;
      }

      final ifuTitle = _ifuTitleController.text.trim();
      final ifuUrl = _ifuUrlController.text.trim();
      String? ifuDocumentId = widget.technicalInfo?.ifuDocumentId;
      if (ifuTitle.isNotEmpty && ifuUrl.isNotEmpty) {
        // Catálogo global: la IFU también es global (organizationId null),
        // igual que el resto de la ficha técnica de un instrumento 'catalog'.
        final doc = await ReferenceDocumentService.instance.createOrGet(
          ifuTitle,
          ifuUrl,
          docType: 'ifu',
          manufacturerId: manufacturerId,
        );
        ifuDocumentId = doc.id;
      } else if (ifuTitle.isEmpty && ifuUrl.isEmpty) {
        ifuDocumentId = null;
      }

      await SterilizationService.instance.upsertTechnicalInfo(
        InstrumentTechnicalInfo(
          id: widget.technicalInfo?.id,
          instrumentRefType: _refType,
          instrumentRefId: widget.instrument.id,
          manufacturerId: manufacturerId,
          ifuDocumentId: ifuDocumentId,
          maintenanceNotes: _nullIfEmpty(_maintenanceController.text),
          inspectionNotes: _nullIfEmpty(_inspectionController.text),
          usefulLifeNotes: _nullIfEmpty(_usefulLifeController.text),
        ),
      );
      await _tagPickerKey.currentState?.save();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.customInstrumentSaveError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Selector de qué fila de `widget.methods` se edita en el formulario de
  /// esterilización (o "añadir nuevo método" para insertar una fila más).
  /// Si el instrumento no tiene ninguna fila registrada todavía, no hay nada
  /// que elegir: el formulario ya arranca en modo "nuevo" y este selector no
  /// se muestra. Ver bug independent 6 del plan de refactor.
  Widget _buildMethodSelector(BuildContext context, AppLocalizations l10n) {
    if (widget.methods.isEmpty) return const SizedBox.shrink();
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
              for (final entry in widget.methods)
                ChoiceChip(
                  label: Text(sterilizationMethodValueLabel(l10n, entry.method)),
                  selected: _selectedMethodId == entry.id,
                  onSelected: (_) => _selectMethod(entry),
                ),
              ChoiceChip(
                label: Text(l10n.sterilizationAddNewMethodOption),
                avatar: const Icon(Icons.add, size: 18),
                selected: _selectedMethodId == null,
                onSelected: (_) => _selectMethod(null),
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
              const Divider(height: 32),
              Text(l10n.tagsLabel, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TagPicker(
                key: _tagPickerKey,
                refType: _refType,
                refId: widget.instrument.id,
                organizationId: null,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(l10n.save),
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
