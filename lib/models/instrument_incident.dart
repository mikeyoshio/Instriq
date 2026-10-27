/// Gravedad de una incidencia de un instrumento (`instrument_incidents.severity`).
/// Decisión confirmada por el propietario: estado + gravedad, no un simple
/// registro de texto libre (ver plan EPIC 3 · CSSD Workspace).
enum IncidentSeverity { low, medium, high }

extension IncidentSeverityLabel on IncidentSeverity {
  String get label {
    switch (this) {
      case IncidentSeverity.low:
        return 'Baja';
      case IncidentSeverity.medium:
        return 'Media';
      case IncidentSeverity.high:
        return 'Alta';
    }
  }

  String get dbValue {
    switch (this) {
      case IncidentSeverity.low:
        return 'low';
      case IncidentSeverity.medium:
        return 'medium';
      case IncidentSeverity.high:
        return 'high';
    }
  }

  static IncidentSeverity fromDb(String value) {
    switch (value) {
      case 'low':
        return IncidentSeverity.low;
      case 'medium':
        return IncidentSeverity.medium;
      case 'high':
        return IncidentSeverity.high;
      default:
        throw ArgumentError('Gravedad de incidencia desconocida: $value');
    }
  }
}

/// Estado de una incidencia (`instrument_incidents.status`). Sin versionado:
/// es un registro operativo, no contenido que haya que aprobar antes de
/// existir (ver schema_v32_cssd_workspace.sql §3). Flujo CAPA de 3 pasos
/// (ISO 9001 10.2, ver schema_v55_instrument_incidents_capa.sql): abierta ->
/// resuelta (causa raíz + acción correctiva) -> verificada (efectividad
/// confirmada por alguien distinto de quien resolvió).
enum IncidentStatus { open, resolved, verified }

extension IncidentStatusLabel on IncidentStatus {
  String get label {
    switch (this) {
      case IncidentStatus.open:
        return 'Abierta';
      case IncidentStatus.resolved:
        return 'Resuelta';
      case IncidentStatus.verified:
        return 'Verificada';
    }
  }

  String get dbValue {
    switch (this) {
      case IncidentStatus.open:
        return 'open';
      case IncidentStatus.resolved:
        return 'resolved';
      case IncidentStatus.verified:
        return 'verified';
    }
  }

  static IncidentStatus fromDb(String value) {
    switch (value) {
      case 'open':
        return IncidentStatus.open;
      case 'resolved':
        return IncidentStatus.resolved;
      case 'verified':
        return IncidentStatus.verified;
      default:
        throw ArgumentError('Estado de incidencia desconocido: $value');
    }
  }
}

/// Una fila de `instrument_incidents`. [organizationId] es obligatorio (a
/// diferencia de [SterilizationMethodEntry]/[InstrumentTechnicalInfo], una
/// incidencia siempre pertenece a una organización — no existe "incidencia
/// de catálogo global"). [workspaceId] nulo significa incidencia a nivel de
/// organización, no de un espacio concreto. Todas las escrituras van vía RPC
/// (`report_instrument_incident`/`resolve_instrument_incident`/
/// `verify_instrument_incident`), nunca insert/update directo — ver
/// [InstrumentIncidentService].
class InstrumentIncident {
  final String? id;
  final String instrumentRefType;
  final String instrumentRefId;
  final String organizationId;
  final String? workspaceId;
  final IncidentSeverity severity;
  final IncidentStatus status;
  final String description;
  final String? resolutionNotes;
  final String? rootCause;
  final String? correctiveAction;
  final String? reportedBy;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final String? verifiedBy;
  final DateTime? verifiedAt;
  final String? verificationNotes;
  final String? trayPreparationSessionId;
  final DateTime? createdAt;

  const InstrumentIncident({
    this.id,
    required this.instrumentRefType,
    required this.instrumentRefId,
    required this.organizationId,
    this.workspaceId,
    this.severity = IncidentSeverity.low,
    this.status = IncidentStatus.open,
    required this.description,
    this.resolutionNotes,
    this.rootCause,
    this.correctiveAction,
    this.reportedBy,
    this.resolvedBy,
    this.resolvedAt,
    this.verifiedBy,
    this.verifiedAt,
    this.verificationNotes,
    this.trayPreparationSessionId,
    this.createdAt,
  });

  factory InstrumentIncident.fromRow(Map<String, dynamic> row) {
    return InstrumentIncident(
      id: row['id'] as String?,
      instrumentRefType: row['instrument_ref_type'] as String,
      instrumentRefId: row['instrument_ref_id'] as String,
      organizationId: row['organization_id'] as String,
      workspaceId: row['workspace_id'] as String?,
      severity: IncidentSeverityLabel.fromDb(row['severity'] as String),
      status: IncidentStatusLabel.fromDb(row['status'] as String),
      description: row['description'] as String? ?? '',
      resolutionNotes: row['resolution_notes'] as String?,
      rootCause: row['root_cause'] as String?,
      correctiveAction: row['corrective_action'] as String?,
      reportedBy: row['reported_by'] as String?,
      resolvedBy: row['resolved_by'] as String?,
      resolvedAt: row['resolved_at'] != null ? DateTime.tryParse(row['resolved_at'] as String) : null,
      verifiedBy: row['verified_by'] as String?,
      verifiedAt: row['verified_at'] != null ? DateTime.tryParse(row['verified_at'] as String) : null,
      verificationNotes: row['verification_notes'] as String?,
      trayPreparationSessionId: row['tray_preparation_session_id'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
    );
  }
}
