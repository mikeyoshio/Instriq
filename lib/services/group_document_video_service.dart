import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_document_video.dart';
import 'auth_service.dart';
import 'profile_service.dart';

/// CRUD de vídeos explicatius d'una tècnica/protocol. Sense RPC ni
/// versionat -- escriptura directa via RLS, mateix criteri que
/// `InstrumentIncidentService` -- però a diferència d'incidències, un vídeo
/// neix `pending` i necessita `approver`/`administrator` per fer-se visible
/// a la resta de l'espai (ver schema_v38_epic2_expansion.sql §5). Aquest
/// servei deixa que l'excepció de Supabase arribi tal qual a qui truca,
/// sense comprovació de rol duplicada aquí.
class GroupDocumentVideoService {
  GroupDocumentVideoService._();
  static final GroupDocumentVideoService instance = GroupDocumentVideoService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<GroupDocumentVideo>> fetchForDocument(String groupDocumentId) async {
    final rows = await _client
        .from('group_document_videos')
        .select()
        .eq('group_document_id', groupDocumentId)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>).map((r) => GroupDocumentVideo.fromRow(r as Map<String, dynamic>)).toList();
  }

  Future<GroupDocumentVideo> submit({
    required String groupDocumentId,
    required String workspaceId,
    required String title,
    required String url,
  }) async {
    final userId = AuthService.instance.currentUser?.id;
    final organizationId = ProfileService.instance.organizationId;
    if (userId == null || organizationId == null) {
      throw StateError('Tu usuario no pertenece a ningún grupo todavía.');
    }
    final row = await _client
        .from('group_document_videos')
        .insert({
          'group_document_id': groupDocumentId,
          'organization_id': organizationId,
          'workspace_id': workspaceId,
          'title': title,
          'url': url,
          'status': VideoStatus.pending.dbValue,
          'submitted_by': userId,
        })
        .select()
        .single();
    return GroupDocumentVideo.fromRow(row);
  }

  Future<GroupDocumentVideo> approve(String videoId) async {
    final userId = AuthService.instance.currentUser?.id;
    final row = await _client
        .from('group_document_videos')
        .update({
          'status': VideoStatus.approved.dbValue,
          'reviewed_by': userId,
          'reviewed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', videoId)
        .select()
        .single();
    return GroupDocumentVideo.fromRow(row);
  }

  Future<GroupDocumentVideo> reject(String videoId) async {
    final userId = AuthService.instance.currentUser?.id;
    final row = await _client
        .from('group_document_videos')
        .update({
          'status': VideoStatus.rejected.dbValue,
          'reviewed_by': userId,
          'reviewed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', videoId)
        .select()
        .single();
    return GroupDocumentVideo.fromRow(row);
  }
}
