import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/instrument.dart';
import '../models/tray.dart';
import 'category_icon.dart';

/// Hoja modal para añadir un item a una bandeja: a diferencia de
/// [CatalogPickerSheet] (solo catálogo global), una bandeja puede llevar
/// instrumental del catálogo global O personalizado del workspace, así que
/// esta hoja tiene dos pestañas, una por origen. Devuelve un [TrayItem] con
/// cantidad 1 (editable después en el formulario), o null si se cierra sin
/// elegir.
class TrayItemPickerSheet extends StatefulWidget {
  final List<CustomInstrument> customInstruments;

  const TrayItemPickerSheet({super.key, required this.customInstruments});

  @override
  State<TrayItemPickerSheet> createState() => _TrayItemPickerSheetState();
}

class _TrayItemPickerSheetState extends State<TrayItemPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredCatalog =
        kInstruments.where((i) => _query.isEmpty || i.name.toLowerCase().contains(_query.toLowerCase())).toList();
    final filteredCustom = widget.customInstruments
        .where((i) => _query.isEmpty || i.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return DefaultTabController(
          length: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: l10n.searchInstrumentHint,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 8),
                TabBar(
                  tabs: [
                    Tab(text: l10n.instrumentSourceCatalogTab),
                    Tab(text: l10n.instrumentSourceCustomTab),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      ListView.builder(
                        controller: scrollController,
                        itemCount: filteredCatalog.length,
                        itemBuilder: (context, index) {
                          final instrument = filteredCatalog[index];
                          return ListTile(
                            leading: InstrumentIcon(
                              iconKey: instrument.icon,
                              category: instrument.category,
                              size: 40,
                            ),
                            title: Text(instrument.name),
                            subtitle: Text(instrument.category.label),
                            onTap: () => Navigator.of(context).pop(
                              TrayItem(instrumentRefType: InstrumentRefType.catalog, instrumentRefId: instrument.id),
                            ),
                          );
                        },
                      ),
                      filteredCustom.isEmpty
                          ? Center(child: Text(l10n.customInstrumentsEmptyState))
                          : ListView.builder(
                              itemCount: filteredCustom.length,
                              itemBuilder: (context, index) {
                                final instrument = filteredCustom[index];
                                return ListTile(
                                  leading: const Icon(Icons.precision_manufacturing_outlined),
                                  title: Text(instrument.name),
                                  subtitle: instrument.category != null ? Text(instrument.category!) : null,
                                  onTap: () => Navigator.of(context).pop(
                                    TrayItem(
                                      instrumentRefType: InstrumentRefType.custom,
                                      instrumentRefId: instrument.id,
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
