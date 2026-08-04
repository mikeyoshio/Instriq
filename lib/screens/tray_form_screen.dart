import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/specialty_entity.dart';
import '../models/tray.dart';
import '../services/custom_instrument_service.dart';
import '../services/profile_service.dart';
import '../services/specialty_service.dart';
import '../services/tray_service.dart';
import '../widgets/tag_picker.dart';
import '../widgets/tray_item_picker_sheet.dart';

/// Edita el borrador de una versión de bandeja ([existingDraft]) o crea una
/// bandeja nueva. Calcado de [GroupDocumentFormScreen]: nunca edita
/// directamente el contenido publicado, guardar solo persiste el borrador.
class TrayFormScreen extends StatefulWidget {
  final String workspaceId;
  final Tray? existingTray;
  final TrayVersion? existingDraft;

  const TrayFormScreen({
    super.key,
    required this.workspaceId,
    this.existingTray,
    this.existingDraft,
  });

  @override
  State<TrayFormScreen> createState() => _TrayFormScreenState();
}

class _TrayFormScreenState extends State<TrayFormScreen> {
  late final TextEditingController _nameController;
  String? _specialtyId;
  // Solo lectura: texto de la antigua columna `specialty`, se muestra como
  // pista cuando la fila todavía no se ha migrado a `specialty_id`.
  String? _legacySpecialtyText;
  List<SpecialtyEntity> _specialties = [];
  late final TextEditingController _descriptionController;
  late final TextEditingController _observationsController;
  late final TextEditingController _commentController;
  late List<TrayItem> _items;
  late List<String> _photoPaths;
  final List<File> _newPhotos = [];
  TrayVersion? _draft;
  List<CustomInstrument> _customInstruments = [];
  final _tagPickerKey = GlobalKey<TagPickerState>();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _observationsController = TextEditingController();
    _commentController = TextEditingController();
    _items = [];
    _photoPaths = [];
    _init();
  }

  Future<void> _init() async {
    try {
      await CustomInstrumentService.instance.fetchForWorkspace(widget.workspaceId);
      _customInstruments = CustomInstrumentService.instance.instruments;
      _specialties = await SpecialtyService.instance.fetchAll();
      TrayVersion draft;
      if (widget.existingDraft != null) {
        draft = widget.existingDraft!;
      } else if (widget.existingTray != null) {
        draft = await TrayService.instance.startEditing(widget.existingTray!);
      } else {
        draft = await TrayService.instance.createTray(widget.workspaceId);
      }
      _applyDraft(draft);
    } catch (e) {
      setState(() => _error = AppLocalizations.of(context)!.formPrepareDraftError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyDraft(TrayVersion draft) {
    _draft = draft;
    _nameController.text = draft.name;
    _specialtyId = draft.specialtyId;
    _legacySpecialtyText = draft.specialtyId == null ? draft.specialty : null;
    _descriptionController.text = draft.description ?? '';
    _observationsController.text = draft.observations ?? '';
    _items = List.of(draft.items);
    _photoPaths = List.of(draft.photoPaths);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _observationsController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final selected = await showModalBottomSheet<TrayItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => TrayItemPickerSheet(customInstruments: _customInstruments),
    );
    if (selected == null) return;
    final alreadyThere = _items.any(
      (i) => i.instrumentRefType == selected.instrumentRefType && i.instrumentRefId == selected.instrumentRefId,
    );
    if (!alreadyThere) {
      setState(() => _items.add(selected));
    }
  }

  Future<void> _editItem(int index) async {
    final l10n = AppLocalizations.of(context)!;
    final qtyController = TextEditingController(text: '${_items[index].expectedQty}');
    final positionController = TextEditingController(text: _items[index].position ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.expectedQtyLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: l10n.expectedQtyLabel, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: positionController,
              decoration: InputDecoration(labelText: l10n.trayItemPositionLabel, border: const OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.saveAction)),
        ],
      ),
    );
    if (result != true) return;
    final qty = int.tryParse(qtyController.text.trim());
    final position = positionController.text.trim();
    setState(() {
      _items[index] = _items[index].copyWith(
        expectedQty: (qty != null && qty > 0) ? qty : null,
        position: position.isEmpty ? null : position,
        clearPosition: position.isEmpty,
      );
    });
  }

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.pickFromGalleryLabel),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l10n.pickFromCameraLabel),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, maxWidth: 1600, imageQuality: 85);
    if (picked != null) {
      setState(() => _newPhotos.add(File(picked.path)));
    }
  }

  TrayVersion _draftWithFormValues() {
    final name = _nameController.text.trim();
    return _draft!.copyWith(
      name: name,
      specialtyId: _specialtyId,
      clearSpecialtyId: _specialtyId == null,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      clearDescription: _descriptionController.text.trim().isEmpty,
      photoPaths: _photoPaths,
      items: _items,
      observations: _observationsController.text.trim().isEmpty ? null : _observationsController.text.trim(),
      clearObservations: _observationsController.text.trim().isEmpty,
      comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    );
  }

  Future<void> _saveDraft({bool andSubmit = false}) async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameController.text.trim().isEmpty) {
      setState(() => _error = l10n.titleRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Sube las fotos nuevas antes de guardar, así el borrador se guarda ya
      // con las rutas finales en `photo_paths`.
      for (final file in _newPhotos) {
        final path = await TrayService.instance
            .uploadPhoto(trayId: _draft!.trayId, workspaceId: widget.workspaceId, file: file);
        _photoPaths.add(path);
      }
      _newPhotos.clear();
      final updated = await TrayService.instance.saveDraft(_draftWithFormValues());
      await _tagPickerKey.currentState?.save();
      if (andSubmit) {
        await TrayService.instance.submitForReview(updated.id);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = l10n.saveError(e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildSpecialtyDropdown(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          initialValue: _specialtyId,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.specialtyLabel, border: const OutlineInputBorder()),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(l10n.noSpecialty)),
            ..._specialties.map((s) => DropdownMenuItem<String?>(value: s.id, child: Text(s.label))),
          ],
          onChanged: (value) => setState(() => _specialtyId = value),
        ),
        if (_legacySpecialtyText != null && _legacySpecialtyText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            l10n.legacySpecialtySuffix(_legacySpecialtyText!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.traysTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_draft == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.traysTitle)),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error ?? l10n.errorLabel))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editDraftAppBarTitle(l10n.trayTitle))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: l10n.trayNameLabel, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            _buildSpecialtyDropdown(l10n),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.descriptionLabel,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(l10n.trayItemsLabel, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: Text(l10n.addAction)),
              ],
            ),
            if (_items.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l10n.trayNoItemsYet)),
            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return ListTile(
                leading: Icon(
                  item.instrumentRefType == InstrumentRefType.catalog
                      ? Icons.build_outlined
                      : Icons.precision_manufacturing_outlined,
                ),
                title: Text(item.resolveName(_customInstruments)),
                subtitle: Text(
                  item.position == null
                      ? l10n.expectedQtyValue(item.expectedQty)
                      : '${l10n.expectedQtyValue(item.expectedQty)} · ${item.position}',
                ),
                onTap: () => _editItem(index),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.removeItemTooltip,
                  onPressed: () => setState(() => _items.removeAt(index)),
                ),
              );
            }),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(l10n.trayPhotosLabel, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(onPressed: _pickPhoto, icon: const Icon(Icons.add_a_photo_outlined), label: Text(l10n.addAction)),
              ],
            ),
            if (_photoPaths.isEmpty && _newPhotos.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l10n.trayNoPhotosYet)),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._photoPaths.asMap().entries.map((entry) => _RemovableChip(
                      label: '${l10n.trayPhotosLabel} ${entry.key + 1}',
                      onRemove: () => setState(() => _photoPaths.removeAt(entry.key)),
                    )),
                ..._newPhotos.asMap().entries.map((entry) => _RemovableChip(
                      label: entry.value.path.split(Platform.pathSeparator).last,
                      onRemove: () => setState(() => _newPhotos.removeAt(entry.key)),
                    )),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _observationsController,
              decoration: InputDecoration(
                labelText: l10n.trayObservationsLabel,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Text(l10n.tagsLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TagPicker(
              key: _tagPickerKey,
              refType: 'tray',
              refId: _draft!.trayId,
              organizationId: ProfileService.instance.organizationId,
            ),
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
              onPressed: _saving ? null : () => _saveDraft(andSubmit: true),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.submitForReview),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _saving ? null : () => _saveDraft(),
              child: Text(l10n.saveAsDraft),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _RemovableChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(label), onDeleted: onRemove);
  }
}
