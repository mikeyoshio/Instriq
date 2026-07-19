import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../models/group_document.dart';
import '../models/group_document_version.dart';
import '../models/instrument.dart';
import '../services/group_document_service.dart';
import '../widgets/catalog_picker_sheet.dart';
import '../widgets/category_icon.dart';

/// Edita el borrador de una versión ([existingDraft]) o crea un documento
/// nuevo. Nunca edita directamente el contenido publicado: guardar solo
/// persiste el borrador, "Enviar a revisión" además dispara el workflow de
/// aprobación (ver GroupDocumentService).
class GroupDocumentFormScreen extends StatefulWidget {
  final DocumentKind kind;
  final String workspaceId;
  final GroupDocument? existingDocument;
  final GroupDocumentVersion? existingDraft;

  const GroupDocumentFormScreen({
    super.key,
    required this.kind,
    required this.workspaceId,
    this.existingDocument,
    this.existingDraft,
  });

  @override
  State<GroupDocumentFormScreen> createState() => _GroupDocumentFormScreenState();
}

class _GroupDocumentFormScreenState extends State<GroupDocumentFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _contentController;
  late final TextEditingController _commentController;
  late List<String> _steps;
  late List<String> _relatedInstrumentIds;
  GroupDocumentVersion? _draft;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _specialtyController = TextEditingController();
    _contentController = TextEditingController();
    _commentController = TextEditingController();
    _steps = [];
    _relatedInstrumentIds = [];
    _init();
  }

  Future<void> _init() async {
    try {
      GroupDocumentVersion draft;
      if (widget.existingDraft != null) {
        draft = widget.existingDraft!;
      } else if (widget.existingDocument != null) {
        draft = await GroupDocumentService.instance.startEditing(widget.existingDocument!);
      } else {
        draft = await GroupDocumentService.instance.createDocument(widget.kind, widget.workspaceId);
      }
      _applyDraft(draft);
    } catch (e) {
      setState(() => _error = 'No se pudo preparar el borrador: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyDraft(GroupDocumentVersion draft) {
    _draft = draft;
    _titleController.text = draft.title;
    _specialtyController.text = draft.specialty ?? '';
    _contentController.text = draft.content ?? '';
    _steps = List.of(draft.steps);
    _relatedInstrumentIds = List.of(draft.relatedInstrumentIds);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _specialtyController.dispose();
    _contentController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Instrument? _instrumentFor(String id) {
    for (final i in kInstruments) {
      if (i.id == id) return i;
    }
    return null;
  }

  Future<void> _addStep() async {
    final controller = TextEditingController();
    final step = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir paso'),
        content: TextField(controller: controller, autofocus: true, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
    if (step != null && step.isNotEmpty) {
      setState(() => _steps.add(step));
    }
  }

  Future<void> _addInstrument() async {
    final selected = await showModalBottomSheet<Instrument>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CatalogPickerSheet(),
    );
    if (selected != null && !_relatedInstrumentIds.contains(selected.id)) {
      setState(() => _relatedInstrumentIds.add(selected.id));
    }
  }

  GroupDocumentVersion _draftWithFormValues() {
    final title = _titleController.text.trim();
    return _draft!.copyWith(
      title: title,
      specialty: _specialtyController.text.trim().isEmpty ? null : _specialtyController.text.trim(),
      content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
      steps: _steps,
      relatedInstrumentIds: _relatedInstrumentIds,
      comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    );
  }

  Future<void> _saveDraft({bool andSubmit = false}) async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Indica un título');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await GroupDocumentService.instance.saveDraft(_draftWithFormValues());
      if (andSubmit) {
        await GroupDocumentService.instance.submitForReview(updated.id);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = 'Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kindLabel = widget.kind.label;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(kindLabel)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_draft == null) {
      return Scaffold(
        appBar: AppBar(title: Text(kindLabel)),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error ?? 'Error'))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Editar borrador · $kindLabel')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _specialtyController,
              decoration: const InputDecoration(
                labelText: 'Especialidad (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Pasos', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir paso'),
                ),
              ],
            ),
            if (_steps.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Sin pasos todavía'),
              ),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final step = _steps.removeAt(oldIndex);
                  _steps.insert(newIndex, step);
                });
              },
              itemBuilder: (context, index) {
                return ListTile(
                  key: ValueKey('step_${index}_${_steps[index]}'),
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(_steps[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _steps.removeAt(index)),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text('Instrumental relacionado', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addInstrument,
                  icon: const Icon(Icons.add),
                  label: const Text('Añadir'),
                ),
              ],
            ),
            if (_relatedInstrumentIds.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Sin instrumental enlazado'),
              ),
            ..._relatedInstrumentIds.map((id) {
              final instrument = _instrumentFor(id);
              return ListTile(
                leading: instrument != null
                    ? InstrumentIcon(iconKey: instrument.icon, category: instrument.category, size: 36)
                    : const Icon(Icons.build_outlined),
                title: Text(instrument?.name ?? id),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _relatedInstrumentIds.remove(id)),
                ),
              );
            }),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comentario del cambio (opcional)',
                border: OutlineInputBorder(),
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
                  : const Text('Enviar a revisión'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _saving ? null : () => _saveDraft(),
              child: const Text('Guardar como borrador'),
            ),
          ],
        ),
      ),
    );
  }
}
