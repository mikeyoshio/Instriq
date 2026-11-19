import 'package:flutter/material.dart';

import '../data/acronyms_data.dart';
import '../l10n/app_localizations.dart';
import '../models/acronym.dart';
import '../utils/fuzzy_match.dart';
import '../widgets/flip_deck.dart';

String acronymAreaLabel(AppLocalizations l10n, AcronymArea a) => switch (a) {
      AcronymArea.quirofano => l10n.acronymAreaTheatre,
      AcronymArea.anestesia => l10n.acronymAreaAnaesthesia,
      AcronymArea.monitorizacion => l10n.acronymAreaMonitoring,
      AcronymArea.procedimientos => l10n.acronymAreaProcedures,
      AcronymArea.general => l10n.acronymAreaGeneral,
    };

/// Glossari de sigles: consulta amb cerca i filtre, i repàs amb targetes.
class AcronymsScreen extends StatefulWidget {
  const AcronymsScreen({super.key});

  @override
  State<AcronymsScreen> createState() => _AcronymsScreenState();
}

class _AcronymsScreenState extends State<AcronymsScreen> {
  String _query = '';
  AcronymArea? _area;
  bool _review = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final filtered = kAcronyms.where((a) {
      final q = _query.trim().toLowerCase();
      final matches = q.isEmpty ||
          a.abbr.toLowerCase().startsWith(q) ||
          fuzzyContains(a.meaning.forLanguageCode(lang), _query);
      return matches && (_area == null || a.area == _area);
    }).toList()
      ..sort((a, b) => a.abbr.toLowerCase().compareTo(b.abbr.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.acronymsTitle),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _review = !_review),
            icon: Icon(_review ? Icons.list : Icons.style_outlined),
            label: Text(_review ? l10n.acronymsBrowse : l10n.acronymsReview),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_review)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: l10n.acronymsSearchHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          SizedBox(
            height: 56,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              scrollDirection: Axis.horizontal,
              children: [
                for (final a in AcronymArea.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(acronymAreaLabel(l10n, a)),
                      selected: _area == a,
                      onSelected: (_) => setState(() => _area = _area == a ? null : a),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _review
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: FlipDeck(
                      key: ValueKey(_area),
                      cards: [
                        for (final a in filtered)
                          (acronymAreaLabel(l10n, a.area), a.abbr, a.meaning.forLanguageCode(lang)),
                      ],
                    ),
                  )
                : filtered.isEmpty
                    ? Center(child: Text(l10n.noResultsFilters))
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final a = filtered[i];
                          return ListTile(
                            leading: SizedBox(
                              width: 72,
                              child: Text(a.abbr,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ),
                            title: Text(a.meaning.forLanguageCode(lang)),
                            subtitle: Text(acronymAreaLabel(l10n, a.area)),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
