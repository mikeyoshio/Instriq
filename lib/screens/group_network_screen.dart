import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/group_document.dart';
import '../models/group_sibling_organization.dart';
import '../models/org_type.dart';
import '../models/tray.dart';
import '../models/workspace.dart';
import '../services/auth_service.dart';
import '../services/group_document_service.dart';
import '../services/profile_service.dart';
import '../services/tray_service.dart';
import '../services/workspace_service.dart';
import 'tray_form_screen.dart';

/// Visibilitat de NOMÉS LECTURA de bandeixes i tècniques/protocols
/// PUBLICATS d'organitzacions germanes de la mateixa cadena (p. ex. Quirón
/// Teknon veient el contingut de Quirón Barcelona) -- ver
/// schema_v65_hospital_groups.sql. Mai contingut propi, mai edició, mai
/// targetes de preferència ni instrumental personalitzat de l'altre centre.
class GroupNetworkScreen extends StatefulWidget {
  const GroupNetworkScreen({super.key});

  @override
  State<GroupNetworkScreen> createState() => _GroupNetworkScreenState();
}

class _GroupNetworkScreenState extends State<GroupNetworkScreen> {
  bool _loading = true;
  List<GroupSiblingOrganization> _siblings = [];
  String? _error;

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
      _siblings = await ProfileService.instance.fetchGroupSiblingOrganizations();
    } catch (e) {
      if (mounted) _error = AppLocalizations.of(context)!.genericError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupNetworkTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  if (!_loading && _siblings.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(l10n.groupNetworkEmpty),
                    )
                  else
                    for (final sibling in _siblings)
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.local_hospital_outlined),
                          title: Text(sibling.name),
                          subtitle: Text(OrgType.fromDb(sibling.orgType).label(l10n)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => _GroupNetworkWorkspacesScreen(organization: sibling),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
    );
  }
}

class _GroupNetworkWorkspacesScreen extends StatefulWidget {
  final GroupSiblingOrganization organization;

  const _GroupNetworkWorkspacesScreen({required this.organization});

  @override
  State<_GroupNetworkWorkspacesScreen> createState() => _GroupNetworkWorkspacesScreenState();
}

class _GroupNetworkWorkspacesScreenState extends State<_GroupNetworkWorkspacesScreen> {
  bool _loading = true;
  List<Workspace> _workspaces = [];
  String? _error;

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
      _workspaces = await WorkspaceService.instance.fetchGroupSiblingWorkspaces(widget.organization.id);
    } catch (e) {
      if (mounted) _error = AppLocalizations.of(context)!.genericError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.organization.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                if (!_loading && _workspaces.isEmpty)
                  Padding(padding: const EdgeInsets.all(16), child: Text(l10n.groupNetworkNoWorkspaces))
                else
                  for (final workspace in _workspaces)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.groups_outlined),
                        title: Text(workspace.name),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => _GroupNetworkContentScreen(workspace: workspace),
                          ),
                        ),
                      ),
                    ),
              ],
            ),
    );
  }
}

class _GroupNetworkContentScreen extends StatefulWidget {
  final Workspace workspace;

  const _GroupNetworkContentScreen({required this.workspace});

  @override
  State<_GroupNetworkContentScreen> createState() => _GroupNetworkContentScreenState();
}

class _GroupNetworkContentScreenState extends State<_GroupNetworkContentScreen> {
  bool _loading = true;
  List<Tray> _trays = [];
  List<GroupDocument> _documents = [];
  String? _error;

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
      final results = await Future.wait([
        TrayService.instance.fetchGroupSiblingTrays(widget.workspace.id),
        GroupDocumentService.instance.fetchGroupSiblingDocuments(DocumentKind.technique, widget.workspace.id),
        GroupDocumentService.instance.fetchGroupSiblingDocuments(DocumentKind.protocol, widget.workspace.id),
      ]);
      _trays = results[0] as List<Tray>;
      _documents = [...results[1] as List<GroupDocument>, ...results[2] as List<GroupDocument>];
    } catch (e) {
      if (mounted) _error = AppLocalizations.of(context)!.genericError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final publishedTrays = _trays.where((t) => t.publishedVersion != null).toList();
    final publishedDocuments = _documents.where((d) => d.publishedVersion != null).toList();
    return Scaffold(
      appBar: AppBar(title: Text(widget.workspace.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                if (!_loading && publishedTrays.isEmpty && publishedDocuments.isEmpty)
                  Padding(padding: const EdgeInsets.all(16), child: Text(l10n.groupNetworkNoContent)),
                if (publishedTrays.isNotEmpty) ...[
                  Text(l10n.traysTitle, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final tray in publishedTrays)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.inventory_2_outlined),
                        title: Text(tray.publishedVersion!.name),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => _GroupTrayDetailScreen(tray: tray)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                if (publishedDocuments.isNotEmpty) ...[
                  Text(l10n.groupDocumentsSectionTitle, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  for (final document in publishedDocuments)
                    Card(
                      child: ListTile(
                        leading: Icon(document.kind == DocumentKind.protocol
                            ? Icons.rule_folder_outlined
                            : Icons.menu_book_outlined),
                        title: Text(document.publishedVersion!.title),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => _GroupDocumentDetailScreen(document: document)),
                        ),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}

class _GroupTrayDetailScreen extends StatefulWidget {
  final Tray tray;

  const _GroupTrayDetailScreen({required this.tray});

  @override
  State<_GroupTrayDetailScreen> createState() => _GroupTrayDetailScreenState();
}

class _GroupTrayDetailScreenState extends State<_GroupTrayDetailScreen> {
  bool _adopting = false;

  List<Widget> _itemGroup(AppLocalizations l10n, String title, List<TrayItem> items) {
    if (items.isEmpty) return const [];
    final languageCode = Localizations.localeOf(context).languageCode;
    return [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      for (final item in items)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(_refTypeIcon(item.instrumentRefType)),
          title: Text(
            item.instrumentRefType == InstrumentRefType.custom
                ? l10n.groupNetworkCustomInstrumentHidden
                : item.resolveName(const [], languageCode: languageCode),
            style: item.instrumentRefType == InstrumentRefType.custom
                ? TextStyle(color: Theme.of(context).colorScheme.outline, fontStyle: FontStyle.italic)
                : null,
          ),
          subtitle: item.position != null ? Text(item.position!) : null,
        ),
      const SizedBox(height: 12),
    ];
  }

  IconData _refTypeIcon(InstrumentRefType type) => switch (type) {
        InstrumentRefType.catalog => Icons.build_outlined,
        InstrumentRefType.custom => Icons.extension_outlined,
        InstrumentRefType.suture => Icons.linear_scale_outlined,
        InstrumentRefType.drug => Icons.medication_outlined,
        InstrumentRefType.woundClosure => Icons.healing_outlined,
      };

  Future<String?> _pickWorkspaceId(AppLocalizations l10n) async {
    await WorkspaceService.instance.fetchWorkspaces();
    final workspaces = WorkspaceService.instance.workspaces;
    if (workspaces.isEmpty) return null;
    if (workspaces.length == 1) return workspaces.first.id;
    if (!mounted) return null;
    return showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.workspaceLabel, style: Theme.of(ctx).textTheme.titleMedium),
            ),
            for (final w in workspaces) ListTile(title: Text(w.name), onTap: () => Navigator.pop(ctx, w.id)),
          ],
        ),
      ),
    );
  }

  Future<void> _adopt() async {
    final l10n = AppLocalizations.of(context)!;
    if (!ProfileService.instance.hasHospital) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.adoptNoWorkspaceError)));
      return;
    }
    final workspaceId = await _pickWorkspaceId(l10n);
    if (workspaceId == null || !mounted) return;
    setState(() => _adopting = true);
    try {
      final draft =
          await TrayService.instance.adoptGroupTray(sourceTrayId: widget.tray.id, targetWorkspaceId: workspaceId);
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TrayFormScreen(workspaceId: workspaceId, existingDraft: draft)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _adopting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final version = widget.tray.publishedVersion!;
    return Scaffold(
      appBar: AppBar(title: Text(version.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (version.description != null && version.description!.isNotEmpty) ...[
            Text(version.description!, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
          ],
          if (version.items.isEmpty) Text(l10n.trayNoItemsYet),
          ..._itemGroup(l10n, l10n.trayReusableItemsLabel, version.items.where((i) => !i.isFungible()).toList()),
          ..._itemGroup(l10n, l10n.trayFungibleItemsLabel, version.items.where((i) => i.isFungible()).toList()),
        ],
      ),
      bottomNavigationBar: AuthService.instance.currentUser == null
          ? null
          : SafeArea(
              minimum: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _adopting ? null : _adopt,
                icon: _adopting
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_outlined),
                label: Text(l10n.groupNetworkAdoptAction),
              ),
            ),
    );
  }
}

class _GroupDocumentDetailScreen extends StatelessWidget {
  final GroupDocument document;

  const _GroupDocumentDetailScreen({required this.document});

  @override
  Widget build(BuildContext context) {
    final version = document.publishedVersion!;
    return Scaffold(
      appBar: AppBar(title: Text(version.title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (version.content != null && version.content!.isNotEmpty) ...[
            Text(version.content!, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 20),
          ],
          for (final step in version.steps)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (step.category != null && step.category!.isNotEmpty)
                    Text(step.category!, style: Theme.of(context).textTheme.labelLarge),
                  Text(step.text, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
