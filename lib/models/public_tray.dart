import 'public_document.dart' show PublicContentStatus, publicContentStatusFromRow;
import 'tray.dart' show TrayItem;

class PublicTray {
  final String id;
  final String? createdBy;
  final DateTime createdAt;
  final String? publishedVersionId;
  final PublicTrayVersion? publishedVersion;

  const PublicTray({
    required this.id,
    this.createdBy,
    required this.createdAt,
    this.publishedVersionId,
    this.publishedVersion,
  });

  factory PublicTray.fromRow(Map<String, dynamic> row) {
    final versionRow = row['published_version'] as Map<String, dynamic>?;
    return PublicTray(
      id: row['id'] as String,
      createdBy: row['created_by'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      publishedVersionId: row['published_version_id'] as String?,
      publishedVersion: versionRow == null ? null : PublicTrayVersion.fromRow(versionRow),
    );
  }
}

class PublicTrayVersion {
  final String id;
  final String trayId;
  final int versionNumber;
  final PublicContentStatus status;
  final String? name;
  final String? specialtyId;
  final String? description;
  final List<TrayItem> items;
  final String? observations;
  final String? authorId;
  final String? comment;
  final String? basedOnVersionId;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;

  const PublicTrayVersion({
    required this.id,
    required this.trayId,
    required this.versionNumber,
    required this.status,
    this.name,
    this.specialtyId,
    this.description,
    this.items = const [],
    this.observations,
    this.authorId,
    this.comment,
    this.basedOnVersionId,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
  });

  factory PublicTrayVersion.fromRow(Map<String, dynamic> row) {
    return PublicTrayVersion(
      id: row['id'] as String,
      trayId: row['tray_id'] as String,
      versionNumber: row['version_number'] as int,
      status: publicContentStatusFromRow(row['status'] as String),
      name: row['name'] as String?,
      specialtyId: row['specialty_id'] as String?,
      description: row['description'] as String?,
      items: (row['items'] as List<dynamic>? ?? const [])
          .map((e) => TrayItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      observations: row['observations'] as String?,
      authorId: row['author_id'] as String?,
      comment: row['comment'] as String?,
      basedOnVersionId: row['based_on_version_id'] as String?,
      approvedBy: row['approved_by'] as String?,
      approvedAt: row['approved_at'] == null ? null : DateTime.parse(row['approved_at'] as String),
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  Map<String, dynamic> toRow() => {
        'name': name,
        'specialty_id': specialtyId,
        'description': description,
        'items': items.map((i) => i.toJson()).toList(),
        'observations': observations,
      };
}
