import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/workspace.dart';
import '../models/workspace_member.dart';
import '../models/workspace_role.dart';
import 'profile_service.dart';

class WorkspaceService {
  WorkspaceService._();
  static final WorkspaceService instance = WorkspaceService._();

  SupabaseClient get _client => Supabase.instance.client;

  List<Workspace> _workspaces = [];

  List<Workspace> get workspaces => List.unmodifiable(_workspaces);

  /// Limpia el caché en memoria. Debe llamarse al cambiar de grupo o cerrar
  /// sesión: si no, un espacio de un grupo anterior puede quedar cacheado y
  /// usarse por error con el hospital_id del grupo nuevo.
  void clear() {
    _workspaces = [];
  }

  Future<void> fetchWorkspaces() async {
    final rows = await _client.from('workspaces').select().order('name');
    _workspaces =
        (rows as List<dynamic>).map((r) => Workspace.fromRow(r as Map<String, dynamic>)).toList();
  }

  Future<Workspace> createWorkspace(String name, {String? description}) async {
    final hospitalId = ProfileService.instance.hospitalId;
    if (hospitalId == null) {
      throw StateError('Tu usuario no pertenece a ningún grupo todavía.');
    }
    final row = await _client
        .from('workspaces')
        .insert({'hospital_id': hospitalId, 'name': name, 'description': description})
        .select()
        .single();
    final workspace = Workspace.fromRow(row);
    _workspaces = [..._workspaces, workspace];
    return workspace;
  }

  Future<void> renameWorkspace(String id, String name) async {
    await _client.from('workspaces').update({'name': name}).eq('id', id);
    final index = _workspaces.indexWhere((w) => w.id == id);
    if (index != -1) {
      final current = _workspaces[index];
      _workspaces[index] = Workspace(
        id: current.id,
        hospitalId: current.hospitalId,
        name: name,
        description: current.description,
        createdBy: current.createdBy,
        createdAt: current.createdAt,
      );
    }
  }

  Future<void> deleteWorkspace(String id) async {
    await _client.from('workspaces').delete().eq('id', id);
    _workspaces.removeWhere((w) => w.id == id);
  }

  /// Rol efectivo del usuario actual en un espacio (null si no tiene ninguno).
  Future<WorkspaceRole?> fetchMyRole(String workspaceId) async {
    final result = await _client.rpc('my_workspace_role', params: {'p_workspace_id': workspaceId});
    return WorkspaceRoleLabel.fromDb(result as String?);
  }

  /// Miembros del hospital y su rol (si tiene alguno) en el espacio indicado.
  /// Solo admin/owner puede llamarlo (gateado por RLS de workspace_members).
  Future<List<WorkspaceMember>> fetchMembers(String workspaceId) async {
    final profileRows = await _client.from('profiles').select('id, display_name, is_admin');
    final roleRows =
        await _client.from('workspace_members').select('user_id, role').eq('workspace_id', workspaceId);
    final rolesByUser = <String, WorkspaceRole?>{
      for (final r in (roleRows as List<dynamic>))
        (r as Map<String, dynamic>)['user_id'] as String: WorkspaceRoleLabel.fromDb(r['role'] as String?),
    };
    return (profileRows as List<dynamic>).map((r) {
      final row = r as Map<String, dynamic>;
      final userId = row['id'] as String;
      return WorkspaceMember(
        userId: userId,
        displayName: row['display_name'] as String?,
        isHospitalAdmin: row['is_admin'] as bool? ?? false,
        role: rolesByUser[userId],
      );
    }).toList();
  }

  /// Asigna (o cambia) el rol de un usuario en un espacio.
  Future<void> setMemberRole(String workspaceId, String userId, WorkspaceRole role) async {
    if (role == WorkspaceRole.administrator) {
      throw ArgumentError('El rol de administrador no se asigna por espacio.');
    }
    await _client.from('workspace_members').upsert({
      'workspace_id': workspaceId,
      'user_id': userId,
      'role': role.dbValue,
    });
  }

  /// Quita el acceso de un usuario a un espacio (no toca su rol de admin del hospital).
  Future<void> removeMemberRole(String workspaceId, String userId) async {
    await _client.from('workspace_members').delete().eq('workspace_id', workspaceId).eq('user_id', userId);
  }
}
