import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../models/instrument.dart';
import '../models/preference_card.dart';
import '../services/preference_card_service.dart';
import '../widgets/catalog_picker_sheet.dart';
import '../widgets/category_icon.dart';

class PreferenceCardFormScreen extends StatefulWidget {
  final String workspaceId;
  final PreferenceCard? existingCard;

  const PreferenceCardFormScreen({super.key, required this.workspaceId, this.existingCard});

  @override
  State<PreferenceCardFormScreen> createState() => _PreferenceCardFormScreenState();
}

class _PreferenceCardFormScreenState extends State<PreferenceCardFormScreen> {
  late final TextEditingController _surgeonController;
  late final TextEditingController _procedureController;
  late final TextEditingController _notesController;
  late List<PreferenceCardItem> _items;

  @override
  void initState() {
    super.initState();
    final card = widget.existingCard;
    _surgeonController = TextEditingController(text: card?.surgeonName ?? '');
    _procedureController = TextEditingController(text: card?.procedureName ?? '');
    _notesController = TextEditingController(text: card?.generalNotes ?? '');
    _items = List.of(card?.items ?? const []);
  }

  @override
  void dispose() {
    _surgeonController.dispose();
    _procedureController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Instrument? _catalogFor(PreferenceCardItem item) {
    if (item.instrumentId == null) return null;
    for (final i in kInstruments) {
      if (i.id == item.instrumentId) return i;
    }
    return null;
  }

  Future<void> _addFromCatalog() async {
    final selected = await showModalBottomSheet<Instrument>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CatalogPickerSheet(),
    );
    if (selected != null) {
      setState(() {
        _items.add(PreferenceCardItem(instrumentId: selected.id, customName: selected.name));
      });
    }
  }

  Future<void> _addCustom() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir instrumento personalizado'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Nombre del instrumento'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() {
        _items.add(PreferenceCardItem(customName: name));
      });
    }
  }

  Future<void> _editNote(int index) async {
    final controller = TextEditingController(text: _items[index].note ?? '');
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nota del instrumento'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'p. ej. tamaño, marca, colocación...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (note != null) {
      setState(() {
        final item = _items[index];
        _items[index] = PreferenceCardItem(
          instrumentId: item.instrumentId,
          customName: item.customName,
          note: note.isEmpty ? null : note,
        );
      });
    }
  }

  Future<void> _save() async {
    final surgeon = _surgeonController.text.trim();
    final procedure = _procedureController.text.trim();
    if (surgeon.isEmpty || procedure.isEmpty || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica cirujano, procedimiento y al menos un instrumento')),
      );
      return;
    }
    final card = PreferenceCard(
      id: widget.existingCard?.id ?? '',
      workspaceId: widget.existingCard?.workspaceId ?? widget.workspaceId,
      surgeonName: surgeon,
      procedureName: procedure,
      items: _items,
      generalNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      validated: widget.existingCard?.validated ?? false,
    );
    try {
      await PreferenceCardService.instance.upsertCard(card);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingCard != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar tarjeta' : 'Nueva tarjeta')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  TextField(
                    controller: _surgeonController,
                    decoration: const InputDecoration(
                      labelText: 'Cirujano',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _procedureController,
                    decoration: const InputDecoration(
                      labelText: 'Procedimiento',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Notas generales (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addFromCatalog,
                          icon: const Icon(Icons.search),
                          label: const Text('Del catálogo'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addCustom,
                          icon: const Icon(Icons.add),
                          label: const Text('Personalizado'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 24),
            Expanded(
              child: _items.isEmpty
                  ? const Center(child: Text('Añade instrumental a la tarjeta'))
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _items.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _items.removeAt(oldIndex);
                          _items.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final catalogInstrument = _catalogFor(item);
                        return Card(
                          key: ValueKey('${item.instrumentId}_${item.customName}_$index'),
                          child: ListTile(
                            leading: catalogInstrument != null
                                ? InstrumentIcon(
                                    iconKey: catalogInstrument.icon,
                                    category: catalogInstrument.category,
                                    size: 40,
                                  )
                                : const CircleAvatar(child: Icon(Icons.build_circle_outlined)),
                            title: Text(item.customName),
                            subtitle: item.note != null ? Text(item.note!) : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.note_alt_outlined),
                                  onPressed: () => _editNote(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => setState(() => _items.removeAt(index)),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar tarjeta'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
