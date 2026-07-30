import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument.dart';
import '../models/preference_card.dart';
import '../models/surgeon.dart';
import '../services/connectivity_service.dart';
import '../services/preference_card_service.dart';
import '../services/surgeon_service.dart';
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
  // Texto libre "espejo" del campo de autocompletar: el TextEditingController
  // real lo crea `Autocomplete` internamente (ver fieldViewBuilder) — este
  // solo sirve para leer el valor final al guardar.
  final TextEditingController _surgeonFieldController = TextEditingController();
  late final TextEditingController _procedureController;
  late final TextEditingController _notesController;
  late List<PreferenceCardItem> _items;

  String? _selectedSurgeonId;
  bool _loadingSurgeons = true;

  @override
  void initState() {
    super.initState();
    final card = widget.existingCard;
    _procedureController = TextEditingController(text: card?.procedureName ?? '');
    _notesController = TextEditingController(text: card?.generalNotes ?? '');
    _items = List.of(card?.items ?? const []);
    _selectedSurgeonId = card?.surgeonId;
    _loadSurgeons();
  }

  Future<void> _loadSurgeons() async {
    await SurgeonService.instance.fetchForOrganization();
    if (!mounted) return;
    final surgeonId = _selectedSurgeonId;
    if (surgeonId != null) {
      final existing = SurgeonService.instance.byId(surgeonId);
      if (existing != null) _surgeonFieldController.text = existing.name;
    }
    setState(() => _loadingSurgeons = false);
  }

  @override
  void dispose() {
    _surgeonFieldController.dispose();
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
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addCustomInstrumentTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.instrumentNameHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.addAction),
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
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _items[index].note ?? '');
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.instrumentNoteTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.noteHint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.save),
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
    final l10n = AppLocalizations.of(context)!;
    final surgeonName = _surgeonFieldController.text.trim();
    final procedure = _procedureController.text.trim();
    if (surgeonName.isEmpty || procedure.isEmpty || _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.missingFieldsSnackbar)),
      );
      return;
    }
    try {
      // _selectedSurgeonId solo es válido si sigue apuntando a un cirujano
      // cuyo nombre cacheado coincide con el texto actual: si la persona lo
      // editó a mano tras seleccionar uno, hay que resolver (o crear) de
      // nuevo — mismo criterio que se aplica en el onChanged del campo.
      final cached = _selectedSurgeonId == null ? null : SurgeonService.instance.byId(_selectedSurgeonId!);
      final surgeonId = (cached != null && cached.name == surgeonName)
          ? cached.id
          : (await SurgeonService.instance.createOrGet(surgeonName)).id;

      final card = PreferenceCard(
        id: widget.existingCard?.id ?? '',
        workspaceId: widget.existingCard?.workspaceId ?? widget.workspaceId,
        surgeonId: surgeonId,
        procedureName: procedure,
        items: _items,
        generalNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        validated: widget.existingCard?.validated ?? false,
      );
      final wasOffline = !ConnectivityService.instance.isOnline.value;
      await PreferenceCardService.instance.upsertCard(card);
      if (mounted) {
        if (wasOffline) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.savedOfflineSnackbar)));
          await Future.delayed(const Duration(milliseconds: 900));
        }
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.existingCard != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? l10n.editCardTitle : l10n.newCardLabel)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  _loadingSurgeons
                      ? const LinearProgressIndicator()
                      : Autocomplete<Surgeon>(
                          optionsBuilder: (value) {
                            if (value.text.trim().isEmpty) return const Iterable<Surgeon>.empty();
                            return SurgeonService.instance.searchByName(value.text);
                          },
                          displayStringForOption: (s) => s.name,
                          initialValue: TextEditingValue(text: _surgeonFieldController.text),
                          onSelected: (s) {
                            _selectedSurgeonId = s.id;
                            _surgeonFieldController.text = s.name;
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            return TextField(
                              controller: controller,
                              focusNode: focusNode,
                              decoration: InputDecoration(
                                labelText: l10n.surgeonLabel,
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                _surgeonFieldController.text = value;
                                final cached = _selectedSurgeonId == null
                                    ? null
                                    : SurgeonService.instance.byId(_selectedSurgeonId!);
                                if (cached != null && cached.name != value) {
                                  _selectedSurgeonId = null;
                                }
                              },
                            );
                          },
                        ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _procedureController,
                    decoration: InputDecoration(
                      labelText: l10n.procedureLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: l10n.generalNotesLabel,
                      border: const OutlineInputBorder(),
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
                          label: Text(l10n.fromCatalog),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _addCustom,
                          icon: const Icon(Icons.add),
                          label: Text(l10n.customLabel),
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
                  ? Center(child: Text(l10n.addInstrumentsToCard))
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
                  label: Text(l10n.saveCardButton),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
