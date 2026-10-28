import 'dart:async';

import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_responsive_content.dart';
import '../design_system/components/instriq_section_header.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/favorite_entry.dart';
import '../models/group_document.dart';
import '../models/instrument.dart';
import '../models/instrument_sterilization.dart';
import '../models/manufacturer.dart';
import '../models/public_instrument.dart';
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
import '../services/public_instrument_service.dart';
import '../services/recent_activity_service.dart';
import '../services/specialty_service.dart';
import '../services/sterilization_service.dart';
import '../services/surgeon_service.dart';
import '../services/tag_service.dart';
import '../services/tray_preparation_service.dart';
import '../services/tray_service.dart';
import '../services/usage_analytics_service.dart';
import '../services/workspace_service.dart';
import '../utils/fuzzy_match.dart';
import '../utils/ref_resolver.dart';
import '../widgets/create_content_sheet.dart';
import '../widgets/sterilization_method_label.dart';
import 'catalog_screen.dart';
import 'custom_instrument_detail_screen.dart';
import 'group_document_detail_screen.dart';
import 'group_document_list_screen.dart';
import 'group_document_review_queue_screen.dart';
import 'home_dashboard_panel.dart';
import 'instrument_detail_screen.dart';
import 'learn_screen.dart';
import 'manufacturer_detail_screen.dart';
import 'preference_cards_screen.dart';
import 'progress_screen.dart';
import 'public_entity_detail_screen.dart';
import 'surgeon_detail_screen.dart';
import 'tag_detail_screen.dart';
import 'team_progress_screen.dart';
import 'tray_detail_screen.dart';
import 'trays_screen.dart';
import 'workspace_list_screen.dart';

/// Orden de secciones de la pantalla de Inicio (sin búsqueda activa) según el
/// modo de trabajo — mismo espíritu que `_modeSectionOrder` en
/// lib/models/work_mode.dart, pero para las secciones del Home en vez de las
/// de una ficha de instrumento.
enum HomeSectionKey { quickAccess, pendingApproval, traysToPrepare, teamProgress, recent, favorites }

const List<HomeSectionKey> _defaultHomeSectionOrder = [
  HomeSectionKey.quickAccess,
  HomeSectionKey.recent,
  HomeSectionKey.favorites,
];

/// "Supervisión" antepone la cola de aprobación e "instrumentista" las
/// bandejas por preparar: son los dos únicos modos cuyo trabajo diario gira
/// en torno a una lista de pendientes muy concreta. El resto de modos se
/// quedan con el orden por defecto — no hay una razón clara para reordenar
/// quickAccess/recent/favorites entre ellos, y forzar una diferencia
/// artificial sería peor que no diferenciarlos.
List<HomeSectionKey> _sectionOrderForMode(WorkMode? mode) {
  if (mode == WorkMode.supervision) {
    return [HomeSectionKey.pendingApproval, ..._defaultHomeSectionOrder];
  }
  if (mode == WorkMode.instrumentista) {
    return [HomeSectionKey.traysToPrepare, ..._defaultHomeSectionOrder];
  }
  if (mode == WorkMode.docente) {
    return [HomeSectionKey.teamProgress, ..._defaultHomeSectionOrder];
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
  final List<PublicInstrument> publicInstruments;
  final List<Manufacturer> manufacturers;
  final List<Surgeon> surgeons;
  final List<Tag> tags;

  const _SearchResults({
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

  // Debounce para el registro de analítica de uso (ver
  // supabase/schema_v23_usage_analytics.sql) -- deliberadamente más largo que
  // el del filtrado en vivo, no hace falta registrar cada tecla intermedia.
  Timer? _searchAnalyticsDebounce;

  // El filtrado en vivo también lleva un debounce corto (por debajo del
  // umbral de percepción humana, ~150ms) desde que _computeSearchResults
  // pasó a recorrer también todo el contenido de espacio agregado (no solo
  // el catálogo): sin él, cada tecla repetía un escaneo difuso completo del
  // catálogo (118 instrumentos) más técnicas/protocolos/safates/instrumental
  // de todos los espacios del usuario, de forma síncrona dentro de build().
  Timer? _liveSearchDebounce;

  bool _loadingGroupContent = true;
  List<Workspace> _workspaces = [];
  List<GroupDocument> _techniques = [];
  List<GroupDocument> _protocols = [];
  List<Tray> _trays = [];
  List<CustomInstrument> _customInstruments = [];
  List<PublicInstrument> _publicInstruments = [];
  List<Tag> _tags = [];
  Map<String, String> _specialtyLabelById = {};
  Map<String, List<SterilizationMethod>> _catalogSterilizationMethods = {};
  Map<String, DateTime> _lastPreparedAtByTray = {};

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
    _loadGroupContent();
    _loadRecentAndFavorites();
    // Inici vive en su propia rama del shell (ver app_shell.dart): cerrar
    // sesión desde Perfil no reconstruye este widget por sí solo, así que sin
    // este listener se quedaba mostrando el grupo y el contenido de la sesión
    // anterior hasta reiniciar la app.
    ProfileService.instance.profileRevision.addListener(_onProfileChanged);
    // `setActiveWorkMode` no toca `profileRevision` (es solo una preferencia
    // de visualización, no justifica recargar todo el contenido de grupo) --
    // sin este listener propio, las secciones condicionadas por modo
    // (bandejas por preparar, cola de aprobación...) no se reordenaban al
    // cambiar de modo desde WorkModeHeader hasta que algo más disparaba un
    // rebuild por otro motivo.
    ProfileService.instance.activeWorkModeNotifier.addListener(_onWorkModeChanged);
  }

  @override
  void dispose() {
    ProfileService.instance.profileRevision.removeListener(_onProfileChanged);
    ProfileService.instance.activeWorkModeNotifier.removeListener(_onWorkModeChanged);
    _searchAnalyticsDebounce?.cancel();
    _liveSearchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onProfileChanged() {
    _pendingApprovalsFuture = null;
    _loadGroupContent();
    _loadRecentAndFavorites();
  }

  void _onWorkModeChanged() => setState(() {});

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
    var publicInstruments = <PublicInstrument>[];
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
    try {
      // Instrumental de la Biblioteca Pública: contenido comunitario, igual
      // de disponible en modo invitado que el resto de metadatos de aquí.
      publicInstruments = await PublicInstrumentService.instance.fetchPublished();
    } catch (_) {
      // Metadato accesorio de búsqueda: no bloquea el resto de Inicio si falla.
    }
    if (mounted) {
      setState(() {
        _tags = tags;
        _specialtyLabelById = specialtyLabelById;
        _catalogSterilizationMethods = catalogSterilizationMethods;
        _publicInstruments = publicInstruments;
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

      // Para el modo Instrumentista (sección "Bandejas por preparar"): una
      // sola consulta por lotes de cuándo se preparó cada bandeja publicada,
      // no N+1. Las bandejas sin versión publicada nunca pueden tener una
      // sesión de preparación (create_tray_preparation_session lo rechaza),
      // así que se excluyen de la consulta.
      var lastPreparedAtByTray = <String, DateTime>{};
      try {
        final publishedTrayIds =
            trays.where((t) => t.publishedVersionId != null).map((t) => t.id).toList();
        lastPreparedAtByTray =
            await TrayPreparationService.instance.fetchLastPreparedAtByTray(publishedTrayIds);
      } catch (_) {
        // Metadato accesorio de la sección de Instrumentista: no bloquea el
        // resto de Inicio si falla.
      }

      if (!mounted) return;
      setState(() {
        _workspaces = workspaces;
        _techniques = techniques;
        _protocols = protocols;
        _trays = trays;
        _customInstruments = customInstruments;
        _lastPreparedAtByTray = lastPreparedAtByTray;
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

  Future<void> _openPreferenceCards() => _openWorkspaceCollection(
        buildDirect: (workspace, myRole) => PreferenceCardsScreen(workspace: workspace, myRole: myRole),
      );

  Future<void> _openProtocols() => _openWorkspaceCollection(
        buildDirect: (workspace, myRole) =>
            GroupDocumentListScreen(kind: DocumentKind.protocol, workspace: workspace, myRole: myRole),
      );

  /// Bandejas publicadas ordenadas para el modo Instrumentista: primero las
  /// que nunca se han preparado, luego de más antigua a más reciente
  /// preparación — una heurística de prioridad razonable, no una caducidad
  /// real (el esquema actual no modela una fecha de caducidad de
  /// esterilización por bandeja, solo lo que sí se ha preparado).
  List<Tray> _traysNeedingPrep() {
    final published = _trays.where((t) => t.publishedVersionId != null).toList();
    published.sort((a, b) {
      final aAt = _lastPreparedAtByTray[a.id];
      final bAt = _lastPreparedAtByTray[b.id];
      if (aAt == null && bAt == null) return 0;
      if (aAt == null) return -1;
      if (bAt == null) return 1;
      return aAt.compareTo(bAt);
    });
    return published;
  }

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

  Future<void> _openTeamProgress() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TeamProgressScreen()),
    );
  }

  Future<void> _openReviewQueue() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReviewQueueScreen()),
    );
    _refreshAfterReturn();
  }

  Future<void> _openPublicInstrument(PublicInstrument instrument) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicEntityDetailScreen.instrument(instrument: instrument)),
    );
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
    final publicInstruments = _publicInstruments.where((i) => _matchesPublicInstrument(i, q)).toList();
    final manufacturers = ManufacturerService.instance.searchByName(q);
    final surgeons = SurgeonService.instance.searchByName(q);
    final tags = _tags.where((t) => fuzzyContains(t.name, q)).toList();
    return _SearchResults(
      instruments: instruments,
      techniques: techniques,
      protocols: protocols,
      trays: trays,
      customInstruments: customInstruments,
      publicInstruments: publicInstruments,
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
    return fuzzyContains(instrument.name.forLanguageCode(languageCode), query) ||
        instrument.aliases.any((alias) => fuzzyContains(alias, query)) ||
        fuzzyContains(instrument.description.forLanguageCode(languageCode), query) ||
        fuzzyContains(instrument.use.forLanguageCode(languageCode), query) ||
        fuzzyContains(instrument.specialty.label(l10n), query) ||
        fuzzyContains(instrument.category.label(l10n), query) ||
        (_catalogSterilizationMethods[instrument.id] ?? const [])
            .any((m) => fuzzyContains(sterilizationMethodValueLabel(l10n, m), query));
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
    return fuzzyContains(published.title, query) ||
        fuzzyContains(_resolvedSpecialtyLabel(published.specialtyId, published.specialty), query);
  }

  bool _matchesTray(Tray tray, String query) {
    final published = tray.publishedVersion;
    if (published == null) return false;
    return fuzzyContains(published.name, query) ||
        fuzzyContains(_resolvedSpecialtyLabel(published.specialtyId, published.specialty), query);
  }

  bool _matchesCustomInstrument(CustomInstrument instrument, String query) {
    return fuzzyContains(instrument.name, query) ||
        fuzzyContains(_resolvedSpecialtyLabel(instrument.specialtyId, instrument.specialty), query);
  }

  bool _matchesPublicInstrument(PublicInstrument instrument, String query) {
    final published = instrument.publishedVersion;
    if (published == null) return false;
    return fuzzyContains(published.name ?? '', query) ||
        fuzzyContains(_resolvedSpecialtyLabel(published.specialtyId, null), query);
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
    // Panel de escritorio (ver home_dashboard_panel.dart): solo sustituye el
    // cuerpo por defecto (sin búsqueda activa) en ventanas de clase PC, y
    // solo para quien ya tiene acceso a los datos que agrega (mismo gate que
    // ya usa cada pantalla destino) — para cualquier otro caso, Inici se
    // comporta exactamente igual que antes, tablet incluida.
    final showDashboard = _query.isEmpty &&
        MediaQuery.sizeOf(context).width >= InstriqBreakpoints.desktop &&
        ProfileService.instance.hasHospital &&
        (ProfileService.instance.isAdmin || ProfileService.instance.canApproveAnyWorkspace);
    final content = Column(
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
                        _liveSearchDebounce?.cancel();
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                    ),
            ),
            onChanged: (value) {
              _liveSearchDebounce?.cancel();
              _liveSearchDebounce = Timer(const Duration(milliseconds: 150), () {
                if (!mounted) return;
                setState(() => _query = value);
              });
              _scheduleSearchAnalytics(value);
            },
          ),
        ),
        Expanded(
          child: _query.isNotEmpty
              ? _buildSearchResults(context, l10n)
              : showDashboard
                  ? const HomeDashboardPanel()
                  : _buildDefaultBody(context, l10n),
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: showDashboard ? content : InstriqResponsiveContent(child: content),
      ),
      floatingActionButton: ProfileService.instance.hasHospital &&
              (ProfileService.instance.isAdmin || ProfileService.instance.canEditAnyWorkspace) &&
              !showDashboard
          ? FloatingActionButton(
              tooltip: l10n.createContentFabTooltip,
              onPressed: () => showCreateContentSheet(context),
              child: const Icon(Icons.add),
            )
          : null,
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

    // ListView.builder en vez de ListView(children: [...]): con una query
    // amplia (p. ex. una sola lletra) els resultats sumats de les 9
    // categories poden ser desenes d'ítems -- construir-los tots de cop en
    // comptes de perezosament en fer scroll era un cost evitable.
    final rows = <Widget Function()>[];
    void addSection(String title, Iterable<Widget Function()> items) {
      if (items.isEmpty) return;
      rows.add(() => InstriqSectionHeader(title));
      rows.add(() => const SizedBox(height: InstriqSpacing.sm));
      for (final build in items) {
        rows.add(build);
        rows.add(() => const SizedBox(height: InstriqSpacing.sm));
      }
      rows.add(() => const SizedBox(height: InstriqSpacing.md));
    }

    addSection(
      l10n.homeSectionInstruments,
      results.instruments.map(
        (instrument) => () => InstriqListItem(
              icon: Icons.build_outlined,
              title: instrument.name.forLanguageCode(languageCode),
              onTap: () => _openInstrument(instrument),
            ),
      ),
    );
    addSection(
      l10n.homeSectionTechniques,
      results.techniques.map(
        (doc) => () => InstriqListItem(
              icon: Icons.menu_book_outlined,
              title: doc.publishedVersion?.title ?? l10n.unpublished,
              onTap: () => _openGroupDocument(doc),
            ),
      ),
    );
    addSection(
      l10n.homeSectionProtocols,
      results.protocols.map(
        (doc) => () => InstriqListItem(
              icon: Icons.fact_check_outlined,
              title: doc.publishedVersion?.title ?? l10n.unpublished,
              onTap: () => _openGroupDocument(doc),
            ),
      ),
    );
    addSection(
      l10n.homeSectionTrays,
      results.trays.map(
        (tray) => () => InstriqListItem(
              icon: Icons.inventory_2_outlined,
              title: tray.publishedVersion?.name ?? l10n.unpublished,
              onTap: () => _openTray(tray),
            ),
      ),
    );
    addSection(
      l10n.homeSectionCustomInstruments,
      results.customInstruments.map(
        (instrument) => () => InstriqListItem(
              icon: Icons.precision_manufacturing_outlined,
              title: instrument.name,
              onTap: () => _openCustomInstrument(instrument),
            ),
      ),
    );
    addSection(
      l10n.publicLibraryTitle,
      results.publicInstruments.map(
        (instrument) => () => InstriqListItem(
              icon: Icons.precision_manufacturing_outlined,
              title: instrument.publishedVersion?.name ?? l10n.unpublished,
              onTap: () => _openPublicInstrument(instrument),
            ),
      ),
    );
    addSection(
      l10n.homeSectionManufacturers,
      results.manufacturers.map(
        (manufacturer) => () => InstriqListItem(
              icon: Icons.precision_manufacturing_outlined,
              title: manufacturer.name,
              onTap: () => _openManufacturer(manufacturer),
            ),
      ),
    );
    addSection(
      l10n.homeSectionSurgeons,
      results.surgeons.map(
        (surgeon) => () => InstriqListItem(
              icon: Icons.person_outline,
              title: surgeon.name,
              onTap: () => _openSurgeon(surgeon),
            ),
      ),
    );
    addSection(
      l10n.homeSectionTags,
      results.tags.map(
        (tag) => () => InstriqListItem(
              icon: Icons.label_outline,
              title: tag.name,
              onTap: () => _openTag(tag),
            ),
      ),
    );

    return ListView.builder(
      padding: const EdgeInsets.all(InstriqSpacing.lg),
      itemCount: rows.length,
      itemBuilder: (context, index) => rows[index](),
    );
  }

  Widget _buildDefaultBody(BuildContext context, AppLocalizations l10n) {
    final mode = ProfileService.instance.activeWorkModeNotifier.value;
    final order = _sectionOrderForMode(mode);
    final sections = <Widget>[];
    for (final key in order) {
      final section = switch (key) {
        HomeSectionKey.quickAccess => _buildQuickAccessSection(context, l10n, mode),
        HomeSectionKey.pendingApproval => _buildPendingApprovalSection(context, l10n),
        HomeSectionKey.traysToPrepare => _buildTrayPrepSection(context, l10n),
        HomeSectionKey.teamProgress => _buildTeamProgressSection(context, l10n),
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

  Widget _buildQuickAccessSection(BuildContext context, AppLocalizations l10n, WorkMode? mode) {
    final hasHospital = ProfileService.instance.hasHospital;
    final techniquesAndTrays = [
      InstriqListItem(
        icon: Icons.menu_book_outlined,
        title: l10n.techniquesTitle,
        // Mientras se cargan los espacios, se asume que hay más de uno
        // (fallback seguro): _openTechniques abre el listado de espacios
        // en vez del único espacio si _workspaces todavía está vacío.
        subtitle: _loadingGroupContent ? null : l10n.techniquesSubtitle,
        onTap: _openTechniques,
      ),
      InstriqListItem(
        icon: Icons.inventory_2_outlined,
        title: l10n.traysTitle,
        subtitle: l10n.traysSubtitle,
        onTap: _openTrays,
      ),
    ];
    // Fichas de preferencia y protocolos no tenían ningún acceso rápido desde
    // Inicio hasta ahora, para ningún modo — se añaden para todos, pero en
    // modo Cirujano van primero (antes que técnicas/bandejas): es lo que más
    // consulta un cirujano al abrir la app.
    final preferenceCardsAndProtocols = [
      InstriqListItem(
        icon: Icons.assignment_outlined,
        title: l10n.preferenceCardsTitle,
        subtitle: l10n.preferenceCardsSubtitle,
        onTap: _openPreferenceCards,
      ),
      InstriqListItem(
        icon: Icons.fact_check_outlined,
        title: l10n.protocolsTitle,
        subtitle: l10n.protocolsSubtitle,
        onTap: _openProtocols,
      ),
    ];
    final groupItems = mode == WorkMode.cirujano
        ? [...preferenceCardsAndProtocols, ...techniquesAndTrays]
        : [...techniquesAndTrays, ...preferenceCardsAndProtocols];
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
        if (hasHospital)
          for (final item in groupItems) ...[
            const SizedBox(height: InstriqSpacing.sm),
            item,
          ],
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
    // La cola de aprobación es de todo el grupo, no por espacio: mismo
    // criterio de acceso que ya usa ReviewQueueScreen/ActivityScreen -- un
    // approver de espacio (no necesariamente admin de organización) también
    // debe ver esta sección, no solo `isAdmin`.
    if (!ProfileService.instance.isAdmin && !ProfileService.instance.canApproveAnyWorkspace) return null;
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

  /// Solo para el modo Instrumentista -- no depende de ningún rol de espacio
  /// (cualquier miembro, incluso lector, puede ya crear una sesión de
  /// preparación hoy), así que no hace falta más gate que el propio modo.
  Widget? _buildTrayPrepSection(BuildContext context, AppLocalizations l10n) {
    if (_loadingGroupContent) return null;
    final trays = _traysNeedingPrep();
    if (trays.isEmpty) return null;
    final preview = trays.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: InstriqSectionHeader(l10n.homeTraysToPrepareTitle)),
            TextButton(onPressed: _openTrays, child: Text(l10n.homeViewAllLabel)),
          ],
        ),
        const SizedBox(height: InstriqSpacing.md),
        for (final tray in preview) ...[
          InstriqListItem(
            icon: Icons.inventory_2_outlined,
            title: tray.publishedVersion?.name ?? l10n.unpublished,
            subtitle: _lastPreparedAtByTray[tray.id] != null
                ? _timeAgo(l10n, _lastPreparedAtByTray[tray.id]!)
                : l10n.homeTrayNeverPrepared,
            onTap: () => _openTray(tray),
          ),
          const SizedBox(height: InstriqSpacing.sm),
        ],
      ],
    );
  }

  /// Solo para modo Docente, y solo si ya se tiene autoridad real de
  /// supervisión en algún espacio (mismo gate que la cola de aprobación /
  /// HomeDashboardPanel) -- este gate de UI es solo conveniencia, el límite
  /// de seguridad real vive en la propia función `team_learning_progress`.
  /// Es un simple enlace de navegación, no una vista previa con datos: el
  /// trabajo de elegir equipo y ver el progreso vive en TeamProgressScreen.
  Widget? _buildTeamProgressSection(BuildContext context, AppLocalizations l10n) {
    if (!ProfileService.instance.isAdmin && !ProfileService.instance.canApproveAnyWorkspace) return null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InstriqSectionHeader(l10n.homeTeamProgressTitle),
        const SizedBox(height: InstriqSpacing.md),
        InstriqListItem(
          icon: Icons.groups_outlined,
          title: l10n.homeTeamProgressTitle,
          onTap: _openTeamProgress,
        ),
      ],
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

  String _groupLabelForRefType(AppLocalizations l10n, String refType) {
    switch (refType) {
      case 'catalog':
        return l10n.catalogTitle;
      case 'custom':
        return l10n.customInstrumentsTitle;
      case 'tray':
        return l10n.traysTitle;
      case 'group_document':
      default:
        return l10n.techniquesTitle;
    }
  }

  Widget? _buildFavoritesSection(BuildContext context, AppLocalizations l10n) {
    if (AuthService.instance.currentUser == null) return null;
    if (_loadingRecentFavorites) return null;
    if (_favorites.isEmpty) return null;

    // Agrupados por tipo de contenido (no una lista plana): con favoritos de
    // instrumentos, técnicas y bandejas mezclados, encontrar uno concreto se
    // hacía lento de escanear. El orden de grupo sigue el mismo criterio que
    // _iconForRefType (catálogo, personalizado, bandejas, técnicas/resto).
    final byType = <String, List<_RecentOrFavoriteItem>>{};
    for (final item in _favorites) {
      byType.putIfAbsent(item.ref.refType, () => []).add(item);
    }
    const typeOrder = ['catalog', 'custom', 'tray', 'group_document'];
    final orderedTypes = [
      ...typeOrder.where(byType.containsKey),
      ...byType.keys.where((t) => !typeOrder.contains(t)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InstriqSectionHeader(l10n.homeFavoritesTitle),
        const SizedBox(height: InstriqSpacing.md),
        for (final refType in orderedTypes) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: InstriqSpacing.sm),
            child: Text(
              _groupLabelForRefType(l10n, refType),
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          for (final item in byType[refType]!) ...[
            InstriqListItem(
              icon: _iconForRefType(item.ref.refType),
              title: item.ref.title,
              onTap: () => navigateToResolvedRef(context, item.ref),
            ),
            const SizedBox(height: InstriqSpacing.sm),
          ],
        ],
      ],
    );
  }
}
