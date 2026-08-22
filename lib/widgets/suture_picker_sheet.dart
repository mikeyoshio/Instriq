import 'package:flutter/material.dart';

import '../data/sutures_data.dart';
import '../l10n/app_localizations.dart';
import '../models/suture.dart';

/// Fulla modal per triar una sutura del catàleg. Calcada de
/// [CatalogPickerSheet], deliberadament no compartida (catàleg propi, no
/// instrumental). Retorna la [Suture] triada, o null si es tanca sense triar.
class SuturePickerSheet extends StatefulWidget {
  const SuturePickerSheet({super.key});

  @override
  State<SuturePickerSheet> createState() => _SuturePickerSheetState();
}

class _SuturePickerSheetState extends State<SuturePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = kSutures
        .where((s) => _query.isEmpty || s.name.toLowerCase().contains(_query.toLowerCase()))
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
                  hintText: l10n.searchSutureHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final suture = filtered[index];
                    return ListTile(
                      leading: const Icon(Icons.line_style),
                      title: Text(suture.name),
                      subtitle: Text(suture.material.label),
                      onTap: () => Navigator.of(context).pop(suture),
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
