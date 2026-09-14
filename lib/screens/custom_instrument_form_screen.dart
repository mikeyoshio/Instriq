import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../design_system/components/instriq_responsive_content.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/specialty_entity.dart';
import '../services/custom_instrument_service.dart';
import '../services/profile_service.dart';
import '../services/specialty_service.dart';

/// Edita el borrador de una versión de instrumento personalizado
/// ([existingDraft]) o crea un instrumento nuevo. Calcado de
/// [TrayFormScreen]: nunca edita directamente el contenido publicado, guardar
/// solo persiste el borrador — las variantes (nombre + foto + nota) viven
/// dentro de este mismo borrador, no en su propio CRUD (ver
/// docs/ADR_004_VERSIONING.md §5).
class CustomInstrumentFormScreen extends StatefulWidget {
  final String workspaceId;
  final CustomInstrument? existingInstrument;
  final CustomInstrumentVersion? existingDraft;

  const CustomInstrumentFormScreen({
    super.key,
    required this.workspaceId,
    this.existingInstrument,
    this.existingDraft,
  });

  @override
  State<CustomInstrumentFormScreen> createState() => _CustomInstrumentFormScreenState();
}

class _VariantDraft {
  final String id;
  final TextEditingController nameController;
  final TextEditingController noteController;
  String? photoPath;
  XFile? pickedPhoto;
  // Bytes de [pickedPhoto], leídos una vez al escogerla, solo para la
  // previsualización (Image.memory) -- Image.file no funciona en Web, donde
  // XFile.path es una blob: URL, no una ruta de disco real (mismo motivo por
  // el que uploadVariantPhoto recibe un XFile en vez de un dart:io.File).
  Uint8List? pickedPhotoBytes;

  _VariantDraft({required this.id, String? name, this.photoPath, String? note})
      : nameController = TextEditingController(text: name ?? ''),
        noteController = TextEditingController(text: note ?? '');

  factory _VariantDraft.fromVariant(CustomInstrumentVariant variant) => _VariantDraft(
        id: variant.id,
        name: variant.name,
        photoPath: variant.photoPath,
        note: variant.note,
      );

  CustomInstrumentVariant toVariant() => CustomInstrumentVariant(
        id: id,
        name: nameController.text.trim(),
        photoPath: photoPath,
        note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
      );
}

class _CustomInstrumentFormScreenState extends State<CustomInstrumentFormScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _categoryController;
  String? _specialtyId;
  // Solo lectura: texto de la antigua columna `specialty`, se muestra como
  // pista cuando la fila todavía no se ha migrado a `specialty_id`.
  String? _legacySpecialtyText;
  List<SpecialtyEntity> _specialties = [];
  late final TextEditingController _descriptionController;
  late final TextEditingController _useController;
  late final TextEditingController _tipController;
  late final TextEditingController _commentController;
  late List<_VariantDraft> _variants;
  CustomInstrumentVersion? _draft;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _categoryController = TextEditingController();
    _descriptionController = TextEditingController();
    _useController = TextEditingController();
    _tipController = TextEditingController();
    _commentController = TextEditingController();
    _variants = [];
    _init();
  }

  Future<void> _init() async {
    try {
      try {
        _specialties = await SpecialtyService.instance.fetchAll();
      } catch (_) {
        // Metadato accesorio para el selector: si falla, el formulario sigue
        // usable sin lista de especialidades.
      }
      CustomInstrumentVersion draft;
      if (widget.existingDraft != null) {
        draft = widget.existingDraft!;
      } else if (widget.existingInstrument != null) {
        draft = await CustomInstrumentService.instance.startEditing(widget.existingInstrument!);
      } else {
        draft = await CustomInstrumentService.instance.create(widget.workspaceId);
      }
      _applyDraft(draft);
    } catch (e) {
      setState(() => _error = AppLocalizations.of(context)!.formPrepareDraftError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyDraft(CustomInstrumentVersion draft) {
    _draft = draft;
    _nameController.text = draft.name;
    _categoryController.text = draft.category ?? '';
    _specialtyId = draft.specialtyId;
    _legacySpecialtyText = draft.specialtyId == null ? draft.specialty : null;
    _descriptionController.text = draft.description ?? '';
    _useController.text = draft.useText ?? '';
    _tipController.text = draft.tip ?? '';
    _variants = draft.variants.map((v) => _VariantDraft.fromVariant(v)).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _useController.dispose();
    _tipController.dispose();
    _commentController.dispose();
    for (final v in _variants) {
      v.nameController.dispose();
      v.noteController.dispose();
    }
    super.dispose();
  }

  void _addVariant() {
    setState(() => _variants.add(_VariantDraft(id: '${DateTime.now().microsecondsSinceEpoch}')));
  }

  void _removeVariant(int index) {
    final removed = _variants.removeAt(index);
    removed.nameController.dispose();
    removed.noteController.dispose();
    setState(() {});
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
      final bytes = await picked.readAsBytes();
      setState(() {
        draft.pickedPhoto = picked;
        draft.pickedPhotoBytes = bytes;
      });
    }
  }

  CustomInstrumentVersion _draftWithFormValues() {
    final name = _nameController.text.trim();
    return _draft!.copyWith(
      name: name,
      category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      clearCategory: _categoryController.text.trim().isEmpty,
      specialtyId: _specialtyId,
      clearSpecialtyId: _specialtyId == null,
      description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      clearDescription: _descriptionController.text.trim().isEmpty,
      useText: _useController.text.trim().isEmpty ? null : _useController.text.trim(),
      clearUseText: _useController.text.trim().isEmpty,
      tip: _tipController.text.trim().isEmpty ? null : _tipController.text.trim(),
      clearTip: _tipController.text.trim().isEmpty,
      variants: _variants.map((v) => v.toVariant()).toList(),
      comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    );
  }

  Future<void> _saveDraft({bool andSubmit = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    if (name.isEmpty || description.isEmpty) {
      setState(() => _error = l10n.customInstrumentMissingFieldsSnackbar);
      return;
    }
    final organizationId = ProfileService.instance.organizationId;
    if (organizationId == null) {
      setState(() => _error = l10n.customInstrumentSaveError('Sin organización'));
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Sube las fotos nuevas antes de guardar, así el borrador se guarda ya
      // con las rutas finales en cada variante.
      for (final variant in _variants) {
        if (variant.pickedPhoto != null) {
          variant.photoPath = await CustomInstrumentService.instance.uploadVariantPhoto(
            organizationId: organizationId,
            workspaceId: widget.workspaceId,
            instrumentId: _draft!.customInstrumentId,
            file: variant.pickedPhoto!,
          );
          variant.pickedPhoto = null;
        }
      }
      final updated = await CustomInstrumentService.instance.saveDraft(_draftWithFormValues());
      if (andSubmit) {
        await CustomInstrumentService.instance.submitForReview(updated.id);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = l10n.customInstrumentSaveError(e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEditing = widget.existingInstrument != null;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(isEditing ? l10n.editCustomInstrumentTitle : l10n.newCustomInstrumentLabel)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_draft == null) {
      return Scaffold(
        appBar: AppBar(title: Text(isEditing ? l10n.editCustomInstrumentTitle : l10n.newCustomInstrumentLabel)),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error ?? l10n.errorLabel))),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? l10n.editCustomInstrumentTitle : l10n.newCustomInstrumentLabel)),
      body: SafeArea(
        child: InstriqResponsiveContent(
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
            DropdownButtonFormField<String?>(
              initialValue: _specialtyId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.customInstrumentSpecialtyLabel,
                border: const OutlineInputBorder(),
              ),
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
            if (_variants.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text(l10n.noVariantsYet)),
            ..._variants.asMap().entries.map((entry) {
              final index = entry.key;
              final draft = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _pickPhoto(draft),
                        child: draft.pickedPhotoBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(draft.pickedPhotoBytes!, width: 64, height: 64, fit: BoxFit.cover),
                              )
                            : CircleAvatar(
                                radius: 32,
                                child: Icon(
                                  draft.photoPath != null ? Icons.image_outlined : Icons.add_a_photo_outlined,
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
                                draft.photoPath != null || draft.pickedPhoto != null
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
                        onPressed: () => _removeVariant(index),
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
          ],
        ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : () => _saveDraft(andSubmit: true),
                  child: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.submitForReview),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _saving ? null : () => _saveDraft(),
                  child: Text(l10n.saveAsDraft),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
