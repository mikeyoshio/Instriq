import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/group_document.dart' show DocumentKind;
import '../models/group_document_version.dart' show ProtocolStep;
import '../models/public_document.dart';
import '../models/public_tray.dart';
import '../models/tray.dart' show TrayItem;
import '../services/public_document_service.dart';
import '../services/public_tray_service.dart';
import '../widgets/tray_item_picker_sheet.dart';

/// Els 3 tipus de contingut que admet la Biblioteca Pública. `technique` i
/// `protocol` comparteixen la variant "document" (contingut+passos);
/// `tray` es la variant "safata" (descripció+items+observacions).
enum PublicEntityKind { technique, protocol, tray }

extension PublicEntityKindX on PublicEntityKind {
  bool get isTray => this == PublicEntityKind.tray;
}

/// Formulari d'una proposta (tècnica/protocol o safata) a la Biblioteca
/// Pública. Nomes edita l'esborrany (mai el contingut publicat) -- mateix
/// criteri que `GroupDocumentFormScreen`. Deliberadament senzill per a
/// aquest tram: sense el picker d'instrumental/safates relacionats de la
/// versió privada.
class PublicEntityFormScreen extends StatefulWidget {
  final PublicEntityKind entityKind;
  final String entityId;
  final PublicDocumentVersion? documentDraft;
  final PublicTrayVersion? trayDraft;

  const PublicEntityFormScreen.document({
    super.key,
    required DocumentKind kind,
    required String documentId,
    required PublicDocumentVersion draft,
  })  : entityKind = kind == DocumentKind.protocol ? PublicEntityKind.protocol : PublicEntityKind.technique,
        entityId = documentId,
        documentDraft = draft,
        trayDraft = null;

  const PublicEntityFormScreen.tray({
    super.key,
    required String trayId,
    required PublicTrayVersion draft,
  })  : entityKind = PublicEntityKind.tray,
        entityId = trayId,
        documentDraft = null,
        trayDraft = draft;

  @override
  State<PublicEntityFormScreen> createState() => _PublicEntityFormScreenState();
}

class _PublicEntityFormScreenState extends State<PublicEntityFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  TextEditingController? _observationsController;
  List<ProtocolStep> _steps = [];
  List<TrayItem> _items = [];
  bool _saving = false;

  bool get _isTray => widget.entityKind.isTray;

  @override
  void initState() {
    super.initState();
    if (_isTray) {
      final draft = widget.trayDraft!;
      _titleController = TextEditingController(text: draft.name ?? '');
      _contentController = TextEditingController(text: draft.description ?? '');
      _observationsController = TextEditingController(text: draft.observations ?? '');
      _items = List.of(draft.items);
    } else {
      final draft = widget.documentDraft!;
      _titleController = TextEditingController(text: draft.title ?? '');
      _contentController = TextEditingController(text: draft.content ?? '');
      _steps = List.of(draft.steps);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _observationsController?.dispose();
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

  Future<void> _saveDraft() async {
    setState(() => _saving = true);
    try {
      if (_isTray) {
        await PublicTrayService.instance.saveDraft(widget.trayDraft!.id, _currentTray);
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
              controller: _titleController,
              decoration: InputDecoration(labelText: l10n.titleFieldLabel),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: _isTray ? 4 : 6,
              decoration: InputDecoration(labelText: l10n.descriptionLabel),
            ),
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
    );
  }
}
