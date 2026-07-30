import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/group_document.dart';
import '../models/group_document_version.dart';
import '../models/workspace.dart';
import '../models/workspace_role.dart';
import '../services/group_document_service.dart';
import '../services/specialty_service.dart';
import '../widgets/offline_banner.dart';
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
  bool _fromCache = false;

  String get _titlePlural {
    final l10n = AppLocalizations.of(context)!;
    return widget.kind == DocumentKind.technique ? l10n.techniquesTitle : l10n.protocolsTitle;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Future.wait([
        GroupDocumentService.instance.fetchDocuments(widget.kind, widget.workspace.id),
        SpecialtyService.instance.fetchAll(),
      ]);
      _fromCache = GroupDocumentService.instance.documentsFromCache;
    } catch (e) {
      _error = l10n.groupDocLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  String? _specialtyLabel(GroupDocumentVersion? published) {
    if (published == null) return null;
    final specialtyId = published.specialtyId;
    if (specialtyId != null) return SpecialtyService.instance.byId(specialtyId)?.label ?? published.specialty;
    return published.specialty;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                FilledButton(onPressed: _load, child: Text(l10n.retry)),
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
              label: Text(l10n.newKindLabel(widget.kind.label.toLowerCase())),
            )
          : null,
      body: Column(
        children: [
          if (_fromCache)
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: OfflineBanner(),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchHint(_titlePlural).toLowerCase(),
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
                        l10n.groupDocEmptyState,
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
                          title: Text(published?.title ?? l10n.unpublished),
                          subtitle: _specialtyLabel(published) != null ? Text(_specialtyLabel(published)!) : null,
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
