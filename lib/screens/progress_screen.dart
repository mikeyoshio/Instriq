import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/instrument.dart';
import '../services/progress_service.dart';
import '../widgets/category_icon.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final progress = ProgressService.instance;
    final bestQuiz = progress.quizBestScore(null);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myProgressTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.overallProgressLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: progress.overallProgress, minHeight: 12),
          ),
          const SizedBox(height: 6),
          Text(l10n.progressCount(progress.learnedCount, progress.totalCount)),
          if (progress.dueCount() > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined, size: 18),
                const SizedBox(width: 8),
                Text(l10n.reviewsDueTodayLabel(progress.dueCount())),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text(l10n.bestQuizScoreLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(l10n.scoreOutOfTen(bestQuiz)),
          const SizedBox(height: 24),
          Text(l10n.byCategoryLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          ...InstrumentCategory.values.map((c) {
            final learned = progress.learnedCountForCategory(c);
            final total = progress.totalCountForCategory(c);
            final value = total == 0 ? 0.0 : learned / total;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorForCategory(c),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(value: value, minHeight: 8),
                        ),
                        const SizedBox(height: 2),
                        Text(l10n.learnedFraction(learned, total)),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.resetProgressTitle),
                  content: Text(l10n.resetProgressBody),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.resetLabel)),
                  ],
                ),
              );
              if (confirmed == true) {
                await progress.resetProgress();
                setState(() {});
              }
            },
            icon: const Icon(Icons.restart_alt),
            label: Text(l10n.resetProgressTitle),
          ),
        ],
      ),
    );
  }
}
