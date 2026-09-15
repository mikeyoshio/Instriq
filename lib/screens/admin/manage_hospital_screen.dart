import 'package:flutter/material.dart';

import '../../design_system/components/instriq_responsive_content.dart';
import '../../l10n/app_localizations.dart';
import '../../models/hospital.dart';
import '../../models/invitation.dart';
import '../../models/workspace.dart';
import '../../models/workspace_role.dart';
import '../../services/auth_service.dart';
import '../../services/invitation_service.dart';
import '../../services/profile_service.dart';
import '../../services/workspace_service.dart';
import '../../widgets/workspace_role_label.dart';

class ManageHospitalScreen extends StatefulWidget {
  const ManageHospitalScreen({super.key});

  @override
  State<ManageHospitalScreen> createState() => _ManageHospitalScreenState();
}

class _ManageHospitalScreenState extends State<ManageHospitalScreen> {
  bool _loading = true;
  bool _regenerating = false;
  List<HospitalMember> _members = [];
  List<Invitation> _invitations = [];
  List<Workspace> _workspaces = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final organizationId = ProfileService.instance.organizationId;
    try {
      _members = await ProfileService.instance.fetchMembers();
      await WorkspaceService.instance.fetchWorkspaces();
      _workspaces = WorkspaceService.instance.workspaces;
      if (organizationId != null) {
        _invitations = await InvitationService.instance.fetchForOrganization(organizationId);
      }
    } catch (e) {
      if (mounted) _error = AppLocalizations.of(context)!.manageMembersLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  /// Invita a una persona concreta por email a un espacio con un rol ya
  /// fijado (ver schema_v41_invitations.sql) -- vía adicional al código de
  /// invitación de arriba, que sigue sirviendo para alta autoservicio.
  Future<void> _openInviteDialog() async {
    final l10n = AppLocalizations.of(context)!;
    if (_workspaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.inviteNoWorkspacesError)));
      return;
    }
    final emailController = TextEditingController();
    String workspaceId = _workspaces.first.id;
    WorkspaceRole role = WorkspaceRole.reader;
    String? dialogError;
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.inviteByEmailTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: emailController,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.email, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: workspaceId,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.workspaceLabel, border: const OutlineInputBorder()),
                  items: _workspaces.map((w) => DropdownMenuItem(value: w.id, child: Text(w.name))).toList(),
                  onChanged: (value) => setDialogState(() => workspaceId = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<WorkspaceRole>(
                  initialValue: role,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.roleLabel, border: const OutlineInputBorder()),
                  items: const [WorkspaceRole.reader, WorkspaceRole.editor, WorkspaceRole.approver]
                      .map((r) => DropdownMenuItem(value: r, child: Text(workspaceRoleLabel(l10n, r))))
                      .toList(),
                  onChanged: (value) => setDialogState(() => role = value!),
                ),
                if (dialogError != null) ...[
                  const SizedBox(height: 12),
                  Text(dialogError!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty) return;
                try {
                  await InvitationService.instance
                      .create(workspaceId: workspaceId, email: email, role: role.dbValue);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  setDialogState(() => dialogError = l10n.genericError(e.toString()));
                }
              },
              child: Text(l10n.sendInviteAction),
            ),
          ],
        ),
      ),
    );
    if (sent == true) _load();
  }

  String _workspaceName(String workspaceId) {
    for (final w in _workspaces) {
      if (w.id == workspaceId) return w.name;
    }
    return '';
  }

  Future<void> _revokeInvitation(Invitation invitation) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.revokeInviteTitle),
        content: Text(l10n.revokeInviteBody(invitation.email)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.revokeInviteAction)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await InvitationService.instance.revoke(invitation.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericError(e.toString()))));
      }
    }
  }

  Future<void> _resendInvitation(Invitation invitation) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await InvitationService.instance.resend(invitation);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.inviteResentSnackbar)));
      }
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericError(e.toString()))));
      }
    }
  }

  Future<void> _regenerateCode() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.regenerateCodeTitle),
        content: Text(l10n.regenerateCodeBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.regenerate)),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _regenerating = true);
    try {
      await ProfileService.instance.regenerateInviteCode();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _regenerating = false);
    }
  }

  Future<void> _transferOwnership(HospitalMember member) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.transferOwnershipTitle),
        content: Text(
          l10n.transferOwnershipBody(
            member.displayName?.isNotEmpty == true ? member.displayName! : l10n.thisPerson,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.transfer)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ProfileService.instance.transferOwnership(member.id);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericError(e.toString()))));
      }
    }
  }

  /// Promueve o quita el rol de administrador/a (RPC `set_hospital_admin`,
  /// ver schema_v30_hospital_admin_promotion.sql). Acción de alto privilegio
  /// -- diálogo de confirmación siempre, tanto al conceder como al quitar. El
  /// error real del RPC (p. ej. rechazo por ser el último admin) se muestra
  /// tal cual, sin silenciarlo -- mismo patrón que `_transferOwnership`.
  Future<void> _setHospitalAdmin(HospitalMember member, bool isAdmin) async {
    final l10n = AppLocalizations.of(context)!;
    final name = member.displayName?.isNotEmpty == true ? member.displayName! : l10n.thisPerson;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAdmin ? l10n.makeAdminTitle : l10n.removeAdminTitle),
        content: Text(isAdmin ? l10n.makeAdminBody(name) : l10n.removeAdminBody(name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isAdmin ? l10n.makeAdminTitle : l10n.removeAdminTitle),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ProfileService.instance.setHospitalAdmin(member.id, isAdmin);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericError(e.toString()))));
      }
    }
  }

  Future<void> _removeMember(HospitalMember member) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.removeFromHospitalTitle),
        content: Text(
          l10n.removeMemberBody(
            member.displayName?.isNotEmpty == true ? member.displayName! : l10n.thisPerson,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.remove)),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ProfileService.instance.removeMember(member.id);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.genericError(e.toString()))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = ProfileService.instance;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.manageGroupTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: InstriqResponsiveContent(
                child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(profile.organizationName ?? '', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.inviteCodeLabel, style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 8),
                          SelectableText(
                            profile.inviteCode ?? 'â€”',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 4),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _regenerating ? null : _regenerateCode,
                            icon: _regenerating
                                ? const SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.refresh),
                            label: Text(l10n.regenerateCodeTitle),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text(l10n.pendingInvitesTitle, style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _openInviteDialog,
                        icon: const Icon(Icons.mail_outline),
                        label: Text(l10n.inviteByEmailTitle),
                      ),
                    ],
                  ),
                  if (_invitations.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(l10n.noPendingInvites),
                    )
                  else
                    ..._invitations.map((invitation) {
                      final status = invitation.effectiveStatus;
                      final statusLabel = switch (status) {
                        InvitationStatus.pending => l10n.inviteStatusPending,
                        InvitationStatus.accepted => l10n.inviteStatusAccepted,
                        InvitationStatus.revoked => l10n.inviteStatusRevoked,
                        InvitationStatus.expired => l10n.inviteStatusExpired,
                      };
                      final statusColor = switch (status) {
                        InvitationStatus.pending => null,
                        InvitationStatus.accepted => Colors.green,
                        InvitationStatus.revoked => Colors.grey,
                        InvitationStatus.expired => Colors.orange,
                      };
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.mail_outline),
                          title: Text(invitation.email),
                          subtitle: Text('${workspaceRoleLabel(l10n, invitation.role)} · ${_workspaceName(invitation.workspaceId)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(label: Text(statusLabel), backgroundColor: statusColor?.withValues(alpha: 0.15)),
                              if (status == InvitationStatus.pending || status == InvitationStatus.expired) ...[
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  tooltip: l10n.resendInviteTooltip,
                                  onPressed: () => _resendInvitation(invitation),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  tooltip: l10n.revokeInviteAction,
                                  onPressed: () => _revokeInvitation(invitation),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  const SizedBox(height: 24),
                  Text(l10n.membersCountTitle(_members.length), style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                  ..._members.map((m) {
                    final isMe = m.id == AuthService.instance.currentUser?.id;
                    final isOwner = m.id == profile.ownerId;
                    final canTransferTo = profile.isOwner && m.isAdmin && !isMe;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person),
                        title: Text(
                          isMe
                              ? l10n.memberNameWithYou(
                                  m.displayName?.isNotEmpty == true ? m.displayName! : l10n.noName)
                              : (m.displayName?.isNotEmpty == true ? m.displayName! : l10n.noName),
                        ),
                        subtitle: (isOwner || m.isAdmin)
                            ? Text([
                                if (isOwner) l10n.ownerLabel,
                                if (m.isAdmin) l10n.adminLabel,
                              ].join(' · '))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (canTransferTo)
                              IconButton(
                                icon: const Icon(Icons.workspace_premium_outlined),
                                tooltip: l10n.transferOwnershipTitle,
                                onPressed: () => _transferOwnership(m),
                              ),
                            if (!m.isAdmin)
                              IconButton(
                                icon: const Icon(Icons.admin_panel_settings_outlined),
                                tooltip: l10n.makeAdminTitle,
                                onPressed: () => _setHospitalAdmin(m, true),
                              ),
                            if (m.isAdmin && !isMe && !isOwner)
                              IconButton(
                                icon: const Icon(Icons.remove_moderator_outlined),
                                tooltip: l10n.removeAdminTitle,
                                onPressed: () => _setHospitalAdmin(m, false),
                              ),
                            if (!isMe && !m.isAdmin)
                              IconButton(
                                icon: const Icon(Icons.person_remove_outlined),
                                tooltip: l10n.removeMemberTooltip,
                                onPressed: () => _removeMember(m),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
              ),
            ),
    );
  }
}
