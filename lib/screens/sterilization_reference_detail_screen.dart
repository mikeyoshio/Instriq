import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/instrument_sterilization.dart' show SterilizationMethodLabel;
import '../models/sterilization_reference.dart';
import '../services/usage_analytics_service.dart';
import '../widgets/sterilization_method_label.dart';

/// Fitxa d'un mètode del catàleg de referència "Esterilització i
/// reprocessat". A diferència de `DrugDetailScreen`, sense cap avís/
/// disclaimer: això és rerefons tècnic de procés, no contingut amb risc de
/// dosi ni de substituir criteri clínic.
class SterilizationReferenceDetailScreen extends StatefulWidget {
  final SterilizationMethodReference reference;

  const SterilizationReferenceDetailScreen({super.key, required this.reference});

  @override
  State<SterilizationReferenceDetailScreen> createState() => _SterilizationReferenceDetailScreenState();
}

class _SterilizationReferenceDetailScreenState extends State<SterilizationReferenceDetailScreen> {
  static const String _refType = 'sterilization_reference';

  @override
  void initState() {
    super.initState();
    // Igual que el catàleg de fàrmacs/instruments: es registra sempre, també
    // per a convidats -- mai dins d'un guard d'autenticació (ver commit
    // 36a13252, que va arreglar exactament aquest bug a altres fitxes).
    UsageAnalyticsService.instance.recordView(_refType, widget.reference.method.dbValue);
  }

  @override
  Widget build(BuildContext context) {
    final reference = widget.reference;
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(sterilizationMethodValueLabel(l10n, reference.method))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reference.aliases.isNotEmpty) ...[
              Text(l10n.alsoKnownAs, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(reference.aliases.join(', ')),
              const SizedBox(height: 16),
            ],
            Text(l10n.descriptionLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(reference.description.forLanguageCode(languageCode), style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text(l10n.mainUseLabel, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(reference.use.forLanguageCode(languageCode), style: Theme.of(context).textTheme.bodyLarge),
            if (reference.tip != null) ...[
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
                      Expanded(child: Text(reference.tip!.forLanguageCode(languageCode))),
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
