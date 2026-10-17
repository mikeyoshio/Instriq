import 'dart:async';

import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument.dart';
import '../utils/fuzzy_match.dart';
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

  // Sin debounce, cada tecla repite un escaneo difuso síncrono de los 521
  // instrumentos del catálogo dentro de build().
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
    final filtered = kInstruments
        .where((i) => fuzzyContains(i.name.forLanguageCode(languageCode), _query))
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
                      title: Text(instrument.name.forLanguageCode(languageCode)),
                      subtitle: Text(instrument.category.label(l10n)),
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
