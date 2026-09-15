import 'package:flutter/material.dart';

import '../../design_system/components/instriq_list_item.dart';
import '../../design_system/components/instriq_responsive_content.dart';
import '../../design_system/components/instriq_section_header.dart';
import '../../design_system/tokens.dart';
import '../../help/help_content.dart';
import '../../l10n/app_localizations.dart';
import '../how_it_works_screen.dart';
import 'help_article_screen.dart';

/// Punt d'entrada de la wiki d'ajuda: la guia general ("Com funciona",
/// `HowItWorksScreen`, sense tocar) més una llista d'articles "com fer X"
/// agrupats per categoria, cadascun amb captures reals
/// (`help_content.dart`). Reemplaça l'antic accés directe a
/// `HowItWorksScreen` des de `ProfileHubScreen`.
class HelpHubScreen extends StatelessWidget {
  const HelpHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final categories = buildHelpCategories(l10n);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.helpCenterTitle)),
      body: SafeArea(
        child: InstriqResponsiveContent(
          child: ListView(
            padding: const EdgeInsets.all(InstriqSpacing.xl),
            children: [
              InstriqListItem(
                icon: Icons.menu_book_outlined,
                title: l10n.helpHowItWorksEntryTitle,
                subtitle: l10n.helpHowItWorksEntrySubtitle,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HowItWorksScreen()),
                ),
              ),
              for (final category in categories) ...[
                const SizedBox(height: InstriqSpacing.xl),
                InstriqSectionHeader(category.title),
                const SizedBox(height: InstriqSpacing.md),
                for (var i = 0; i < category.articles.length; i++) ...[
                  if (i != 0) const SizedBox(height: InstriqSpacing.sm),
                  InstriqListItem(
                    icon: category.articles[i].icon,
                    title: category.articles[i].title,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => HelpArticleScreen(article: category.articles[i])),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
