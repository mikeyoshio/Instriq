import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// "Com funciona" -- pantalla d'ajuda en llenguatge planer, pensada perquè
/// sigui fàcil de fer servir amb qualsevol limitació (visual, motora,
/// cognitiva o amb lector de pantalla). Per això, deliberadament:
/// - Una sola pàgina que es desplaça (`ListView`), sense `ExpansionTile` ni
///   pestanyes -- cap contingut amagat rere un toc addicional.
/// - Text a mida `bodyLarge` (16sp), no `bodyMedium` -- més llegible.
/// - Frases curtes, una idea per paràgraf, sense argot tècnic.
/// - Capçaleres en `titleLarge` (no versemblança amb `InstriqSectionHeader`,
///   pensat per a llistes compactes, no per a contingut de lectura).
class HowItWorksScreen extends StatelessWidget {
  const HowItWorksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    Widget section(IconData icon, String title, String body) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 28),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: textTheme.titleLarge)),
              ],
            ),
            const SizedBox(height: 8),
            Text(body, style: textTheme.bodyLarge),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.howItWorksTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l10n.howItWorksIntro, style: textTheme.bodyLarge),
            const SizedBox(height: 28),
            section(Icons.home_outlined, l10n.navHome, l10n.howItWorksHomeBody),
            section(Icons.search_outlined, l10n.navSearch, l10n.howItWorksSearchBody),
            section(Icons.local_library_outlined, l10n.navLibrary, l10n.howItWorksLibraryBody),
            section(Icons.notifications_outlined, l10n.navActivity, l10n.howItWorksActivityBody),
            section(Icons.person_outline, l10n.navProfile, l10n.howItWorksProfileBody),
            section(Icons.tips_and_updates_outlined, l10n.howItWorksTipsTitle, l10n.howItWorksTipsBody),
            section(Icons.accessibility_new_outlined, l10n.howItWorksAccessibilityTitle, l10n.howItWorksAccessibilityBody),
          ],
        ),
      ),
    );
  }
}
