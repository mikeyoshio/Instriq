import 'group_document_version.dart';

enum DocumentKind { technique, protocol }

extension DocumentKindLabel on DocumentKind {
  String get label {
    switch (this) {
      case DocumentKind.technique:
        return 'Técnica quirúrgica';
      case DocumentKind.protocol:
        return 'Protocolo';
    }
  }

  String get dbValue => name;

  static DocumentKind fromDb(String value) {
    return DocumentKind.values.firstWhere((k) => k.dbValue == value);
  }
}

/// Cabecera de un documento de conocimiento propio de un grupo: técnica
/// quirúrgica o protocolo. El contenido vive en [GroupDocumentVersion] — esta
/// clase solo identifica el documento y, si existe, su versión publicada.
class GroupDocument {
  final String id;
  final DocumentKind kind;
  final String? createdBy;
  final DateTime? createdAt;
  final String? publishedVersionId;
  final GroupDocumentVersion? publishedVersion;

  const GroupDocument({
    required this.id,
    required this.kind,
    this.createdBy,
    this.createdAt,
    this.publishedVersionId,
    this.publishedVersion,
  });

  Map<String, dynamic> toRow({required String hospitalId}) => {
        'hospital_id': hospitalId,
        'kind': kind.dbValue,
      };

  GroupDocument copyWith({
    String? publishedVersionId,
    GroupDocumentVersion? publishedVersion,
  }) {
    return GroupDocument(
      id: id,
      kind: kind,
      createdBy: createdBy,
      createdAt: createdAt,
      publishedVersionId: publishedVersionId ?? this.publishedVersionId,
      publishedVersion: publishedVersion ?? this.publishedVersion,
    );
  }

  factory GroupDocument.fromRow(Map<String, dynamic> row) {
    final versionRow = row['published_version'] as Map<String, dynamic>?;
    return GroupDocument(
      id: row['id'] as String,
      kind: DocumentKindLabel.fromDb(row['kind'] as String),
      createdBy: row['created_by'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      publishedVersionId: row['published_version_id'] as String?,
      publishedVersion: versionRow != null ? GroupDocumentVersion.fromRow(versionRow) : null,
    );
  }
}
