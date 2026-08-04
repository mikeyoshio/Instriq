import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument.dart';
import '../models/preference_card.dart';
import '../models/surgeon.dart';
import '../services/preference_card_service.dart';
import '../services/surgeon_service.dart';
import '../widgets/catalog_picker_sheet.dart';
import '../widgets/category_icon.dart';

/// Edita el borrador de una versión de tarjeta de preferencia
/// ([existingDraft]) o crea una tarjeta nueva. Calcado de [TrayFormScreen]:
/// nunca edita directamente el contenido publicado, guardar solo persiste el
/// borrador.
class PreferenceCardFormScreen extends StatefulWidget {
  final String workspaceId;
  final PreferenceCard? existingCard;
  final PreferenceCardVersion? existingDraft;

  const PreferenceCardFormScreen({
    super.key,
    required this.workspaceId,
    this.existingCard,
    this.existingDraft,
  });

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
  late final TextEditingController _commentController;
  late List<PreferenceCardItem> _items;
  String? _selectedSurgeonId;
  PreferenceCardVersion? _draft;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _procedureController = TextEditingController();
    _notesController = TextEditingController();
    _commentController = TextEditingController();
    _items = [];
    _init();
  }

  Future<void> _init() async {
    try {
      await SurgeonService.instance.fetchForOrganization();
      PreferenceCardVersion draft;
      if (widget.existingDraft != null) {
        draft = widget.existingDraft!;
      } else if (widget.existingCard != null) {
        draft = await PreferenceCardService.instance.startEditing(widget.existingCard!);
      } else {
        draft = await PreferenceCardService.instance.createCard(widget.workspaceId);
      }
      _applyDraft(draft);
    } catch (e) {
      if (mounted) {
        setState(() => _error = AppLocalizations.of(context)!.formPrepareDraftError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyDraft(PreferenceCardVersion draft) {
    _draft = draft;
    _procedureController.text = draft.procedureName;
    _notesController.text = draft.generalNotes ?? '';
    _items = List.of(draft.items);
    _selectedSurgeonId = draft.surgeonId;
    final surgeonId = _selectedSurgeonId;
    if (surgeonId != null) {
      final surgeon = SurgeonService.instance.byId(surgeonId);
      if (surgeon != null) _surgeonFieldController.text = surgeon.name;
    }
  }

  @override
  void dispose() {
    _surgeonFieldController.dispose();
    _procedureController.dispose();
    _notesController.dispose();
    _commentController.dispose();
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

  Future<void> _save({bool andSubmit = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final surgeonName = _surgeonFieldController.text.trim();
    final procedure = _procedureController.text.trim();
    if (surgeonName.isEmpty || procedure.isEmpty || _items.isEmpty) {
      setState(() => _error = l10n.missingFieldsSnackbar);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // _selectedSurgeonId solo es válido si sigue apuntando a un cirujano
      // cuyo nombre cacheado coincide con el texto actual: si la persona lo
      // editó a mano tras seleccionar uno, hay que resolver (o crear) de
      // nuevo — mismo criterio que se aplica en el onChanged del campo.
      final cached = _selectedSurgeonId == null ? null : SurgeonService.instance.byId(_selectedSurgeonId!);
      final surgeonId = (cached != null && cached.name == surgeonName)
          ? cached.id
          : (await SurgeonService.instance.createOrGet(surgeonName)).id;

      final updatedDraft = _draft!.copyWith(
        surgeonId: surgeonId,
        procedureName: procedure,
        items: _items,
        generalNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        clearGeneralNotes: _notesController.text.trim().isEmpty,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
      );
      final updated = await PreferenceCardService.instance.saveDraft(updatedDraft);
      if (andSubmit) {
        await PreferenceCardService.instance.submitForReview(updated.id);
      }
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
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.preferenceCardTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_draft == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.preferenceCardTitle)),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error ?? l10n.errorLabel))),
      );
    }

    final isEditing = widget.existingCard != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editDraftAppBarTitle(l10n.preferenceCardTitle) : l10n.newCardLabel),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Autocomplete<Surgeon>(
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
                  decoration: InputDecoration(labelText: l10n.surgeonLabel, border: const OutlineInputBorder()),
                  onChanged: (value) {
                    _surgeonFieldController.text = value;
                    final cached =
                        _selectedSurgeonId == null ? null : SurgeonService.instance.byId(_selectedSurgeonId!);
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
              decoration: InputDecoration(labelText: l10n.procedureLabel, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(labelText: l10n.generalNotesLabel, border: const OutlineInputBorder()),
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
            const SizedBox(height: 12),
            if (_items.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l10n.addInstrumentsToCard))
            else
              ..._items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final catalogInstrument = _catalogFor(item);
                return Card(
                  child: ListTile(
                    leading: catalogInstrument != null
                        ? InstrumentIcon(iconKey: catalogInstrument.icon, category: catalogInstrument.category, size: 40)
                        : const CircleAvatar(child: Icon(Icons.build_circle_outlined)),
                    title: Text(item.customName),
                    subtitle: item.note != null ? Text(item.note!) : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.note_alt_outlined),
                          tooltip: l10n.editNoteTooltip,
                          onPressed: () => _editNote(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.removeItemTooltip,
                          onPressed: () => setState(() => _items.removeAt(index)),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: l10n.changeCommentLabel,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : () => _save(andSubmit: true),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.submitForReview),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _saving ? null : () => _save(),
              child: Text(l10n.saveAsDraft),
            ),
          ],
        ),
      ),
    );
  }
}
