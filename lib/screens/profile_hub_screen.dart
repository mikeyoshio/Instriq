import 'package:flutter/material.dart';

import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_section_header.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/contributor_application.dart';
import '../services/auth_service.dart';
import '../services/contributor_service.dart';
import '../services/locale_service.dart';
import '../services/profile_service.dart';
import '../services/sync_queue_service.dart';
import '../services/theme_service.dart';
import 'account_privacy_screen.dart';
import 'admin/manage_hospital_screen.dart';
import 'contributor_application_form_screen.dart';
import 'contributor_profile_screen.dart';
import 'contributor_review_queue_screen.dart';
import 'global_catalog_review_queue_screen.dart';
import 'how_it_works_screen.dart';
import 'knowledge_dashboard_screen.dart';
import 'manage_teams_screen.dart';
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

  Future<void> _openContributorReviewQueue() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ContributorReviewQueueScreen()),
    );
    _refreshContributorState();
  }

  Future<void> _openGlobalCatalogReviewQueue() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const GlobalCatalogReviewQueueScreen()),
    );
    _refreshContributorState();
  }

  Future<void> _pickLanguage() async {
    final l10n = AppLocalizations.of(context)!;
    final locale = await showDialog<Locale>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.languageDialogTitle),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, const Locale('ca')),
            child: Text(l10n.languageCatalan),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, const Locale('es')),
            child: Text(l10n.languageSpanish),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, const Locale('en')),
            child: Text(l10n.languageEnglish),
          ),
        ],
      ),
    );
    if (locale != null) await LocaleService.instance.setLocale(locale);
  }

  Future<void> _openHowItWorks() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HowItWorksScreen()),
    );
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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navProfile)),
      body: SafeArea(
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
                onTap: _pickLanguage,
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
                title: l10n.howItWorksTitle,
                onTap: _openHowItWorks,
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
                      title: l10n.contributorReviewQueueTitle,
                      onTap: _openContributorReviewQueue,
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
              if (isAdmin) ...[
                const SizedBox(height: InstriqSpacing.xl),
                InstriqSectionHeader(l10n.manageGroupTitle),
                const SizedBox(height: InstriqSpacing.md),
                InstriqListItem(
                  icon: Icons.admin_panel_settings,
                  title: l10n.manageGroupTitle,
                  subtitle: l10n.manageGroupSubtitle,
                  onTap: _openManageHospital,
                ),
                const SizedBox(height: InstriqSpacing.sm),
                InstriqListItem(
                  icon: Icons.insights_outlined,
                  title: l10n.knowledgeDashboardTitle,
                  subtitle: l10n.knowledgeDashboardSubtitle,
                  onTap: _openKnowledgeDashboard,
                ),
                const SizedBox(height: InstriqSpacing.sm),
                InstriqListItem(
                  icon: Icons.groups_outlined,
                  title: l10n.manageTeamsTitle,
                  subtitle: l10n.manageTeamsSubtitle,
                  onTap: _openManageTeams,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
