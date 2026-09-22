import 'package:flutter/material.dart';

import '../design_system/components/instriq_badge.dart';
import '../design_system/components/instriq_section_header.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/audit_entry.dart';
import '../models/hospital_content_stats.dart';
import '../models/usage_stats.dart';
import '../services/analytics_service.dart';
import '../services/audit_service.dart';
import '../services/contributor_service.dart';
import '../services/custom_instrument_service.dart';
import '../services/group_document_service.dart';
import '../services/preference_card_service.dart';
import '../services/profile_service.dart';
import '../services/public_document_service.dart';
import '../services/public_instrument_service.dart';
import '../services/public_tray_service.dart';
import '../services/sterilization_service.dart';
import '../services/sync_queue_service.dart';
import '../services/tray_service.dart';
import '../services/usage_analytics_service.dart';
import 'audit_log_screen.dart';
import 'group_document_review_queue_screen.dart';
import 'knowledge_dashboard_screen.dart';
import 'manage_teams_screen.dart';
import 'review_inbox_screen.dart';
import 'sterilization_review_queue_support.dart';
import 'sync_issues_screen.dart';

/// Contenido de la rama "Inici" en pantallas de clase PC (ver
/// `InstriqBreakpoints.desktop` en home_screen.dart): sustituye la lista de
/// accesos rápidos por un panel de lo que ya existe en el código pero vivía
/// sin enlazar o disperso — [KnowledgeDashboardScreen] (construida y sin
/// enlazar a propósito, ver su propio comentario de clase), [ReviewInboxScreen],
/// [SyncIssuesScreen], [AuditLogScreen] y los mismos conteos de
/// `_fetchPendingApprovals` de home_screen.dart. Solo se construye cuando
/// home_screen.dart ya ha comprobado `isAdmin || canApproveAnyWorkspace` — no
/// introduce ningún permiso nuevo, solo reutiliza el mismo gate por sección
/// que ya usa cada pantalla destino.
///
/// Cada tile carga su propio `Future` (o escucha su propio `ValueListenable`,
/// en el caso de incidencias de sincronización) en vez de compartir un único
/// `Future.wait`: un RPC lento o caído (p. ej. `organization_usage_stats`) no
/// debe dejar en blanco el resto del panel — mismo criterio que ya usa
/// [KnowledgeDashboardScreen] entre su sección de cobertura y la de uso.
class HomeDashboardPanel extends StatefulWidget {
  const HomeDashboardPanel({super.key});

  @override
  State<HomeDashboardPanel> createState() => _HomeDashboardPanelState();
}

class _PendingApprovalPreview {
  final String title;
  final bool isTray;

  const _PendingApprovalPreview({required this.title, required this.isTray});
}

class _PendingApprovalData {
  final int count;
  final List<_PendingApprovalPreview> preview;

  const _PendingApprovalData({required this.count, required this.preview});
}

class _ReviewInboxData {
  final int? groupContent;
  final int? contributorApplications;
  final int? publicLibrary;

  const _ReviewInboxData({this.groupContent, this.contributorApplications, this.publicLibrary});
}

class _HomeDashboardPanelState extends State<HomeDashboardPanel> {
  Future<_PendingApprovalData>? _pendingFuture;
  Future<_ReviewInboxData>? _inboxFuture;
  Future<HospitalContentStats?>? _statsFuture;
  Future<UsageStats?>? _usageFuture;
  Future<List<AuditEntry>>? _auditFuture;

  // Mismo criterio de acceso que ReviewInboxScreen (no hay un único permiso
  // que cubra las 3 colas, ver el comentario de clase de esa pantalla).
  bool get _canSeeCommunityQueues => ContributorService.instance.isEditorialBoard;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final organizationId = ProfileService.instance.organizationId;
    setState(() {
      _pendingFuture = _loadPendingApproval();
      _inboxFuture = _loadReviewInbox();
      _statsFuture = organizationId == null
          ? Future.value(null)
          : AnalyticsService.instance.fetchHospitalContentStats(organizationId);
      _usageFuture = organizationId == null
          ? Future.value(null)
          : UsageAnalyticsService.instance.fetchStats(organizationId);
      _auditFuture = AuditService.instance.fetchAuditLog(organizationId: organizationId, limit: 4);
    });
  }

  Future<_PendingApprovalData> _loadPendingApproval() async {
    final docs = await GroupDocumentService.instance.fetchReviewQueue();
    final trays = await TrayService.instance.fetchReviewQueue();
    final preview = <_PendingApprovalPreview>[
      ...docs.map((v) => _PendingApprovalPreview(title: v.title, isTray: false)),
      ...trays.map((v) => _PendingApprovalPreview(title: v.name, isTray: true)),
    ];
    return _PendingApprovalData(count: preview.length, preview: preview.take(4).toList());
  }

  /// Misma agregación que `ReviewInboxScreen._load()` — duplicada aquí (en
  /// vez de reutilizada) porque esa cuenta es privada a esa pantalla; ambas
  /// llaman a los mismos servicios, así que no hay riesgo de que diverjan en
  /// qué cuentan, solo en cómo se muestra.
  Future<_ReviewInboxData> _loadReviewInbox() async {
    final canSeeGroupContent =
        ProfileService.instance.isAdmin || ProfileService.instance.canApproveAnyWorkspace;
    final results = await Future.wait([
      if (canSeeGroupContent) _groupContentReviewCount() else Future.value(null),
      if (_canSeeCommunityQueues)
        ContributorService.instance.fetchPendingApplications().then((l) => l.length)
      else
        Future.value(null),
      if (_canSeeCommunityQueues)
        Future.wait([
          PublicDocumentService.instance.fetchReviewQueue(),
          PublicTrayService.instance.fetchReviewQueue(),
          PublicInstrumentService.instance.fetchReviewQueue(),
        ]).then((lists) => lists.fold<int>(0, (sum, l) => sum + l.length))
      else
        Future.value(null),
    ]);
    return _ReviewInboxData(
      groupContent: results[0],
      contributorApplications: results[1],
      publicLibrary: results[2],
    );
  }

  /// Métodes/fitxes tècniques de catàleg global (`organization_id` nul)
  /// s'exclouen d'aquest recompte -- exigeixen Editorial Board i només es
  /// veuen/resolen a `GlobalCatalogReviewQueueScreen`, no aquí. Sense aquest
  /// filtre, el número inflava amb propostes que un admin d'espai corrent
  /// no pot ni veure ni actuar des d'aquesta safata.
  Future<int> _groupContentReviewCount() async {
    final nonSterilization = await Future.wait([
      GroupDocumentService.instance.fetchReviewQueue(),
      TrayService.instance.fetchReviewQueue(),
      PreferenceCardService.instance.fetchReviewQueue(),
      CustomInstrumentService.instance.fetchReviewQueue(),
    ]).then((lists) => lists.fold<int>(0, (sum, l) => sum + l.length));
    final methodQueue = await SterilizationService.instance.fetchMethodReviewQueue();
    final infoQueue = await SterilizationService.instance.fetchTechnicalInfoReviewQueue();
    final sterilizationCount = await countOrgScopedSterilizationReviewItems(methodQueue, infoQueue);
    return nonSterilization + sterilizationCount;
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _reload();
  }

  String _actionLabel(AppLocalizations l10n, AuditEntry entry) {
    switch (entry.action) {
      case 'user_signed_in':
        return l10n.auditActionUserSignedIn;
      case 'document_version_approved':
        return l10n.auditActionDocumentVersionApproved;
      case 'document_version_rejected':
        return l10n.auditActionDocumentVersionRejected;
      case 'document_created':
        return l10n.auditActionDocumentCreated;
      case 'document_deleted':
        return l10n.auditActionDocumentDeleted;
      case 'workspace_member_role_changed':
        return l10n.auditActionWorkspaceMemberRoleChanged;
      case 'hospital_ownership_transferred':
        return l10n.auditActionHospitalOwnershipTransferred;
      default:
        return entry.action;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return RefreshIndicator(
      onRefresh: () async => _reload(),
      child: ListView(
        padding: const EdgeInsets.all(InstriqSpacing.xl),
        children: [
          InstriqSectionHeader(l10n.homeDashboardTitle),
          const SizedBox(height: InstriqSpacing.lg),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 1500 ? 3 : 2;
              const gap = InstriqSpacing.lg;
              final tileWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final tile in _buildTiles(context, l10n)) SizedBox(width: tileWidth, child: tile),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTiles(BuildContext context, AppLocalizations l10n) {
    final tiles = <Widget>[];

    if (ProfileService.instance.isAdmin) {
      tiles.add(FutureBuilder<_PendingApprovalData>(
        future: _pendingFuture,
        builder: (context, snapshot) {
          final data = snapshot.data;
          return _DashboardTile(
            icon: Icons.assignment_turned_in_outlined,
            title: l10n.homePendingApprovalTitle,
            stat: data != null ? '${data.count}' : null,
            statIsWarning: (data?.count ?? 0) > 0,
            loading: snapshot.connectionState != ConnectionState.done,
            errorText: snapshot.hasError ? l10n.entityUsageLoadError(snapshot.error.toString()) : null,
            onTap: () => _open(const ReviewQueueScreen()),
            linkLabel: l10n.homeViewAllLabel,
            child: (data == null || data.preview.isEmpty)
                ? Text(l10n.usageEmptyState, style: Theme.of(context).textTheme.bodySmall)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final item in data.preview)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(item.isTray ? Icons.inventory_2_outlined : Icons.description_outlined,
                                  size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(item.title, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ),
                    ],
                  ),
          );
        },
      ));
    }

    tiles.add(FutureBuilder<_ReviewInboxData>(
      future: _inboxFuture,
      builder: (context, snapshot) {
        final data = snapshot.data;
        return _DashboardTile(
          icon: Icons.inbox_outlined,
          title: l10n.reviewInboxTitle,
          loading: snapshot.connectionState != ConnectionState.done,
          errorText: snapshot.hasError ? l10n.entityUsageLoadError(snapshot.error.toString()) : null,
          onTap: () => _open(const ReviewInboxScreen()),
          linkLabel: l10n.homeViewAllLabel,
          child: data == null
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (data.groupContent != null) _statLine(context, l10n.reviewQueueTitle, data.groupContent!),
                    if (data.contributorApplications != null)
                      _statLine(context, l10n.contributorReviewQueueTitle, data.contributorApplications!),
                    if (data.publicLibrary != null)
                      _statLine(context, l10n.publicLibraryReviewQueueTitle, data.publicLibrary!),
                  ],
                ),
        );
      },
    ));

    tiles.add(FutureBuilder<HospitalContentStats?>(
      future: _statsFuture,
      builder: (context, statsSnapshot) {
        final stats = statsSnapshot.data;
        final published = stats?.bySpecialty.fold<int>(0, (sum, s) => sum + s.publishedCount);
        return FutureBuilder<UsageStats?>(
          future: _usageFuture,
          builder: (context, usageSnapshot) {
            final zeroResult = usageSnapshot.data?.zeroResultSearches.length ?? 0;
            return _DashboardTile(
              icon: Icons.bar_chart,
              title: l10n.homeDashboardCoverageTileTitle,
              stat: published != null ? '$published' : null,
              loading: statsSnapshot.connectionState != ConnectionState.done,
              errorText:
                  statsSnapshot.hasError ? l10n.entityUsageLoadError(statsSnapshot.error.toString()) : null,
              onTap: () => _open(const KnowledgeDashboardScreen()),
              linkLabel: l10n.homeViewAllLabel,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.homeDashboardCoverageTileSubtitle, style: Theme.of(context).textTheme.bodySmall),
                  if (zeroResult > 0) ...[
                    const SizedBox(height: 8),
                    InstriqBadge(
                      label: l10n.homeDashboardZeroResultSearches(zeroResult),
                      color: InstriqColors.statusInReview,
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    ));

    tiles.add(ValueListenableBuilder<List<SyncFailure>>(
      valueListenable: SyncQueueService.instance.failures,
      builder: (context, failures, _) {
        return _DashboardTile(
          icon: Icons.sync_problem_outlined,
          title: l10n.syncIssuesTitle,
          stat: '${failures.length}',
          statIsWarning: failures.isNotEmpty,
          onTap: () => _open(const SyncIssuesScreen()),
          linkLabel: l10n.homeViewAllLabel,
          child: failures.isEmpty
              ? Text(l10n.syncIssuesEmptyState, style: Theme.of(context).textTheme.bodySmall)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final f in failures.take(2))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(f.description,
                            overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                      ),
                  ],
                ),
        );
      },
    ));

    if (ProfileService.instance.isAdmin) {
      tiles.add(FutureBuilder<List<AuditEntry>>(
        future: _auditFuture,
        builder: (context, snapshot) {
          final entries = snapshot.data ?? const [];
          return _DashboardTile(
            icon: Icons.history,
            title: l10n.auditLogTitle,
            loading: snapshot.connectionState != ConnectionState.done,
            errorText: snapshot.hasError ? l10n.entityUsageLoadError(snapshot.error.toString()) : null,
            onTap: () => _open(const AuditLogScreen()),
            linkLabel: l10n.homeViewAllLabel,
            child: entries.isEmpty
                ? Text(l10n.usageEmptyState, style: Theme.of(context).textTheme.bodySmall)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final entry in entries.take(3))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${entry.actorDisplayName ?? l10n.deletedUserLabel} · ${_actionLabel(l10n, entry)}',
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
          );
        },
      ));

      tiles.add(FutureBuilder<HospitalContentStats?>(
        future: _statsFuture,
        builder: (context, snapshot) {
          final roles = snapshot.data?.membersByRole;
          return _DashboardTile(
            icon: Icons.groups_outlined,
            title: l10n.manageTeamsTitle,
            loading: snapshot.connectionState != ConnectionState.done,
            errorText: snapshot.hasError ? l10n.entityUsageLoadError(snapshot.error.toString()) : null,
            onTap: () => _open(const ManageTeamsScreen()),
            linkLabel: l10n.homeViewAllLabel,
            child: roles == null
                ? const SizedBox.shrink()
                : Wrap(
                    spacing: InstriqSpacing.lg,
                    runSpacing: InstriqSpacing.sm,
                    children: [
                      _roleStat(context, l10n.workspaceRoleAdministratorLabel, roles.administrator),
                      _roleStat(context, l10n.workspaceRoleApproverLabel, roles.approver),
                      _roleStat(context, l10n.workspaceRoleEditorLabel, roles.editor),
                      _roleStat(context, l10n.workspaceRoleReaderLabel, roles.reader),
                    ],
                  ),
          );
        },
      ));
    }

    return tiles;
  }
}

Widget _statLine(BuildContext context, String label, int count) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
        const SizedBox(width: 8),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    ),
  );
}

Widget _roleStat(BuildContext context, String label, int count) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text('$count', style: Theme.of(context).textTheme.titleMedium),
      Text(label, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
}

/// Tarjeta de una única métrica del panel: icono+título, un número grande
/// opcional, un cuerpo libre (`child`) y un enlace de acción. `loading`/
/// `errorText` son independientes por tile a propósito — ver comentario de
/// clase de [HomeDashboardPanel].
class _DashboardTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? stat;
  final bool statIsWarning;
  final bool loading;
  final String? errorText;
  final Widget child;
  final VoidCallback onTap;
  final String linkLabel;

  const _DashboardTile({
    required this.icon,
    required this.title,
    this.stat,
    this.statIsWarning = false,
    this.loading = false,
    this.errorText,
    required this.child,
    required this.onTap,
    required this.linkLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(InstriqSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: InstriqSpacing.sm),
                  Expanded(
                    child: Text(title, style: theme.textTheme.titleSmall, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: InstriqSpacing.md),
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: InstriqSpacing.md),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (errorText != null)
                Text(errorText!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error))
              else ...[
                if (stat != null) ...[
                  Text(
                    stat!,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: statIsWarning ? InstriqColors.statusInReview : null,
                    ),
                  ),
                  const SizedBox(height: InstriqSpacing.sm),
                ],
                child,
              ],
              const SizedBox(height: InstriqSpacing.md),
              Text(linkLabel, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary)),
            ],
          ),
        ),
      ),
    );
  }
}
