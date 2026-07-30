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
import '../models/tray.dart';
import '../models/work_mode.dart';
import '../models/workspace.dart';
import '../services/auth_service.dart';
import '../services/custom_instrument_service.dart';
import '../services/favorites_service.dart';
import '../services/group_document_service.dart';
import '../services/profile_service.dart';
import '../services/recent_activity_service.dart';
import '../services/tray_service.dart';
import '../services/workspace_service.dart';
import '../utils/ref_resolver.dart';
import 'catalog_screen.dart';
import 'custom_instrument_detail_screen.dart';
import 'group_document_detail_screen.dart';
import 'group_document_list_screen.dart';
import 'group_document_review_queue_screen.dart';
import 'instrument_detail_screen.dart';
import 'learn_screen.dart';
import 'progress_screen.dart';
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

  bool _loadingGroupContent = true;
  List<Workspace> _workspaces = [];
  List<GroupDocument> _techniques = [];
  List<GroupDocument> _protocols = [];
  List<Tray> _trays = [];
  List<CustomInstrument> _customInstruments = [];

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGroupContent() async {
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

  Future<void> _openTechniques() async {
    if (!ProfileService.instance.hasHospital) return;
    if (_workspaces.length == 1) {
      final workspace = _workspaces.first;
      final myRole = await WorkspaceService.instance.fetchMyRole(workspace.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              GroupDocumentListScreen(kind: DocumentKind.technique, workspace: workspace, myRole: myRole),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WorkspaceListScreen()),
      );
    }
    _refreshAfterReturn();
  }

  Future<void> _openTrays() async {
    if (!ProfileService.instance.hasHospital) return;
    if (_workspaces.length == 1) {
      final workspace = _workspaces.first;
      final myRole = await WorkspaceService.instance.fetchMyRole(workspace.id);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => TraysScreen(workspace: workspace, myRole: myRole)),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WorkspaceListScreen()),
      );
    }
    _refreshAfterReturn();
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

  Future<void> _openReviewQueue() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReviewQueueScreen()),
    );
    _refreshAfterReturn();
  }

  bool _matchesInstrument(Instrument instrument, String query, String languageCode) {
    return instrument.name.toLowerCase().contains(query) ||
        instrument.aliases.any((alias) => alias.toLowerCase().contains(query)) ||
        instrument.description.forLanguageCode(languageCode).toLowerCase().contains(query) ||
        instrument.use.forLanguageCode(languageCode).toLowerCase().contains(query);
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
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
                onChanged: (value) => setState(() => _query = value),
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
    final query = _query.toLowerCase();
    final languageCode = Localizations.localeOf(context).languageCode;
    final instruments = kInstruments.where((i) => _matchesInstrument(i, query, languageCode)).toList();
    final techniques = _techniques
        .where((d) => (d.publishedVersion?.title ?? '').toLowerCase().contains(query))
        .toList();
    final protocols =
        _protocols.where((d) => (d.publishedVersion?.title ?? '').toLowerCase().contains(query)).toList();
    final trays =
        _trays.where((t) => (t.publishedVersion?.name ?? '').toLowerCase().contains(query)).toList();
    final customInstruments =
        _customInstruments.where((i) => i.name.toLowerCase().contains(query)).toList();

    final hasResults = instruments.isNotEmpty ||
        techniques.isNotEmpty ||
        protocols.isNotEmpty ||
        trays.isNotEmpty ||
        customInstruments.isNotEmpty;

    if (!hasResults) {
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
        if (instruments.isNotEmpty) ...[
          InstriqSectionHeader(l10n.homeSectionInstruments),
          const SizedBox(height: InstriqSpacing.sm),
          for (final instrument in instruments) ...[
            InstriqListItem(
              icon: Icons.build_outlined,
              title: instrument.name,
              onTap: () => _openInstrument(instrument),
            ),
            const SizedBox(height: InstriqSpacing.sm),
          ],
          const SizedBox(height: InstriqSpacing.md),
        ],
        if (techniques.isNotEmpty) ...[
          InstriqSectionHeader(l10n.homeSectionTechniques),
          const SizedBox(height: InstriqSpacing.sm),
          for (final doc in techniques) ...[
            InstriqListItem(
              icon: Icons.menu_book_outlined,
              title: doc.publishedVersion?.title ?? l10n.unpublished,
              onTap: () => _openGroupDocument(doc),
            ),
            const SizedBox(height: InstriqSpacing.sm),
          ],
          const SizedBox(height: InstriqSpacing.md),
        ],
        if (protocols.isNotEmpty) ...[
          InstriqSectionHeader(l10n.homeSectionProtocols),
          const SizedBox(height: InstriqSpacing.sm),
          for (final doc in protocols) ...[
            InstriqListItem(
              icon: Icons.fact_check_outlined,
              title: doc.publishedVersion?.title ?? l10n.unpublished,
              onTap: () => _openGroupDocument(doc),
            ),
            const SizedBox(height: InstriqSpacing.sm),
          ],
          const SizedBox(height: InstriqSpacing.md),
        ],
        if (trays.isNotEmpty) ...[
          InstriqSectionHeader(l10n.homeSectionTrays),
          const SizedBox(height: InstriqSpacing.sm),
          for (final tray in trays) ...[
            InstriqListItem(
              icon: Icons.inventory_2_outlined,
              title: tray.publishedVersion?.name ?? l10n.unpublished,
              onTap: () => _openTray(tray),
            ),
            const SizedBox(height: InstriqSpacing.sm),
          ],
          const SizedBox(height: InstriqSpacing.md),
        ],
        if (customInstruments.isNotEmpty) ...[
          InstriqSectionHeader(l10n.homeSectionCustomInstruments),
          const SizedBox(height: InstriqSpacing.sm),
          for (final instrument in customInstruments) ...[
            InstriqListItem(
              icon: Icons.precision_manufacturing_outlined,
              title: instrument.name,
              onTap: () => _openCustomInstrument(instrument),
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
