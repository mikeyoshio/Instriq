/// Rol efectivo de un usuario dentro de un espacio de trabajo. `administrator`
/// nunca se guarda en `workspace_members` — es un valor derivado (viene de
/// `profiles.is_admin`, ver `my_workspace_role()` en Supabase) que implica
/// acceso total a todos los espacios del hospital sin necesidad de fila propia.
enum WorkspaceRole { reader, editor, approver, administrator }

extension WorkspaceRoleLabel on WorkspaceRole {
  /// Puede crear o editar borradores de contenido.
  bool get canEdit =>
      this == WorkspaceRole.editor || this == WorkspaceRole.approver || this == WorkspaceRole.administrator;

  /// Puede aprobar/rechazar cambios y eliminar contenido.
  bool get canApprove => this == WorkspaceRole.approver || this == WorkspaceRole.administrator;

  /// Administrador del hospital -- acceso total, no solo aprobación de
  /// contenido (gestión de miembros del espacio, etc.). Nombrado a propósito
  /// en vez de comparar `== WorkspaceRole.administrator` en cada pantalla,
  /// mismo criterio que [canEdit]/[canApprove] (docs/BACKLOG.md Nivell 3).
  bool get isAdministrator => this == WorkspaceRole.administrator;

  String get dbValue => name;

  static WorkspaceRole? fromDb(String? value) {
    if (value == null) return null;
    for (final r in WorkspaceRole.values) {
      if (r.dbValue == value) return r;
    }
    return null;
  }
}
