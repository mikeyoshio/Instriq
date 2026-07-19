import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/workspace.dart';
import 'profile_service.dart';

class WorkspaceService {
  WorkspaceService._();
  static final WorkspaceService instance = WorkspaceService._();

  SupabaseClient get _client => Supabase.instance.client;

  List<Workspace> _workspaces = [];

  List<Workspace> get workspaces => List.unmodifiable(_workspaces);

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
}
