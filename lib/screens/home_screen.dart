import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_section_header.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import 'auth/hospital_connect_flow.dart';
import 'catalog_screen.dart';
import 'learn_screen.dart';
import 'progress_screen.dart';
import 'workspace_list_screen.dart';

/// Destino "Inicio" del shell (ver navigation/app_shell.dart). Perfil,
/// Biblioteca y Actividad viven ahora en sus propias pantallas del shell —
/// esto solo conserva el acceso rápido a catálogo/aprender/progreso y el
/// atajo a Espacios/conectar grupo.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _appVersion;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = info.version);
    });
  }

  void _refresh() => setState(() {});

  bool get _isConnected =>
      AuthService.instance.currentUser != null && ProfileService.instance.hasHospital;

  Future<void> _openHospitalConnectFlow() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const HospitalConnectFlow()),
    );
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = ProgressService.instance;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Instriq'),
            if (_appVersion != null) ...[
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'v$_appVersion',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(InstriqSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.learnInstrumentsHeadline,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: InstriqSpacing.lg),
              ClipRRect(
                borderRadius: BorderRadius.circular(InstriqRadius.sm),
                child: LinearProgressIndicator(
                  value: progress.overallProgress,
                  minHeight: 10,
                ),
              ),
              const SizedBox(height: InstriqSpacing.sm),
              Text(
                l10n.progressCount(progress.learnedCount, progress.totalCount),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: InstriqSpacing.xxl),
              InstriqListItem(
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
              const SizedBox(height: InstriqSpacing.md),
              InstriqListItem(
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
              const SizedBox(height: InstriqSpacing.md),
              InstriqListItem(
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
              const SizedBox(height: InstriqSpacing.xl),
              InstriqSectionHeader(l10n.myGroup),
              const SizedBox(height: InstriqSpacing.md),
              if (_isConnected)
                InstriqListItem(
                  icon: Icons.workspaces_outlined,
                  title: l10n.spacesTitle,
                  subtitle: ProfileService.instance.hospitalName ?? l10n.spacesSubtitleDefault,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const WorkspaceListScreen()),
                    );
                    _refresh();
                  },
                )
              else
                InstriqListItem(
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
