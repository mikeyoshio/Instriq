import 'group_document_version.dart' show GroupDocumentVersionStatus, GroupDocumentVersionStatusLabel;

/// Instrumental personalizado de un equipo (organización/workspace) — aparte
/// y nunca mezclado con el catálogo global curado ([Instrument] en
/// `lib/models/instrument.dart`). Cada equipo da de alta lo que necesite:
/// puede ser instrumental muy específico de ese quirófano o de un cirujano
/// concreto.
///
/// Cabecera + versiones (borrador -> en revisión -> publicada -> archivada),
/// calcado de [Tray]/[GroupDocument] (ver
/// supabase/schema_v39_custom_instrument_versioning.sql y
/// docs/ADR_004_VERSIONING.md §5) — el contenido (nombre, categoría,
/// especialidad, descripción, variantes...) vive en [CustomInstrumentVersion],
/// no aquí.
class CustomInstrument {
  final String id;
  final String organizationId;
  final String workspaceId;
  final String? createdBy;
  final DateTime? createdAt;
  final String? publishedVersionId;
  final CustomInstrumentVersion? publishedVersion;

  const CustomInstrument({
    required this.id,
    required this.organizationId,
    required this.workspaceId,
    this.createdBy,
    this.createdAt,
    this.publishedVersionId,
    this.publishedVersion,
  });

  /// Accesores de conveniencia sobre la versión publicada. A diferencia de
  /// [Tray]/[GroupDocument] (donde cada pantalla escribe
  /// `.publishedVersion?.campo` explícito), aquí se reenvían los campos de
  /// solo lectura más usados directamente desde la cabecera: hay decenas de
  /// sitios (buscador, "usado en", selector de bandeja...) que solo
  /// necesitan mostrar el contenido vigente, nunca un borrador, y no les
  /// interesa el resto del workflow de versionado. Un instrumento recién
  /// creado que todavía no tiene ninguna versión publicada (borrador propio
  /// en curso) muestra estos campos vacíos, igual que una bandeja/documento
  /// sin `publishedVersion` no aparece con contenido en sus pantallas.
  String get name => publishedVersion?.name ?? '';
  String? get category => publishedVersion?.category;
  String? get specialty => publishedVersion?.specialty;
  String? get specialtyId => publishedVersion?.specialtyId;
  String? get description => publishedVersion?.description;
  String? get useText => publishedVersion?.useText;
  String? get tip => publishedVersion?.tip;
  List<CustomInstrumentVariant> get variants => publishedVersion?.variants ?? const [];

  CustomInstrument copyWith({String? publishedVersionId, CustomInstrumentVersion? publishedVersion}) {
    return CustomInstrument(
      id: id,
      organizationId: organizationId,
      workspaceId: workspaceId,
      createdBy: createdBy,
      createdAt: createdAt,
      publishedVersionId: publishedVersionId ?? this.publishedVersionId,
      publishedVersion: publishedVersion ?? this.publishedVersion,
    );
  }

  factory CustomInstrument.fromRow(Map<String, dynamic> row) {
    final versionRow = row['published_version'] as Map<String, dynamic>?;
    return CustomInstrument(
      id: row['id'] as String,
      organizationId: row['organization_id'] as String,
      workspaceId: row['workspace_id'] as String,
      createdBy: row['created_by'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      publishedVersionId: row['published_version_id'] as String?,
      publishedVersion: versionRow != null ? CustomInstrumentVersion.fromRow(versionRow) : null,
    );
  }
}

/// Una variante concreta de un [CustomInstrument] (p.ej. "Variante corta" /
/// "Variante larga"), cada una con su propia foto opcional. Vive dentro de
/// [CustomInstrumentVersion.variants] (jsonb) desde
/// schema_v39_custom_instrument_versioning.sql — antes era su propia tabla
/// (`custom_instrument_variants`), editada en directo; ahora cambiar una
/// variante exige un borrador nuevo, igual que el resto del instrumento. El
/// [id] se genera en el cliente (no hay secuencia de base de datos para un
/// elemento dentro de un jsonb). La foto vive en el bucket privado
/// `custom-instrument-photos` (ver [CustomInstrumentService.uploadPhoto]) —
/// nunca es pública ni tiene atribución de licencia verificada como las del
/// catálogo global.
class CustomInstrumentVariant {
  final String id;
  final String name;
  final String? photoPath;
  final String? note;

  const CustomInstrumentVariant({
    required this.id,
    required this.name,
    this.photoPath,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'photo_path': photoPath,
        'note': note,
      };

  CustomInstrumentVariant copyWith({
    String? name,
    String? photoPath,
    bool clearPhotoPath = false,
    String? note,
  }) {
    return CustomInstrumentVariant(
      id: id,
      name: name ?? this.name,
      photoPath: clearPhotoPath ? null : (photoPath ?? this.photoPath),
      note: note ?? this.note,
    );
  }

  factory CustomInstrumentVariant.fromJson(Map<String, dynamic> json) {
    return CustomInstrumentVariant(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      photoPath: json['photo_path'] as String?,
      note: json['note'] as String?,
    );
  }
}

/// Una versión concreta del contenido de un [CustomInstrument]. Calcado de
/// [TrayVersion]/[GroupDocumentVersion]: cada edición crea una versión nueva
/// en vez de sobrescribir la anterior, con el mismo workflow borrador -> en
/// revisión -> publicada -> archivada (reutiliza [GroupDocumentVersionStatus]).
class CustomInstrumentVersion {
  final String id;
  final String customInstrumentId;
  final int versionNumber;
  final GroupDocumentVersionStatus status;
  final String name;
  final String? category;

  /// Texto libre heredado, ya no se escribe desde código nuevo (ver
  /// [specialtyId]) — se conserva solo para mostrar filas antiguas sin migrar.
  final String? specialty;

  /// FK a `specialties` (Fase C). Fuente de verdad para código nuevo.
  final String? specialtyId;
  final String? description;
  final String? useText;
  final String? tip;
  final List<CustomInstrumentVariant> variants;
  final String? authorId;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? comment;
  final String? basedOnVersionId;
  final DateTime? createdAt;

  const CustomInstrumentVersion({
    required this.id,
    required this.customInstrumentId,
    required this.versionNumber,
    required this.status,
    required this.name,
    this.category,
    this.specialty,
    this.specialtyId,
    this.description,
    this.useText,
    this.tip,
    this.variants = const [],
    this.authorId,
    this.approvedBy,
    this.approvedAt,
    this.comment,
    this.basedOnVersionId,
    this.createdAt,
  });

  Map<String, dynamic> toRow() => {
        'name': name,
        'category': category,
        'specialty_id': specialtyId,
        'description': description,
        'use_text': useText,
        'tip': tip,
        'variants': variants.map((v) => v.toJson()).toList(),
        'comment': comment,
      };

  /// [clearSpecialtyId]/[clearCategory]/[clearDescription]/[clearUseText]/
  /// [clearTip]: campos nullable donde pasar `null` no basta para vaciarlos
  /// (se confundiría con "no lo toques") — hay que pedirlo explícitamente,
  /// mismo patrón que [TrayVersion.copyWith].
  CustomInstrumentVersion copyWith({
    String? name,
    String? category,
    bool clearCategory = false,
    String? specialtyId,
    bool clearSpecialtyId = false,
    String? description,
    bool clearDescription = false,
    String? useText,
    bool clearUseText = false,
    String? tip,
    bool clearTip = false,
    List<CustomInstrumentVariant>? variants,
    String? comment,
  }) {
    return CustomInstrumentVersion(
      id: id,
      customInstrumentId: customInstrumentId,
      versionNumber: versionNumber,
      status: status,
      name: name ?? this.name,
      category: clearCategory ? null : (category ?? this.category),
      specialty: specialty,
      specialtyId: clearSpecialtyId ? null : (specialtyId ?? this.specialtyId),
      description: clearDescription ? null : (description ?? this.description),
      useText: clearUseText ? null : (useText ?? this.useText),
      tip: clearTip ? null : (tip ?? this.tip),
      variants: variants ?? this.variants,
      authorId: authorId,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      comment: comment ?? this.comment,
      basedOnVersionId: basedOnVersionId,
      createdAt: createdAt,
    );
  }

  factory CustomInstrumentVersion.fromRow(Map<String, dynamic> row) {
    return CustomInstrumentVersion(
      id: row['id'] as String,
      customInstrumentId: row['custom_instrument_id'] as String,
      versionNumber: row['version_number'] as int,
      status: GroupDocumentVersionStatusLabel.fromDb(row['status'] as String),
      name: row['name'] as String? ?? '',
      category: row['category'] as String?,
      specialty: row['specialty'] as String?,
      specialtyId: row['specialty_id'] as String?,
      description: row['description'] as String?,
      useText: row['use_text'] as String?,
      tip: row['tip'] as String?,
      variants: (row['variants'] as List<dynamic>? ?? [])
          .map((e) => CustomInstrumentVariant.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      authorId: row['author_id'] as String?,
      approvedBy: row['approved_by'] as String?,
      approvedAt: row['approved_at'] != null ? DateTime.tryParse(row['approved_at'] as String) : null,
      comment: row['comment'] as String?,
      basedOnVersionId: row['based_on_version_id'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
    );
  }
}
