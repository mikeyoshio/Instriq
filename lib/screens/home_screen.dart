import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_responsive_content.dart';
import '../design_system/components/instriq_section_header.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/favorite_entry.dart';
import '../models/instrument_incident.dart';
import '../models/surgical_slot.dart';
import '../models/tray.dart';
import '../models/work_mode.dart';
import '../models/workspace.dart';
import '../models/workspace_role.dart';
import '../navigation/profile_button.dart';
import '../services/auth_service.dart';
import '../services/favorites_service.dart';
import '../services/group_document_service.dart';
import '../services/instrument_incident_service.dart';
import '../services/profile_service.dart';
import '../services/recent_activity_service.dart';
import '../services/surgeon_service.dart';
import '../services/surgical_slot_service.dart';
import '../services/tray_preparation_service.dart';
import '../services/tray_service.dart';
import '../services/workspace_service.dart';
import '../utils/ref_resolver.dart';
import '../widgets/create_content_sheet.dart';
import '../widgets/instrument_incident_label.dart';
import '../widgets/work_mode_picker.dart';
import 'auth/hospital_connect_flow.dart';
import 'home_dashboard_panel.dart';
import 'incident_capa_queue_screen.dart';
import 'learning_path_screen.dart';
import 'review_inbox_screen.dart';
import 'surgical_case_screen.dart';
import 'team_progress_screen.dart';
import 'tray_detail_screen.dart';
import 'trays_screen.dart';
import 'workspace_list_screen.dart';

/// Orden de secciones de la pantalla de Inicio (sin búsqueda activa) según el
/// modo de trabajo — mismo espíritu que `_modeSectionOrder` en
/// lib/models/work_mode.dart, pero para las secciones del Home en vez de las
/// de una ficha de instrumento.
enum HomeSectionKey { radar, startHere, pendingApproval, openIncidents, traysToPrepare, teamProgress, recent, favorites }

// 2.0-beta: sense Dreceres (el seu contingut viu a Cercar, El meu equip i
// Aprèn). Revisió pendent i incidències obertes surten només si n'hi ha.
const List<HomeSectionKey> _defaultHomeSectionOrder = [
  HomeSectionKey.startHere,
  HomeSectionKey.pendingApproval,
  HomeSectionKey.openIncidents,
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
  if (mode == WorkMode.instrumentista) {
    return [HomeSectionKey.traysToPrepare, ..._defaultHomeSectionOrder];
  }
  if (mode == WorkMode.docente) {
    return [HomeSectionKey.teamProgress, ..._defaultHomeSectionOrder];
  }
  return _defaultHomeSectionOrder;
}

const _workModePromptKey = 'has_prompted_work_mode';

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
  bool _loadingGroupContent = true;
  List<Workspace> _workspaces = [];
  List<Tray> _trays = [];
  Map<String, DateTime> _lastPreparedAtByTray = {};

  bool _loadingRecentFavorites = true;
  List<_RecentOrFavoriteItem> _recent = [];
  List<_RecentOrFavoriteItem> _favorites = [];

  // Cacheada en el estado (no recreada en cada build): si no, cada setState
  // de la pantalla (p.ej. al escribir en la búsqueda y volver a vaciarla)
  // dispararía una consulta nueva a la cola de aprobación.
  Future<List<_PendingApprovalItem>>? _pendingApprovalsFuture;
  Future<List<InstrumentIncident>>? _openIncidentsFuture;

  (int, int)? _learningPathProgress;
  List<SurgicalSlot> _radarSlots = const [];
  bool _workModePromptPending = false;
  bool _workModePromptShowing = false;

  @override
  void initState() {
    super.initState();
    _loadGroupContent();
    _loadRecentAndFavorites();
    _loadLearningPathProgress();
    _loadRadar();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptWorkMode());
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
    super.dispose();
  }

  void _onProfileChanged() {
    _pendingApprovalsFuture = null;
    _openIncidentsFuture = null;
    _loadGroupContent();
    _loadRecentAndFavorites();
    _loadLearningPathProgress();
    _loadRadar();
    _maybePromptWorkMode();
  }

  /// Radar: cites d'avui de la meva organització (tots els espais visibles).
  // ponytail: si falla la xarxa la secció no surt (sense estat d'error propi);
  // l'agenda de cada espai sí mostra l'error.
  Future<void> _loadRadar() async {
    final orgId = ProfileService.instance.organizationId;
    if (!ProfileService.instance.hasHospital || orgId == null) {
      if (mounted && _radarSlots.isNotEmpty) setState(() => _radarSlots = const []);
      return;
    }
    try {
      final results = await Future.wait([
        SurgicalSlotService.instance.fetchForDay(DateTime.now(), organizationId: orgId),
        SurgeonService.instance.fetchForOrganization(),
      ]);
      if (mounted) setState(() => _radarSlots = results[0] as List<SurgicalSlot>);
    } catch (_) {}
  }

  Future<void> _openCase(SurgicalSlot slot) async {
    final myRole = await WorkspaceService.instance.fetchMyRole(slot.workspaceId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => SurgicalCaseScreen(slot: slot, myRole: myRole)),
    );
    _loadRadar();
  }

  Widget? _buildRadarSection(BuildContext context, AppLocalizations l10n) {
    if (_radarSlots.isEmpty) return null;
    String hm(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InstriqSectionHeader('${l10n.radarTitle} · ${l10n.radarSubtitle(_radarSlots.length)}'),
        const SizedBox(height: InstriqSpacing.md),
        for (final slot in _radarSlots) ...[
          InstriqListItem(
            icon: Icons.radar,
            title: slot.procedureName?.isNotEmpty == true
                ? slot.procedureName!
                : (SurgeonService.instance.byId(slot.surgeonId)?.name ?? l10n.surgicalCaseTitle),
            subtitle: [
              '${hm(slot.startsAt.toLocal())}–${hm(slot.endsAt.toLocal())}',
              if (slot.procedureName?.isNotEmpty == true) SurgeonService.instance.byId(slot.surgeonId)?.name,
              if (slot.location?.isNotEmpty == true) slot.location,
            ].whereType<String>().join(' · '),
            onTap: () => _openCase(slot),
          ),
          const SizedBox(height: InstriqSpacing.sm),
        ],
      ],
    );
  }

  void _onWorkModeChanged() => setState(() {});

  Future<void> _loadLearningPathProgress() async {
    final progress = await LearningPathScreen.progress();
    if (mounted) setState(() => _learningPathProgress = progress);
  }

  /// docs/redesign_v1.2_personalization.md §5.1: sense això ningú descobreix
  /// el selector de mode i tota la personalització per mode és morta. Un sol
  /// cop, el primer cop que hi ha hospital sense mode triat; es marca com a
  /// vist encara que se salti (descartable per sempre, decisió del
  /// propietari). Només si Inici és la ruta visible del seu navigator: si
  /// HospitalConnectFlow encara és a sobre, un sheet empès ara quedaria per
  /// sobre del flux i el seu pop() automàtic tancaria el sheet en lloc d'ell
  /// -- en aquest cas queda pendent i es reintenta al pròxim build.
  Future<void> _maybePromptWorkMode() async {
    final profile = ProfileService.instance;
    if (_workModePromptShowing || !profile.hasHospital || profile.activeWorkModeNotifier.value != null) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_workModePromptKey) == true || !mounted) return;
    if (ModalRoute.of(context)?.isCurrent != true) {
      _workModePromptPending = true;
      return;
    }
    _workModePromptPending = false;
    _workModePromptShowing = true;
    await prefs.setBool(_workModePromptKey, true);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(InstriqSpacing.lg, 0, InstriqSpacing.lg, InstriqSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.workModeOnboardingQuestion, style: theme.textTheme.titleLarge),
                const SizedBox(height: InstriqSpacing.sm),
                Text(l10n.workModeSectionSubtitle),
                const SizedBox(height: InstriqSpacing.lg),
                WorkModePicker(
                  selected: null,
                  onChanged: (mode) {
                    Navigator.of(sheetContext).pop();
                    // Preferència de visualització: si falla (sense xarxa), es
                    // pot triar després a Perfil -- no bloqueja res.
                    if (mode != null) unawaited(profile.setActiveWorkMode(mode).catchError((_) {}));
                  },
                ),
                const SizedBox(height: InstriqSpacing.lg),
                Text(
                  l10n.workModePromptChangeLater,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text(l10n.notNow),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    _workModePromptShowing = false;
  }

  /// Contingut de grup que Inici necessita per a les seves pròpies seccions
  /// (espais i safates per a "Safates per preparar"). La cerca ja no viu
  /// aquí: Omnihub (pestanya "Cercar") carrega el seu propi índex.
  Future<void> _loadGroupContent() async {
    if (!ProfileService.instance.hasHospital) {
      if (mounted) setState(() => _loadingGroupContent = false);
      return;
    }
    try {
      await WorkspaceService.instance.fetchWorkspaces();
      final workspaces = WorkspaceService.instance.workspaces;
      final trays = <Tray>[];
      for (final workspace in workspaces) {
        try {
          await TrayService.instance.fetchTrays(workspace.id);
          trays.addAll(TrayService.instance.traysOfWorkspace(workspace.id));
        } catch (_) {
          // Un espacio fallando (sin acceso, sin conexión puntual) no debe
          // bloquear la agregación del resto de espacios.
        }
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
        _trays = trays;
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
    _openIncidentsFuture = null;
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

  Future<void> _openTrays() => _openWorkspaceCollection(
        buildDirect: (workspace, myRole) => TraysScreen(workspace: workspace, myRole: myRole),
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

  Future<void> _openTray(Tray tray) async {
    final myRole = await WorkspaceService.instance.fetchMyRole(tray.workspaceId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TrayDetailScreen(tray: tray, myRole: myRole)),
    );
  }

  Future<void> _openTeamProgress() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TeamProgressScreen()),
    );
  }

  Future<void> _openReviewQueue() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReviewInboxScreen()),
    );
    _refreshAfterReturn();
  }

  Future<void> _openIncidentQueue() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const IncidentCapaQueueScreen()),
    );
    _refreshAfterReturn();
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
    if (_workModePromptPending) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybePromptWorkMode());
    }
    // Panel de escritorio (ver home_dashboard_panel.dart): solo sustituye el
    // cuerpo por defecto (sin búsqueda activa) en ventanas de clase PC, y
    // solo para quien ya tiene acceso a los datos que agrega (mismo gate que
    // ya usa cada pantalla destino) — para cualquier otro caso, Inici se
    // comporta exactamente igual que antes, tablet incluida.
    final showDashboard = MediaQuery.sizeOf(context).width >= InstriqBreakpoints.desktop &&
        ProfileService.instance.hasHospital &&
        (ProfileService.instance.isAdmin || ProfileService.instance.canApproveAnyWorkspace);
    final content = Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: InstriqSpacing.lg, vertical: InstriqSpacing.sm),
          // Entrada a Omnihub (pestanya "Cercar"): la cerca viu en un sol lloc.
          child: TextField(
            readOnly: true,
            onTap: () => context.go('/buscar'),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: l10n.homeSearchHint,
              border: OutlineInputBorder(borderRadius: InstriqRadius.mdRadius),
            ),
          ),
        ),
        Expanded(
          child: showDashboard ? const HomeDashboardPanel() : _buildDefaultBody(context, l10n),
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(actions: const [ProfileButton()]),
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

  Widget _buildDefaultBody(BuildContext context, AppLocalizations l10n) {
    final mode = ProfileService.instance.activeWorkModeNotifier.value;
    // Radar (casos d'avui) sempre primer per a tots els modes: si avui hi ha
    // cirurgies, és el més urgent; si no n'hi ha, la secció no apareix.
    final order = [HomeSectionKey.radar, ..._sectionOrderForMode(mode)];
    final sections = <Widget>[];
    for (final key in order) {
      final section = switch (key) {
        HomeSectionKey.radar => _buildRadarSection(context, l10n),
        HomeSectionKey.startHere => _buildStartHereSection(context, l10n),
        HomeSectionKey.pendingApproval => _buildPendingApprovalSection(context, l10n),
        HomeSectionKey.openIncidents => _buildOpenIncidentsSection(context, l10n),
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

  /// Per a qui encara no té grup (Avui quedaria buit): tres primers passos.
  Widget? _buildStartHereSection(BuildContext context, AppLocalizations l10n) {
    if (ProfileService.instance.hasHospital) return null;
    final pathProgress = _learningPathProgress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InstriqSectionHeader(l10n.homeStartHereTitle),
        const SizedBox(height: InstriqSpacing.md),
        InstriqListItem(
          icon: Icons.route_outlined,
          title: l10n.learningPathTitle,
          subtitle: pathProgress != null && pathProgress.$1 > 0
              ? l10n.learningPathProgress(pathProgress.$1, pathProgress.$2)
              : l10n.learningPathSubtitle,
          onTap: () async {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LearningPathScreen()));
            _loadLearningPathProgress();
          },
        ),
        const SizedBox(height: InstriqSpacing.sm),
        InstriqListItem(
          icon: Icons.groups_outlined,
          title: l10n.connectGroupTitle,
          subtitle: l10n.connectGroupSubtitle,
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HospitalConnectFlow())),
        ),
        const SizedBox(height: InstriqSpacing.sm),
        InstriqListItem(
          icon: Icons.menu_book,
          title: l10n.catalogTitle,
          subtitle: l10n.catalogSubtitle,
          onTap: () => context.go('/buscar'),
        ),
      ],
    );
  }

  /// Incidències obertes de l'organització (abans a Activitat): només si
  /// n'hi ha, i només per a admin/approver -- els qui poden resoldre-les.
  Widget? _buildOpenIncidentsSection(BuildContext context, AppLocalizations l10n) {
    if (!ProfileService.instance.hasHospital) return null;
    if (!ProfileService.instance.isAdmin && !ProfileService.instance.canApproveAnyWorkspace) return null;
    _openIncidentsFuture ??= InstrumentIncidentService.instance
        .fetchForOrganization()
        .then((list) => list.where((i) => i.status == IncidentStatus.open).toList())
        .catchError((_) => <InstrumentIncident>[]);
    return FutureBuilder<List<InstrumentIncident>>(
      future: _openIncidentsFuture,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <InstrumentIncident>[];
        if (items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: InstriqSectionHeader(l10n.incidentCapaQueueTitle)),
                TextButton(onPressed: _openIncidentQueue, child: Text(l10n.homeViewAllLabel)),
              ],
            ),
            for (final incident in items.take(3)) ...[
              InstriqListItem(
                icon: Icons.report_problem_outlined,
                title: incident.description,
                subtitle: incidentSeverityValueLabel(l10n, incident.severity),
                onTap: _openIncidentQueue,
              ),
              const SizedBox(height: InstriqSpacing.sm),
            ],
          ],
        );
      },
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
