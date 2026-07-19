import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../models/group_document.dart';
import '../models/group_document_version.dart';
import '../models/instrument.dart';
import '../services/auth_service.dart';
import '../services/group_document_service.dart';
import '../widgets/category_icon.dart';
import 'group_document_form_screen.dart';
import 'group_document_version_history_screen.dart';
import 'instrument_detail_screen.dart';

class GroupDocumentDetailScreen extends StatefulWidget {
  final GroupDocument document;

  const GroupDocumentDetailScreen({super.key, required this.document});

  @override
  State<GroupDocumentDetailScreen> createState() => _GroupDocumentDetailScreenState();
}

class _GroupDocumentDetailScreenState extends State<GroupDocumentDetailScreen> {
  late GroupDocument _document;
  GroupDocumentVersion? _ownPendingDraft;
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
    _loadOwnDraft();
  }

  Future<void> _loadOwnDraft() async {
    final userId = AuthService.instance.currentUser?.id;
    try {
      final versions = await GroupDocumentService.instance.fetchVersionHistory(_document.id);
      _ownPendingDraft = versions
          .where((v) =>
              v.authorId == userId &&
              (v.status == GroupDocumentVersionStatus.draft ||
                  v.status == GroupDocumentVersionStatus.inReview))
          .cast<GroupDocumentVersion?>()
          .firstWhere((_) => true, orElse: () => null);
    } catch (_) {
      _ownPendingDraft = null;
    }
    if (mounted) setState(() => _loadingHistory = false);
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
        builder: (_) => GroupDocumentFormScreen(
          kind: _document.kind,
          existingDocument: _document,
          existingDraft: _ownPendingDraft?.status == GroupDocumentVersionStatus.draft
              ? _ownPendingDraft
              : null,
        ),
      ),
    );
    if (saved == true && mounted) {
      await GroupDocumentService.instance.fetchDocuments(_document.kind);
      final updated = GroupDocumentService.instance.documentById(_document.id);
      setState(() => _document = updated ?? _document);
      _loadOwnDraft();
    }
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GroupDocumentVersionHistoryScreen(document: _document)),
    );
    _loadOwnDraft();
  }

  Future<void> _delete() async {
    final title = _document.publishedVersion?.title ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Eliminar ${_document.kind.label.toLowerCase()}'),
        content: Text('¿Eliminar "$title"? No se puede deshacer.'),
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
    final published = _document.publishedVersion;
    return Scaffold(
      appBar: AppBar(
        title: Text(published?.title ?? 'Sin publicar'),
        actions: [
          IconButton(icon: const Icon(Icons.history), onPressed: _openHistory, tooltip: 'Historial'),
          IconButton(icon: const Icon(Icons.edit), onPressed: _edit),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (!_loadingHistory && _ownPendingDraft != null) ...[
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: ListTile(
                leading: const Icon(Icons.pending_actions),
                title: Text(
                  _ownPendingDraft!.status == GroupDocumentVersionStatus.inReview
                      ? 'Tienes cambios pendientes de revisión'
                      : 'Tienes un borrador sin enviar',
                ),
                subtitle: const Text('Este contenido publicado no cambiará hasta que se apruebe'),
                onTap: _edit,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (published == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('Este documento todavía no tiene una versión publicada.'),
            )
          else ...[
            if (published.specialty != null) ...[
              Chip(label: Text(published.specialty!)),
              const SizedBox(height: 16),
            ],
            if (published.content != null) ...[
              Text('Descripción', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(published.content!, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 20),
            ],
            if (published.steps.isNotEmpty) ...[
              Text('Pasos', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...published.steps.asMap().entries.map((entry) {
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${entry.key + 1}')),
                    title: Text(entry.value),
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
            if (published.relatedInstrumentIds.isNotEmpty) ...[
              Text('Instrumental relacionado', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...published.relatedInstrumentIds.map((id) {
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
        ],
      ),
    );
  }
}
