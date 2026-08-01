import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/tray.dart';
import '../models/tray_preparation_session.dart';
import '../services/custom_instrument_service.dart';
import '../services/tray_preparation_service.dart';

/// Checklist de una sesión real de preparación: se registra qué había de
/// verdad al montar la bandeja tras el lavado/esterilización, item a item,
/// frente a lo que la versión publicada esperaba (EPIC 4 · Bandejas 2.0).
class TrayPreparationFormScreen extends StatefulWidget {
  final Tray tray;

  const TrayPreparationFormScreen({super.key, required this.tray});

  @override
  State<TrayPreparationFormScreen> createState() => _TrayPreparationFormScreenState();
}

class _ItemDraft {
  final TrayItem item;
  bool present;
  final TextEditingController actualQtyController;
  final TextEditingController noteController;

  _ItemDraft(this.item)
      : present = true,
        actualQtyController = TextEditingController(text: '${item.expectedQty}'),
        noteController = TextEditingController();

  void dispose() {
    actualQtyController.dispose();
    noteController.dispose();
  }
}

class _TrayPreparationFormScreenState extends State<TrayPreparationFormScreen> {
  List<CustomInstrument> _customInstruments = [];
  late List<_ItemDraft> _drafts;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final items = widget.tray.publishedVersion?.items ?? const <TrayItem>[];
    _drafts = items.map(_ItemDraft.new).toList();
    _load();
  }

  Future<void> _load() async {
    try {
      await CustomInstrumentService.instance.fetchForWorkspace(widget.tray.workspaceId);
      _customInstruments = CustomInstrumentService.instance.instruments;
    } catch (_) {
      // Sin bloquear el formulario: se muestra el id crudo si falla.
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final results = _drafts
          .map((d) => TrayPreparationItemResult(
                instrumentRefType: d.item.instrumentRefType,
                instrumentRefId: d.item.instrumentRefId,
                expectedQty: d.item.expectedQty,
                actualQty: int.tryParse(d.actualQtyController.text.trim()) ?? 0,
                present: d.present,
                note: d.noteController.text.trim().isEmpty ? null : d.noteController.text.trim(),
              ))
          .toList();
      await TrayPreparationService.instance.createSession(widget.tray.id, results);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = l10n.saveError(e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.prepareTrayTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(l10n.prepareTrayInstructions, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 16),
                  if (_drafts.isEmpty) Text(l10n.trayNoItemsYet),
                  ..._drafts.map((draft) => Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                value: draft.present,
                                onChanged: (value) => setState(() => draft.present = value ?? true),
                                title: Text(draft.item.resolveName(_customInstruments)),
                                subtitle: Text(
                                  draft.item.position == null
                                      ? l10n.expectedQtyValue(draft.item.expectedQty)
                                      : '${l10n.expectedQtyValue(draft.item.expectedQty)} · ${draft.item.position}',
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: draft.actualQtyController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        labelText: l10n.actualQtyLabel,
                                        border: const OutlineInputBorder(),
                                        isDense: true,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: draft.noteController,
                                decoration: InputDecoration(
                                  labelText: l10n.itemNoteLabel,
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.submitPreparationAction),
                  ),
                ],
              ),
            ),
    );
  }
}
