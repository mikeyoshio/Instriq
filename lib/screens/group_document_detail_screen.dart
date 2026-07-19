import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../models/group_document.dart';
import '../models/instrument.dart';
import '../services/group_document_service.dart';
import '../widgets/category_icon.dart';
import 'group_document_form_screen.dart';
import 'instrument_detail_screen.dart';

class GroupDocumentDetailScreen extends StatefulWidget {
  final GroupDocument document;

  const GroupDocumentDetailScreen({super.key, required this.document});

  @override
  State<GroupDocumentDetailScreen> createState() => _GroupDocumentDetailScreenState();
}

class _GroupDocumentDetailScreenState extends State<GroupDocumentDetailScreen> {
  late GroupDocument _document;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
  }

  Instrument? _instrumentFor(String id) {
    for (final i in kInstruments) {
      if (i.id == id) return i;
    }
    return null;
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => GroupDocumentFormScreen(kind: _document.kind, existingDocument: _document),
      ),
    );
    if (saved == true && mounted) {
      final updated = GroupDocumentService.instance
          .documentsOfKind(_document.kind)
          .firstWhere((d) => d.id == _document.id, orElse: () => _document);
      setState(() => _document = updated);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar ${_document.kind.label.toLowerCase()}'),
        content: Text('¿Eliminar "${_document.title}"? No se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed == true) {
      await GroupDocumentService.instance.deleteDocument(_document.id);
      if (mounted) Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_document.title),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _edit),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (_document.specialty != null) ...[
            Chip(label: Text(_document.specialty!)),
            const SizedBox(height: 16),
          ],
          if (_document.content != null) ...[
            Text('Descripción', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 4),
            Text(_document.content!, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
          ],
          if (_document.steps.isNotEmpty) ...[
            Text('Pasos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._document.steps.asMap().entries.map((entry) {
              return Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${entry.key + 1}')),
                  title: Text(entry.value),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
          if (_document.relatedInstrumentIds.isNotEmpty) ...[
            Text('Instrumental relacionado', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._document.relatedInstrumentIds.map((id) {
              final instrument = _instrumentFor(id);
              if (instrument == null) return const SizedBox.shrink();
              return Card(
                child: ListTile(
                  leading: InstrumentIcon(iconKey: instrument.icon, category: instrument.category, size: 40),
                  title: Text(instrument.name),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => InstrumentDetailScreen(instrument: instrument)),
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
