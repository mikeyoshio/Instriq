import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/tray.dart';
import '../models/workspace.dart';
import '../models/workspace_role.dart';
import '../services/specialty_service.dart';
import '../services/tray_service.dart';
import 'tray_detail_screen.dart';
import 'tray_form_screen.dart';

/// Lista de bandejas de instrumental de un espacio. Calcado de
/// [GroupDocumentListScreen].
class TraysScreen extends StatefulWidget {
  final Workspace workspace;
  final WorkspaceRole? myRole;

  const TraysScreen({super.key, required this.workspace, required this.myRole});

  @override
  State<TraysScreen> createState() => _TraysScreenState();
}

class _TraysScreenState extends State<TraysScreen> {
  bool _loading = true;
  String? _error;
  String _query = '';

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
        TrayService.instance.fetchTrays(widget.workspace.id),
        SpecialtyService.instance.fetchAll(),
      ]);
    } catch (e) {
      _error = l10n.trayLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  String? _specialtyLabel(TrayVersion? published) {
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
        appBar: AppBar(title: Text(l10n.traysTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.traysTitle)),
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

    final trays = TrayService.instance
        .traysOfWorkspace(widget.workspace.id)
        .where((t) => _query.isEmpty || (t.publishedVersion?.name ?? '').toLowerCase().contains(_query.toLowerCase()))
        .toList();

    final canEdit = widget.myRole?.canEdit ?? false;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.traysTitle)),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () async {
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => TrayFormScreen(workspaceId: widget.workspace.id),
                  ),
                );
                if (saved == true) _load();
              },
              icon: const Icon(Icons.add),
              label: Text(l10n.newTrayLabel),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.searchHint(l10n.traysTitle).toLowerCase(),
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: trays.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(l10n.trayEmptyState, textAlign: TextAlign.center),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: trays.length,
                    itemBuilder: (context, index) {
                      final tray = trays[index];
                      final published = tray.publishedVersion;
                      return Card(
                        child: ListTile(
                          title: Text(published?.name ?? l10n.unpublished),
                          subtitle: _specialtyLabel(published) != null ? Text(_specialtyLabel(published)!) : null,
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TrayDetailScreen(tray: tray, myRole: widget.myRole),
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
