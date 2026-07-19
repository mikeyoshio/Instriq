import 'workspace_role.dart';

/// Un miembro del hospital y su rol (si tiene alguno) en un espacio concreto.
class WorkspaceMember {
  final String userId;
  final String? displayName;
  final bool isHospitalAdmin;
  final WorkspaceRole? role;

  const WorkspaceMember({
    required this.userId,
    this.displayName,
    this.isHospitalAdmin = false,
    this.role,
  });

  /// Rol efectivo a mostrar: un administrador del hospital siempre tiene
  /// acceso total, independientemente de si tiene fila en workspace_members.
  WorkspaceRole? get effectiveRole => isHospitalAdmin ? WorkspaceRole.administrator : role;
}
