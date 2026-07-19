import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../models/group_document.dart';
import '../models/instrument.dart';
import '../services/group_document_service.dart';
import '../widgets/catalog_picker_sheet.dart';
import '../widgets/category_icon.dart';

class GroupDocumentFormScreen extends StatefulWidget {
  final DocumentKind kind;
  final GroupDocument? existingDocument;

  const GroupDocumentFormScreen({super.key, required this.kind, this.existingDocument});

  @override
  State<GroupDocumentFormScreen> createState() => _GroupDocumentFormScreenState();
}

class _GroupDocumentFormScreenState extends State<GroupDocumentFormScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _contentController;
  late List<String> _steps;
  late List<String> _relatedInstrumentIds;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final doc = widget.existingDocument;
    _titleController = TextEditingController(text: doc?.title ?? '');
    _specialtyController = TextEditingController(text: doc?.specialty ?? '');
    _contentController = TextEditingController(text: doc?.content ?? '');
    _steps = List.of(doc?.steps ?? const []);
    _relatedInstrumentIds = List.of(doc?.relatedInstrumentIds ?? const []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _specialtyController.dispose();
    _contentController.dispose();
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

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Indica un título');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final doc = GroupDocument(
        id: widget.existingDocument?.id ?? '',
        kind: widget.kind,
        title: title,
        specialty: _specialtyController.text.trim().isEmpty ? null : _specialtyController.text.trim(),
        content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
        steps: _steps,
        relatedInstrumentIds: _relatedInstrumentIds,
      );
      await GroupDocumentService.instance.upsertDocument(doc);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = 'Error al guardar: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingDocument != null;
    final kindLabel = widget.kind.label;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Editar $kindLabel' : 'Nuevo/a $kindLabel')),
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
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Guardar $kindLabel'),
            ),
          ],
        ),
      ),
    );
  }
}
