import 'dart:async';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/instruments_data.dart';
import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_section_header.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/favorite_entry.dart';
import '../models/group_document.dart';
import '../models/instrument.dart';
import '../models/instrument_sterilization.dart';
import '../models/manufacturer.dart';
import '../models/surgeon.dart';
import '../models/tag.dart';
import '../models/tray.dart';
import '../models/work_mode.dart';
import '../models/workspace.dart';
import '../models/workspace_role.dart';
import '../services/auth_service.dart';
import '../services/custom_instrument_service.dart';
import '../services/favorites_service.dart';
import '../services/group_document_service.dart';
import '../services/manufacturer_service.dart';
import '../services/profile_service.dart';
import '../services/recent_activity_service.dart';
import '../services/specialty_service.dart';
import '../services/sterilization_service.dart';
import '../services/surgeon_service.dart';
import '../services/tag_service.dart';
import '../services/tray_service.dart';
import '../services/usage_analytics_service.dart';
import '../services/workspace_service.dart';
import '../utils/ref_resolver.dart';
import '../widgets/sterilization_method_label.dart';
import 'catalog_screen.dart';
import 'custom_instrument_detail_screen.dart';
import 'group_document_detail_screen.dart';
import 'group_document_list_screen.dart';
import 'group_document_review_queue_screen.dart';
import 'instrument_detail_screen.dart';
import 'learn_screen.dart';
import 'manufacturer_detail_screen.dart';
import 'progress_screen.dart';
import 'surgeon_detail_screen.dart';
import 'tag_detail_screen.dart';
import 'tray_detail_screen.dart';
import 'trays_screen.dart';
import 'workspace_list_screen.dart';

/// Orden de secciones de la pantalla de Inicio (sin búsqueda activa) según el
/// modo de trabajo — mismo espíritu que `_modeSectionOrder` en
/// lib/models/work_mode.dart, pero para las secciones del Home en vez de las
/// de una ficha de instrumento.
enum HomeSectionKey { quickAccess, pendingApproval, recent, favorites }

const List<HomeSectionKey> _defaultHomeSectionOrder = [
  HomeSectionKey.quickAccess,
  HomeSectionKey.recent,
  HomeSectionKey.favorites,
];

/// Solo "supervisión" antepone la cola de aprobación: es el único modo cuyo
/// trabajo diario gira en torno a revisar cambios ajenos. El resto de modos
/// se quedan con el orden por defecto — no hay una razón clara para
/// reordenar quickAccess/recent/favorites entre ellos, y forzar una
/// diferencia artificial sería peor que no diferenciarlos.
List<HomeSectionKey> _sectionOrderForMode(WorkMode? mode) {
  if (mode == WorkMode.supervision) {
    return [HomeSectionKey.pendingApproval, ..._defaultHomeSectionOrder];
  }
  return _defaultHomeSectionOrder;
}

class _RecentOrFavoriteItem {
  final ResolvedRef ref;
  final DateTime? viewedAt;

  const _RecentOrFavoriteItem({required this.ref, this.viewedAt});
}

class _PendingApprovalItem {
  final String title;
  final bool isTray;

  const _PendingApprovalItem({required this.title, required this.isTray});
}

/// Resultado de una búsqueda en Inicio, agrupado por tipo de entidad — un
/// único cómputo que alimenta tanto el render (`_buildSearchResults`) como el
/// chequeo de "hay resultados" para la analítica de uso, así los dos nunca
/// pueden desincronizarse (EPIC 5 · Smart Search).
class _SearchResults {
  final List<Instrument> instruments;
  final List<GroupDocument> techniques;
  final List<GroupDocument> protocols;
  final List<Tray> trays;
  final List<CustomInstrument> customInstruments;
  final List<Manufacturer> manufacturers;
  final List<Surgeon> surgeons;
  final List<Tag> tags;

  const _SearchResults({
    required this.instruments,
    required this.techniques,
    required this.protocols,
    required this.trays,
    required this.customInstruments,
    required this.manufacturers,
    required this.surgeons,
    required this.tags,
  });

  bool get isEmpty =>
      instruments.isEmpty &&
      techniques.isEmpty &&
      protocols.isEmpty &&
      trays.isEmpty &&
      customInstruments.isEmpty &&
      manufacturers.isEmpty &&
      surgeons.isEmpty &&
      tags.isEmpty;
}

/// Destino "Inicio" del shell (ver navigation/app_shell.dart): cerca
/// prominente arriba de todo, con resultados agregados del catálogo global y
/// del contenido propio del grupo (todo en cliente, sin RPC nueva — ver
/// supabase/schema_v18_work_mode_favorites_recent.sql). Sin búsqueda activa,
/// muestra accesos rápidos, actividad reciente, favoritos y — en modo
/// supervisión — la cola de aprobación.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _appVersion;

  // Debounce solo para el registro de analítica de uso (ver
  // supabase/schema_v23_usage_analytics.sql) — el filtrado en vivo de
  // _buildSearchResults sigue sin debounce, tecla a tecla, para no introducir
  // latencia percibida en la búsqueda en sí.
  Timer? _searchAnalyticsDebounce;

  bool _loadingGroupContent = true;
  List<Workspace> _workspaces = [];
  List<GroupDocument> _techniques = [];
  List<GroupDocument> _protocols = [];
  List<Tray> _trays = [];
  List<CustomInstrument> _customInstruments = [];
  List<Tag> _tags = [];
  Map<String, String> _specialtyLabelById = {};
  Map<String, List<SterilizationMethod>> _catalogSterilizationMethods = {};

  bool _loadingRecentFavorites = true;
  List<_RecentOrFavoriteItem> _recent = [];
  List<_RecentOrFavoriteItem> _favorites = [];

  // Cacheada en el estado (no recreada en cada build): si no, cada setState
  // de la pantalla (p.ej. al escribir en la búsqueda y volver a vaciarla)
  // dispararía una consulta nueva a la cola de aprobación.
  Future<List<_PendingApprovalItem>>? _pendingApprovalsFuture;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
    _loadGroupContent();
    _loadRecentAndFavorites();
    // Inici vive en su propia rama del shell (ver app_shell.dart): cerrar
    // sesión desde Perfil no reconstruye este widget por sí solo, así que sin
    // este listener se quedaba mostrando el grupo y el contenido de la sesión
    // anterior hasta reiniciar la app.
    ProfileService.instance.profileRevision.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    ProfileService.instance.profileRevision.removeListener(_onProfileChanged);
    _searchAnalyticsDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onProfileChanged() {
    _pendingApprovalsFuture = null;
    _loadGroupContent();
    _loadRecentAndFavorites();
  }

  Future<void> _loadGroupContent() async {
    // Metadato de catálogo global (fabricantes, etiquetas, especialidades,
    // métodos de esterilización): disponible también en modo invitado, igual
    // que el propio catálogo de instrumentos — no depende de tener grupo, así
    // que se carga ANTES del corte por `hasHospital` de más abajo (EPIC 5 ·
    // Smart Search). Fabricantes no se guarda en el estado de Home: se busca
    // directamente sobre el caché en memoria de `ManufacturerService`
    // (`.searchByName`), esta llamada solo calienta ese caché la primera vez.
    var tags = <Tag>[];
    var specialtyLabelById = <String, String>{};
    var catalogSterilizationMethods = <String, List<SterilizationMethod>>{};
    try {
      await ManufacturerService.instance.fetchAll();
    } catch (_) {
      // Metadato accesorio de búsqueda: no bloquea el resto de Inicio si falla.
    }
    try {
      tags = await TagService.instance.fetchAll();
    } catch (_) {
      // Metadato accesorio de búsqueda: no bloquea el resto de Inicio si falla.
    }
    try {
      final specialties = await SpecialtyService.instance.fetchAll();
      specialtyLabelById = {for (final s in specialties) s.id: s.label};
    } catch (_) {
      // Metadato accesorio de búsqueda: no bloquea el resto de Inicio si falla.
    }
    try {
      catalogSterilizationMethods = await SterilizationService.instance.fetchAllCatalogMethods();
    } catch (_) {
      // Metadato accesorio de búsqueda: no bloquea el resto de Inicio si falla.
    }
    if (mounted) {
      setState(() {
        _tags = tags;
        _specialtyLabelById = specialtyLabelById;
        _catalogSterilizationMethods = catalogSterilizationMethods;
      });
    }

    if (!ProfileService.instance.hasHospital) {
      if (mounted) setState(() => _loadingGroupContent = false);
      return;
    }
    try {
      await WorkspaceService.instance.fetchWorkspaces();
      final workspaces = WorkspaceService.instance.workspaces;
      final techniques = <GroupDocument>[];
      final protocols = <GroupDocument>[];
      final trays = <Tray>[];
      final customInstruments = <CustomInstrument>[];
      for (final workspace in workspaces) {
        try {
          await GroupDocumentService.instance.fetchDocuments(DocumentKind.technique, workspace.id);
          await GroupDocumentService.instance.fetchDocuments(DocumentKind.protocol, workspace.id);
          await TrayService.instance.fetchTrays(workspace.id);
          await CustomInstrumentService.instance.fetchForWorkspace(workspace.id);
          techniques.addAll(
              GroupDocumentService.instance.documentsOfKind(DocumentKind.technique, workspace.id));
          protocols
              .addAll(GroupDocumentService.instance.documentsOfKind(DocumentKind.protocol, workspace.id));
          trays.addAll(TrayService.instance.traysOfWorkspace(workspace.id));
          customInstruments.addAll(CustomInstrumentService.instance.instruments);
        } catch (_) {
          // Un espacio fallando (sin acceso, sin conexión puntual) no debe
          // bloquear la agregación del resto de espacios.
        }
      }
      // Cirujanos: de organización, no por espacio — se carga una sola vez,
      // no dentro del bucle de arriba. No se guarda en el estado de Home
      // (mismo criterio que fabricantes): se busca sobre el caché de
      // `SurgeonService` (`.searchByName`).
      try {
        await SurgeonService.instance.fetchForOrganization();
      } catch (_) {
        // Metadato accesorio de búsqueda: no bloquea el resto de Inicio si falla.
      }

      if (!mounted) return;
      setState(() {
        _workspaces = workspaces;
        _techniques = techniques;
        _protocols = protocols;
        _trays = trays;
        _customInstruments = customInstruments;
        _loadingGroupContent = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingGroupContent = false);
    }
  }

  Future<void> _loadRecentAndFavorites() async {
    if (AuthService.instance.currentUser == null) {
      if (mounted) setState(() => _loadingRecentFavorites = false);
      return;
    }
    try {
      final recentEntries = await RecentActivityService.instance.fetchRecent(limit: 8);
      final favoriteEntries = await FavoritesService.instance.fetchFavorites();
      final recent = await _resolveEntries(recentEntries);
      final favorites = await _resolveFavorites(favoriteEntries);
      if (!mounted) return;
      setState(() {
        _recent = recent;
        _favorites = favorites;
        _loadingRecentFavorites = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingRecentFavorites = false);
    }
  }

  Future<List<_RecentOrFavoriteItem>> _resolveEntries(List<RecentViewEntry> entries) async {
    final items = <_RecentOrFavoriteItem>[];
    for (final entry in entries) {
      final resolved = await resolveRef(entry.refType, entry.refId);
      if (resolved != null) {
        items.add(_RecentOrFavoriteItem(ref: resolved, viewedAt: entry.viewedAt));
      }
    }
    return items;
  }

  Future<List<_RecentOrFavoriteItem>> _resolveFavorites(List<FavoriteEntry> entries) async {
    final items = <_RecentOrFavoriteItem>[];
    for (final entry in entries) {
      final resolved = await resolveRef(entry.refType, entry.refId);
      if (resolved != null) {
        items.add(_RecentOrFavoriteItem(ref: resolved));
      }
    }
    return items;
  }

  Future<void> _refreshAfterReturn() async {
    _pendingApprovalsFuture = null;
    await Future.wait([_loadGroupContent(), _loadRecentAndFavorites()]);
    if (mounted) setState(() {});
  }

  /// Patrón compartido de los accesos rápidos que apuntan a una colección
  /// dentro de un espacio de trabajo: si solo hay un espacio, se salta
  /// directo a la colección (sin pasar por el selector); si hay 0 o 2+, se
  /// abre WorkspaceListScreen (que a su vez colapsa igual si length == 1).
  Future<void> _openWorkspaceCollection({
    required Widget Function(Workspace workspace, WorkspaceRole? myRole) buildDirect,
  }) async {
    if (!ProfileService.instance.hasHospital) return;
    if (_workspaces.length == 1) {
      final workspace = _workspaces.first;
      final myRole = await WorkspaceService.instance.fetchMyRole(workspace.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => buildDirect(workspace, myRole)),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WorkspaceListScreen()),
      );
    }
    _refreshAfterReturn();
  }

  Future<void> _openTechniques() => _openWorkspaceCollection(
        buildDirect: (workspace, myRole) =>
            GroupDocumentListScreen(kind: DocumentKind.technique, workspace: workspace, myRole: myRole),
      );

  Future<void> _openTrays() => _openWorkspaceCollection(
        buildDirect: (workspace, myRole) => TraysScreen(workspace: workspace, myRole: myRole),
      );

  Future<void> _openInstrument(Instrument instrument) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => InstrumentDetailScreen(instrument: instrument)),
    );
  }

  Future<void> _openGroupDocument(GroupDocument document) async {
    final myRole = await WorkspaceService.instance.fetchMyRole(document.workspaceId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GroupDocumentDetailScreen(document: document, myRole: myRole)),
    );
  }

  Future<void> _openTray(Tray tray) async {
    final myRole = await WorkspaceService.instance.fetchMyRole(tray.workspaceId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TrayDetailScreen(tray: tray, myRole: myRole)),
    );
  }

  Future<void> _openCustomInstrument(CustomInstrument instrument) async {
    final myRole = await WorkspaceService.instance.fetchMyRole(instrument.workspaceId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomInstrumentDetailScreen(instrument: instrument, myRole: myRole),
      ),
    );
  }

  Future<void> _openReviewQueue() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReviewQueueScreen()),
    );
    _refreshAfterReturn();
  }

  Future<void> _openManufacturer(Manufacturer manufacturer) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ManufacturerDetailScreen(manufacturer: manufacturer)),
    );
  }

  Future<void> _openSurgeon(Surgeon surgeon) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SurgeonDetailScreen(surgeon: surgeon)),
    );
  }

  Future<void> _openTag(Tag tag) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TagDetailScreen(tag: tag)),
    );
  }

  /// Único cómputo de resultados, usado tanto por el render
  /// (`_buildSearchResults`) como por la analítica de búsqueda tras el
  /// debounce — antes eran dos listados de predicados mantenidos por
  /// separado (riesgo de desincronización), ahora es uno solo (EPIC 5).
  _SearchResults _computeSearchResults(String query, String languageCode, AppLocalizations l10n) {
    final q = query.toLowerCase();
    final instruments = kInstruments.where((i) => _matchesInstrument(i, q, languageCode, l10n)).toList();
    final techniques = _techniques.where((d) => _matchesGroupDocument(d, q)).toList();
    final protocols = _protocols.where((d) => _matchesGroupDocument(d, q)).toList();
    final trays = _trays.where((t) => _matchesTray(t, q)).toList();
    final customInstruments = _customInstruments.where((i) => _matchesCustomInstrument(i, q)).toList();
    final manufacturers = ManufacturerService.instance.searchByName(q);
    final surgeons = SurgeonService.instance.searchByName(q);
    final tags = _tags.where((t) => t.name.toLowerCase().contains(q)).toList();
    return _SearchResults(
      instruments: instruments,
      techniques: techniques,
      protocols: protocols,
      trays: trays,
      customInstruments: customInstruments,
      manufacturers: manufacturers,
      surgeons: surgeons,
      tags: tags,
    );
  }

  /// Solo cuando hay a qué organización atribuir el evento (mismo criterio de
  /// guest-gating que favoritos/recientes en esta pantalla) — evita la
  /// llamada de red para invitados aunque el RPC ya sea un no-op para ellos.
  void _scheduleSearchAnalytics(String value) {
    _searchAnalyticsDebounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    if (AuthService.instance.currentUser == null || !ProfileService.instance.hasHospital) return;
    _searchAnalyticsDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final languageCode = Localizations.localeOf(context).languageCode;
      final l10n = AppLocalizations.of(context)!;
      final results = _computeSearchResults(trimmed, languageCode, l10n);
      if (!results.isEmpty) {
        UsageAnalyticsService.instance.recordSearch(trimmed);
      } else {
        UsageAnalyticsService.instance.recordZeroResultSearch(trimmed);
      }
    });
  }

  bool _matchesInstrument(Instrument instrument, String query, String languageCode, AppLocalizations l10n) {
    return instrument.name.toLowerCase().contains(query) ||
        instrument.aliases.any((alias) => alias.toLowerCase().contains(query)) ||
        instrument.description.forLanguageCode(languageCode).toLowerCase().contains(query) ||
        instrument.use.forLanguageCode(languageCode).toLowerCase().contains(query) ||
        instrument.specialty.label.toLowerCase().contains(query) ||
        instrument.category.label.toLowerCase().contains(query) ||
        (_catalogSterilizationMethods[instrument.id] ?? const [])
            .any((m) => sterilizationMethodValueLabel(l10n, m).toLowerCase().contains(query));
  }

  /// Especialidad resuelta de una versión publicada (`specialtyId` → label,
  /// o el texto legado `specialty` si la fila todavía no se migró) — mismo
  /// criterio de fallback que usan las fichas de detalle.
  String _resolvedSpecialtyLabel(String? specialtyId, String? legacySpecialty) {
    if (specialtyId != null) return _specialtyLabelById[specialtyId] ?? '';
    return legacySpecialty ?? '';
  }

  bool _matchesGroupDocument(GroupDocument document, String query) {
    final published = document.publishedVersion;
    if (published == null) return false;
    return published.title.toLowerCase().contains(query) ||
        _resolvedSpecialtyLabel(published.specialtyId, published.specialty).toLowerCase().contains(query);
  }

  bool _matchesTray(Tray tray, String query) {
    final published = tray.publishedVersion;
    if (published == null) return false;
    return published.name.toLowerCase().contains(query) ||
        _resolvedSpecialtyLabel(published.specialtyId, published.specialty).toLowerCase().contains(query);
  }

  bool _matchesCustomInstrument(CustomInstrument instrument, String query) {
    return instrument.name.toLowerCase().contains(query) ||
        _resolvedSpecialtyLabel(instrument.specialtyId, instrument.specialty).toLowerCase().contains(query);
  }

  String _timeAgo(AppLocalizations l10n, DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return l10n.timeAgoJustNow;
    if (diff.inHours < 1) return l10n.timeAgoMinutes(diff.inMinutes);
    if (diff.inDays < 1) return l10n.timeAgoHours(diff.inHours);
    return l10n.timeAgoDays(diff.inDays);
  }

  IconData _iconForRefType(String refType) {
    switch (refType) {
      case 'catalog':
        return Icons.build_outlined;
      case 'custom':
        return Icons.precision_manufacturing_outlined;
      case 'tray':
        return Icons.inventory_2_outlined;
      case 'group_document':
      default:
        return Icons.menu_book_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: _appVersion != null
            ? Text(
                'v$_appVersion',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: InstriqSpacing.lg, vertical: InstriqSpacing.sm),
              child: TextField(
                controller: _searchController,
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
                            _searchAnalyticsDebounce?.cancel();
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
                onChanged: (value) {
                  setState(() => _query = value);
                  _scheduleSearchAnalytics(value);
                },
              ),
            ),
            Expanded(
              child: _query.isEmpty ? _buildDefaultBody(context, l10n) : _buildSearchResults(context, l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults(BuildContext context, AppLocalizations l10n) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final results = _computeSearchResults(_query, languageCode, l10n);

    if (results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(InstriqSpacing.xl),
          child: Text(l10n.homeNoResultsForQuery(_query), textAlign: TextAlign.center),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(InstriqSpacing.lg),
      children: [
        if (results.instruments.isNotEmpty) ...[
          InstriqSectionHeader(l10n.homeSectionInstruments),
          const SizedBox(height: InstriqSpacing.sm),
          for (final instrument in results.instruments) ...[
            InstriqListItem(
              icon: Icons.build_outlined,
              title: instrument.name,
              onTap: () => _openInstrument(instrument),
            ),
            const SizedBox(height: InstriqSpacing.sm),
          ],
          const SizedBox(height: InstriqSpacing.md),
        ],
        if (results.techniques.isNotEmpty) ...[
          InstriqSectionHeader(l10n.homeSectionTechniques),
          const SizedBox(height: InstriqSpacing.sm),
          for (final doc in results.techniques) ...[
            InstriqListItem(
              icon: Icons.menu_book_outlined,
              title: doc.publishedVersion?.title ?? l10n.unpublished,
              onTap: () => _openGroupDocument(doc),
            ),
            const SizedBox(height: InstriqSpacing.sm),
          ],
          const SizedBox(height: InstriqSpacing.md),
        ],
        if (results.protocols.isNotEmpty) ...[
          InstriqSectionHeader(l10n.homeSectionProtocols),
          const SizedBox(height: InstriqSpacing.sm),
          for (final doc in results.protocols) ...[
            InstriqListItem(
              icon: Icons.fact_check_outlined,
              title: doc.publishedVersion?.title ?? l10n.unpublished,
              onTap: () => _openGroupDocument(doc),
            ),
            const SizedBox(height: InstriqSpacing.sm),
          ],
          const SizedBox(height: InstriqSpacing.md),
        ],
        if (results.trays.isNotEmpty) ...[
          InstriqSectionHeader(l10n.homeSectionTrays),
          const SizedBox(height: InstriqSpacing.sm),
          for (final tray in results.trays) ...[
            InstriqListItem(
              icon: Icons.inventory_2_outlined,
              title: tray.publishedVersion?.name ?? l10n.unpublished,
              onTap: () => _openTray(tray),
            ),
            const SizedBox(height: InstriqSpacing.sm),
          ],
          const SizedBox(height: InstriqSpacing.md),
        ],
        if (results.customInstruments.isNotEmpty) ...[
          InstriqSectionHeader(l10n.homeSectionCustomInstruments),
          const SizedBox(height: InstriqSpacing.sm),
          for (final instrument in results.customInstruments) ...[
            InstriqListItem(
              icon: Icons.precision_manufacturing_outlined,
              title: instrument.name,
              onTap: () => _openCustomInstrument(instrument),
            ),
            const SizedBox(height: InstriqSpacing.sm),
          ],
          const SizedBox(height: InstriqSpacing.md),
        ],
        if (results.manufacturers.isNotEmpty) ...[
          InstriqSectionHeader(l10n.homeSectionManufacturers),
          const SizedBox(height: InstriqSpacing.sm),
          for (final manufacturer in results.manufacturers) ...[
            InstriqListItem(
              icon: Icons.precision_manufacturing_outlined,
              title: manufacturer.name,
              onTap: () => _openManufacturer(manufacturer),
            ),
            const SizedBox(height: InstriqSpacing.sm),
          ],
          const SizedBox(height: InstriqSpacing.md),
        ],
        if (results.surgeons.isNotEmpty) ...[
          InstriqSectionHeader(l10n.homeSectionSurgeons),
          const SizedBox(height: InstriqSpacing.sm),
          for (final surgeon in results.surgeons) ...[
            InstriqListItem(
              icon: Icons.person_outline,
              title: surgeon.name,
              onTap: () => _openSurgeon(surgeon),
            ),
            const SizedBox(height: InstriqSpacing.sm),
          ],
          const SizedBox(height: InstriqSpacing.md),
        ],
        if (results.tags.isNotEmpty) ...[
          InstriqSectionHeader(l10n.homeSectionTags),
          const SizedBox(height: InstriqSpacing.sm),
          for (final tag in results.tags) ...[
            InstriqListItem(
              icon: Icons.label_outline,
              title: tag.name,
              onTap: () => _openTag(tag),
            ),
            const SizedBox(height: InstriqSpacing.sm),
          ],
        ],
      ],
    );
  }

  Widget _buildDefaultBody(BuildContext context, AppLocalizations l10n) {
    final order = _sectionOrderForMode(ProfileService.instance.activeWorkModeNotifier.value);
    final sections = <Widget>[];
    for (final key in order) {
      final section = switch (key) {
        HomeSectionKey.quickAccess => _buildQuickAccessSection(context, l10n),
        HomeSectionKey.pendingApproval => _buildPendingApprovalSection(context, l10n),
        HomeSectionKey.recent => _buildRecentSection(context, l10n),
        HomeSectionKey.favorites => _buildFavoritesSection(context, l10n),
      };
      if (section != null) {
        sections.add(section);
        sections.add(const SizedBox(height: InstriqSpacing.xl));
      }
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: InstriqSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: sections),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context, AppLocalizations l10n) {
    final hasHospital = ProfileService.instance.hasHospital;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InstriqSectionHeader(l10n.homeQuickAccessTitle),
        const SizedBox(height: InstriqSpacing.md),
        InstriqListItem(
          icon: Icons.menu_book,
          title: l10n.catalogTitle,
          subtitle: l10n.catalogSubtitle,
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CatalogScreen()));
          },
        ),
        if (hasHospital) ...[
          const SizedBox(height: InstriqSpacing.sm),
          InstriqListItem(
            icon: Icons.menu_book_outlined,
            title: l10n.techniquesTitle,
            // Mientras se cargan los espacios, se asume que hay más de uno
            // (fallback seguro): _openTechniques abre el listado de espacios
            // en vez del único espacio si _workspaces todavía está vacío.
            subtitle: _loadingGroupContent ? null : l10n.techniquesSubtitle,
            onTap: _openTechniques,
          ),
          const SizedBox(height: InstriqSpacing.sm),
          InstriqListItem(
            icon: Icons.inventory_2_outlined,
            title: l10n.traysTitle,
            subtitle: l10n.traysSubtitle,
            onTap: _openTrays,
          ),
        ],
        const SizedBox(height: InstriqSpacing.sm),
        // No existe todavía una pantalla dedicada de esterilización — el
        // contenido de esterilización vive hoy dentro de la ficha de cada
        // instrumento del catálogo (ver instrument_detail_screen.dart), así
        // que este acceso apunta ahí en vez de a una pantalla nueva.
        InstriqListItem(
          icon: Icons.cleaning_services_outlined,
          title: l10n.sterilizationSectionTitle,
          subtitle: l10n.homeSterilizationSubtitle,
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CatalogScreen()));
          },
        ),
        const SizedBox(height: InstriqSpacing.sm),
        InstriqListItem(
          icon: Icons.school,
          title: l10n.learnTitle,
          subtitle: l10n.learnSubtitle,
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LearnScreen()));
          },
        ),
        const SizedBox(height: InstriqSpacing.sm),
        InstriqListItem(
          icon: Icons.bar_chart,
          title: l10n.myProgressTitle,
          subtitle: l10n.myProgressSubtitle,
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgressScreen()));
          },
        ),
      ],
    );
  }

  Widget? _buildPendingApprovalSection(BuildContext context, AppLocalizations l10n) {
    // La cola de aprobación es de todo el grupo, no por espacio: se reutiliza
    // el mismo criterio de acceso que ya usa ReviewQueueScreen/ActivityScreen
    // (`ProfileService.isAdmin` hace de "aprobador" hasta que exista un rol
    // Approver a nivel de hospital, no solo por espacio).
    if (!ProfileService.instance.isAdmin) return null;
    _pendingApprovalsFuture ??= _fetchPendingApprovals();
    return FutureBuilder<List<_PendingApprovalItem>>(
      future: _pendingApprovalsFuture,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const [];
        if (snapshot.connectionState == ConnectionState.done && items.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: InstriqSectionHeader(l10n.homePendingApprovalTitle)),
                TextButton(onPressed: _openReviewQueue, child: Text(l10n.homeViewAllLabel)),
              ],
            ),
            if (snapshot.connectionState != ConnectionState.done)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: InstriqSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              for (final item in items) ...[
                InstriqListItem(
                  icon: item.isTray ? Icons.inventory_2_outlined : Icons.pending_actions,
                  title: item.title,
                  onTap: _openReviewQueue,
                ),
                const SizedBox(height: InstriqSpacing.sm),
              ],
          ],
        );
      },
    );
  }

  Future<List<_PendingApprovalItem>> _fetchPendingApprovals() async {
    final docs = await GroupDocumentService.instance.fetchReviewQueue();
    final trays = await TrayService.instance.fetchReviewQueue();
    final items = <_PendingApprovalItem>[
      ...docs.map((v) => _PendingApprovalItem(title: v.title, isTray: false)),
      ...trays.map((v) => _PendingApprovalItem(title: v.name, isTray: true)),
    ];
    return items.take(5).toList();
  }

  Widget? _buildRecentSection(BuildContext context, AppLocalizations l10n) {
    if (AuthService.instance.currentUser == null) return null;
    if (_loadingRecentFavorites) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InstriqSectionHeader(l10n.homeRecentActivityTitle),
          const SizedBox(height: InstriqSpacing.md),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (_recent.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InstriqSectionHeader(l10n.homeRecentActivityTitle),
        const SizedBox(height: InstriqSpacing.md),
        for (final item in _recent) ...[
          InstriqListItem(
            icon: _iconForRefType(item.ref.refType),
            title: item.ref.title,
            subtitle: item.viewedAt != null ? _timeAgo(l10n, item.viewedAt!) : null,
            onTap: () => navigateToResolvedRef(context, item.ref),
          ),
          const SizedBox(height: InstriqSpacing.sm),
        ],
      ],
    );
  }

  Widget? _buildFavoritesSection(BuildContext context, AppLocalizations l10n) {
    if (AuthService.instance.currentUser == null) return null;
    if (_loadingRecentFavorites) return null;
    if (_favorites.isEmpty) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InstriqSectionHeader(l10n.homeFavoritesTitle),
        const SizedBox(height: InstriqSpacing.md),
        for (final item in _favorites) ...[
          InstriqListItem(
            icon: _iconForRefType(item.ref.refType),
            title: item.ref.title,
            onTap: () => navigateToResolvedRef(context, item.ref),
          ),
          const SizedBox(height: InstriqSpacing.sm),
        ],
      ],
    );
  }
}
