import 'package:flutter/material.dart';

import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_responsive_content.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import 'ecg_screen.dart';
import 'flashcards_screen.dart';
import 'lookalike_quiz_screen.dart';
import 'my_techniques_screen.dart';
import 'quiz_screen.dart';
import 'reference_study_screen.dart';
import 'team_quizzes_screen.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.learnTitle)),
      body: SafeArea(
        child: InstriqResponsiveContent(
        // ListView: amb 7 targetes, en finestres baixes (portàtils de 768 px)
        // les últimes quedaven tallades i no s'hi podia arribar.
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: ListView(
            children: [
              Text(
                l10n.chooseReviewMode,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              _LearnCard(
                icon: Icons.style,
                title: l10n.flashcardsTitle,
                subtitle: l10n.flashcardsSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FlashcardsScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _LearnCard(
                icon: Icons.quiz,
                title: l10n.quizTitle,
                subtitle: l10n.quizSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuizScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _LearnCard(
                icon: Icons.compare_outlined,
                title: l10n.lookalikeQuizTitle,
                subtitle: l10n.lookalikeQuizSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LookalikeQuizScreen()),
                ),
              ),
              _LearnCard(
                icon: Icons.airline_seat_flat_outlined,
                title: l10n.referenceStudyTitle,
                subtitle: l10n.referenceStudySubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReferenceFlashcardsScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _LearnCard(
                icon: Icons.help_outline,
                title: l10n.positionQuizTitle,
                subtitle: l10n.positionQuizSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PositionQuizScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _LearnCard(
                icon: Icons.task_alt,
                title: l10n.myTechniquesTitle,
                subtitle: l10n.myTechniquesSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MyTechniquesScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _LearnCard(
                icon: Icons.monitor_heart_outlined,
                title: l10n.ecgTitle,
                subtitle: l10n.ecgSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EcgScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _LearnCard(
                icon: Icons.groups_outlined,
                title: l10n.teamQuizzesMenuTitle,
                subtitle: l10n.teamQuizzesMenuSubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const TeamQuizzesScreen()),
                ),
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: InstriqSpacing.sm),
      child: InstriqListItem(icon: icon, title: title, subtitle: subtitle, onTap: onTap),
    );
  }
}
