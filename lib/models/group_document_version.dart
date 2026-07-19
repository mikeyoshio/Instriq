enum GroupDocumentVersionStatus { draft, inReview, published, archived }

extension GroupDocumentVersionStatusLabel on GroupDocumentVersionStatus {
  String get label {
    switch (this) {
      case GroupDocumentVersionStatus.draft:
        return 'Borrador';
      case GroupDocumentVersionStatus.inReview:
        return 'En revisión';
      case GroupDocumentVersionStatus.published:
        return 'Publicada';
      case GroupDocumentVersionStatus.archived:
        return 'Archivada';
    }
  }

  String get dbValue {
    switch (this) {
      case GroupDocumentVersionStatus.draft:
        return 'draft';
      case GroupDocumentVersionStatus.inReview:
        return 'in_review';
      case GroupDocumentVersionStatus.published:
        return 'published';
      case GroupDocumentVersionStatus.archived:
        return 'archived';
    }
  }

  static GroupDocumentVersionStatus fromDb(String value) {
    switch (value) {
      case 'draft':
        return GroupDocumentVersionStatus.draft;
      case 'in_review':
        return GroupDocumentVersionStatus.inReview;
      case 'published':
        return GroupDocumentVersionStatus.published;
      case 'archived':
        return GroupDocumentVersionStatus.archived;
      default:
        throw ArgumentError('Estado de versión desconocido: $value');
    }
  }
}

/// Una versión concreta del contenido de un [GroupDocument]. El contenido
/// (título, pasos, instrumental relacionado...) vive aquí, no en la cabecera:
/// cada edición crea una versión nueva en vez de sobrescribir la anterior.
class GroupDocumentVersion {
  final String id;
  final String documentId;
  final int versionNumber;
  final GroupDocumentVersionStatus status;
  final String title;
  final String? specialty;
  final String? content;
  final List<String> steps;
  final List<String> relatedInstrumentIds;
  final String? authorId;
  final String? comment;
  final String? basedOnVersionId;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? createdAt;

  const GroupDocumentVersion({
    required this.id,
    required this.documentId,
    required this.versionNumber,
    required this.status,
    required this.title,
    this.specialty,
    this.content,
    this.steps = const [],
    this.relatedInstrumentIds = const [],
    this.authorId,
    this.comment,
    this.basedOnVersionId,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
  });

  Map<String, dynamic> toRow() => {
        'title': title,
        'specialty': specialty,
        'content': content,
        'steps': steps,
        'related_instrument_ids': relatedInstrumentIds,
        'comment': comment,
      };

  GroupDocumentVersion copyWith({
    String? title,
    String? specialty,
    String? content,
    List<String>? steps,
    List<String>? relatedInstrumentIds,
    String? comment,
  }) {
    return GroupDocumentVersion(
      id: id,
      documentId: documentId,
      versionNumber: versionNumber,
      status: status,
      title: title ?? this.title,
      specialty: specialty ?? this.specialty,
      content: content ?? this.content,
      steps: steps ?? this.steps,
      relatedInstrumentIds: relatedInstrumentIds ?? this.relatedInstrumentIds,
      authorId: authorId,
      comment: comment ?? this.comment,
      basedOnVersionId: basedOnVersionId,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      createdAt: createdAt,
    );
  }

  factory GroupDocumentVersion.fromRow(Map<String, dynamic> row) {
    return GroupDocumentVersion(
      id: row['id'] as String,
      documentId: row['document_id'] as String,
      versionNumber: row['version_number'] as int,
      status: GroupDocumentVersionStatusLabel.fromDb(row['status'] as String),
      title: row['title'] as String? ?? '',
      specialty: row['specialty'] as String?,
      content: row['content'] as String?,
      steps: (row['steps'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      relatedInstrumentIds:
          (row['related_instrument_ids'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      authorId: row['author_id'] as String?,
      comment: row['comment'] as String?,
      basedOnVersionId: row['based_on_version_id'] as String?,
      approvedBy: row['approved_by'] as String?,
      approvedAt: row['approved_at'] != null ? DateTime.tryParse(row['approved_at'] as String) : null,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
    );
  }
}
