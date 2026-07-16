import 'package:flutter/material.dart';

import '../services/progress_service.dart';
import 'catalog_screen.dart';
import 'flashcards_screen.dart';
import 'preference_cards_screen.dart';
import 'progress_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final progress = ProgressService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Instrumental Qx')),
      body: SafeArea(
        child: Padding(
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
                icon: Icons.style,
                title: 'Flashcards',
                subtitle: 'Estudia con tarjetas de repaso',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
                  );
                  _refresh();
                },
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.quiz,
                title: 'Quiz',
                subtitle: 'Ponte a prueba con preguntas rápidas',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const QuizScreen()),
                  );
                  _refresh();
                },
              ),
              const SizedBox(height: 12),
              _MenuCard(
                icon: Icons.assignment_ind,
                title: 'Tarjetas de preferencia',
                subtitle: 'Instrumental específico por cirujano y procedimiento',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PreferenceCardsScreen()),
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
