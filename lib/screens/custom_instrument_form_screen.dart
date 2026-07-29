import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../services/custom_instrument_service.dart';
import '../services/profile_service.dart';

/// Crear/editar un instrumento personalizado del equipo, con sus variantes
/// (nombre + foto) gestionadas inline. Nunca toca el catálogo global.
class CustomInstrumentFormScreen extends StatefulWidget {
  final String workspaceId;
  final CustomInstrument? existingInstrument;

  const CustomInstrumentFormScreen({super.key, required this.workspaceId, this.existingInstrument});

  @override
  State<CustomInstrumentFormScreen> createState() => _CustomInstrumentFormScreenState();
}

class _VariantDraft {
  final CustomInstrumentVariant? existing;
  final TextEditingController nameController;
  final TextEditingController noteController;
  File? pickedPhoto;
  bool markedForDeletion = false;

  _VariantDraft({this.existing})
      : nameController = TextEditingController(text: existing?.name ?? ''),
        noteController = TextEditingController(text: existing?.note ?? '');
}

class _CustomInstrumentFormScreenState extends State<CustomInstrumentFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _useController;
  late final TextEditingController _tipController;
  late List<_VariantDraft> _variants;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final instrument = widget.existingInstrument;
    _nameController = TextEditingController(text: instrument?.name ?? '');
    _categoryController = TextEditingController(text: instrument?.category ?? '');
    _specialtyController = TextEditingController(text: instrument?.specialty ?? '');
    _descriptionController = TextEditingController(text: instrument?.description ?? '');
    _useController = TextEditingController(text: instrument?.useText ?? '');
    _tipController = TextEditingController(text: instrument?.tip ?? '');
    _variants = (instrument?.variants ?? const []).map((v) => _VariantDraft(existing: v)).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _specialtyController.dispose();
    _descriptionController.dispose();
    _useController.dispose();
    _tipController.dispose();
    for (final v in _variants) {
      v.nameController.dispose();
      v.noteController.dispose();
    }
    super.dispose();
  }

  void _addVariant() {
    setState(() => _variants.add(_VariantDraft()));
  }

  Future<void> _pickPhoto(_VariantDraft draft) async {
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
      setState(() => draft.pickedPhoto = File(picked.path));
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (name.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.customInstrumentMissingFieldsSnackbar)),
      );
      return;
    }
    final hospitalId = ProfileService.instance.hospitalId;
    if (hospitalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.customInstrumentSaveError('Sin hospital'))),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final service = CustomInstrumentService.instance;
      CustomInstrument instrument;
      if (widget.existingInstrument == null) {
        instrument = await service.create(CustomInstrument(
          id: '',
          hospitalId: hospitalId,
          workspaceId: widget.workspaceId,
          name: name,
          category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
          specialty: _specialtyController.text.trim().isEmpty ? null : _specialtyController.text.trim(),
          description: description,
          useText: _useController.text.trim().isEmpty ? null : _useController.text.trim(),
          tip: _tipController.text.trim().isEmpty ? null : _tipController.text.trim(),
        ));
      } else {
        instrument = await service.update(widget.existingInstrument!.copyWith(
          name: name,
          category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
          specialty: _specialtyController.text.trim().isEmpty ? null : _specialtyController.text.trim(),
          description: description,
          useText: _useController.text.trim().isEmpty ? null : _useController.text.trim(),
          tip: _tipController.text.trim().isEmpty ? null : _tipController.text.trim(),
        ));
      }

      for (final draft in _variants) {
        if (draft.markedForDeletion) {
          if (draft.existing != null) {
            await service.deleteVariant(draft.existing!.id, instrument.id);
          }
          continue;
        }
        final variantName = draft.nameController.text.trim();
        if (variantName.isEmpty && draft.existing == null) continue;

        CustomInstrumentVariant variant;
        if (draft.existing == null) {
          variant = await service.addVariant(CustomInstrumentVariant(
            id: '',
            customInstrumentId: instrument.id,
            name: variantName,
            note: draft.noteController.text.trim().isEmpty ? null : draft.noteController.text.trim(),
          ));
        } else {
          variant = await service.updateVariant(draft.existing!.copyWith(
            name: variantName,
            note: draft.noteController.text.trim().isEmpty ? null : draft.noteController.text.trim(),
          ));
        }

        if (draft.pickedPhoto != null) {
          await service.uploadVariantPhoto(
            variant: variant,
            hospitalId: hospitalId,
            workspaceId: widget.workspaceId,
            file: draft.pickedPhoto!,
          );
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.customInstrumentSaveError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.existingInstrument != null;
    final visibleVariants = _variants.where((v) => !v.markedForDeletion).toList();
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? l10n.editCustomInstrumentTitle : l10n.newCustomInstrumentLabel)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.customInstrumentNameLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _categoryController,
              decoration: InputDecoration(
                labelText: l10n.customInstrumentCategoryLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _specialtyController,
              decoration: InputDecoration(
                labelText: l10n.customInstrumentSpecialtyLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: l10n.customInstrumentDescriptionLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _useController,
              decoration: InputDecoration(
                labelText: l10n.customInstrumentUseLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tipController,
              decoration: InputDecoration(
                labelText: l10n.customInstrumentTipLabel,
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.customInstrumentVariantsTitle, style: Theme.of(context).textTheme.titleMedium),
                TextButton.icon(
                  onPressed: _addVariant,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addVariantLabel),
                ),
              ],
            ),
            if (visibleVariants.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(l10n.noVariantsYet)),
            ...visibleVariants.map((draft) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () => _pickPhoto(draft),
                            child: draft.pickedPhoto != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(draft.pickedPhoto!, width: 64, height: 64, fit: BoxFit.cover),
                                  )
                                : CircleAvatar(
                                    radius: 32,
                                    child: Icon(
                                      draft.existing?.photoPath != null
                                          ? Icons.image_outlined
                                          : Icons.add_a_photo_outlined,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              children: [
                                TextField(
                                  controller: draft.nameController,
                                  decoration: InputDecoration(
                                    labelText: l10n.variantNameLabel,
                                    hintText: l10n.variantNameHint,
                                    isDense: true,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton.icon(
                                  onPressed: () => _pickPhoto(draft),
                                  icon: const Icon(Icons.photo_camera_outlined, size: 18),
                                  label: Text(
                                    draft.existing?.photoPath != null || draft.pickedPhoto != null
                                        ? l10n.changePhotoLabel
                                        : l10n.pickPhotoLabel,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: l10n.removeVariantLabel,
                            onPressed: () => setState(() => draft.markedForDeletion = true),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: Text(l10n.save),
            ),
          ),
        ),
      ),
    );
  }
}
