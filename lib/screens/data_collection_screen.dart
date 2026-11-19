import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

/// "Quines dades recull Instriq": explicació en llenguatge planer del que
/// es compta, com i què no surt mai del dispositiu. Ha de coincidir amb
/// `record_usage_event` (supabase/schema_v74_usage_events_anonymous.sql).
class DataCollectionScreen extends StatelessWidget {
  const DataCollectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    Widget section(String title, String body) => Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(body, style: theme.textTheme.bodyLarge),
            ],
          ),
        );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.dataCollectionTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l10n.dataCollectionIntro, style: theme.textTheme.bodyLarge),
          section(l10n.dataCollectionCountedTitle, l10n.dataCollectionCountedBody),
          section(l10n.dataCollectionHowTitle, l10n.dataCollectionHowBody),
          section(l10n.dataCollectionNeverTitle, l10n.dataCollectionNeverBody),
          section(l10n.dataCollectionAccountTitle, l10n.dataCollectionAccountBody),
        ],
      ),
    );
  }
}
