import 'workspace_role.dart';

/// Estado de una [Invitation]. `expired` nunca se guarda en la fila (la
/// columna solo admite pending/accepted/revoked, ver
/// schema_v41_invitations.sql) -- es derivado, calculado aquí o por
/// `get_invitation_preview` en el servidor, comparando `expiresAt` con la
/// hora actual.
enum InvitationStatus { pending, accepted, revoked, expired }

extension InvitationStatusLabel on InvitationStatus {
  String get dbValue => name;

  static InvitationStatus fromDb(String value) {
    for (final s in InvitationStatus.values) {
      if (s.dbValue == value) return s;
    }
    throw ArgumentError('Estado de invitación desconocido: $value');
  }
}

/// Invitación por email a una persona concreta, con rol de espacio ya
/// asignado -- vía adicional al código de invitación de organización (ver
/// ProfileService.joinHospitalWithCode). Esta forma (fila cruda de
/// `invitations`) es la que usa la lista de administración; ver
/// [InvitationPreview] para lo que ve quien recibe el enlace, antes incluso
/// de tener cuenta.
class Invitation {
  final String id;
  final String organizationId;
  final String workspaceId;
  final String email;
  final WorkspaceRole role;
  final InvitationStatus status;
  final String? invitedByName;
  final DateTime createdAt;
  final DateTime expiresAt;

  const Invitation({
    required this.id,
    required this.organizationId,
    required this.workspaceId,
    required this.email,
    required this.role,
    required this.status,
    this.invitedByName,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => status == InvitationStatus.pending && expiresAt.isBefore(DateTime.now());

  /// Estado a mostrar en la UI -- ver comentario de [InvitationStatus].
  InvitationStatus get effectiveStatus => isExpired ? InvitationStatus.expired : status;

  factory Invitation.fromRow(Map<String, dynamic> row) {
    return Invitation(
      id: row['id'] as String,
      organizationId: row['organization_id'] as String,
      workspaceId: row['workspace_id'] as String,
      email: row['email'] as String,
      role: WorkspaceRoleLabel.fromDb(row['role'] as String)!,
      status: InvitationStatusLabel.fromDb(row['status'] as String),
      invitedByName: row['invited_by_name'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      expiresAt: DateTime.parse(row['expires_at'] as String),
    );
  }
}

/// Lo que ve quien recibe el enlace de invitación (`get_invitation_preview`,
/// callable sin sesión) -- deliberadamente no expone nada más que esto: ni
/// otros miembros, ni el resto de invitaciones, nada fuera de esta única fila.
class InvitationPreview {
  final String organizationName;
  final String workspaceName;
  final WorkspaceRole role;
  final String email;
  final InvitationStatus status;
  final String? invitedByName;

  const InvitationPreview({
    required this.organizationName,
    required this.workspaceName,
    required this.role,
    required this.email,
    required this.status,
    this.invitedByName,
  });

  factory InvitationPreview.fromRow(Map<String, dynamic> row) {
    return InvitationPreview(
      organizationName: row['organization_name'] as String,
      workspaceName: row['workspace_name'] as String,
      role: WorkspaceRoleLabel.fromDb(row['role'] as String)!,
      email: row['email'] as String,
      status: InvitationStatusLabel.fromDb(row['status'] as String),
      invitedByName: row['invited_by_name'] as String?,
    );
  }
}
