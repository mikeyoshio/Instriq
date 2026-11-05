import 'dart:async';

import 'package:flutter/material.dart';

import '../data/wound_closure_data.dart';
import '../l10n/app_localizations.dart';
import '../models/wound_closure_material.dart';
import '../utils/fuzzy_match.dart';
import '../widgets/wound_closure_labels.dart';
import 'wound_closure_detail_screen.dart';

/// Llistat del catàleg de material de tancament de ferides i hemostàtics.
/// Deliberadament sense modal de filtres (a diferència de `CatalogScreen`):
/// un únic filtre per `WoundClosureCategory` en forma de chips n'hi ha prou,
/// mateix criteri que `DrugCatalogScreen` per a un catàleg petit.
class WoundClosureCatalogScreen extends StatefulWidget {
  const WoundClosureCatalogScreen({super.key});

  @override
  State<WoundClosureCatalogScreen> createState() => _WoundClosureCatalogScreenState();
}

class _WoundClosureCatalogScreenState extends State<WoundClosureCatalogScreen> {
  String _query = '';
  final Set<WoundClosureCategory> _categoryFilters = {};

  // Mismo criterio que DrugCatalogScreen/CatalogScreen: evita repetir el
  // escaneo difuso en cada tecla dentro de build().
  Timer? _liveSearchDebounce;

  @override
  void dispose() {
    _liveSearchDebounce?.cancel();
    super.dispose();
  }

  void _toggleCategory(WoundClosureCategory c) {
    setState(() {
      if (!_categoryFilters.add(c)) _categoryFilters.remove(c);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;

    final filtered = kWoundClosureMaterials.where((m) {
      final matchesQuery = fuzzyContains(m.name.forLanguageCode(languageCode), _query) ||
          m.aliases.any((a) => fuzzyContains(a, _query));
      final matchesCategory = _categoryFilters.isEmpty || _categoryFilters.contains(m.category);
      return matchesQuery && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.woundClosureCatalogTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.woundClosureSearchHint,
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
                  for (final c in WoundClosureCategory.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(woundClosureCategoryValueLabel(l10n, c)),
                        selected: _categoryFilters.contains(c),
                        onSelected: (_) => _toggleCategory(c),
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
                      final material = filtered[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.healing_outlined),
                          title: Text(material.name.forLanguageCode(languageCode)),
                          subtitle: Text(woundClosureCategoryValueLabel(l10n, material.category)),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => WoundClosureDetailScreen(material: material)),
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
