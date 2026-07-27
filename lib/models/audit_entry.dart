/// Una entrada del log de auditoría (`audit_log`): quién hizo qué y cuándo
/// sobre una acción sensible (aprobar/rechazar contenido, crear/borrar
/// documentos, cambios de rol, transferencia de propiedad del hospital).
/// Solo se inserta desde funciones `security definer` en Supabase (ver
/// supabase/schema_v10_audit.sql) — nunca desde el cliente.
class AuditEntry {
  final String id;
  final String? hospitalId;
  final String? actorId;
  final String action;
  final String? entityType;
  final String? entityId;
  final String? workspaceId;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  /// Nombre del espacio (resuelto vía join con `workspaces` en la consulta,
  /// ver [AuditService.fetchAuditLog]).
  final String? workspaceName;

  /// Nombre del autor de la acción, o null si aún no se ha resuelto /
  /// la cuenta ya no existe (se muestra como "Usuario eliminado").
  final String? actorDisplayName;

  const AuditEntry({
    required this.id,
    this.hospitalId,
    this.actorId,
    required this.action,
    this.entityType,
    this.entityId,
    this.workspaceId,
    this.metadata = const {},
    this.createdAt,
    this.workspaceName,
    this.actorDisplayName,
  });

  AuditEntry copyWith({String? actorDisplayName}) {
    return AuditEntry(
      id: id,
      hospitalId: hospitalId,
      actorId: actorId,
      action: action,
      entityType: entityType,
      entityId: entityId,
      workspaceId: workspaceId,
      metadata: metadata,
      createdAt: createdAt,
      workspaceName: workspaceName,
      actorDisplayName: actorDisplayName ?? this.actorDisplayName,
    );
  }

  factory AuditEntry.fromRow(Map<String, dynamic> row) {
    final workspaceRow = row['workspaces'] as Map<String, dynamic>?;
    return AuditEntry(
      id: row['id'] as String,
      hospitalId: row['hospital_id'] as String?,
      actorId: row['actor_id'] as String?,
      action: row['action'] as String,
      entityType: row['entity_type'] as String?,
      entityId: row['entity_id'] as String?,
      workspaceId: row['workspace_id'] as String?,
      metadata: (row['metadata'] as Map<String, dynamic>?) ?? const {},
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      workspaceName: workspaceRow?['name'] as String?,
    );
  }
}
