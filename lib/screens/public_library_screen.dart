import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/group_document.dart' show DocumentKind;
import '../models/public_document.dart';
import '../models/public_tray.dart';
import '../services/contributor_service.dart';
import '../services/public_document_service.dart';
import '../services/public_tray_service.dart';
import 'public_entity_detail_screen.dart';
import 'public_entity_form_screen.dart';
import 'public_library_review_queue_screen.dart';

/// Biblioteca Pública (EPIC 9, segon tram): tècniques/protocols i safates
/// mantingudes per la comunitat, obertes a tothom (també convidats -- RLS
/// de `public_documents`/`public_trays` és `using (true)`). Independent de
/// si l'usuari està connectat a cap hospital -- per això no viu dins de
/// `LibraryScreen` (que sí ho exigeix), sinó com a accés propi.
class PublicLibraryScreen extends StatefulWidget {
  const PublicLibraryScreen({super.key});

  @override
  State<PublicLibraryScreen> createState() => _PublicLibraryScreenState();
}

class _PublicLibraryScreenState extends State<PublicLibraryScreen> {
  bool get _canContribute => ContributorService.instance.myProfile != null;
  bool get _canReview => ContributorService.instance.isEditorialBoard;

  Future<void> _proposeDocument(DocumentKind kind) async {
    final documentId = await PublicDocumentService.instance.createDraft(kind);
    final draft = await PublicDocumentService.instance.fetchDraftVersion(documentId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PublicEntityFormScreen.document(kind: kind, documentId: documentId, draft: draft),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _proposeTray() async {
    final trayId = await PublicTrayService.instance.createDraft();
    final draft = await PublicTrayService.instance.fetchDraftVersion(trayId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicEntityFormScreen.tray(trayId: trayId, draft: draft)),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.publicLibraryTitle),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.techniquesTitle),
              Tab(text: l10n.traysTitle),
            ],
          ),
          actions: [
            if (_canReview)
              IconButton(
                icon: const Icon(Icons.fact_check_outlined),
                tooltip: l10n.publicLibraryReviewQueueTitle,
                onPressed: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => const PublicLibraryReviewQueueScreen())),
              ),
          ],
        ),
        body: TabBarView(
          children: [
            _PublicDocumentList(canContribute: _canContribute, onPropose: _proposeDocument),
            _PublicTrayList(canContribute: _canContribute, onPropose: _proposeTray),
          ],
        ),
      ),
    );
  }
}

class _PublicDocumentList extends StatefulWidget {
  final bool canContribute;
  final ValueChanged<DocumentKind> onPropose;

  const _PublicDocumentList({required this.canContribute, required this.onPropose});

  @override
  State<_PublicDocumentList> createState() => _PublicDocumentListState();
}

class _PublicDocumentListState extends State<_PublicDocumentList> {
  bool _loading = true;
  String? _error;
  List<PublicDocument> _documents = [];

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
      final techniques = await PublicDocumentService.instance.fetchPublished(DocumentKind.technique);
      final protocols = await PublicDocumentService.instance.fetchPublished(DocumentKind.protocol);
      _documents = [...techniques, ...protocols];
    } catch (e) {
      if (mounted) _error = AppLocalizations.of(context)!.publicLibraryLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _documents.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.publicLibraryEmptyState)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _documents.length,
                        itemBuilder: (context, index) {
                          final document = _documents[index];
                          final version = document.publishedVersion;
                          return Card(
                            child: ListTile(
                              leading: Icon(document.kind == DocumentKind.protocol
                                  ? Icons.checklist_outlined
                                  : Icons.menu_book_outlined),
                              title: Text(version?.title ?? l10n.auditDocumentUntitledLabel),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => PublicEntityDetailScreen.document(document: document)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: widget.canContribute
          ? FloatingActionButton.extended(
              onPressed: () async {
                final kind = await showModalBottomSheet<DocumentKind>(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          title: Text(l10n.techniquesTitle),
                          onTap: () => Navigator.pop(ctx, DocumentKind.technique),
                        ),
                        ListTile(
                          title: Text(l10n.protocolsTitle),
                          onTap: () => Navigator.pop(ctx, DocumentKind.protocol),
                        ),
                      ],
                    ),
                  ),
                );
                if (kind != null) widget.onPropose(kind);
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.publicLibraryProposeAction),
            )
          : null,
    );
  }
}

class _PublicTrayList extends StatefulWidget {
  final bool canContribute;
  final VoidCallback onPropose;

  const _PublicTrayList({required this.canContribute, required this.onPropose});

  @override
  State<_PublicTrayList> createState() => _PublicTrayListState();
}

class _PublicTrayListState extends State<_PublicTrayList> {
  bool _loading = true;
  String? _error;
  List<PublicTray> _trays = [];

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
      _trays = await PublicTrayService.instance.fetchPublished();
    } catch (e) {
      if (mounted) _error = AppLocalizations.of(context)!.publicLibraryLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : _trays.isEmpty
                  ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(l10n.publicLibraryEmptyState)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _trays.length,
                        itemBuilder: (context, index) {
                          final tray = _trays[index];
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.inventory_2_outlined),
                              title: Text(tray.publishedVersion?.name ?? l10n.auditDocumentUntitledLabel),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => PublicEntityDetailScreen.tray(tray: tray)),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: widget.canContribute
          ? FloatingActionButton.extended(
              onPressed: widget.onPropose,
              icon: const Icon(Icons.add),
              label: Text(l10n.publicLibraryProposeAction),
            )
          : null,
    );
  }
}
