import 'package:flutter/material.dart';

import '../models/group_document.dart';
import '../models/workspace.dart';
import '../models/workspace_role.dart';
import '../services/group_document_service.dart';
import 'group_document_detail_screen.dart';
import 'group_document_form_screen.dart';

/// Lista de técnicas quirúrgicas o protocolos de un espacio (según [kind]).
class GroupDocumentListScreen extends StatefulWidget {
  final DocumentKind kind;
  final Workspace workspace;
  final WorkspaceRole? myRole;

  const GroupDocumentListScreen({
    super.key,
    required this.kind,
    required this.workspace,
    required this.myRole,
  });

  @override
  State<GroupDocumentListScreen> createState() => _GroupDocumentListScreenState();
}

class _GroupDocumentListScreenState extends State<GroupDocumentListScreen> {
  bool _loading = true;
  String? _error;
  String _query = '';

  String get _titlePlural =>
      widget.kind == DocumentKind.technique ? 'Técnicas quirúrgicas' : 'Protocolos';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await GroupDocumentService.instance.fetchDocuments(widget.kind, widget.workspace.id);
    } catch (e) {
      _error = 'No se pudo cargar: $e';
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(_titlePlural)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_titlePlural)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: _load, child: const Text('Reintentar')),
              ],
            ),
          ),
        ),
      );
    }

    final documents = GroupDocumentService.instance
        .documentsOfKind(widget.kind, widget.workspace.id)
        .where((d) =>
            _query.isEmpty ||
            (d.publishedVersion?.title ?? '').toLowerCase().contains(_query.toLowerCase()))
        .toList();

    final canEdit = widget.myRole?.canEdit ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(_titlePlural)),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () async {
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) =>
                        GroupDocumentFormScreen(kind: widget.kind, workspaceId: widget.workspace.id),
                  ),
                );
                if (saved == true) _load();
              },
              icon: const Icon(Icons.add),
              label: Text('Nuevo/a ${widget.kind.label.toLowerCase()}'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Buscar $_titlePlural...'.toLowerCase(),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: documents.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Todavía no hay contenido. Crea el primero con el botón +.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: documents.length,
                    itemBuilder: (context, index) {
                      final doc = documents[index];
                      final published = doc.publishedVersion;
                      return Card(
                        child: ListTile(
                          title: Text(published?.title ?? 'Sin publicar'),
                          subtitle: published?.specialty != null ? Text(published!.specialty!) : null,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    GroupDocumentDetailScreen(document: doc, myRole: widget.myRole),
                              ),
                            );
                            _load();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
