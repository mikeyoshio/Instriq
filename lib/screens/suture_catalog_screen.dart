import 'package:flutter/material.dart';

import '../data/sutures_data.dart';
import '../l10n/app_localizations.dart';
import '../models/suture.dart';
import 'suture_detail_screen.dart';

/// Catàleg de sutures, paral·lel a [CatalogScreen] però deliberadament
/// separat: una sutura no és un instrument (és consumible, amb propietats
/// pròpies) encara que sigui també un ítem de referència estàtic que es
/// busca i s'aprèn. Sense quiz/flashcards en aquesta primera passada.
class SutureCatalogScreen extends StatefulWidget {
  const SutureCatalogScreen({super.key});

  @override
  State<SutureCatalogScreen> createState() => _SutureCatalogScreenState();
}

class _SutureCatalogScreenState extends State<SutureCatalogScreen> {
  String _query = '';
  final Set<SutureMaterial> _materialFilters = {};

  void _toggleMaterial(SutureMaterial m) {
    setState(() {
      if (!_materialFilters.add(m)) _materialFilters.remove(m);
    });
  }

  void _clearFilters() => setState(_materialFilters.clear);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = kSutures.where((s) {
      final matchesQuery = _query.isEmpty || s.name.toLowerCase().contains(_query.toLowerCase());
      final matchesMaterial = _materialFilters.isEmpty || _materialFilters.contains(s.material);
      return matchesQuery && matchesMaterial;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sutureCatalogTitle),
        actions: [
          if (_materialFilters.isNotEmpty)
            TextButton(
              onPressed: _clearFilters,
              child: Text(
                l10n.clearWithCount(_materialFilters.length),
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchSutureHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final m in SutureMaterial.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(m.label),
                      selected: _materialFilters.contains(m),
                      onSelected: (_) => _toggleMaterial(m),
                      showCheckmark: true,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text(l10n.noResultsFilters))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final suture = filtered[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.line_style),
                          title: Text(suture.name),
                          subtitle: Text('${suture.material.label} · ${suture.gauge}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => SutureDetailScreen(suture: suture)),
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
