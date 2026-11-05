import 'dart:async';

import 'package:flutter/material.dart';

import '../data/drugs_data.dart';
import '../data/instruments_data.dart';
import '../data/sutures_data.dart';
import '../data/wound_closure_data.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/instrument.dart';
import '../models/tray.dart';
import '../utils/fuzzy_match.dart';
import '../widgets/drug_labels.dart';
import '../widgets/wound_closure_labels.dart';
import 'category_icon.dart';

/// Hoja modal para añadir un item a una bandeja: a diferencia de
/// [CatalogPickerSheet] (solo catálogo global), una bandeja puede llevar
/// instrumental reutilizable (catálogo global o personalizado del
/// workspace) Y material fungible (suturas, fármacos, material de cierre),
/// así que esta hoja tiene 5 pestañas, una por origen. Devuelve un
/// [TrayItem] con cantidad 1 (editable después en el formulario), o null si
/// se cierra sin elegir.
class TrayItemPickerSheet extends StatefulWidget {
  final List<CustomInstrument> customInstruments;

  const TrayItemPickerSheet({super.key, required this.customInstruments});

  @override
  State<TrayItemPickerSheet> createState() => _TrayItemPickerSheetState();
}

class _TrayItemPickerSheetState extends State<TrayItemPickerSheet> {
  String _query = '';

  // Sin debounce, cada tecla repite un escaneo difuso síncrono de los 521
  // instrumentos del catálogo (más el instrumental personalizado) dentro de
  // build().
  Timer? _liveSearchDebounce;

  @override
  void dispose() {
    _liveSearchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final filteredCatalog =
        kInstruments.where((i) => fuzzyContains(i.name.forLanguageCode(languageCode), _query)).toList();
    final filteredCustom = widget.customInstruments.where((i) => fuzzyContains(i.name, _query)).toList();
    final filteredSutures =
        kSutures.where((s) => fuzzyContains(s.name.forLanguageCode(languageCode), _query)).toList();
    final filteredDrugs = kDrugs.where((d) => fuzzyContains(d.name.forLanguageCode(languageCode), _query)).toList();
    final filteredWoundClosure = kWoundClosureMaterials
        .where((w) => fuzzyContains(w.name.forLanguageCode(languageCode), _query))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return DefaultTabController(
          length: 5,
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
                  onChanged: (v) {
                    _liveSearchDebounce?.cancel();
                    _liveSearchDebounce = Timer(const Duration(milliseconds: 150), () {
                      if (!mounted) return;
                      setState(() => _query = v);
                    });
                  },
                ),
                const SizedBox(height: 8),
                TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: l10n.instrumentSourceCatalogTab),
                    Tab(text: l10n.instrumentSourceCustomTab),
                    Tab(text: l10n.instrumentSourceSutureTab),
                    Tab(text: l10n.instrumentSourceDrugTab),
                    Tab(text: l10n.instrumentSourceWoundClosureTab),
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
                            title: Text(instrument.name.forLanguageCode(languageCode)),
                            subtitle: Text(instrument.category.label(l10n)),
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
                      ListView.builder(
                        itemCount: filteredSutures.length,
                        itemBuilder: (context, index) {
                          final suture = filteredSutures[index];
                          return ListTile(
                            leading: const Icon(Icons.linear_scale_outlined),
                            title: Text(suture.name.forLanguageCode(languageCode)),
                            onTap: () => Navigator.of(context).pop(
                              TrayItem(instrumentRefType: InstrumentRefType.suture, instrumentRefId: suture.id),
                            ),
                          );
                        },
                      ),
                      ListView.builder(
                        itemCount: filteredDrugs.length,
                        itemBuilder: (context, index) {
                          final drug = filteredDrugs[index];
                          return ListTile(
                            leading: const Icon(Icons.medication_outlined),
                            title: Text(drug.name.forLanguageCode(languageCode)),
                            subtitle: Text(drugClassValueLabel(l10n, drug.drugClass)),
                            onTap: () => Navigator.of(context).pop(
                              TrayItem(instrumentRefType: InstrumentRefType.drug, instrumentRefId: drug.id),
                            ),
                          );
                        },
                      ),
                      ListView.builder(
                        itemCount: filteredWoundClosure.length,
                        itemBuilder: (context, index) {
                          final material = filteredWoundClosure[index];
                          return ListTile(
                            leading: const Icon(Icons.healing_outlined),
                            title: Text(material.name.forLanguageCode(languageCode)),
                            subtitle: Text(woundClosureCategoryValueLabel(l10n, material.category)),
                            onTap: () => Navigator.of(context).pop(
                              TrayItem(
                                instrumentRefType: InstrumentRefType.woundClosure,
                                instrumentRefId: material.id,
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
