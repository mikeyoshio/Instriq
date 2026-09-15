import 'package:flutter/material.dart';

import '../../design_system/components/instriq_responsive_content.dart';
import '../../design_system/tokens.dart';
import '../../models/help_article.dart';

/// Renderitzador genèric d'un article de la wiki d'ajuda: intro + passos
/// numerats, cadascun amb una captura real opcional. Un sol widget per a
/// tots els articles -- el contingut viu a `help_content.dart`, no aquí.
class HelpArticleScreen extends StatelessWidget {
  final HelpArticle article;

  const HelpArticleScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(article.title)),
      body: SafeArea(
        child: InstriqResponsiveContent(
          child: ListView(
            padding: const EdgeInsets.all(InstriqSpacing.xl),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(article.icon, size: 28, color: InstriqColors.accent),
                  const SizedBox(width: InstriqSpacing.md),
                  Expanded(child: Text(article.intro, style: textTheme.bodyLarge)),
                ],
              ),
              const SizedBox(height: InstriqSpacing.xl),
              for (var i = 0; i < article.steps.length; i++) ...[
                _StepTile(index: i + 1, step: article.steps[i]),
                if (i != article.steps.length - 1) const SizedBox(height: InstriqSpacing.xl),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final int index;
  final HelpStep step;

  const _StepTile({required this.index, required this.step});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: InstriqColors.accent,
              foregroundColor: InstriqColors.onAccent,
              child: Text('$index', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: InstriqSpacing.md),
            Expanded(child: Text(step.text, style: theme.textTheme.bodyLarge)),
          ],
        ),
        if (step.image != null) ...[
          const SizedBox(height: InstriqSpacing.md),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: ClipRRect(
              borderRadius: InstriqRadius.mdRadius,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: isDark ? InstriqColors.borderDark : InstriqColors.borderLight),
                  borderRadius: InstriqRadius.mdRadius,
                ),
                child: Image.asset(step.image!),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
