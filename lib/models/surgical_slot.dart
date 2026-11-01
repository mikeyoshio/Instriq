enum SurgicalSlotStatus { scheduled, cancelled }

extension SurgicalSlotStatusLabel on SurgicalSlotStatus {
  String get dbValue => name;

  static SurgicalSlotStatus fromDb(String value) {
    return SurgicalSlotStatus.values.firstWhere(
      (s) => s.dbValue == value,
      orElse: () => throw ArgumentError('Estado de slot de agenda desconocido: $value'),
    );
  }
}

/// Un hueco de agenda quirúrgica: dato operativo ("Dr. X, quirófano 3,
/// 10:00–12:00, hernioplastia"), nunca dato de paciente -- ni nombre ni
/// identificador de paciente debe entrar aquí, ni siquiera en [notes] (eso es
/// solo para notas internas del equipo y la Edge Function del feed `.ics`
/// nunca lo lee ni lo expone). Sin versionado: se escribe directo vía RPC
/// `security definer`, igual que [TrayPreparationSession].
class SurgicalSlot {
  final String id;
  final String organizationId;
  final String workspaceId;
  final String surgeonId;
  final String? preferenceCardId;
  final String? documentId;
  final String? trayId;
  final String? procedureName;
  final String? location;
  final DateTime startsAt;
  final DateTime endsAt;
  final String? notes;
  final SurgicalSlotStatus status;
  final String? createdBy;
  final DateTime? createdAt;
  final String? cancelledBy;
  final DateTime? cancelledAt;
  final String? cancellationReason;

  const SurgicalSlot({
    required this.id,
    required this.organizationId,
    required this.workspaceId,
    required this.surgeonId,
    this.preferenceCardId,
    this.documentId,
    this.trayId,
    this.procedureName,
    this.location,
    required this.startsAt,
    required this.endsAt,
    this.notes,
    this.status = SurgicalSlotStatus.scheduled,
    this.createdBy,
    this.createdAt,
    this.cancelledBy,
    this.cancelledAt,
    this.cancellationReason,
  });

  factory SurgicalSlot.fromRow(Map<String, dynamic> row) {
    return SurgicalSlot(
      id: row['id'] as String,
      organizationId: row['organization_id'] as String,
      workspaceId: row['workspace_id'] as String,
      surgeonId: row['surgeon_id'] as String,
      preferenceCardId: row['preference_card_id'] as String?,
      documentId: row['document_id'] as String?,
      trayId: row['tray_id'] as String?,
      procedureName: row['procedure_name'] as String?,
      location: row['location'] as String?,
      startsAt: DateTime.parse(row['starts_at'] as String),
      endsAt: DateTime.parse(row['ends_at'] as String),
      notes: row['notes'] as String?,
      status: SurgicalSlotStatusLabel.fromDb(row['status'] as String),
      createdBy: row['created_by'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      cancelledBy: row['cancelled_by'] as String?,
      cancelledAt: row['cancelled_at'] != null ? DateTime.tryParse(row['cancelled_at'] as String) : null,
      cancellationReason: row['cancellation_reason'] as String?,
    );
  }
}
