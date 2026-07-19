import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import '../services/theme_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Instriq'),
        actions: [
          IconButton(
            tooltip: 'Cambiar tema claro/oscuro',
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () => ThemeService.instance.toggle(Theme.of(context).brightness),
          ),
          if (AuthService.instance.currentUser != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await AuthService.instance.signOut();
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
                'Aprende el instrumental de quirófano',
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
                '${progress.learnedCount} de ${progress.totalCount} instrumentos aprendidos',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              _MenuCard(
                icon: Icons.menu_book,
                title: 'Catálogo',
                subtitle: 'Explora todo el instrumental por categoría',
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
                title: 'Aprende',
                subtitle: 'Flashcards y quiz para repasar el instrumental',
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
                title: 'Mi progreso',
                subtitle: 'Revisa tu avance por categoría',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProgressScreen()),
                  );
                  _refresh();
                },
              ),
              const SizedBox(height: 24),
              Text('Mi grupo', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_isConnected) ...[
                _MenuCard(
                  icon: Icons.workspaces_outlined,
                  title: 'Espacios',
                  subtitle: ProfileService.instance.hospitalName ??
                      'Técnicas, protocolos y tarjetas de preferencia por especialidad o servicio',
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
                    title: 'Administrar grupo',
                    subtitle: 'Código de invitación y miembros',
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
                    title: 'Revisar cambios pendientes',
                    subtitle: 'Aprueba o rechaza técnicas y protocolos en revisión',
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
                  title: 'Conecta con tu grupo',
                  subtitle: 'Únete con un código o crea el tuyo para compartir conocimiento con tu equipo',
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
