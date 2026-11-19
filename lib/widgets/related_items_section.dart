import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../l10n/app_localizations.dart';
import '../screens/instrument_detail_screen.dart';

/// Xips amb el material del catàleg que esmenta una postura o una guia;
/// cada xip obre la fitxa de l'instrument.
class RelatedItemsSection extends StatelessWidget {
  final List<String> ids;

  const RelatedItemsSection({super.key, required this.ids});

  @override
  Widget build(BuildContext context) {
    final items = [for (final id in ids) ...kInstruments.where((i) => i.id == id)];
    if (items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.relatedItemsLabel, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final i in items)
                ActionChip(
                  label: Text(i.name.forLanguageCode(lang)),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => InstrumentDetailScreen(instrument: i)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
