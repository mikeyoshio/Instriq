import 'package:flutter/material.dart';

import '../design_system/components/instriq_responsive_content.dart';
import '../l10n/app_localizations.dart';
import '../models/group_document.dart';
import '../models/workspace.dart';
import '../models/workspace_role.dart';
import '../services/custom_instrument_service.dart';
import '../services/group_document_service.dart';
import '../services/preference_card_service.dart';
import '../services/tray_service.dart';
import '../services/workspace_service.dart';
import 'custom_instruments_screen.dart';
import 'group_document_list_screen.dart';
import 'manage_workspace_members_screen.dart';
import 'preference_cards_screen.dart';
import 'trays_screen.dart';

/// Colecciones disponibles dentro de un espacio: técnicas, protocolos,
/// tarjetas de preferencia e instrumental propio del equipo. El catálogo
/// global de instrumentos es aparte y no cuelga de ningún espacio; el
/// instrumental personalizado de esta pantalla sí, y nunca se mezcla con
/// el catálogo global (ver supabase/schema_v13_custom_instruments.sql).
class WorkspaceDetailScreen extends StatefulWidget {
  final Workspace workspace;

  const WorkspaceDetailScreen({super.key, required this.workspace});

  @override
  State<WorkspaceDetailScreen> createState() => _WorkspaceDetailScreenState();
}

class _WorkspaceDetailScreenState extends State<WorkspaceDetailScreen> {
  WorkspaceRole? _myRole;
  bool _loadingRole = true;

  /// Recuento de contenido propio del espacio por colección -- "reunir lo
  /// que usa el equipo en un solo sitio" (propuesta de producto auditada
  /// esta sesión) sin inventar una pantalla ni relaciones nuevas: ya había
  /// 5 tarjetas de navegación a cada colección, aquí solo se les añade
  /// cuántos elementos tiene cada una. `null` mientras carga.
  int? _techniqueCount;
  int? _protocolCount;
  int? _preferenceCardCount;
  int? _customInstrumentCount;
  int? _trayCount;

  @override
  void initState() {
    super.initState();
    _loadRole();
    _loadCounts();
  }

  Future<void> _loadRole() async {
    try {
      _myRole = await WorkspaceService.instance.fetchMyRole(widget.workspace.id);
    } catch (_) {
      _myRole = null;
    }
    if (mounted) setState(() => _loadingRole = false);
  }

  Future<void> _loadCounts() async {
    final workspaceId = widget.workspace.id;
    try {
      await Future.wait([
        GroupDocumentService.instance.fetchDocuments(DocumentKind.technique, workspaceId),
        GroupDocumentService.instance.fetchDocuments(DocumentKind.protocol, workspaceId),
        PreferenceCardService.instance.fetchCards(workspaceId),
        CustomInstrumentService.instance.fetchForWorkspace(workspaceId),
        TrayService.instance.fetchTrays(workspaceId),
      ]);
      if (!mounted) return;
      setState(() {
        _techniqueCount = GroupDocumentService.instance.documentsOfKind(DocumentKind.technique, workspaceId).length;
        _protocolCount = GroupDocumentService.instance.documentsOfKind(DocumentKind.protocol, workspaceId).length;
        _preferenceCardCount = PreferenceCardService.instance.cardsOfWorkspace(workspaceId).length;
        _customInstrumentCount =
            CustomInstrumentService.instance.instruments.where((i) => i.workspaceId == workspaceId).length;
        _trayCount = TrayService.instance.traysOfWorkspace(workspaceId).length;
      });
    } catch (_) {
      // El recuento es un extra informativo: si falla (sin conexión, etc.)
      // las tarjetas simplemente se quedan sin número, nunca rompen la
      // navegación a cada colección.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canManage = _myRole?.isAdministrator ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workspace.name),
        actions: [
          if (canManage)
            IconButton(
              icon: const Icon(Icons.group_outlined),
              tooltip: l10n.workspaceMembersTooltip,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ManageWorkspaceMembersScreen(workspace: widget.workspace),
                ),
              ),
            ),
        ],
      ),
      body: _loadingRole
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: InstriqResponsiveContent(
                child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (widget.workspace.description != null) ...[
                    Text(widget.workspace.description!, style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 20),
                  ],
                  if (_myRole == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(l10n.workspaceNoAccess),
                    )
                  else ...[
                    _CollectionCard(
                      icon: Icons.menu_book_outlined,
                      title: l10n.techniquesTitle,
                      subtitle: l10n.techniquesSubtitle,
                      count: _techniqueCount,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GroupDocumentListScreen(
                            kind: DocumentKind.technique,
                            workspace: widget.workspace,
                            myRole: _myRole,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CollectionCard(
                      icon: Icons.fact_check_outlined,
                      title: l10n.protocolsTitle,
                      subtitle: l10n.protocolsSubtitle,
                      count: _protocolCount,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GroupDocumentListScreen(
                            kind: DocumentKind.protocol,
                            workspace: widget.workspace,
                            myRole: _myRole,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CollectionCard(
                      icon: Icons.assignment_ind,
                      title: l10n.preferenceCardsTitle,
                      subtitle: l10n.preferenceCardsSubtitle,
                      count: _preferenceCardCount,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PreferenceCardsScreen(workspace: widget.workspace, myRole: _myRole),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CollectionCard(
                      icon: Icons.precision_manufacturing_outlined,
                      title: l10n.customInstrumentsTitle,
                      subtitle: l10n.customInstrumentsSubtitle,
                      count: _customInstrumentCount,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              CustomInstrumentsScreen(workspaceId: widget.workspace.id, myRole: _myRole),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _CollectionCard(
                      icon: Icons.inventory_2_outlined,
                      title: l10n.traysTitle,
                      subtitle: l10n.traysSubtitle,
                      count: _trayCount,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => TraysScreen(workspace: widget.workspace, myRole: _myRole),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              ),
            ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final int? count;
  final VoidCallback onTap;

  const _CollectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count != null) ...[
              Text('$count', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
