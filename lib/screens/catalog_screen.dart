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
  InstrumentCategory? _categoryFilter;
  Specialty? _specialtyFilter;

  @override
  Widget build(BuildContext context) {
    final filtered = kInstruments.where((i) {
      final matchesQuery = _query.isEmpty ||
          i.name.toLowerCase().contains(_query.toLowerCase()) ||
          i.aliases.any((a) => a.toLowerCase().contains(_query.toLowerCase()));
      final matchesCategory = _categoryFilter == null || i.category == _categoryFilter;
      final matchesSpecialty = _specialtyFilter == null || i.specialty == _specialtyFilter;
      return matchesQuery && matchesCategory && matchesSpecialty;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
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
              child: Text('Especialidad', style: Theme.of(context).textTheme.labelMedium),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _FilterChip(
                  label: 'Todas',
                  selected: _specialtyFilter == null,
                  onTap: () => setState(() => _specialtyFilter = null),
                ),
                ...Specialty.values.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _FilterChip(
                      label: s.label,
                      selected: _specialtyFilter == s,
                      onTap: () => setState(() => _specialtyFilter = s),
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
                _FilterChip(
                  label: 'Todas',
                  selected: _categoryFilter == null,
                  onTap: () => setState(() => _categoryFilter = null),
                ),
                ...InstrumentCategory.values.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _FilterChip(
                      label: c.label,
                      selected: _categoryFilter == c,
                      onTap: () => setState(() => _categoryFilter = c),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('Sin resultados'))
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
