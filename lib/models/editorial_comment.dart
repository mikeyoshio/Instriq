/// Fil de comentaris de revisió multi-ronda (EPIC 9, segon tram) --
/// capacitat genuïnament nova: cap dels 3 fluxos privats existents
/// (tècniques/protocols, safates, targetes) té més que un únic camp
/// `comment` sobreescrivible, vegeu docs/EPIC_COMMUNITY_GOVERNANCE.md §2.5.
class EditorialComment {
  final String id;
  final String refType;
  final String refId;
  final String authorId;
  final String body;
  final bool resolved;
  final DateTime createdAt;
  final String? authorDisplayName;

  const EditorialComment({
    required this.id,
    required this.refType,
    required this.refId,
    required this.authorId,
    required this.body,
    required this.resolved,
    required this.createdAt,
    this.authorDisplayName,
  });

  factory EditorialComment.fromRow(Map<String, dynamic> row, {String? authorDisplayName}) {
    return EditorialComment(
      id: row['id'] as String,
      refType: row['ref_type'] as String,
      refId: row['ref_id'] as String,
      authorId: row['author_id'] as String,
      body: row['body'] as String,
      resolved: row['resolved'] as bool? ?? false,
      createdAt: DateTime.parse(row['created_at'] as String),
      authorDisplayName: authorDisplayName,
    );
  }
}
