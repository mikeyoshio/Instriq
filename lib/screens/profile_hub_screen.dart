import 'package:flutter/material.dart';

import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_section_header.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../services/profile_service.dart';
import '../services/theme_service.dart';
import 'account_privacy_screen.dart';
import 'admin/manage_hospital_screen.dart';
import 'knowledge_dashboard_screen.dart';

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
  void _refresh() => setState(() {});

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

  Future<void> _openAccountPrivacy() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AccountPrivacyScreen()),
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
                InstriqListItem(
                  icon: Icons.logout,
                  title: l10n.signOut,
                  onTap: _signOut,
                ),
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
              ],
            ],
          ),
        ),
      ),
    );
  }
}
