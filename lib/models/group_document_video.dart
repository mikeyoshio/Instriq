/// Estado de moderación de un vídeo (`group_document_videos.status`). A
/// diferencia de `instrument_incidents` (registro operativo sin gate de
/// visibilidad), un vídeo sí necesita estar aprobado antes de mostrarse a
/// todo el espacio — más cercano a `catalog_community_photos` que a una
/// incidencia (ver schema_v38_epic2_expansion.sql §5).
enum VideoStatus { pending, approved, rejected }

extension VideoStatusLabel on VideoStatus {
  String get label {
    switch (this) {
      case VideoStatus.pending:
        return 'Pendent';
      case VideoStatus.approved:
        return 'Aprovat';
      case VideoStatus.rejected:
        return 'Rebutjat';
    }
  }

  String get dbValue {
    switch (this) {
      case VideoStatus.pending:
        return 'pending';
      case VideoStatus.approved:
        return 'approved';
      case VideoStatus.rejected:
        return 'rejected';
    }
  }

  static VideoStatus fromDb(String value) {
    switch (value) {
      case 'pending':
        return VideoStatus.pending;
      case 'approved':
        return VideoStatus.approved;
      case 'rejected':
        return VideoStatus.rejected;
      default:
        throw ArgumentError('Estado de vídeo desconocido: $value');
    }
  }
}

/// Una fila de `group_document_videos`: un vídeo explicatiu (URL externa,
/// mai pujada de fitxer) enllaçat a una tècnica/protocol. Sense versionat
/// (escriptura directa via RLS, mateix criteri que `instrument_incidents`),
/// però amb estat de moderació perquè és contingut visible per a tothom amb
/// accés a l'espai, no un registre operatiu intern.
class GroupDocumentVideo {
  final String? id;
  final String groupDocumentId;
  final String organizationId;
  final String workspaceId;
  final String title;
  final String url;
  final VideoStatus status;
  final String? submittedBy;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime? createdAt;

  const GroupDocumentVideo({
    this.id,
    required this.groupDocumentId,
    required this.organizationId,
    required this.workspaceId,
    required this.title,
    required this.url,
    this.status = VideoStatus.pending,
    this.submittedBy,
    this.reviewedBy,
    this.reviewedAt,
    this.createdAt,
  });

  Map<String, dynamic> toRow() => {
        'group_document_id': groupDocumentId,
        'organization_id': organizationId,
        'workspace_id': workspaceId,
        'title': title,
        'url': url,
        'status': status.dbValue,
        'submitted_by': submittedBy,
        'reviewed_by': reviewedBy,
        'reviewed_at': reviewedAt?.toIso8601String(),
      };

  GroupDocumentVideo copyWith({
    VideoStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
  }) {
    return GroupDocumentVideo(
      id: id,
      groupDocumentId: groupDocumentId,
      organizationId: organizationId,
      workspaceId: workspaceId,
      title: title,
      url: url,
      status: status ?? this.status,
      submittedBy: submittedBy,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt,
    );
  }

  factory GroupDocumentVideo.fromRow(Map<String, dynamic> row) {
    return GroupDocumentVideo(
      id: row['id'] as String?,
      groupDocumentId: row['group_document_id'] as String,
      organizationId: row['organization_id'] as String,
      workspaceId: row['workspace_id'] as String,
      title: row['title'] as String? ?? '',
      url: row['url'] as String? ?? '',
      status: VideoStatusLabel.fromDb(row['status'] as String),
      submittedBy: row['submitted_by'] as String?,
      reviewedBy: row['reviewed_by'] as String?,
      reviewedAt: row['reviewed_at'] != null ? DateTime.tryParse(row['reviewed_at'] as String) : null,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
    );
  }
}
