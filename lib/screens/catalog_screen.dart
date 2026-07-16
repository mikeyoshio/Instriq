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
  InstrumentCategory? _filter;

  @override
  Widget build(BuildContext context) {
    final filtered = kInstruments.where((i) {
      final matchesQuery = _query.isEmpty ||
          i.name.toLowerCase().contains(_query.toLowerCase()) ||
          i.aliases.any((a) => a.toLowerCase().contains(_query.toLowerCase()));
      final matchesCategory = _filter == null || i.category == _filter;
      return matchesQuery && matchesCategory;
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
                hintText: 'Buscar instrumento...',
                border: OutlineInputBorder(),
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
                _CategoryChip(
                  label: 'Todas',
                  selected: _filter == null,
                  onTap: () => setState(() => _filter = null),
                ),
                ...InstrumentCategory.values.map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _CategoryChip(
                      label: c.label,
                      selected: _filter == c,
                      onTap: () => setState(() => _filter = c),
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
                          subtitle: Text(instrument.category.label),
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
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
