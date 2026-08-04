import 'group_document.dart' show DocumentKind, DocumentKindLabel;
import 'group_document_version.dart' show ProtocolStep;

enum PublicContentStatus { draft, inReview, published, archived }

PublicContentStatus publicContentStatusFromRow(String value) {
  switch (value) {
    case 'in_review':
      return PublicContentStatus.inReview;
    case 'published':
      return PublicContentStatus.published;
    case 'archived':
      return PublicContentStatus.archived;
    case 'draft':
    default:
      return PublicContentStatus.draft;
  }
}

class PublicDocument {
  final String id;
  final DocumentKind kind;
  final String? createdBy;
  final DateTime createdAt;
  final String? publishedVersionId;
  final PublicDocumentVersion? publishedVersion;

  const PublicDocument({
    required this.id,
    required this.kind,
    this.createdBy,
    required this.createdAt,
    this.publishedVersionId,
    this.publishedVersion,
  });

  factory PublicDocument.fromRow(Map<String, dynamic> row) {
    final versionRow = row['published_version'] as Map<String, dynamic>?;
    return PublicDocument(
      id: row['id'] as String,
      kind: DocumentKindLabel.fromDb(row['kind'] as String),
      createdBy: row['created_by'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      publishedVersionId: row['published_version_id'] as String?,
      publishedVersion: versionRow == null ? null : PublicDocumentVersion.fromRow(versionRow),
    );
  }
}

class PublicDocumentVersion {
  final String id;
  final String documentId;
  final int versionNumber;
  final PublicContentStatus status;
  final String? title;
  final String? specialtyId;
  final String? content;
  final List<ProtocolStep> steps;
  final List<String> relatedInstrumentIds;
  final List<String> relatedTrayIds;
  final String? authorId;
  final String? comment;
  final String? basedOnVersionId;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;

  const PublicDocumentVersion({
    required this.id,
    required this.documentId,
    required this.versionNumber,
    required this.status,
    this.title,
    this.specialtyId,
    this.content,
    this.steps = const [],
    this.relatedInstrumentIds = const [],
    this.relatedTrayIds = const [],
    this.authorId,
    this.comment,
    this.basedOnVersionId,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
  });

  factory PublicDocumentVersion.fromRow(Map<String, dynamic> row) {
    return PublicDocumentVersion(
      id: row['id'] as String,
      documentId: row['document_id'] as String,
      versionNumber: row['version_number'] as int,
      status: publicContentStatusFromRow(row['status'] as String),
      title: row['title'] as String?,
      specialtyId: row['specialty_id'] as String?,
      content: row['content'] as String?,
      steps: (row['steps'] as List<dynamic>? ?? const []).map(ProtocolStep.fromDynamic).toList(),
      relatedInstrumentIds: (row['related_instrument_ids'] as List<dynamic>? ?? const []).cast<String>(),
      relatedTrayIds: (row['related_tray_ids'] as List<dynamic>? ?? const []).cast<String>(),
      authorId: row['author_id'] as String?,
      comment: row['comment'] as String?,
      basedOnVersionId: row['based_on_version_id'] as String?,
      approvedBy: row['approved_by'] as String?,
      approvedAt: row['approved_at'] == null ? null : DateTime.parse(row['approved_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Map<String, dynamic> toRow() => {
        'title': title,
        'specialty_id': specialtyId,
        'content': content,
        'steps': steps.map((s) => s.toJson()).toList(),
        'related_instrument_ids': relatedInstrumentIds,
        'related_tray_ids': relatedTrayIds,
      };
}
