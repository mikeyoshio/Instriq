import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../design_system/components/instriq_responsive_content.dart';
import '../l10n/app_localizations.dart';
import '../models/group_document.dart' show DocumentKind;
import '../models/group_document_version.dart' show ProtocolStep;
import '../models/instrument.dart' show InstrumentCategory, InstrumentCategoryLabel;
import '../models/public_document.dart';
import '../models/public_instrument.dart';
import '../models/public_tray.dart';
import '../models/specialty_entity.dart';
import '../models/tray.dart' show TrayItem;
import '../services/auth_service.dart';
import '../services/public_document_service.dart';
import '../services/public_instrument_service.dart';
import '../services/public_tray_service.dart';
import '../services/specialty_service.dart';
import '../widgets/tray_item_picker_sheet.dart';

/// Els tipus de contingut que admet la Biblioteca Pública. `technique` i
/// `protocol` comparteixen la variant "document" (contingut+passos);
/// `tray` es la variant "safata" (descripció+items+observacions); `instrument`
/// es la variant "instrumental" (categoria+especialitat+descripció+ús+foto).
enum PublicEntityKind { technique, protocol, tray, instrument }

extension PublicEntityKindX on PublicEntityKind {
  bool get isTray => this == PublicEntityKind.tray;
  bool get isInstrument => this == PublicEntityKind.instrument;
}

/// Formulari d'una proposta (tècnica/protocol, safata o instrumental) a la
/// Biblioteca Pública. Nomes edita l'esborrany (mai el contingut publicat) --
/// mateix criteri que `GroupDocumentFormScreen`. Deliberadament senzill per a
/// aquest tram: sense el picker d'instrumental/safates relacionats de la
/// versió privada.
class PublicEntityFormScreen extends StatefulWidget {
  final PublicEntityKind entityKind;
  final String entityId;
  final PublicDocumentVersion? documentDraft;
  final PublicTrayVersion? trayDraft;
  final PublicInstrumentVersion? instrumentDraft;

  const PublicEntityFormScreen.document({
    super.key,
    required DocumentKind kind,
    required String documentId,
    required PublicDocumentVersion draft,
  })  : entityKind = kind == DocumentKind.protocol ? PublicEntityKind.protocol : PublicEntityKind.technique,
        entityId = documentId,
        documentDraft = draft,
        trayDraft = null,
        instrumentDraft = null;

  const PublicEntityFormScreen.tray({
    super.key,
    required String trayId,
    required PublicTrayVersion draft,
  })  : entityKind = PublicEntityKind.tray,
        entityId = trayId,
        documentDraft = null,
        trayDraft = draft,
        instrumentDraft = null;

  const PublicEntityFormScreen.instrument({
    super.key,
    required String instrumentId,
    required PublicInstrumentVersion draft,
  })  : entityKind = PublicEntityKind.instrument,
        entityId = instrumentId,
        documentDraft = null,
        trayDraft = null,
        instrumentDraft = draft;

  @override
  State<PublicEntityFormScreen> createState() => _PublicEntityFormScreenState();
}

class _PublicEntityFormScreenState extends State<PublicEntityFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  TextEditingController? _observationsController;
  TextEditingController? _useTextController;
  TextEditingController? _tipController;
  List<ProtocolStep> _steps = [];
  List<TrayItem> _items = [];
  InstrumentCategory? _category;
  String? _specialtyId;
  List<SpecialtyEntity> _specialties = [];
  String? _photoPath;
  XFile? _pickedPhoto;
  Uint8List? _pickedPhotoBytes;
  bool _saving = false;
  bool _loadingSpecialties = true;

  bool get _isTray => widget.entityKind.isTray;
  bool get _isInstrument => widget.entityKind.isInstrument;

  @override
  void initState() {
    super.initState();
    if (_isTray) {
      final draft = widget.trayDraft!;
      _titleController = TextEditingController(text: draft.name ?? '');
      _contentController = TextEditingController(text: draft.description ?? '');
      _observationsController = TextEditingController(text: draft.observations ?? '');
      _items = List.of(draft.items);
    } else if (_isInstrument) {
      final draft = widget.instrumentDraft!;
      _titleController = TextEditingController(text: draft.name ?? '');
      _contentController = TextEditingController(text: draft.description ?? '');
      _useTextController = TextEditingController(text: draft.useText ?? '');
      _tipController = TextEditingController(text: draft.tip ?? '');
      _category = draft.category;
      _specialtyId = draft.specialtyId;
      _photoPath = draft.photoPath;
      _loadSpecialties();
    } else {
      final draft = widget.documentDraft!;
      _titleController = TextEditingController(text: draft.title ?? '');
      _contentController = TextEditingController(text: draft.content ?? '');
      _steps = List.of(draft.steps);
    }
  }

  Future<void> _loadSpecialties() async {
    try {
      final specialties = await SpecialtyService.instance.fetchAll();
      if (mounted) setState(() => _specialties = specialties);
    } catch (_) {
      // Selector auxiliar: si falla, el formulari sigue usable sense ell.
    } finally {
      if (mounted) setState(() => _loadingSpecialties = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _observationsController?.dispose();
    _useTextController?.dispose();
    _tipController?.dispose();
    super.dispose();
  }

  PublicDocumentVersion get _currentDocument {
    final draft = widget.documentDraft!;
    return PublicDocumentVersion(
      id: draft.id,
      documentId: widget.entityId,
      versionNumber: draft.versionNumber,
      status: draft.status,
      title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      specialtyId: draft.specialtyId,
      content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
      steps: _steps,
      relatedInstrumentIds: draft.relatedInstrumentIds,
      relatedTrayIds: draft.relatedTrayIds,
      createdAt: draft.createdAt,
    );
  }

  PublicTrayVersion get _currentTray {
    final draft = widget.trayDraft!;
    return PublicTrayVersion(
      id: draft.id,
      trayId: widget.entityId,
      versionNumber: draft.versionNumber,
      status: draft.status,
      name: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      specialtyId: draft.specialtyId,
      description: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
      items: _items,
      observations: _observationsController!.text.trim().isEmpty ? null : _observationsController!.text.trim(),
      createdAt: draft.createdAt,
    );
  }

  PublicInstrumentVersion get _currentInstrument {
    final draft = widget.instrumentDraft!;
    return PublicInstrumentVersion(
      id: draft.id,
      instrumentId: widget.entityId,
      versionNumber: draft.versionNumber,
      status: draft.status,
      name: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
      category: _category,
      specialtyId: _specialtyId,
      description: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
      useText: _useTextController!.text.trim().isEmpty ? null : _useTextController!.text.trim(),
      tip: _tipController!.text.trim().isEmpty ? null : _tipController!.text.trim(),
      photoPath: _photoPath,
      createdAt: draft.createdAt,
    );
  }

  Future<void> _addStep() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.addStepTitle),
        content: TextField(controller: controller, autofocus: true, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: Text(l10n.addAction)),
        ],
      ),
    );
    if (text != null && text.isNotEmpty) setState(() => _steps = [..._steps, ProtocolStep(text: text)]);
  }

  Future<void> _addTrayItem() async {
    final selected = await showModalBottomSheet<TrayItem>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const TrayItemPickerSheet(customInstruments: []),
    );
    if (selected != null) setState(() => _items = [..._items, selected]);
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
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedPhoto = picked;
        _pickedPhotoBytes = bytes;
      });
    }
  }

  Future<void> _saveDraft() async {
    setState(() => _saving = true);
    try {
      if (_isTray) {
        await PublicTrayService.instance.saveDraft(widget.trayDraft!.id, _currentTray);
      } else if (_isInstrument) {
        if (_pickedPhoto != null) {
          final userId = AuthService.instance.currentUser!.id;
          _photoPath = await PublicInstrumentService.instance.uploadPhoto(userId: userId, file: _pickedPhoto!);
          _pickedPhoto = null;
          _pickedPhotoBytes = null;
        }
        await PublicInstrumentService.instance.saveDraft(widget.instrumentDraft!.id, _currentInstrument);
      } else {
        await PublicDocumentService.instance.saveDraft(widget.documentDraft!.id, _currentDocument);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.publicLibrarySubmitError(e.toString()))));
      }
      rethrow;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitForReview() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await _saveDraft();
    } catch (_) {
      // _saveDraft ya mostró su propio aviso de error -- no seguimos a submitForReview.
      return;
    }
    try {
      if (_isTray) {
        await PublicTrayService.instance.submitForReview(widget.trayDraft!.id);
      } else if (_isInstrument) {
        await PublicInstrumentService.instance.submitForReview(widget.instrumentDraft!.id);
      } else {
        await PublicDocumentService.instance.submitForReview(widget.documentDraft!.id);
      }
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

  Widget _buildPhotoPicker(AppLocalizations l10n) {
    final existingUrl = _photoPath != null ? PublicInstrumentService.instance.photoUrl(_photoPath!) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _pickPhoto,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _pickedPhotoBytes != null
                    ? Image.memory(_pickedPhotoBytes!, width: 72, height: 72, fit: BoxFit.cover)
                    : existingUrl != null
                        ? Image.network(existingUrl, width: 72, height: 72, fit: BoxFit.cover)
                        : Container(
                            width: 72,
                            height: 72,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.add_a_photo_outlined),
                          ),
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: _pickPhoto,
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(
                _photoPath != null || _pickedPhoto != null ? l10n.changePhotoLabel : l10n.pickPhotoLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          l10n.publicInstrumentPhotoDisclaimer,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown(AppLocalizations l10n) {
    return DropdownButtonFormField<InstrumentCategory?>(
      initialValue: _category,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.categoryFilterLabel,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<InstrumentCategory?>(value: null, child: Text(l10n.noCategoryOption)),
        ...InstrumentCategory.values
            .map((c) => DropdownMenuItem<InstrumentCategory?>(value: c, child: Text(c.label(l10n)))),
      ],
      onChanged: (value) => setState(() => _category = value),
    );
  }

  Widget _buildSpecialtyDropdown(AppLocalizations l10n) {
    return DropdownButtonFormField<String?>(
      initialValue: _specialtyId,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: l10n.specialtyLabel,
        border: const OutlineInputBorder(),
      ),
      items: [
        DropdownMenuItem<String?>(value: null, child: Text(l10n.noSpecialty)),
        ..._specialties.map((s) => DropdownMenuItem<String?>(value: s.id, child: Text(s.label))),
      ],
      onChanged: _loadingSpecialties ? null : (value) => setState(() => _specialtyId = value),
    );
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
        child: InstriqResponsiveContent(
          child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: l10n.titleFieldLabel),
            ),
            const SizedBox(height: 12),
            if (_isInstrument) ...[
              _buildCategoryDropdown(l10n),
              const SizedBox(height: 12),
              _buildSpecialtyDropdown(l10n),
              const SizedBox(height: 12),
              _buildPhotoPicker(l10n),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _contentController,
              maxLines: _isTray || _isInstrument ? 4 : 6,
              decoration: InputDecoration(labelText: l10n.descriptionLabel),
            ),
            if (_isInstrument) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _useTextController,
                maxLines: 3,
                decoration: InputDecoration(labelText: l10n.customInstrumentUseLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tipController,
                maxLines: 2,
                decoration: InputDecoration(labelText: l10n.customInstrumentTipLabel),
              ),
            ],
            if (!_isInstrument) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(_isTray ? l10n.trayItemsLabel : l10n.stepsLabel, style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _isTray ? _addTrayItem : _addStep,
                    icon: const Icon(Icons.add),
                    label: Text(_isTray ? l10n.addAction : l10n.addStepTitle),
                  ),
                ],
              ),
              if (_isTray)
                for (var i = 0; i < _items.length; i++)
                  ListTile(
                    leading: const Icon(Icons.build_outlined),
                    title: Text(_items[i].resolveName(const [])),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.removeItemTooltip,
                      onPressed: () => setState(() => _items = List.of(_items)..removeAt(i)),
                    ),
                  )
              else
                for (var i = 0; i < _steps.length; i++)
                  ListTile(
                    leading: CircleAvatar(radius: 14, child: Text('${i + 1}')),
                    title: Text(_steps[i].text),
                    trailing: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: l10n.removeStepTooltip,
                      onPressed: () => setState(() => _steps = List.of(_steps)..removeAt(i)),
                    ),
                  ),
            ],
            if (_isTray) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _observationsController,
                maxLines: 3,
                decoration: InputDecoration(labelText: l10n.sterilizationObservationsLabel),
              ),
            ],
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
      ),
    );
  }
}
