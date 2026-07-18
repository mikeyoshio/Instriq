import 'package:flutter/material.dart';

import 'flashcards_screen.dart';
import 'quiz_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aprende')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Elige cómo quieres repasar el instrumental',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              _LearnCard(
                icon: Icons.style,
                title: 'Flashcards',
                subtitle: 'Estudia con tarjetas de repaso',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _LearnCard(
                icon: Icons.quiz,
                title: 'Quiz',
                subtitle: 'Ponte a prueba con preguntas rápidas',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuizScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearnCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LearnCard({
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
