/// Instrumental personalizado de un equipo (hospital/workspace) — aparte y
/// nunca mezclado con el catálogo global curado ([Instrument] en
/// `lib/models/instrument.dart`). Cada equipo da de alta lo que necesite:
/// puede ser instrumental muy específico de ese quirófano o de un cirujano
/// concreto. Ver supabase/schema_v13_custom_instruments.sql para las reglas
/// de acceso (privado del workspace/hospital que lo crea).
class CustomInstrument {
  final String id;
  final String organizationId;
  final String workspaceId;
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
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<CustomInstrumentVariant> variants;

  const CustomInstrument({
    required this.id,
    required this.organizationId,
    required this.workspaceId,
    required this.name,
    this.category,
    this.specialty,
    this.specialtyId,
    this.description,
    this.useText,
    this.tip,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.variants = const [],
  });

  Map<String, dynamic> toRow() => {
        'organization_id': organizationId,
        'workspace_id': workspaceId,
        'name': name,
        'category': category,
        'specialty_id': specialtyId,
        'description': description,
        'use_text': useText,
        'tip': tip,
      };

  CustomInstrument copyWith({
    String? name,
    String? category,
    String? specialtyId,
    bool clearSpecialtyId = false,
    String? description,
    String? useText,
    String? tip,
    List<CustomInstrumentVariant>? variants,
  }) {
    return CustomInstrument(
      id: id,
      organizationId: organizationId,
      workspaceId: workspaceId,
      name: name ?? this.name,
      category: category ?? this.category,
      specialty: specialty,
      specialtyId: clearSpecialtyId ? null : (specialtyId ?? this.specialtyId),
      description: description ?? this.description,
      useText: useText ?? this.useText,
      tip: tip ?? this.tip,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      variants: variants ?? this.variants,
    );
  }

  factory CustomInstrument.fromRow(Map<String, dynamic> row) {
    final rawVariants = row['custom_instrument_variants'] as List<dynamic>?;
    return CustomInstrument(
      id: row['id'] as String,
      organizationId: row['organization_id'] as String,
      workspaceId: row['workspace_id'] as String,
      name: row['name'] as String? ?? '',
      category: row['category'] as String?,
      specialty: row['specialty'] as String?,
      specialtyId: row['specialty_id'] as String?,
      description: row['description'] as String?,
      useText: row['use_text'] as String?,
      tip: row['tip'] as String?,
      createdBy: row['created_by'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      updatedAt: row['updated_at'] != null ? DateTime.tryParse(row['updated_at'] as String) : null,
      variants: rawVariants == null
          ? const []
          : rawVariants.map((v) => CustomInstrumentVariant.fromRow(v as Map<String, dynamic>)).toList(),
    );
  }
}

/// Una variante concreta de un [CustomInstrument] (p.ej. "Variante corta" /
/// "Variante larga"), cada una con su propia foto opcional. La foto vive en
/// el bucket privado `custom-instrument-photos` (ver
/// CustomInstrumentService.uploadVariantPhoto) — nunca es pública ni tiene
/// atribución de licencia verificada como las del catálogo global.
class CustomInstrumentVariant {
  final String id;
  final String customInstrumentId;
  final String name;
  final String? photoPath;
  final String? note;
  final DateTime? createdAt;

  const CustomInstrumentVariant({
    required this.id,
    required this.customInstrumentId,
    required this.name,
    this.photoPath,
    this.note,
    this.createdAt,
  });

  Map<String, dynamic> toRow() => {
        'custom_instrument_id': customInstrumentId,
        'name': name,
        'photo_path': photoPath,
        'note': note,
      };

  CustomInstrumentVariant copyWith({
    String? name,
    String? photoPath,
    String? note,
  }) {
    return CustomInstrumentVariant(
      id: id,
      customInstrumentId: customInstrumentId,
      name: name ?? this.name,
      photoPath: photoPath ?? this.photoPath,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  factory CustomInstrumentVariant.fromRow(Map<String, dynamic> row) {
    return CustomInstrumentVariant(
      id: row['id'] as String,
      customInstrumentId: row['custom_instrument_id'] as String,
      name: row['name'] as String? ?? '',
      photoPath: row['photo_path'] as String?,
      note: row['note'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
    );
  }
}
