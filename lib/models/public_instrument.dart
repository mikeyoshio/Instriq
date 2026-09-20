import 'instrument.dart' show InstrumentCategory;
import 'public_document.dart' show PublicContentStatus, publicContentStatusFromRow;

InstrumentCategory? _categoryFromRow(String? value) {
  if (value == null) return null;
  for (final c in InstrumentCategory.values) {
    if (c.name == value) return c;
  }
  return null;
}

class PublicInstrument {
  final String id;
  final String? createdBy;
  final DateTime createdAt;
  final String? publishedVersionId;
  final PublicInstrumentVersion? publishedVersion;

  const PublicInstrument({
    required this.id,
    this.createdBy,
    required this.createdAt,
    this.publishedVersionId,
    this.publishedVersion,
  });

  factory PublicInstrument.fromRow(Map<String, dynamic> row) {
    final versionRow = row['published_version'] as Map<String, dynamic>?;
    return PublicInstrument(
      id: row['id'] as String,
      createdBy: row['created_by'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      publishedVersionId: row['published_version_id'] as String?,
      publishedVersion: versionRow == null ? null : PublicInstrumentVersion.fromRow(versionRow),
    );
  }
}

/// Camps de contingut alineats amb `CustomInstrumentVersion` (mateix
/// concepte, sense `variants` -- un instrument de la Biblioteca Pública és
/// una proposta única, no un catàleg de mides/colors d'un mateix equip).
class PublicInstrumentVersion {
  final String id;
  final String instrumentId;
  final int versionNumber;
  final PublicContentStatus status;
  final String? name;
  final InstrumentCategory? category;
  final String? specialtyId;
  final String? description;
  final String? useText;
  final String? tip;
  final String? photoPath;
  final String? authorId;
  final String? comment;
  final String? basedOnVersionId;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;

  const PublicInstrumentVersion({
    required this.id,
    required this.instrumentId,
    required this.versionNumber,
    required this.status,
    this.name,
    this.category,
    this.specialtyId,
    this.description,
    this.useText,
    this.tip,
    this.photoPath,
    this.authorId,
    this.comment,
    this.basedOnVersionId,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
  });

  factory PublicInstrumentVersion.fromRow(Map<String, dynamic> row) {
    return PublicInstrumentVersion(
      id: row['id'] as String,
      instrumentId: row['instrument_id'] as String,
      versionNumber: row['version_number'] as int,
      status: publicContentStatusFromRow(row['status'] as String),
      name: row['name'] as String?,
      category: _categoryFromRow(row['category'] as String?),
      specialtyId: row['specialty_id'] as String?,
      description: row['description'] as String?,
      useText: row['use_text'] as String?,
      tip: row['tip'] as String?,
      photoPath: row['photo_path'] as String?,
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
        'category': category?.name,
        'specialty_id': specialtyId,
        'description': description,
        'use_text': useText,
        'tip': tip,
        'photo_path': photoPath,
      };
}
