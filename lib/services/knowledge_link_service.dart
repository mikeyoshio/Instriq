import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/knowledge_link.dart';

/// Lectura del índice de relaciones del grafo de conocimiento (EPIC 1, ver
/// `docs/BACKLOG.md` y `supabase/schema_v24_knowledge_links.sql`). Solo
/// lectura: `knowledge_links` se escribe exclusivamente desde
/// `approve_group_document_version`/`approve_tray_version`, nunca desde el
/// cliente — mismo modelo de confianza que `audit_log`.
class KnowledgeLinkService {
  KnowledgeLinkService._();
  static final KnowledgeLinkService instance = KnowledgeLinkService._();

  SupabaseClient get _client => Supabase.instance.client;

  /// Qué técnicas/protocolos/safates referencian a [toType]/[toId] — p. ej.
  /// "en qué técnicas se usa este instrumento" o "en qué protocolos aparece
  /// esta safata".
  Future<List<KnowledgeLink>> fetchRelatedTo(String toType, String toId) async {
    final rows = await _client.from('knowledge_links').select().eq('to_type', toType).eq('to_id', toId);
    return (rows as List<dynamic>).map((r) => KnowledgeLink.fromRow(r as Map<String, dynamic>)).toList();
  }
}
