import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/public_tray.dart';
import '../models/tray.dart' show TrayItem;
import '../services/public_tray_service.dart';
import '../widgets/tray_item_picker_sheet.dart';

/// Formulari d'una proposta de safata a la Biblioteca Pública. Mateix
/// criteri que [PublicDocumentFormScreen]: nomes edita l'esborrany, sense
/// fotos ni instrumental personalitzat (no te sentit per a contingut de
/// comunitat -- l'instrumental personalitzat és propi d'una organització).
class PublicTrayFormScreen extends StatefulWidget {
  final String trayId;
  final PublicTrayVersion draft;

  const PublicTrayFormScreen({super.key, required this.trayId, required this.draft});

  @override
  State<PublicTrayFormScreen> createState() => _PublicTrayFormScreenState();
}

class _PublicTrayFormScreenState extends State<PublicTrayFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _observationsController;
  late List<TrayItem> _items;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.draft.name ?? '');
    _descriptionController = TextEditingController(text: widget.draft.description ?? '');
    _observationsController = TextEditingController(text: widget.draft.observations ?? '');
    _items = List.of(widget.draft.items);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _observationsController.dispose();
    super.dispose();
  }

  PublicTrayVersion get _current => PublicTrayVersion(
        id: widget.draft.id,
        trayId: widget.trayId,
        versionNumber: widget.draft.versionNumber,
        status: widget.draft.status,
        name: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
        specialtyId: widget.draft.specialtyId,
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        items: _items,
        observations: _observationsController.text.trim().isEmpty ? null : _observationsController.text.trim(),
        createdAt: widget.draft.createdAt,
      );

  Future<void> _addItem() async {
    final selected = await showModalBottomSheet<TrayItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const TrayItemPickerSheet(customInstruments: []),
    );
    if (selected != null) setState(() => _items = [..._items, selected]);
  }

  Future<void> _saveDraft() async {
    setState(() => _saving = true);
    try {
      await PublicTrayService.instance.saveDraft(widget.draft.id, _current);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitForReview() async {
    final l10n = AppLocalizations.of(context)!;
    await _saveDraft();
    try {
      await PublicTrayService.instance.submitForReview(widget.draft.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.publicLibrarySubmittedSnackbar)));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.publicLibrarySubmitError(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.publicLibraryProposeAction),
        actions: [
          IconButton(onPressed: _saving ? null : _saveDraft, icon: const Icon(Icons.save_outlined), tooltip: l10n.saveAction),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.titleFieldLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(labelText: l10n.descriptionLabel),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(l10n.trayItemsLabel, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: Text(l10n.addAction)),
              ],
            ),
            for (var i = 0; i < _items.length; i++)
              ListTile(
                leading: const Icon(Icons.build_outlined),
                title: Text(_items[i].resolveName(const [])),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.removeItemTooltip,
                  onPressed: () => setState(() => _items = List.of(_items)..removeAt(i)),
                ),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _observationsController,
              maxLines: 3,
              decoration: InputDecoration(labelText: l10n.sterilizationObservationsLabel),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _submitForReview,
                child: Text(l10n.publicLibrarySubmitForReviewAction),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
