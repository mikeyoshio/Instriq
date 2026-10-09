import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/group_document.dart';
import '../models/workspace.dart';
import '../models/workspace_role.dart';
import '../screens/custom_instrument_form_screen.dart';
import '../screens/group_document_form_screen.dart';
import '../screens/preference_card_form_screen.dart';
import '../screens/tray_form_screen.dart';
import '../services/profile_service.dart';
import '../services/workspace_service.dart';

enum _CreateContentType { technique, protocol, tray, preferenceCard, customInstrument }

/// Punto de entrada único para crear contenido (técnica/protocolo/bandeja/
/// ficha de preferencia/instrumental personalizado), llamado tanto desde el
/// FAB de `HomeScreen` como desde la cabecera de `HomeDashboardPanel`. Antes
/// cada tipo solo era alcanzable entrando a un espacio concreto vía
/// Biblioteca -> `WorkspaceDetailScreen` -> su propia lista -> su propio FAB
/// (y solo técnicas/bandejas tenían además un atajo en Inicio). No reutiliza
/// `WorkspaceListScreen` a propósito: esa pantalla no filtra por rol, tiene
/// sus propias acciones admin (renombrar/crear espacio) y su colapso a 1
/// espacio siempre asume `WorkspaceDetailScreen` como destino -- aquí el
/// destino es un formulario concreto, no la gestión del espacio en sí.
Future<void> showCreateContentSheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final type = await showModalBottomSheet<_CreateContentType>(
    context: context,
    builder: (sheetContext) => _CreateTypePicker(l10n: l10n),
  );
  if (type == null || !context.mounted) return;

  final workspaceId = await _resolveWorkspace(context);
  if (workspaceId == null || !context.mounted) return;

  final Widget form = switch (type) {
    _CreateContentType.technique =>
      GroupDocumentFormScreen(kind: DocumentKind.technique, workspaceId: workspaceId),
    _CreateContentType.protocol =>
      GroupDocumentFormScreen(kind: DocumentKind.protocol, workspaceId: workspaceId),
    _CreateContentType.tray => TrayFormScreen(workspaceId: workspaceId),
    _CreateContentType.preferenceCard => PreferenceCardFormScreen(workspaceId: workspaceId),
    _CreateContentType.customInstrument => CustomInstrumentFormScreen(workspaceId: workspaceId),
  };
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => form));
}

/// Resuelve en qué espacio crear el contenido nuevo: si es admin de
/// organización, cualquier espacio (administrator se deriva de
/// `profiles.is_admin`, aplica a todos sin necesidad de fila propia); si no,
/// solo aquellos donde `canEdit` (editor/approver/administrator de espacio).
/// Un único candidato salta directo sin mostrar nada; varios, un selector
/// mínimo por nombre.
Future<String?> _resolveWorkspace(BuildContext context) async {
  await WorkspaceService.instance.fetchWorkspaces();
  if (!context.mounted) return null;
  final all = WorkspaceService.instance.workspaces;

  List<Workspace> candidates;
  if (ProfileService.instance.isAdmin) {
    candidates = all;
  } else {
    final roles = await Future.wait(all.map((w) => WorkspaceService.instance.fetchMyRole(w.id)));
    candidates = [
      for (var i = 0; i < all.length; i++)
        if (roles[i]?.canEdit ?? false) all[i],
    ];
  }
  if (!context.mounted) return null;

  if (candidates.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.createContentNoWorkspace)),
    );
    return null;
  }
  if (candidates.length == 1) return candidates.first.id;

  return showModalBottomSheet<String>(
    context: context,
    builder: (sheetContext) => _WorkspacePicker(workspaces: candidates),
  );
}

class _CreateTypePicker extends StatelessWidget {
  final AppLocalizations l10n;

  const _CreateTypePicker({required this.l10n});

  @override
  Widget build(BuildContext context) {
    Widget tile(IconData icon, String label, _CreateContentType type) {
      return ListTile(
        leading: Icon(icon),
        title: Text(label),
        onTap: () => Navigator.of(context).pop(type),
      );
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.createContentTitle, style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          tile(Icons.menu_book_outlined, l10n.techniquesTitle, _CreateContentType.technique),
          tile(Icons.fact_check_outlined, l10n.protocolsTitle, _CreateContentType.protocol),
          tile(Icons.inventory_2_outlined, l10n.traysTitle, _CreateContentType.tray),
          tile(Icons.assignment_ind, l10n.preferenceCardsTitle, _CreateContentType.preferenceCard),
          tile(
            Icons.precision_manufacturing_outlined,
            l10n.customInstrumentsTitle,
            _CreateContentType.customInstrument,
          ),
        ],
      ),
    );
  }
}

class _WorkspacePicker extends StatelessWidget {
  final List<Workspace> workspaces;

  const _WorkspacePicker({required this.workspaces});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.createContentChooseWorkspace, style: Theme.of(context).textTheme.titleMedium),
            ),
          ),
          for (final w in workspaces)
            ListTile(
              leading: const Icon(Icons.workspaces_outlined),
              title: Text(w.name),
              onTap: () => Navigator.of(context).pop(w.id),
            ),
        ],
      ),
    );
  }
}
