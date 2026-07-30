/// Documento de referencia (IFU/guía/manual, tabla `reference_documents`,
/// Fase C). [organizationId] null significa documento global (p.ej. una IFU
/// pública de un fabricante); no nulo, privado de ese grupo.
class ReferenceDocument {
  final String id;
  final String title;
  final String url;
  final String docType;
  final String? organizationId;
  final String? manufacturerId;

  const ReferenceDocument({
    required this.id,
    required this.title,
    required this.url,
    this.docType = 'other',
    this.organizationId,
    this.manufacturerId,
  });

  factory ReferenceDocument.fromRow(Map<String, dynamic> row) {
    return ReferenceDocument(
      id: row['id'] as String,
      title: row['title'] as String? ?? '',
      url: row['url'] as String? ?? '',
      docType: row['doc_type'] as String? ?? 'other',
      organizationId: row['organization_id'] as String?,
      manufacturerId: row['manufacturer_id'] as String?,
    );
  }
}
