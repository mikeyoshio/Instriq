import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/editorial_comment.dart';

class EditorialCommentService {
  EditorialCommentService._();
  static final EditorialCommentService instance = EditorialCommentService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<EditorialComment>> fetchFor(String refType, String refId) async {
    final rows = await _client
        .from('editorial_comments')
        .select()
        .eq('ref_type', refType)
        .eq('ref_id', refId)
        .order('created_at');
    final comments = (rows as List).map((r) => EditorialComment.fromRow((r as Map).cast<String, dynamic>())).toList();
    if (comments.isEmpty) return comments;

    final authorIds = comments.map((c) => c.authorId).toSet().toList();
    final profileRows = await _client.from('profiles').select('id, display_name').inFilter('id', authorIds);
    final namesByAuthor = {
      for (final r in profileRows as List) (r as Map<String, dynamic>)['id'] as String: r['display_name'] as String?,
    };
    return [
      for (final c in comments)
        EditorialComment(
          id: c.id,
          refType: c.refType,
          refId: c.refId,
          authorId: c.authorId,
          body: c.body,
          resolved: c.resolved,
          createdAt: c.createdAt,
          authorDisplayName: namesByAuthor[c.authorId],
        ),
    ];
  }

  Future<void> addComment(String refType, String refId, String body) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Cal haver iniciat sessio per comentar');
    await _client.from('editorial_comments').insert({
      'ref_type': refType,
      'ref_id': refId,
      'author_id': userId,
      'body': body,
    });
  }

  Future<void> setResolved(String commentId, bool resolved) async {
    await _client.from('editorial_comments').update({'resolved': resolved}).eq('id', commentId);
  }
}
