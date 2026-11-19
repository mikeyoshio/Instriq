import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/technique_log_service.dart';

String techniqueStatusLabel(AppLocalizations l10n, TechniqueStatus s) => switch (s) {
      TechniqueStatus.notYet => l10n.techniqueNotYet,
      TechniqueStatus.practising => l10n.techniquePractising,
      TechniqueStatus.confident => l10n.techniqueConfident,
    };

IconData techniqueStatusIcon(TechniqueStatus s) => switch (s) {
      TechniqueStatus.notYet => Icons.radio_button_unchecked,
      TechniqueStatus.practising => Icons.timelapse,
      TechniqueStatus.confident => Icons.check_circle,
    };

/// "La meva pràctica" a la fitxa d'una guia.
class TechniqueStatusPicker extends StatelessWidget {
  final String guideId;

  const TechniqueStatusPicker({super.key, required this.guideId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ValueListenableBuilder(
      valueListenable: TechniqueLogService.instance.statuses,
      builder: (context, _, __) {
        final current = TechniqueLogService.instance.statusOf(guideId);
        return Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.techniqueMyPractice, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in TechniqueStatus.values)
                    ChoiceChip(
                      avatar: Icon(techniqueStatusIcon(s), size: 18),
                      label: Text(techniqueStatusLabel(l10n, s)),
                      selected: current == s,
                      onSelected: (_) => TechniqueLogService.instance.set(guideId, s),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(l10n.techniquePrivateNote, style: theme.textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}
