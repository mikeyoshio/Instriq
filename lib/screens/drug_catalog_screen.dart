import 'dart:async';

import 'package:flutter/material.dart';

import '../data/drugs_data.dart';
import '../l10n/app_localizations.dart';
import '../models/drug.dart';
import '../utils/fuzzy_match.dart';
import '../widgets/drug_labels.dart';
import 'drug_detail_screen.dart';

/// Llistat del catàleg de farmacologia d'anestèsia. Deliberadament sense
/// modal de filtres (a diferència de `CatalogScreen`): un únic filtre per
/// `DrugClass` en forma de chips n'hi ha prou, no calen categories ni
/// especialitat per a només 22 fàrmacs.
class DrugCatalogScreen extends StatefulWidget {
  const DrugCatalogScreen({super.key});

  @override
  State<DrugCatalogScreen> createState() => _DrugCatalogScreenState();
}

class _DrugCatalogScreenState extends State<DrugCatalogScreen> {
  String _query = '';
  final Set<DrugClass> _classFilters = {};

  // Mismo criterio que CatalogScreen: evita repetir el escaneo difuso en
  // cada tecla dentro de build().
  Timer? _liveSearchDebounce;

  @override
  void dispose() {
    _liveSearchDebounce?.cancel();
    super.dispose();
  }

  void _toggleClass(DrugClass c) {
    setState(() {
      if (!_classFilters.add(c)) _classFilters.remove(c);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    final filtered = kDrugs.where((d) {
      final matchesQuery = fuzzyContains(d.name.forLanguageCode(languageCode), _query) ||
          d.aliases.any((a) => fuzzyContains(a, _query));
      final matchesClass = _classFilters.isEmpty || _classFilters.contains(d.drugClass);
      return matchesQuery && matchesClass;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.drugsCatalogTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.drugSearchHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) {
                _liveSearchDebounce?.cancel();
                _liveSearchDebounce = Timer(const Duration(milliseconds: 150), () {
                  if (!mounted) return;
                  setState(() => _query = v);
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final c in DrugClass.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(drugClassValueLabel(l10n, c)),
                        selected: _classFilters.contains(c),
                        onSelected: (_) => _toggleClass(c),
                        showCheckmark: true,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text(l10n.noResultsFilters))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final drug = filtered[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.medication_outlined),
                          title: Text(drug.name.forLanguageCode(languageCode)),
                          subtitle: Text(
                            '${drugClassValueLabel(l10n, drug.drugClass)} · ${drug.routes.join(', ')}',
                          ),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => DrugDetailScreen(drug: drug)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
