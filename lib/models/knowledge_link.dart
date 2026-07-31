/// Una arista del grafo de conocimiento (EPIC 1): relaciona una técnica o
/// protocolo ([fromType] `group_document`) o una safata ([fromType] `tray`)
/// con un instrumento (`catalog`/`custom`) o una safata (`tray`) — ver
/// `supabase/schema_v24_knowledge_links.sql`.
///
/// Es un índice derivado: se sincroniza automáticamente al publicar una
/// versión, no se crea ni edita a mano desde el cliente.
class KnowledgeLink {
  final String fromType;
  final String fromId;
  final String toType;
  final String toId;

  const KnowledgeLink({
    required this.fromType,
    required this.fromId,
    required this.toType,
    required this.toId,
  });

  factory KnowledgeLink.fromRow(Map<String, dynamic> row) => KnowledgeLink(
        fromType: row['from_type'] as String,
        fromId: row['from_id'] as String,
        toType: row['to_type'] as String,
        toId: row['to_id'] as String,
      );
}
