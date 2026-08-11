import 'group_document_version.dart' show GroupDocumentVersionStatus, GroupDocumentVersionStatusLabel;

class PreferenceCardItem {
  final String? instrumentId;
  final String customName;
  final String? note;

  const PreferenceCardItem({
    this.instrumentId,
    required this.customName,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'instrumentId': instrumentId,
        'customName': customName,
        'note': note,
      };

  factory PreferenceCardItem.fromJson(Map<String, dynamic> json) {
    return PreferenceCardItem(
      instrumentId: json['instrumentId'] as String?,
      customName: json['customName'] as String? ?? '',
      note: json['note'] as String?,
    );
  }
}

/// Cabecera de una tarjeta de preferencia. El contenido (cirujano,
/// procedimiento, instrumental, notas, validación) vive en
/// [PreferenceCardVersion] — igual que [GroupDocument]/[Tray] (ver
/// supabase/schema_v22_preference_card_versioning.sql).
class PreferenceCard {
  final String id;
  final String organizationId;
  final String workspaceId;
  final String? createdBy;
  final DateTime? createdAt;
  final String? publishedVersionId;
  final PreferenceCardVersion? publishedVersion;

  const PreferenceCard({
    required this.id,
    required this.organizationId,
    required this.workspaceId,
    this.createdBy,
    this.createdAt,
    this.publishedVersionId,
    this.publishedVersion,
  });

  PreferenceCard copyWith({String? publishedVersionId, PreferenceCardVersion? publishedVersion}) {
    return PreferenceCard(
      id: id,
      organizationId: organizationId,
      workspaceId: workspaceId,
      createdBy: createdBy,
      createdAt: createdAt,
      publishedVersionId: publishedVersionId ?? this.publishedVersionId,
      publishedVersion: publishedVersion ?? this.publishedVersion,
    );
  }

  factory PreferenceCard.fromRow(Map<String, dynamic> row) {
    final versionRow = row['published_version'] as Map<String, dynamic>?;
    return PreferenceCard(
      id: row['id'] as String,
      organizationId: row['organization_id'] as String,
      workspaceId: row['workspace_id'] as String,
      createdBy: row['created_by'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      publishedVersionId: row['published_version_id'] as String?,
      publishedVersion: versionRow != null ? PreferenceCardVersion.fromRow(versionRow) : null,
    );
  }

  /// Fila completa para [OfflineCacheService] — ver [GroupDocument.toCacheRow].
  Map<String, dynamic> toCacheRow() => {
        'id': id,
        'organization_id': organizationId,
        'workspace_id': workspaceId,
        'created_by': createdBy,
        'created_at': createdAt?.toIso8601String(),
        'published_version_id': publishedVersionId,
        'published_version': publishedVersion?.toCacheRow(),
      };
}

/// Una versión concreta del contenido de una [PreferenceCard]. Calcado de
/// [TrayVersion]/[GroupDocumentVersion]: cada edición crea una versión nueva
/// en vez de sobrescribir la anterior, con el mismo workflow borrador -> en
/// revisión -> publicada -> archivada.
class PreferenceCardVersion {
  final String id;
  final String cardId;
  final int versionNumber;
  final GroupDocumentVersionStatus status;

  /// FK a `surgeons` (Fase C). Nullable porque una versión puede guardarse
  /// sin cirujano asignado todavía; el nombre se resuelve vía [SurgeonService]
  /// (caché por grupo), no se guarda aquí.
  final String? surgeonId;
  final String procedureName;
  final List<PreferenceCardItem> items;
  final String? generalNotes;
  final bool validatedBySurgeon;
  final String? authorId;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? comment;
  final String? basedOnVersionId;
  final DateTime? createdAt;

  /// true si esta versión solo existe localmente todavía — ver
  /// [GroupDocumentVersion.pendingSync] (mismo patrón, generalizado a
  /// tarjetas de preferencia en EPIC 7).
  final bool pendingSync;

  const PreferenceCardVersion({
    required this.id,
    required this.cardId,
    required this.versionNumber,
    required this.status,
    this.surgeonId,
    required this.procedureName,
    this.items = const [],
    this.generalNotes,
    this.validatedBySurgeon = false,
    this.authorId,
    this.approvedBy,
    this.approvedAt,
    this.comment,
    this.basedOnVersionId,
    this.createdAt,
    this.pendingSync = false,
  });

  Map<String, dynamic> toRow() => {
        'surgeon_id': surgeonId,
        'procedure_name': procedureName,
        'items': items.map((i) => i.toJson()).toList(),
        'general_notes': generalNotes,
        'validated_by_surgeon': validatedBySurgeon,
        'comment': comment,
      };

  /// [clearSurgeonId]/[clearGeneralNotes]: campos nullable donde pasar `null`
  /// no basta para vaciarlos (se confundiría con "no lo toques") — hay que
  /// pedirlo explícitamente, mismo patrón que [TrayVersion.copyWith].
  PreferenceCardVersion copyWith({
    String? surgeonId,
    bool clearSurgeonId = false,
    String? procedureName,
    List<PreferenceCardItem>? items,
    String? generalNotes,
    bool clearGeneralNotes = false,
    bool? validatedBySurgeon,
    String? comment,
    bool? pendingSync,
  }) {
    return PreferenceCardVersion(
      id: id,
      cardId: cardId,
      versionNumber: versionNumber,
      status: status,
      surgeonId: clearSurgeonId ? null : (surgeonId ?? this.surgeonId),
      procedureName: procedureName ?? this.procedureName,
      items: items ?? this.items,
      generalNotes: clearGeneralNotes ? null : (generalNotes ?? this.generalNotes),
      validatedBySurgeon: validatedBySurgeon ?? this.validatedBySurgeon,
      authorId: authorId,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      comment: comment ?? this.comment,
      basedOnVersionId: basedOnVersionId,
      createdAt: createdAt,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  factory PreferenceCardVersion.fromRow(Map<String, dynamic> row) {
    final rawItems = row['items'] as List<dynamic>? ?? [];
    return PreferenceCardVersion(
      id: row['id'] as String,
      cardId: row['card_id'] as String,
      versionNumber: row['version_number'] as int,
      status: GroupDocumentVersionStatusLabel.fromDb(row['status'] as String),
      surgeonId: row['surgeon_id'] as String?,
      procedureName: row['procedure_name'] as String? ?? '',
      items: rawItems.map((e) => PreferenceCardItem.fromJson((e as Map).cast<String, dynamic>())).toList(),
      generalNotes: row['general_notes'] as String?,
      validatedBySurgeon: row['validated_by_surgeon'] as bool? ?? false,
      authorId: row['author_id'] as String?,
      approvedBy: row['approved_by'] as String?,
      approvedAt: row['approved_at'] != null ? DateTime.tryParse(row['approved_at'] as String) : null,
      comment: row['comment'] as String?,
      basedOnVersionId: row['based_on_version_id'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      pendingSync: row['pending_sync'] as bool? ?? false,
    );
  }

  /// Fila completa para [OfflineCacheService] — ver
  /// [GroupDocumentVersion.toCacheRow].
  Map<String, dynamic> toCacheRow() => {
        'id': id,
        'card_id': cardId,
        'version_number': versionNumber,
        'status': status.dbValue,
        'surgeon_id': surgeonId,
        'procedure_name': procedureName,
        'items': items.map((i) => i.toJson()).toList(),
        'general_notes': generalNotes,
        'validated_by_surgeon': validatedBySurgeon,
        'author_id': authorId,
        'approved_by': approvedBy,
        'approved_at': approvedAt?.toIso8601String(),
        'comment': comment,
        'based_on_version_id': basedOnVersionId,
        'created_at': createdAt?.toIso8601String(),
        'pending_sync': pendingSync,
      };
}
