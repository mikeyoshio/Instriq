import 'dart:async';

import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_responsive_content.dart';
import '../design_system/components/instriq_section_header.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/group_document.dart';
import '../models/instrument.dart';
import '../models/instrument_sterilization.dart';
import '../models/manufacturer.dart';
import '../models/procedure.dart';
import '../models/public_instrument.dart';
import '../models/surgeon.dart';
import '../models/tag.dart';
import '../models/tray.dart';
import '../models/workspace_role.dart';
import '../navigation/profile_button.dart';
import '../services/custom_instrument_service.dart';
import '../services/group_document_service.dart';
import '../services/manufacturer_service.dart';
import '../services/procedure_service.dart';
import '../services/profile_service.dart';
import '../services/public_instrument_service.dart';
import '../services/specialty_service.dart';
import '../services/sterilization_service.dart';
import '../services/surgeon_service.dart';
import '../services/tag_service.dart';
import '../services/tray_service.dart';
import '../services/usage_analytics_service.dart';
import '../services/workspace_service.dart';
import '../utils/fuzzy_match.dart';
import '../widgets/sterilization_method_label.dart';
import 'catalog_screen.dart';
import 'custom_instrument_detail_screen.dart';
import 'drug_catalog_screen.dart';
import 'group_document_detail_screen.dart';
import 'instrument_detail_screen.dart';
import 'manufacturer_detail_screen.dart';
import 'procedure_detail_screen.dart';
import 'public_entity_detail_screen.dart';
import 'sterilization_reference_catalog_screen.dart';
import 'perioperative_guides_screen.dart';
import 'acronyms_screen.dart';
import 'surgical_position_catalog_screen.dart';
import 'surgeon_detail_screen.dart';
import 'tag_detail_screen.dart';
import 'tray_detail_screen.dart';
import 'wound_closure_catalog_screen.dart';

/// Resultat d'una cerca a Omnihub, agrupat per tipus d'entitat -- un únic
/// càlcul que alimenta tant el pintat com l'analítica d'ús (EPIC 5).
class OmnihubResults {
  final List<Procedure> procedures;
  final List<Instrument> instruments;
  final List<GroupDocument> techniques;
  final List<GroupDocument> protocols;
  final List<Tray> trays;
  final List<CustomInstrument> customInstruments;
  final List<PublicInstrument> publicInstruments;
  final List<Manufacturer> manufacturers;
  final List<Surgeon> surgeons;
  final List<Tag> tags;

  const OmnihubResults({
    required this.procedures,
    required this.instruments,
    required this.techniques,
    required this.protocols,
    required this.trays,
    required this.customInstruments,
    required this.publicInstruments,
    required this.manufacturers,
    required this.surgeons,
    required this.tags,
  });

  bool get isEmpty =>
      procedures.isEmpty &&
      instruments.isEmpty &&
      techniques.isEmpty &&
      protocols.isEmpty &&
      trays.isEmpty &&
      customInstruments.isEmpty &&
      publicInstruments.isEmpty &&
      manufacturers.isEmpty &&
      surgeons.isEmpty &&
      tags.isEmpty;
}

/// Tot el que Omnihub recorre en cada cerca. Es carrega un cop en obrir la
/// pestanya; els serveis ja cachegen, així que si Inici ja havia carregat el
/// contingut de grup no es repeteix cap petició cara. Fabricants i
/// cirurgians no es guarden aquí: es cerquen sobre el caché del seu servei.
class OmnihubIndex {
  final List<Procedure> procedures;
  final List<GroupDocument> techniques;
  final List<GroupDocument> protocols;
  final List<Tray> trays;
  final List<CustomInstrument> customInstruments;
  final List<PublicInstrument> publicInstruments;
  final List<Tag> tags;
  final Map<String, String> specialtyLabelById;
  final Map<String, List<SterilizationMethod>> catalogSterilizationMethods;

  const OmnihubIndex({
    this.procedures = const [],
    this.techniques = const [],
    this.protocols = const [],
    this.trays = const [],
    this.customInstruments = const [],
    this.publicInstruments = const [],
    this.tags = const [],
    this.specialtyLabelById = const {},
    this.catalogSterilizationMethods = const {},
  });

  static Future<OmnihubIndex> load() async {
    // Metadada global (catàleg, etiquetes, especialitats, esterilització,
    // Biblioteca Pública): disponible també en mode convidat. Cada peça és
    // accessòria: si una falla no bloqueja la resta de la cerca.
    var tags = <Tag>[];
    var specialtyLabelById = <String, String>{};
    var catalogSterilizationMethods = <String, List<SterilizationMethod>>{};
    var publicInstruments = <PublicInstrument>[];
    try {
      await ManufacturerService.instance.fetchAll();
    } catch (_) {}
    try {
      tags = await TagService.instance.fetchAll();
    } catch (_) {}
    try {
      final specialties = await SpecialtyService.instance.fetchAll();
      specialtyLabelById = {for (final s in specialties) s.id: s.label};
    } catch (_) {}
    try {
      catalogSterilizationMethods = await SterilizationService.instance.fetchAllCatalogMethods();
    } catch (_) {}
    try {
      publicInstruments = await PublicInstrumentService.instance.fetchPublished();
    } catch (_) {}

    final procedures = <Procedure>[];
    final techniques = <GroupDocument>[];
    final protocols = <GroupDocument>[];
    final trays = <Tray>[];
    final customInstruments = <CustomInstrument>[];
    if (ProfileService.instance.hasHospital) {
      try {
        await WorkspaceService.instance.fetchWorkspaces();
        for (final workspace in WorkspaceService.instance.workspaces) {
          // Un espai fallant (sense accés, sense connexió puntual) no ha de
          // bloquejar l'agregació de la resta.
          try {
            await GroupDocumentService.instance.fetchDocuments(DocumentKind.technique, workspace.id);
            await GroupDocumentService.instance.fetchDocuments(DocumentKind.protocol, workspace.id);
            await TrayService.instance.fetchTrays(workspace.id);
            await CustomInstrumentService.instance.fetchForWorkspace(workspace.id);
            techniques.addAll(GroupDocumentService.instance.documentsOfKind(DocumentKind.technique, workspace.id));
            protocols.addAll(GroupDocumentService.instance.documentsOfKind(DocumentKind.protocol, workspace.id));
            trays.addAll(TrayService.instance.traysOfWorkspace(workspace.id));
            customInstruments.addAll(CustomInstrumentService.instance.instruments);
          } catch (_) {}
          try {
            procedures.addAll(await ProcedureService.instance.fetchForWorkspace(workspace.id));
          } catch (_) {}
        }
        await SurgeonService.instance.fetchForOrganization();
      } catch (_) {}
    }

    return OmnihubIndex(
      procedures: procedures,
      techniques: techniques,
      protocols: protocols,
      trays: trays,
      customInstruments: customInstruments,
      publicInstruments: publicInstruments,
      tags: tags,
      specialtyLabelById: specialtyLabelById,
      catalogSterilizationMethods: catalogSterilizationMethods,
    );
  }

  OmnihubResults search(String query, String languageCode, AppLocalizations l10n) {
    final q = query.toLowerCase();
    return OmnihubResults(
      procedures: procedures.where((p) => fuzzyContains(p.name, q) || fuzzyContains(p.description ?? '', q)).toList(),
      instruments: kInstruments.where((i) => _matchesInstrument(i, q, languageCode, l10n)).toList(),
      techniques: techniques.where((d) => _matchesGroupDocument(d, q)).toList(),
      protocols: protocols.where((d) => _matchesGroupDocument(d, q)).toList(),
      trays: trays.where((t) => _matchesTray(t, q)).toList(),
      customInstruments: customInstruments.where((i) => _matchesCustomInstrument(i, q)).toList(),
      publicInstruments: publicInstruments.where((i) => _matchesPublicInstrument(i, q)).toList(),
      manufacturers: ManufacturerService.instance.searchByName(q),
      surgeons: SurgeonService.instance.searchByName(q),
      tags: tags.where((t) => fuzzyContains(t.name, q)).toList(),
    );
  }

  bool _matchesInstrument(Instrument instrument, String query, String languageCode, AppLocalizations l10n) {
    return fuzzyContains(instrument.name.forLanguageCode(languageCode), query) ||
        instrument.aliases.any((alias) => fuzzyContains(alias, query)) ||
        fuzzyContains(instrument.description.forLanguageCode(languageCode), query) ||
        fuzzyContains(instrument.use.forLanguageCode(languageCode), query) ||
        fuzzyContains(instrument.specialty.label(l10n), query) ||
        fuzzyContains(instrument.category.label(l10n), query) ||
        (catalogSterilizationMethods[instrument.id] ?? const [])
            .any((m) => fuzzyContains(sterilizationMethodValueLabel(l10n, m), query));
  }

  /// Especialitat resolta d'una versió publicada (`specialtyId` → label, o el
  /// text llegat `specialty` si la fila encara no es va migrar).
  String _specialtyLabel(String? specialtyId, String? legacySpecialty) {
    if (specialtyId != null) return specialtyLabelById[specialtyId] ?? '';
    return legacySpecialty ?? '';
  }

  bool _matchesGroupDocument(GroupDocument document, String query) {
    final published = document.publishedVersion;
    if (published == null) return false;
    return fuzzyContains(published.title, query) ||
        fuzzyContains(_specialtyLabel(published.specialtyId, published.specialty), query);
  }

  bool _matchesTray(Tray tray, String query) {
    final published = tray.publishedVersion;
    if (published == null) return false;
    return fuzzyContains(published.name, query) ||
        fuzzyContains(_specialtyLabel(published.specialtyId, published.specialty), query);
  }

  bool _matchesCustomInstrument(CustomInstrument instrument, String query) {
    return fuzzyContains(instrument.name, query) ||
        fuzzyContains(_specialtyLabel(instrument.specialtyId, instrument.specialty), query);
  }

  bool _matchesPublicInstrument(PublicInstrument instrument, String query) {
    final published = instrument.publishedVersion;
    if (published == null) return false;
    return fuzzyContains(published.name ?? '', query) ||
        fuzzyContains(_specialtyLabel(published.specialtyId, null), query);
  }
}

/// Omnihub: la cerca unificada de tot Instriq (pestanya "Cercar"). Abans
/// vivia amagada dins el camp de cerca d'Inici mentre la pestanya obria
/// només el catàleg (docs/redesign_v1.2_plan.md, Fase 3). El catàleg amb els
/// seus filtres per categoria/especialitat continua a un toc, des de l'estat
/// buit.
class OmnihubScreen extends StatefulWidget {
  const OmnihubScreen({super.key});

  @override
  State<OmnihubScreen> createState() => _OmnihubScreenState();
}

class _OmnihubScreenState extends State<OmnihubScreen> {
  final _controller = TextEditingController();
  String _query = '';
  OmnihubIndex _index = const OmnihubIndex();
  bool _loading = true;

  // Filtrat en viu amb debounce curt (~150ms, per sota del llindar de
  // percepció): cada tecla recorre el catàleg sencer més tot el contingut
  // de grup, de forma síncrona dins de build().
  Timer? _liveDebounce;
  // Analítica amb debounce més llarg: no cal registrar cada tecla intermèdia.
  Timer? _analyticsDebounce;

  @override
  void initState() {
    super.initState();
    _load();
    ProfileService.instance.profileRevision.addListener(_load);
  }

  @override
  void dispose() {
    ProfileService.instance.profileRevision.removeListener(_load);
    _liveDebounce?.cancel();
    _analyticsDebounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final index = await OmnihubIndex.load();
    if (mounted) {
      setState(() {
        _index = index;
        _loading = false;
      });
    }
  }

  /// També per a convidats i comptes sense organització (schema_v63).
  void _scheduleAnalytics(String value) {
    _analyticsDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    _analyticsDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final results =
          _index.search(trimmed, Localizations.localeOf(context).languageCode, AppLocalizations.of(context)!);
      if (!results.isEmpty) {
        UsageAnalyticsService.instance.recordSearch(trimmed);
      } else {
        UsageAnalyticsService.instance.recordZeroResultSearch(trimmed);
      }
    });
  }

  Future<void> _push(Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  Future<void> _pushWithRole(String workspaceId, Widget Function(WorkspaceRole? role) build) async {
    final myRole = await WorkspaceService.instance.fetchMyRole(workspaceId);
    if (!mounted) return;
    await _push(build(myRole));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.omnihubTitle), actions: const [ProfileButton()]),
      body: SafeArea(
        child: InstriqResponsiveContent(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: InstriqSpacing.lg, vertical: InstriqSpacing.sm),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.homeSearchHint,
                    border: OutlineInputBorder(borderRadius: InstriqRadius.mdRadius),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: l10n.clearSearchTooltip,
                            onPressed: () {
                              _analyticsDebounce?.cancel();
                              _liveDebounce?.cancel();
                              _controller.clear();
                              setState(() => _query = '');
                            },
                          ),
                  ),
                  onChanged: (value) {
                    _liveDebounce?.cancel();
                    _liveDebounce = Timer(const Duration(milliseconds: 150), () {
                      if (mounted) setState(() => _query = value.trim());
                    });
                    _scheduleAnalytics(value);
                  },
                ),
              ),
              if (_loading) const LinearProgressIndicator(minHeight: 2),
              Expanded(child: _query.isEmpty ? _buildIntro(l10n) : _buildResults(context, l10n)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntro(AppLocalizations l10n) {
    return ListView(
      padding: const EdgeInsets.all(InstriqSpacing.lg),
      children: [
        Text(l10n.omnihubIntro, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: InstriqSpacing.lg),
        // Els catàlegs de referència viuen aquí (2.0-beta): abans eren a
        // les Dreceres d'Inici.
        for (final (icon, title, subtitle, screen) in [
          (Icons.menu_book, l10n.catalogTitle, l10n.omnihubBrowseCatalog, const CatalogScreen() as Widget),
          (Icons.medication_outlined, l10n.drugsCatalogTitle, l10n.drugsCatalogSubtitle, const DrugCatalogScreen()),
          (Icons.healing_outlined, l10n.woundClosureCatalogTitle, l10n.woundClosureCatalogSubtitle,
              const WoundClosureCatalogScreen()),
          (Icons.cleaning_services_outlined, l10n.sterilizationReferenceCatalogTitle,
              l10n.sterilizationReferenceCatalogSubtitle, const SterilizationReferenceCatalogScreen()),
          (Icons.airline_seat_flat_outlined, l10n.positionsCatalogTitle, l10n.positionsCatalogSubtitle,
              const SurgicalPositionCatalogScreen()),
          (Icons.fact_check_outlined, l10n.guidesCatalogTitle, l10n.guidesCatalogSubtitle,
              const PerioperativeGuidesScreen()),
          (Icons.abc, l10n.acronymsTitle, l10n.acronymsSubtitle, const AcronymsScreen()),
        ]) ...[
          InstriqListItem(icon: icon, title: title, subtitle: subtitle, onTap: () => _push(screen)),
          const SizedBox(height: InstriqSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildResults(BuildContext context, AppLocalizations l10n) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final results = _index.search(_query, languageCode, l10n);

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(InstriqSpacing.xl),
          child: Text(
            _loading ? l10n.omnihubStillLoading : l10n.homeNoResultsForQuery(_query),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // ListView.builder: amb una consulta àmplia els resultats sumats poden
    // ser desenes d'ítems -- es construeixen de forma mandrosa.
    final rows = <Widget Function()>[];
    void addSection<T>(String title, List<T> items, Widget Function(T) row) {
      if (items.isEmpty) return;
      rows.add(() => InstriqSectionHeader(title));
      rows.add(() => const SizedBox(height: InstriqSpacing.sm));
      for (final item in items) {
        rows.add(() => row(item));
        rows.add(() => const SizedBox(height: InstriqSpacing.sm));
      }
      rows.add(() => const SizedBox(height: InstriqSpacing.md));
    }

    // Procediments primer: és la porta a tota la resta (2.0).
    addSection<Procedure>(l10n.proceduresTitle, results.procedures, (p) => InstriqListItem(
          icon: Icons.medical_services_outlined,
          title: p.name,
          subtitle: p.description,
          onTap: () => _pushWithRole(
            p.workspaceId,
            (role) => ProcedureDetailScreen(procedureId: p.id, workspaceId: p.workspaceId, myRole: role),
          ),
        ));
    addSection<Instrument>(l10n.homeSectionInstruments, results.instruments, (i) => InstriqListItem(
          icon: Icons.build_outlined,
          title: i.name.forLanguageCode(languageCode),
          onTap: () => _push(InstrumentDetailScreen(instrument: i)),
        ));
    addSection<GroupDocument>(l10n.homeSectionTechniques, results.techniques, (d) => InstriqListItem(
          icon: Icons.menu_book_outlined,
          title: d.publishedVersion?.title ?? l10n.unpublished,
          onTap: () =>
              _pushWithRole(d.workspaceId, (role) => GroupDocumentDetailScreen(document: d, myRole: role)),
        ));
    addSection<GroupDocument>(l10n.homeSectionProtocols, results.protocols, (d) => InstriqListItem(
          icon: Icons.fact_check_outlined,
          title: d.publishedVersion?.title ?? l10n.unpublished,
          onTap: () =>
              _pushWithRole(d.workspaceId, (role) => GroupDocumentDetailScreen(document: d, myRole: role)),
        ));
    addSection<Tray>(l10n.homeSectionTrays, results.trays, (t) => InstriqListItem(
          icon: Icons.inventory_2_outlined,
          title: t.publishedVersion?.name ?? l10n.unpublished,
          onTap: () => _pushWithRole(t.workspaceId, (role) => TrayDetailScreen(tray: t, myRole: role)),
        ));
    addSection<CustomInstrument>(l10n.homeSectionCustomInstruments, results.customInstruments, (i) => InstriqListItem(
          icon: Icons.precision_manufacturing_outlined,
          title: i.name,
          onTap: () =>
              _pushWithRole(i.workspaceId, (role) => CustomInstrumentDetailScreen(instrument: i, myRole: role)),
        ));
    addSection<PublicInstrument>(l10n.publicLibraryTitle, results.publicInstruments, (i) => InstriqListItem(
          icon: Icons.precision_manufacturing_outlined,
          title: i.publishedVersion?.name ?? l10n.unpublished,
          onTap: () => _push(PublicEntityDetailScreen.instrument(instrument: i)),
        ));
    addSection<Manufacturer>(l10n.homeSectionManufacturers, results.manufacturers, (m) => InstriqListItem(
          icon: Icons.precision_manufacturing_outlined,
          title: m.name,
          onTap: () => _push(ManufacturerDetailScreen(manufacturer: m)),
        ));
    addSection<Surgeon>(l10n.homeSectionSurgeons, results.surgeons, (s) => InstriqListItem(
          icon: Icons.person_outline,
          title: s.name,
          onTap: () => _push(SurgeonDetailScreen(surgeon: s)),
        ));
    addSection<Tag>(l10n.homeSectionTags, results.tags, (t) => InstriqListItem(
          icon: Icons.label_outline,
          title: t.name,
          onTap: () => _push(TagDetailScreen(tag: t)),
        ));

    return ListView.builder(
      padding: const EdgeInsets.all(InstriqSpacing.lg),
      itemCount: rows.length,
      itemBuilder: (context, index) => rows[index](),
    );
  }
}
