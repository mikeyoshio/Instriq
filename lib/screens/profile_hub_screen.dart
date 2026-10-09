import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_responsive_content.dart';
import '../design_system/components/instriq_section_header.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/contributor_application.dart';
import '../services/auth_service.dart';
import '../services/contributor_service.dart';
import '../services/offline_download_service.dart';
import '../services/profile_service.dart';
import '../services/sync_queue_service.dart';
import '../services/theme_service.dart';
import '../widgets/language_picker.dart';
import 'account_privacy_screen.dart';
import 'admin/manage_hospital_screen.dart';
import 'contributor_application_form_screen.dart';
import 'contributor_profile_screen.dart';
import 'global_catalog_review_queue_screen.dart';
import 'help/help_hub_screen.dart';
import 'knowledge_dashboard_screen.dart';
import 'manage_teams_screen.dart';
import 'review_inbox_screen.dart';
import 'sync_issues_screen.dart';

/// Cuenta, idioma, tema y — si `ProfileService.instance.isAdmin` —
/// administración del grupo. Todo esto vivía como botones sueltos en el
/// `AppBar` de `home_screen.dart`; aquí es su propia pantalla dentro del
/// shell.
class ProfileHubScreen extends StatefulWidget {
  const ProfileHubScreen({super.key});

  @override
  State<ProfileHubScreen> createState() => _ProfileHubScreenState();
}

class _ProfileHubScreenState extends State<ProfileHubScreen> {
  ContributorApplication? _lastApplication;
  bool _loadingContributorState = true;

  @override
  void initState() {
    super.initState();
    _loadContributorState();
    OfflineDownloadService.instance.progress.addListener(_onOfflineDownloadFinished);
  }

  @override
  void dispose() {
    OfflineDownloadService.instance.progress.removeListener(_onOfflineDownloadFinished);
    super.dispose();
  }

  Future<void> _loadContributorState() async {
    if (AuthService.instance.currentUser == null) {
      if (mounted) setState(() => _loadingContributorState = false);
      return;
    }
    try {
      await ContributorService.instance.loadMyProfile();
      _lastApplication =
          ContributorService.instance.myProfile == null ? await ContributorService.instance.fetchMyLatestApplication() : null;
    } catch (_) {
      // La secció de comunitat es un extra: si falla la carrega, no bloqueja
      // la resta de "El meu compte".
    }
    if (mounted) setState(() => _loadingContributorState = false);
  }

  void _refresh() => setState(() {});

  Future<void> _refreshContributorState() async {
    setState(() => _loadingContributorState = true);
    await _loadContributorState();
  }

  Future<void> _openContributorApplicationForm() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ContributorApplicationFormScreen()),
    );
    _refreshContributorState();
  }

  Future<void> _openContributorProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ContributorProfileScreen()),
    );
    _refreshContributorState();
  }

  Future<void> _openReviewInbox() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReviewInboxScreen()),
    );
    _refreshContributorState();
  }

  Future<void> _openGlobalCatalogReviewQueue() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GlobalCatalogReviewQueueScreen()),
    );
    _refreshContributorState();
  }

  Future<void> _openHelpHub() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HelpHubScreen()),
    );
  }

  /// Engega la descàrrega en segon pla -- no bloqueja la pantalla, es pot
  /// seguir navegant mentre dura (veure comentari de classe d'
  /// [OfflineDownloadService]).
  void _downloadForOfflineUse() {
    final l10n = AppLocalizations.of(context)!;
    if (OfflineDownloadService.instance.isRunning) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.offlineDownloadAlreadyRunning)));
      return;
    }
    OfflineDownloadService.instance.startInBackground();
  }

  /// Escolta `progress` en comptes de `lastResult`/`lastError` directament
  /// perquè aquests dos poden rebre el seu valor nou (dins de `_run()`)
  /// abans que `progress` torni a `null` -- esperar que `progress` sigui
  /// `null` garanteix que la descàrrega ja ha acabat del tot.
  void _onOfflineDownloadFinished() {
    if (!mounted || OfflineDownloadService.instance.isRunning) return;
    final error = OfflineDownloadService.instance.lastError.value;
    final result = OfflineDownloadService.instance.lastResult.value;
    if (error == null && result == null) return;

    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.offlineDownloadError(error.toString()))));
    } else if (result != null) {
      final items =
          result.documentsCached + result.traysCached + result.preferenceCardsCached + result.publicItemsCached;
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.offlineDownloadSuccess(items, result.imagesCached)),
        duration: const Duration(seconds: 5),
      ));
    }
    // Consumit: una altra visita a aquesta pantalla no ha de tornar a
    // mostrar el mateix avís d'una descàrrega que ja es va notificar.
    OfflineDownloadService.instance.lastError.value = null;
    OfflineDownloadService.instance.lastResult.value = null;
  }

  String _offlineStepLabel(AppLocalizations l10n, OfflineDownloadProgress progress) {
    switch (progress.step) {
      case OfflineDownloadStep.catalogPhotos:
        return l10n.offlineDownloadStepCatalogPhotos;
      case OfflineDownloadStep.publicLibrary:
        return l10n.offlineDownloadStepPublicLibrary;
      case OfflineDownloadStep.publicLibraryPhotos:
        return l10n.offlineDownloadStepPublicLibraryPhotos;
      case OfflineDownloadStep.workspace:
        return l10n.offlineDownloadStepWorkspace(progress.workspaceName ?? '');
      case OfflineDownloadStep.workspacePhotos:
        return l10n.offlineDownloadStepWorkspacePhotos(progress.workspaceName ?? '');
    }
  }

  Future<void> _openAccountPrivacy() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AccountPrivacyScreen()),
    );
    _refresh();
  }

  Future<void> _openSyncIssues() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SyncIssuesScreen()),
    );
    _refresh();
  }

  Future<void> _signOut() async {
    await AuthService.instance.signOut();
    // loadProfile() detecta que ya no hay sesión y limpia el caché de
    // grupo/espacios; sin esto quedaba en memoria.
    await ProfileService.instance.loadProfile();
    _refresh();
  }

  Future<void> _openManageHospital() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ManageHospitalScreen()),
    );
    _refresh();
  }

  Future<void> _openKnowledgeDashboard() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const KnowledgeDashboardScreen()),
    );
    _refresh();
  }

  Future<void> _openManageTeams() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ManageTeamsScreen()),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loggedIn = AuthService.instance.currentUser != null;
    final isAdmin = ProfileService.instance.isAdmin;
    final canSeeKnowledgeDashboard = isAdmin || ProfileService.instance.canApproveAnyWorkspace;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProfile)),
      body: SafeArea(
        child: InstriqResponsiveContent(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(InstriqSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InstriqSectionHeader(l10n.profilePreferencesHeader),
              const SizedBox(height: InstriqSpacing.md),
              InstriqListItem(
                icon: Icons.language,
                title: l10n.languageTooltip,
                onTap: () => pickLanguage(context),
              ),
              const SizedBox(height: InstriqSpacing.sm),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeService.instance.themeMode,
                builder: (context, mode, _) {
                  return InstriqListItem(
                    icon: Theme.of(context).brightness == Brightness.dark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    title: l10n.themeToggleTooltip,
                    onTap: () => ThemeService.instance.toggle(Theme.of(context).brightness),
                  );
                },
              ),
              const SizedBox(height: InstriqSpacing.sm),
              InstriqListItem(
                icon: Icons.help_outline,
                title: l10n.helpCenterTitle,
                onTap: _openHelpHub,
              ),
              const SizedBox(height: InstriqSpacing.sm),
              ValueListenableBuilder<OfflineDownloadProgress?>(
                valueListenable: OfflineDownloadService.instance.progress,
                builder: (context, progress, _) {
                  return InstriqListItem(
                    icon: Icons.download_for_offline_outlined,
                    title: l10n.offlineDownloadTitle,
                    subtitle: progress == null
                        ? null
                        : l10n.offlineDownloadProgressSubtitle(
                            _offlineStepLabel(l10n, progress),
                            progress.total > 0 ? ((progress.done / progress.total) * 100).round() : 0,
                          ),
                    trailing: progress == null
                        ? null
                        : SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              value: progress.total > 0 ? progress.done / progress.total : null,
                            ),
                          ),
                    onTap: _downloadForOfflineUse,
                  );
                },
              ),
              if (loggedIn) ...[
                const SizedBox(height: InstriqSpacing.xl),
                InstriqSectionHeader(l10n.accountPrivacyTitle),
                const SizedBox(height: InstriqSpacing.md),
                InstriqListItem(
                  icon: Icons.privacy_tip_outlined,
                  title: l10n.accountTooltip,
                  onTap: _openAccountPrivacy,
                ),
                const SizedBox(height: InstriqSpacing.sm),
                ValueListenableBuilder<List<SyncFailure>>(
                  valueListenable: SyncQueueService.instance.failures,
                  builder: (context, failures, _) {
                    return InstriqListItem(
                      icon: Icons.sync_problem_outlined,
                      title: l10n.syncIssuesTitle,
                      subtitle: failures.isEmpty
                          ? l10n.syncIssuesMenuSubtitle
                          : l10n.syncIssuesCountLabel(failures.length),
                      onTap: _openSyncIssues,
                    );
                  },
                ),
                const SizedBox(height: InstriqSpacing.sm),
                InstriqListItem(
                  icon: Icons.logout,
                  title: l10n.signOut,
                  onTap: _signOut,
                ),
              ],
              if (loggedIn && !_loadingContributorState) ...[
                const SizedBox(height: InstriqSpacing.xl),
                InstriqSectionHeader(l10n.communitySectionHeader),
                const SizedBox(height: InstriqSpacing.md),
                if (ContributorService.instance.myProfile != null) ...[
                  InstriqListItem(
                    icon: Icons.diversity_3_outlined,
                    title: l10n.contributorProfileTitle,
                    onTap: _openContributorProfile,
                  ),
                  if (ContributorService.instance.isEditorialBoard) ...[
                    const SizedBox(height: InstriqSpacing.sm),
                    InstriqListItem(
                      icon: Icons.fact_check_outlined,
                      title: l10n.reviewInboxTitle,
                      onTap: _openReviewInbox,
                    ),
                    const SizedBox(height: InstriqSpacing.sm),
                    InstriqListItem(
                      icon: Icons.inventory_2_outlined,
                      title: l10n.globalCatalogReviewQueueTitle,
                      onTap: _openGlobalCatalogReviewQueue,
                    ),
                  ],
                ] else if (_lastApplication?.status == ContributorApplicationStatus.pending) ...[
                  InstriqListItem(
                    icon: Icons.hourglass_top_outlined,
                    title: l10n.contributorApplicationPendingTitle,
                    subtitle: l10n.contributorApplicationPendingSubtitle,
                    onTap: null,
                    trailing: const SizedBox.shrink(),
                  ),
                ] else if (_lastApplication?.status == ContributorApplicationStatus.rejected) ...[
                  InstriqListItem(
                    icon: Icons.refresh,
                    title: l10n.contributorApplicationRejectedTitle,
                    subtitle: _lastApplication?.reviewNotes ?? l10n.contributorApplicationRejectedSubtitle,
                    onTap: _openContributorApplicationForm,
                  ),
                ] else ...[
                  InstriqListItem(
                    icon: Icons.volunteer_activism_outlined,
                    title: l10n.contributorBecomeAction,
                    subtitle: l10n.contributorBecomeSubtitle,
                    onTap: _openContributorApplicationForm,
                  ),
                ],
              ],
              if (isAdmin || canSeeKnowledgeDashboard) ...[
                const SizedBox(height: InstriqSpacing.xl),
                InstriqSectionHeader(l10n.manageGroupTitle),
                const SizedBox(height: InstriqSpacing.md),
                if (isAdmin) ...[
                  InstriqListItem(
                    icon: Icons.admin_panel_settings,
                    title: l10n.manageGroupTitle,
                    subtitle: l10n.manageGroupSubtitle,
                    onTap: _openManageHospital,
                  ),
                  const SizedBox(height: InstriqSpacing.sm),
                ],
                if (canSeeKnowledgeDashboard) ...[
                  InstriqListItem(
                    icon: Icons.insights_outlined,
                    title: l10n.knowledgeDashboardTitle,
                    subtitle: l10n.knowledgeDashboardSubtitle,
                    onTap: _openKnowledgeDashboard,
                  ),
                  const SizedBox(height: InstriqSpacing.sm),
                ],
                if (isAdmin)
                  InstriqListItem(
                    icon: Icons.groups_outlined,
                    title: l10n.manageTeamsTitle,
                    subtitle: l10n.manageTeamsSubtitle,
                    onTap: _openManageTeams,
                  ),
              ],
              const SizedBox(height: InstriqSpacing.xl),
              const Center(child: _VersionEasterEgg()),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

/// Versión de la app, discretamente al final de Perfil (vivía suelta en el
/// AppBar de Inici). Tocarla 7 veces seguidas (en menos de 3s entre toque y
/// toque) desvela una broma sobre campo estéril — sin efecto real, solo un
/// guiño para quien la encuentre.
class _VersionEasterEgg extends StatefulWidget {
  const _VersionEasterEgg();

  @override
  State<_VersionEasterEgg> createState() => _VersionEasterEggState();
}

class _VersionEasterEggState extends State<_VersionEasterEgg> {
  static const _requiredTaps = 7;
  static const _tapWindow = Duration(seconds: 3);

  String? _version;
  int _tapCount = 0;
  DateTime? _firstTapAt;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  void _onTap() {
    final now = DateTime.now();
    if (_firstTapAt == null || now.difference(_firstTapAt!) > _tapWindow) {
      _firstTapAt = now;
      _tapCount = 1;
      return;
    }
    _tapCount++;
    if (_tapCount >= _requiredTaps) {
      _tapCount = 0;
      _firstTapAt = null;
      _showEasterEgg();
    }
  }

  Future<void> _showEasterEgg() async {
    HapticFeedback.mediumImpact();
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.easterEggTitle),
        content: Text(l10n.easterEggMessage),
        actions: [
          FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(l10n.easterEggAction)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final version = _version;
    if (version == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: InstriqSpacing.md),
        child: Text(
          'Instriq v$version',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}
