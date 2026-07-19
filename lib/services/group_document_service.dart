import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_document.dart';
import 'profile_service.dart';

class GroupDocumentService {
  GroupDocumentService._();
  static final GroupDocumentService instance = GroupDocumentService._();

  SupabaseClient get _client => Supabase.instance.client;

  List<GroupDocument> _documents = [];

  List<GroupDocument> documentsOfKind(DocumentKind kind) =>
      _documents.where((d) => d.kind == kind).toList();

  Future<void> fetchDocuments(DocumentKind kind) async {
    final rows = await _client
        .from('group_documents')
        .select()
        .eq('kind', kind.dbValue)
        .order('title');
    final fetched = (rows as List<dynamic>)
        .map((r) => GroupDocument.fromRow(r as Map<String, dynamic>))
        .toList();
    _documents = [..._documents.where((d) => d.kind != kind), ...fetched];
  }

  Future<GroupDocument> upsertDocument(GroupDocument document) async {
    final hospitalId = ProfileService.instance.hospitalId;
    if (hospitalId == null) {
      throw StateError('Tu usuario no pertenece a ningún grupo todavía.');
    }
    final row = document.toRow(hospitalId: hospitalId);
    Map<String, dynamic> saved;
    if (document.id.isEmpty) {
      saved = await _client.from('group_documents').insert(row).select().single();
    } else {
      saved = await _client
          .from('group_documents')
          .update(row)
          .eq('id', document.id)
          .select()
          .single();
    }
    final result = GroupDocument.fromRow(saved);
    _documents = [..._documents.where((d) => d.id != result.id), result];
    return result;
  }

  Future<void> deleteDocument(String id) async {
    await _client.from('group_documents').delete().eq('id', id);
    _documents.removeWhere((d) => d.id == id);
  }
}
