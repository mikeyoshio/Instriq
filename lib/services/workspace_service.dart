import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/workspace.dart';
import '../models/workspace_member.dart';
import '../models/workspace_role.dart';
import 'connectivity_service.dart';
import 'profile_service.dart';

class WorkspaceService {
  WorkspaceService._();
  static final WorkspaceService instance = WorkspaceService._();

  SupabaseClient get _client => Supabase.instance.client;

  List<Workspace> _workspaces = [];

  List<Workspace> get workspaces => List.unmodifiable(_workspaces);

  /// Último rol conocido por workspace, para poder seguir navegando a las
  /// colecciones de un espacio (bandejas, técnicas...) sin conexión -- ver
  /// nota en [fetchMyRole].
  final Map<String, WorkspaceRole?> _roleCache = {};

  /// Limpia el caché en memoria. Debe llamarse al cambiar de grupo o cerrar
  /// sesión: si no, un espacio de un grupo anterior puede quedar cacheado y
  /// usarse por error con el organization_id del grupo nuevo.
  void clear() {
    _workspaces = [];
    _roleCache.clear();
  }

  Future<void> fetchWorkspaces() async {
    final rows = await _client.from('workspaces').select().order('name');
    _workspaces =
        (rows as List<dynamic>).map((r) => Workspace.fromRow(r as Map<String, dynamic>)).toList();
  }

  Future<Workspace> createWorkspace(String name, {String? description}) async {
    final organizationId = ProfileService.instance.organizationId;
    if (organizationId == null) {
      throw StateError('Tu usuario no pertenece a ningún grupo todavía.');
    }
    final row = await _client
        .from('workspaces')
        .insert({'organization_id': organizationId, 'name': name, 'description': description})
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
        organizationId: current.organizationId,
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
  ///
  /// Sin conexión, cae al último rol conocido para ese espacio en vez de
  /// lanzar la excepción de red tal cual: esta llamada se hace antes de
  /// navegar a bandejas/técnicas/etc. desde Inicio, y las propias pantallas
  /// de destino ya saben mostrar contenido cacheado sin conexión (EPIC 7) --
  /// dejar que esto falle sin capturar convertía ese caso en un botón que no
  /// hace nada (excepción no gestionada, sin ningún aviso en pantalla).
  Future<WorkspaceRole?> fetchMyRole(String workspaceId) async {
    try {
      final result = await _client.rpc('my_workspace_role', params: {'p_workspace_id': workspaceId});
      final role = WorkspaceRoleLabel.fromDb(result as String?);
      _roleCache[workspaceId] = role;
      return role;
    } catch (e) {
      if (!ConnectivityService.isNetworkError(e)) rethrow;
      return _roleCache[workspaceId];
    }
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

  /// Asigna (o cambia) el rol de un usuario en un espacio. Va vía función
  /// `security definer` (ver supabase/schema_v10_audit.sql) para que el
  /// cambio quede registrado en el log de auditoría.
  Future<void> setMemberRole(String workspaceId, String userId, WorkspaceRole role) async {
    if (role == WorkspaceRole.administrator) {
      throw ArgumentError('El rol de administrador no se asigna por espacio.');
    }
    await _client.rpc('set_workspace_member_role', params: {
      'p_workspace_id': workspaceId,
      'p_user_id': userId,
      'p_role': role.dbValue,
    });
  }

  /// Quita el acceso de un usuario a un espacio (no toca su rol de admin del
  /// hospital). Va vía función `security definer` para que quede registrado
  /// en el log de auditoría.
  Future<void> removeMemberRole(String workspaceId, String userId) async {
    await _client.rpc('remove_workspace_member_role', params: {
      'p_workspace_id': workspaceId,
      'p_user_id': userId,
    });
  }
}
