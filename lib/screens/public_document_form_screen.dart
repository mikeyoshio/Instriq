import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/group_document_version.dart' show ProtocolStep;
import '../models/public_document.dart';
import '../services/public_document_service.dart';

/// Formulari d'una proposta de tècnica/protocol a la Biblioteca Pública.
/// Nomes edita l'esborrany (mai el contingut publicat) -- mateix criteri
/// que `GroupDocumentFormScreen`. Deliberadament senzill per a aquest tram:
/// sense el picker d'instrumental/safates relacionats de la versió privada.
class PublicDocumentFormScreen extends StatefulWidget {
  final String documentId;
  final PublicDocumentVersion draft;

  const PublicDocumentFormScreen({super.key, required this.documentId, required this.draft});

  @override
  State<PublicDocumentFormScreen> createState() => _PublicDocumentFormScreenState();
}

class _PublicDocumentFormScreenState extends State<PublicDocumentFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late List<ProtocolStep> _steps;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.draft.title ?? '');
    _contentController = TextEditingController(text: widget.draft.content ?? '');
    _steps = List.of(widget.draft.steps);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  PublicDocumentVersion get _current => PublicDocumentVersion(
        id: widget.draft.id,
        documentId: widget.documentId,
        versionNumber: widget.draft.versionNumber,
        status: widget.draft.status,
        title: _titleController.text.trim().isEmpty ? null : _titleController.text.trim(),
        specialtyId: widget.draft.specialtyId,
        content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
        steps: _steps,
        relatedInstrumentIds: widget.draft.relatedInstrumentIds,
        relatedTrayIds: widget.draft.relatedTrayIds,
        createdAt: widget.draft.createdAt,
      );

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

  Future<void> _saveDraft() async {
    setState(() => _saving = true);
    try {
      await PublicDocumentService.instance.saveDraft(widget.draft.id, _current);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submitForReview() async {
    final l10n = AppLocalizations.of(context)!;
    await _saveDraft();
    try {
      await PublicDocumentService.instance.submitForReview(widget.draft.id);
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
              maxLines: 6,
              decoration: InputDecoration(labelText: l10n.descriptionLabel),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(l10n.stepsLabel, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(onPressed: _addStep, icon: const Icon(Icons.add), label: Text(l10n.addStepTitle)),
              ],
            ),
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
