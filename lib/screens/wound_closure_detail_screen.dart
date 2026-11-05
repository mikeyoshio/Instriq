import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/wound_closure_material.dart';
import '../services/usage_analytics_service.dart';
import '../widgets/wound_closure_labels.dart';

/// Fitxa d'un material del catàleg de tancament de ferides i hemostàtics.
/// L'avís clínic és sempre visible (no un tooltip amagat): aquest catàleg és
/// referència educativa, mai substitueix la fitxa tècnica del fabricant ni
/// el protocol de la institució.
class WoundClosureDetailScreen extends StatefulWidget {
  final WoundClosureMaterial material;

  const WoundClosureDetailScreen({super.key, required this.material});

  @override
  State<WoundClosureDetailScreen> createState() => _WoundClosureDetailScreenState();
}

class _WoundClosureDetailScreenState extends State<WoundClosureDetailScreen> {
  static const String _refType = 'wound_closure';

  @override
  void initState() {
    super.initState();
    // Igual que el catàleg d'instruments i de fàrmacs: es registra també per
    // a convidats, és contingut accessible sense compte (ver commit 36a13252).
    UsageAnalyticsService.instance.recordView(_refType, widget.material.id);
  }

  @override
  Widget build(BuildContext context) {
    final material = widget.material;
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(material.name.forLanguageCode(languageCode))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_outlined, color: Theme.of(context).colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.woundClosureDetailDisclaimer,
                        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [Chip(label: Text(woundClosureCategoryValueLabel(l10n, material.category)))],
            ),
            if (material.aliases.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l10n.alsoKnownAs, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(material.aliases.join(', ')),
            ],
            const SizedBox(height: 16),
            Text(l10n.descriptionLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(material.description.forLanguageCode(languageCode), style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text(l10n.mainUseLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(material.use.forLanguageCode(languageCode), style: Theme.of(context).textTheme.bodyLarge),
            if (material.tip != null) ...[
              const SizedBox(height: 16),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline),
                      const SizedBox(width: 8),
                      Expanded(child: Text(material.tip!.forLanguageCode(languageCode))),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
