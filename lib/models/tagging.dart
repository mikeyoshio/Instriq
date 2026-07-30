/// Fila cruda de `taggings` (join polimórfico etiqueta -> entidad, Fase C).
/// [organizationId] null significa que lo etiquetado es global (instrumento
/// de catálogo, fabricante, especialidad); no nulo, que es privado de ese
/// grupo (bandeja, documento, cirujano...).
class Tagging {
  final String id;
  final String tagId;
  final String refType;
  final String refId;
  final String? organizationId;
  final String? createdBy;

  const Tagging({
    required this.id,
    required this.tagId,
    required this.refType,
    required this.refId,
    this.organizationId,
    this.createdBy,
  });

  factory Tagging.fromRow(Map<String, dynamic> row) {
    return Tagging(
      id: row['id'] as String,
      tagId: row['tag_id'] as String,
      refType: row['ref_type'] as String,
      refId: row['ref_id'] as String,
      organizationId: row['organization_id'] as String?,
      createdBy: row['created_by'] as String?,
    );
  }
}
