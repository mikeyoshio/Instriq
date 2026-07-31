import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/tray.dart';
import '../services/tray_service.dart';

/// Hoja modal para elegir una safata del espacio. Calcada de
/// [CatalogPickerSheet] (`lib/widgets/catalog_picker_sheet.dart`), pero las
/// safates viven en Supabase (no en un catálogo estático), así que carga
/// antes de mostrar la lista. Devuelve la [Tray] elegida, o null si se cierra
/// sin elegir.
class TrayPickerSheet extends StatefulWidget {
  final String workspaceId;

  const TrayPickerSheet({super.key, required this.workspaceId});

  @override
  State<TrayPickerSheet> createState() => _TrayPickerSheetState();
}

class _TrayPickerSheetState extends State<TrayPickerSheet> {
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await TrayService.instance.fetchTrays(widget.workspaceId);
    } catch (_) {
      // Se muestra la lista vacía (o lo que ya hubiera en caché) en vez de
      // bloquear el picker si falla la carga.
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final trays = TrayService.instance
        .traysOfWorkspace(widget.workspaceId)
        .where((t) => t.publishedVersion != null)
        .where((t) => _query.isEmpty || (t.publishedVersion!.name.toLowerCase().contains(_query.toLowerCase())))
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
                  hintText: l10n.searchTrayHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : trays.isEmpty
                        ? Center(child: Text(l10n.noTraysInWorkspace))
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: trays.length,
                            itemBuilder: (context, index) {
                              final tray = trays[index];
                              return ListTile(
                                leading: const Icon(Icons.inventory_2_outlined),
                                title: Text(tray.publishedVersion!.name),
                                onTap: () => Navigator.of(context).pop(tray),
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
