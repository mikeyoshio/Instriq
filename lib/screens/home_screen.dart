import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import '../services/theme_service.dart';
import 'account_privacy_screen.dart';
import 'admin/manage_hospital_screen.dart';
import 'auth/hospital_connect_flow.dart';
import 'catalog_screen.dart';
import 'group_document_review_queue_screen.dart';
import 'learn_screen.dart';
import 'progress_screen.dart';
import 'workspace_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _refresh() => setState(() {});

  bool get _isConnected =>
      AuthService.instance.currentUser != null && ProfileService.instance.hasHospital;

  Future<void> _openHospitalConnectFlow() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HospitalConnectFlow()),
    );
    _refresh();
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = ProgressService.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instriq'),
        actions: [
          IconButton(
            tooltip: l10n.languageTooltip,
            icon: const Icon(Icons.language),
            onPressed: _pickLanguage,
          ),
          IconButton(
            tooltip: l10n.themeToggleTooltip,
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => ThemeService.instance.toggle(Theme.of(context).brightness),
          ),
          if (AuthService.instance.currentUser != null)
            IconButton(
              tooltip: l10n.accountTooltip,
              icon: const Icon(Icons.privacy_tip_outlined),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AccountPrivacyScreen()),
                );
                _refresh();
              },
            ),
          if (AuthService.instance.currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await AuthService.instance.signOut();
                // loadProfile() detecta que ya no hay sesión y limpia el
                // caché de grupo/espacios; sin esto quedaba en memoria.
                await ProfileService.instance.loadProfile();
                _refresh();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.learnInstrumentsHeadline,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.overallProgress,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.progressCount(progress.learnedCount, progress.totalCount),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              _MenuCard(
                icon: Icons.menu_book,
                title: l10n.catalogTitle,
                subtitle: l10n.catalogSubtitle,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CatalogScreen()),
                  );
                  _refresh();
                },
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.school,
                title: l10n.learnTitle,
                subtitle: l10n.learnSubtitle,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LearnScreen()),
                  );
                  _refresh();
                },
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.bar_chart,
                title: l10n.myProgressTitle,
                subtitle: l10n.myProgressSubtitle,
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProgressScreen()),
                  );
                  _refresh();
                },
              ),
              const SizedBox(height: 24),
              Text(l10n.myGroup, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_isConnected) ...[
                _MenuCard(
                  icon: Icons.workspaces_outlined,
                  title: l10n.spacesTitle,
                  subtitle: ProfileService.instance.hospitalName ?? l10n.spacesSubtitleDefault,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WorkspaceListScreen()),
                    );
                    _refresh();
                  },
                ),
                if (ProfileService.instance.isAdmin) ...[
                  const SizedBox(height: 12),
                  _MenuCard(
                    icon: Icons.admin_panel_settings,
                    title: l10n.manageGroupTitle,
                    subtitle: l10n.manageGroupSubtitle,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ManageHospitalScreen()),
                      );
                      _refresh();
                    },
                  ),
                  const SizedBox(height: 12),
                  _MenuCard(
                    icon: Icons.rate_review_outlined,
                    title: l10n.reviewQueueTitle,
                    subtitle: l10n.reviewQueueSubtitle,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const GroupDocumentReviewQueueScreen()),
                      );
                      _refresh();
                    },
                  ),
                ],
              ] else
                _MenuCard(
                  icon: Icons.groups_outlined,
                  title: l10n.connectGroupTitle,
                  subtitle: l10n.connectGroupSubtitle,
                  onTap: _openHospitalConnectFlow,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
