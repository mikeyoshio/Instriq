import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/drug.dart';
import '../services/usage_analytics_service.dart';
import '../widgets/drug_labels.dart';

/// Fitxa d'un fàrmac del catàleg de farmacologia d'anestèsia. El disclaimer
/// clínic és sempre visible (no un tooltip amagat): aquest catàleg és
/// referència educativa, mai substitueix la fitxa tècnica oficial, les
/// guies de la institució ni el criteri clínic, i mai inclou dosis.
class DrugDetailScreen extends StatefulWidget {
  final Drug drug;

  const DrugDetailScreen({super.key, required this.drug});

  @override
  State<DrugDetailScreen> createState() => _DrugDetailScreenState();
}

class _DrugDetailScreenState extends State<DrugDetailScreen> {
  static const String _refType = 'drug';

  @override
  void initState() {
    super.initState();
    // Igual que el catàleg d'instruments: es registra també per a convidats,
    // és contingut accessible sense compte.
    UsageAnalyticsService.instance.recordView(_refType, widget.drug.id);
  }

  @override
  Widget build(BuildContext context) {
    final drug = widget.drug;
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(drug.name.forLanguageCode(languageCode))),
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
                        l10n.drugDetailDisclaimer,
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
              children: [Chip(label: Text(drugClassValueLabel(l10n, drug.drugClass)))],
            ),
            const SizedBox(height: 16),
            Text(l10n.drugRoutesLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final route in drug.routes) Chip(label: Text(route))],
            ),
            if (drug.aliases.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(l10n.alsoKnownAs, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(drug.aliases.join(', ')),
            ],
            const SizedBox(height: 16),
            Text(l10n.descriptionLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(drug.description.forLanguageCode(languageCode), style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text(l10n.mainUseLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(drug.use.forLanguageCode(languageCode), style: Theme.of(context).textTheme.bodyLarge),
            if (drug.tip != null) ...[
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
                      Expanded(child: Text(drug.tip!.forLanguageCode(languageCode))),
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
