import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/public_tray.dart';
import '../models/workspace.dart';
import '../services/tray_service.dart';

/// Pas final del wizard de creació d'espai: mostra les safates públiques
/// recomanades per a l'especialitat triada (`starter_sets`) perquè qui crea
/// l'espai pugui adoptar-les d'un cop -- totes preseleccionades, 100%
/// saltable. Cada safata adoptada queda com un esborrany propi normal
/// (`TraySyncStatus.synced`), editable des del primer moment.
class WorkspaceStarterPackScreen extends StatefulWidget {
  final Workspace workspace;
  final List<PublicTray> recommended;

  const WorkspaceStarterPackScreen({super.key, required this.workspace, required this.recommended});

  @override
  State<WorkspaceStarterPackScreen> createState() => _WorkspaceStarterPackScreenState();
}

class _WorkspaceStarterPackScreenState extends State<WorkspaceStarterPackScreen> {
  late final Set<String> _selected = widget.recommended.map((t) => t.id).toSet();
  // Bandejas ya adoptadas con éxito en un intento anterior de esta misma
  // pantalla -- `adopt_public_tray` no es idempotente (crea una fila nueva
  // cada vez), así que si un fallo a mitad de lista deja algunas ya
  // adoptadas, un reintento debe saltárselas en vez de duplicarlas.
  final Set<String> _adopted = {};
  bool _adopting = false;
  String? _error;

  Future<void> _confirm() async {
    setState(() {
      _adopting = true;
      _error = null;
    });
    var succeededThisRun = 0;
    try {
      for (final tray in widget.recommended) {
        if (!_selected.contains(tray.id) || _adopted.contains(tray.id)) continue;
        await TrayService.instance.adoptPublicTray(publicTrayId: tray.id, workspaceId: widget.workspace.id);
        _adopted.add(tray.id);
        succeededThisRun++;
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _adopting = false;
          _error = succeededThisRun > 0
              ? l10n.starterPackPartialError(succeededThisRun, e.toString())
              : l10n.starterPackError(e.toString());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.starterPackTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(l10n.starterPackBody, style: Theme.of(context).textTheme.bodyMedium),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: widget.recommended.length,
              itemBuilder: (context, index) {
                final tray = widget.recommended[index];
                final alreadyAdopted = _adopted.contains(tray.id);
                return CheckboxListTile(
                  title: Text(tray.publishedVersion?.name ?? ''),
                  subtitle: alreadyAdopted
                      ? Text(l10n.starterPackAlreadyAdded)
                      : tray.publishedVersion?.description != null
                          ? Text(tray.publishedVersion!.description!, maxLines: 2, overflow: TextOverflow.ellipsis)
                          : null,
                  value: alreadyAdopted || _selected.contains(tray.id),
                  onChanged: _adopting || alreadyAdopted
                      ? null
                      : (checked) => setState(() {
                            if (checked ?? false) {
                              _selected.add(tray.id);
                            } else {
                              _selected.remove(tray.id);
                            }
                          }),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _adopting ? null : () => Navigator.of(context).pop(),
                      child: Text(l10n.starterPackSkip),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _adopting || _selected.isEmpty ? null : _confirm,
                      child: _adopting
                          ? const SizedBox(
                              height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(l10n.starterPackAdd(_selected.length)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
