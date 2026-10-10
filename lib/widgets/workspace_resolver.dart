import 'package:flutter/material.dart';

import '../models/workspace.dart';
import '../models/workspace_role.dart';
import '../services/profile_service.dart';
import '../services/workspace_service.dart';

/// Un espacio ya resuelto junto con el rol propio en él -- `role` solo es
/// `null` cuando quien resuelve es admin de organización sin fila propia en
/// `workspace_members` (administrator se deriva de `profiles.is_admin`, no
/// de una fila por espacio).
typedef ResolvedWorkspace = ({Workspace workspace, WorkspaceRole? role});

/// Resuelve en qué espacio actuar: si es admin de organización, cualquier
/// espacio; si no, solo aquellos donde [isEligible] del rol propio da true.
/// Un único candidato salta directo sin mostrar nada; varios, un selector
/// mínimo por nombre; ninguno, un SnackBar con [noWorkspaceMessage]. Mismo
/// código tanto para crear contenido (elegible = `canEdit`) como para
/// navegar directo a una colección existente desde la Biblioteca (elegible =
/// cualquier rol) -- antes cada uno tenía su propia copia de esta lógica.
Future<ResolvedWorkspace?> resolveWorkspace(
  BuildContext context, {
  required bool Function(WorkspaceRole role) isEligible,
  required String noWorkspaceMessage,
  required String chooseWorkspaceTitle,
}) async {
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
        if (roles[i] != null && isEligible(roles[i]!)) all[i],
    ];
  }
  if (!context.mounted) return null;

  if (candidates.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(noWorkspaceMessage)));
    return null;
  }

  Workspace chosen;
  if (candidates.length == 1) {
    chosen = candidates.first;
  } else {
    final pickedId = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => _WorkspacePicker(title: chooseWorkspaceTitle, workspaces: candidates),
    );
    if (pickedId == null || !context.mounted) return null;
    chosen = candidates.firstWhere((w) => w.id == pickedId);
  }

  final role = await WorkspaceService.instance.fetchMyRole(chosen.id);
  if (!context.mounted) return null;
  return (workspace: chosen, role: role);
}

class _WorkspacePicker extends StatelessWidget {
  final String title;
  final List<Workspace> workspaces;

  const _WorkspacePicker({required this.title, required this.workspaces});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
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
