/// Un reporte de error de contenido en el catálogo global
/// (`catalog_content_reports.status`). Sin versionado, igual que
/// [InstrumentIncident]: es una señal operativa de "esto está mal", no una
/// propuesta de cambio que necesite pasar por draft/revisión/aprobación.
enum ContentReportStatus { open, resolved }

extension ContentReportStatusLabel on ContentReportStatus {
  String get dbValue {
    switch (this) {
      case ContentReportStatus.open:
        return 'open';
      case ContentReportStatus.resolved:
        return 'resolved';
    }
  }

  static ContentReportStatus fromDb(String value) {
    switch (value) {
      case 'open':
        return ContentReportStatus.open;
      case 'resolved':
        return ContentReportStatus.resolved;
      default:
        throw ArgumentError('Estado de reporte desconocido: $value');
    }
  }
}

/// Una fila de `catalog_content_reports` -- ver
/// supabase/schema_v39_catalog_content_reports.sql. A diferencia de
/// [InstrumentIncident], no lleva `organizationId`/`workspaceId` ni
/// `severity`: un error de contenido en el catálogo global no pertenece a
/// ninguna organización.
class CatalogContentReport {
  final String? id;
  final String instrumentRefType;
  final String instrumentRefId;
  final String description;
  final ContentReportStatus status;
  final String? reportedBy;
  final String? resolvedBy;
  final String? resolutionNotes;
  final DateTime? resolvedAt;
  final DateTime? createdAt;

  const CatalogContentReport({
    this.id,
    required this.instrumentRefType,
    required this.instrumentRefId,
    required this.description,
    this.status = ContentReportStatus.open,
    this.reportedBy,
    this.resolvedBy,
    this.resolutionNotes,
    this.resolvedAt,
    this.createdAt,
  });

  factory CatalogContentReport.fromRow(Map<String, dynamic> row) {
    return CatalogContentReport(
      id: row['id'] as String?,
      instrumentRefType: row['instrument_ref_type'] as String,
      instrumentRefId: row['instrument_ref_id'] as String,
      description: row['description'] as String? ?? '',
      status: ContentReportStatusLabel.fromDb(row['status'] as String),
      reportedBy: row['reported_by'] as String?,
      resolvedBy: row['resolved_by'] as String?,
      resolutionNotes: row['resolution_notes'] as String?,
      resolvedAt: row['resolved_at'] != null ? DateTime.tryParse(row['resolved_at'] as String) : null,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
    );
  }
}
