import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../models/instrument.dart';
import '../services/progress_service.dart';
import '../widgets/category_icon.dart';
import 'instrument_detail_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  String _query = '';
  final Set<InstrumentCategory> _categoryFilters = {};
  final Set<Specialty> _specialtyFilters = {};

  int get _activeFilterCount => _categoryFilters.length + _specialtyFilters.length;

  void _toggleSpecialty(Specialty s) {
    setState(() {
      if (!_specialtyFilters.add(s)) _specialtyFilters.remove(s);
    });
  }

  void _toggleCategory(InstrumentCategory c) {
    setState(() {
      if (!_categoryFilters.add(c)) _categoryFilters.remove(c);
    });
  }

  void _clearFilters() {
    setState(() {
      _specialtyFilters.clear();
      _categoryFilters.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = kInstruments.where((i) {
      final matchesQuery = _query.isEmpty ||
          i.name.toLowerCase().contains(_query.toLowerCase()) ||
          i.aliases.any((a) => a.toLowerCase().contains(_query.toLowerCase()));
      final matchesCategory = _categoryFilters.isEmpty || _categoryFilters.contains(i.category);
      final matchesSpecialty = _specialtyFilters.isEmpty || _specialtyFilters.contains(i.specialty);
      return matchesQuery && matchesCategory && matchesSpecialty;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          if (_activeFilterCount > 0)
            TextButton(
              onPressed: _clearFilters,
              child: Text(
                'Limpiar ($_activeFilterCount)',
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
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar instrumento o marca comercial...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Especialidad — toca varias a la vez',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                ...Specialty.values.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _MultiFilterChip(
                      label: s.label,
                      selected: _specialtyFilters.contains(s),
                      onTap: () => _toggleSpecialty(s),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Categoría', style: Theme.of(context).textTheme.labelMedium),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                ...InstrumentCategory.values.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _MultiFilterChip(
                      label: c.label,
                      selected: _categoryFilters.contains(c),
                      onTap: () => _toggleCategory(c),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${filtered.length} instrumento${filtered.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Sin resultados con estos filtros'),
                        if (_activeFilterCount > 0) ...[
                          const SizedBox(height: 8),
                          TextButton(onPressed: _clearFilters, child: const Text('Limpiar filtros')),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final instrument = filtered[index];
                      final learned =
                          ProgressService.instance.isLearned(instrument.id);
                      return Card(
                        child: ListTile(
                          leading: InstrumentIcon(
                            iconKey: instrument.icon,
                            category: instrument.category,
                            size: 48,
                          ),
                          title: Text(instrument.name),
                          subtitle: Text('${instrument.specialty.label} · ${instrument.category.label}'),
                          trailing: learned
                              ? const Icon(Icons.check_circle, color: Colors.green)
                              : const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    InstrumentDetailScreen(instrument: instrument),
                              ),
                            );
                            setState(() {});
                          },
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

class _MultiFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MultiFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: true,
    );
  }
}
