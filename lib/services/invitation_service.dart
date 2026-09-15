import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/invitation.dart';
import '../models/workspace_role.dart';

/// Invitación por email a una persona concreta, con rol de espacio ya
/// asignado de entrada (ver schema_v41_invitations.sql). Toda escritura pasa
/// por RPC -- `invitations` no tiene policy de insert/update/delete, solo de
/// select para administradores de la propia organización (lista de
/// pendientes). Aceptar una invitación vive en
/// [ProfileService.acceptInvitation], no aquí: actualiza el estado en caché
/// de la organización actual, igual que `joinHospitalWithCode`.
class InvitationService {
  InvitationService._();
  static final InvitationService instance = InvitationService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<Invitation> create({required String workspaceId, required String email, required String role}) async {
    final row = await _client.rpc('create_invitation', params: {
      'p_workspace_id': workspaceId,
      'p_email': email,
      'p_role': role,
    });
    return Invitation.fromRow(row as Map<String, dynamic>);
  }

  Future<void> revoke(String invitationId) async {
    await _client.rpc('revoke_invitation', params: {'p_invitation_id': invitationId});
  }

  /// Revoca la invitación anterior y crea una nueva (token y caducidad
  /// frescos): reutiliza el mismo INSERT que ya dispara el Database Webhook
  /// de envío de correo (ver supabase/functions/send-invitation-email), sin
  /// necesitar un segundo evento configurado en el dashboard.
  Future<Invitation> resend(Invitation invitation) async {
    await revoke(invitation.id);
    return create(workspaceId: invitation.workspaceId, email: invitation.email, role: invitation.role.dbValue);
  }

  Future<List<Invitation>> fetchForOrganization(String organizationId) async {
    final rows = await _client
        .from('invitations')
        .select()
        .eq('organization_id', organizationId)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>).map((r) => Invitation.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// Callable sin sesión: quien recibe el enlace puede no tener cuenta todavía.
  Future<InvitationPreview> preview(String token) async {
    final rows = await _client.rpc('get_invitation_preview', params: {'p_token': token}) as List<dynamic>;
    return InvitationPreview.fromRow(rows.first as Map<String, dynamic>);
  }

  /// Callable sin sesión, igual que [preview].
  Future<void> decline(String token) async {
    await _client.rpc('decline_invitation', params: {'p_token': token});
  }
}
