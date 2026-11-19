import 'package:flutter/material.dart';

import '../data/perioperative_guides_data.dart';
import '../l10n/app_localizations.dart';
import '../models/perioperative_guide.dart';
import '../services/technique_log_service.dart';
import '../widgets/technique_status_picker.dart';
import 'perioperative_guides_screen.dart';

/// "Les meves tècniques": les guies amb el que ja has fet i com t'hi sents.
class MyTechniquesScreen extends StatelessWidget {
  const MyTechniquesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.myTechniquesTitle)),
      body: ValueListenableBuilder(
        valueListenable: TechniqueLogService.instance.statuses,
        builder: (context, statuses, _) {
          final done = kPerioperativeGuides.where((g) => statuses.containsKey(g.id)).length;
          final confident = statuses.values.where((s) => s == TechniqueStatus.confident).length;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.myTechniquesProgress(done, kPerioperativeGuides.length, confident),
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: done / kPerioperativeGuides.length),
                      const SizedBox(height: 8),
                      Text(l10n.techniquePrivateNote, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
              for (final area in GuideArea.values) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 16, 4, 4),
                  child: Text(guideAreaLabel(l10n, area).toUpperCase(), style: theme.textTheme.labelLarge),
                ),
                for (final g in kPerioperativeGuides.where((g) => g.area == area))
                  ListTile(
                    leading: Icon(techniqueStatusIcon(TechniqueLogService.instance.statusOf(g.id))),
                    title: Text(g.name.forLanguageCode(lang)),
                    subtitle: Text(techniqueStatusLabel(l10n, TechniqueLogService.instance.statusOf(g.id))),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PerioperativeGuideDetailScreen(guide: g)),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
