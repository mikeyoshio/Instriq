import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../models/instrument.dart';
import 'category_icon.dart';

/// Hoja modal para elegir un instrumento del catálogo. Se usa en tarjetas de
/// preferencia y en técnicas/protocolos para enlazar instrumental relacionado.
/// Devuelve el [Instrument] elegido, o null si se cierra sin elegir.
class CatalogPickerSheet extends StatefulWidget {
  const CatalogPickerSheet({super.key});

  @override
  State<CatalogPickerSheet> createState() => _CatalogPickerSheetState();
}

class _CatalogPickerSheetState extends State<CatalogPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = kInstruments
        .where((i) => _query.isEmpty || i.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar instrumento...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final instrument = filtered[index];
                    return ListTile(
                      leading: InstrumentIcon(
                        iconKey: instrument.icon,
                        category: instrument.category,
                        size: 40,
                      ),
                      title: Text(instrument.name),
                      subtitle: Text(instrument.category.label),
                      onTap: () => Navigator.of(context).pop(instrument),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
