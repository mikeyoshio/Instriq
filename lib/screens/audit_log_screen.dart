import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/audit_entry.dart';
import '../services/audit_service.dart';

/// Log de auditoría: quién hizo qué y cuándo sobre acciones sensibles del
/// grupo (aprobar/rechazar contenido, crear/borrar documentos, cambios de
/// rol, transferencia de propiedad). Solo accesible para admin/owner del
/// hospital (la RLS de `audit_log` ya lo garantiza en el servidor).
///
/// Pantalla standalone: de momento no está enlazada desde ninguna navegación
/// existente. Para abrirla:
/// `Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AuditLogScreen()));`
class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key, this.organizationId, this.workspaceId});

  final String? organizationId;
  final String? workspaceId;

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  bool _loading = true;
  String? _error;
  List<AuditEntry> _entries = [];

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
    try {
      _entries = await AuditService.instance.fetchAuditLog(
        organizationId: widget.organizationId,
        workspaceId: widget.workspaceId,
      );
    } catch (e) {
      if (mounted) _error = AppLocalizations.of(context)!.auditLogLoadError(e.toString());
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.auditLogTitle),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh), tooltip: l10n.refreshTooltip),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      Padding(padding: const EdgeInsets.all(24), child: Text(_error!)),
                    ],
                  )
                : _entries.isEmpty
                    ? ListView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(l10n.auditLogEmptyState),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: _entries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemBuilder: (context, index) => _AuditEntryTile(entry: _entries[index]),
                      ),
      ),
    );
  }
}

class _AuditEntryTile extends StatelessWidget {
  const _AuditEntryTile({required this.entry});

  final AuditEntry entry;

  static const _actionIcons = <String, IconData>{
    'document_version_approved': Icons.check_circle_outline,
    'document_version_rejected': Icons.cancel_outlined,
    'document_created': Icons.note_add_outlined,
    'document_deleted': Icons.delete_outline,
    'workspace_member_role_changed': Icons.manage_accounts_outlined,
    'hospital_ownership_transferred': Icons.swap_horiz,
    'user_signed_in': Icons.login,
  };

  String _actionLabel(AppLocalizations l10n) {
    switch (entry.action) {
      case 'user_signed_in':
        return l10n.auditActionUserSignedIn;
      case 'document_version_approved':
        return l10n.auditActionDocumentVersionApproved;
      case 'document_version_rejected':
        return l10n.auditActionDocumentVersionRejected;
      case 'document_created':
        return l10n.auditActionDocumentCreated;
      case 'document_deleted':
        return l10n.auditActionDocumentDeleted;
      case 'workspace_member_role_changed':
        return l10n.auditActionWorkspaceMemberRoleChanged;
      case 'hospital_ownership_transferred':
        return l10n.auditActionHospitalOwnershipTransferred;
      default:
        return entry.action;
    }
  }

  IconData get _icon => _actionIcons[entry.action] ?? Icons.history;

  /// Texto descriptivo de sobre qué entidad fue la acción, a partir de
  /// `metadata`/`entity_type`.
  String? _entityDescription(AppLocalizations l10n) {
    final metadata = entry.metadata;
    switch (entry.entityType) {
      case 'group_document_version':
        final title = metadata['title'] as String?;
        return (title != null && title.isNotEmpty) ? title : l10n.auditDocumentUntitledLabel;
      case 'group_document':
        final title = metadata['title'] as String?;
        final kind = metadata['kind'] as String?;
        final kindLabel =
            kind == 'protocol' ? l10n.auditKindProtocolLabel : (kind == 'technique' ? l10n.auditKindTechniqueLabel : null);
        if (title != null && title.isNotEmpty) return title;
        return kindLabel;
      case 'workspace_member':
        final previousRole = metadata['previous_role'] as String?;
        final newRole = metadata['new_role'] as String?;
        if (newRole == null) return l10n.auditAccessRemovedDescription(_roleLabel(l10n, previousRole));
        if (previousRole == null) return l10n.auditAssignedAsRoleDescription(_roleLabel(l10n, newRole));
        return l10n.auditRoleChangeDescription(_roleLabel(l10n, previousRole), _roleLabel(l10n, newRole));
      case 'hospital':
        return l10n.auditHospitalOwnerDescription;
      default:
        return null;
    }
  }

  String _roleLabel(AppLocalizations l10n, String? role) {
    switch (role) {
      case 'reader':
        return l10n.workspaceRoleReaderLabel;
      case 'editor':
        return l10n.workspaceRoleEditorLabel;
      case 'approver':
        return l10n.workspaceRoleApproverLabel;
      case 'administrator':
        return l10n.workspaceRoleAdministratorLabel;
      default:
        return l10n.auditNoRoleLabel;
    }
  }

  String _who(AppLocalizations l10n) =>
      entry.actorId == null ? l10n.deletedUserLabel : (entry.actorDisplayName ?? l10n.deletedUserLabel);

  String _when(AppLocalizations l10n, DateTime? createdAt) {
    if (createdAt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 1) return l10n.auditJustNowLabel;
    if (diff.inMinutes < 60) return l10n.auditMinutesAgoLabel(diff.inMinutes);
    if (diff.inHours < 24) return l10n.auditHoursAgoLabel(diff.inHours);
    if (diff.inDays < 7) return l10n.auditDaysAgoLabel(diff.inDays);
    return '${createdAt.day.toString().padLeft(2, '0')}/'
        '${createdAt.month.toString().padLeft(2, '0')}/'
        '${createdAt.year} '
        '${createdAt.hour.toString().padLeft(2, '0')}:'
        '${createdAt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final description = _entityDescription(l10n);
    return Card(
      child: ListTile(
        leading: Icon(_icon),
        title: Text(_actionLabel(l10n)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description != null) ...[
              const SizedBox(height: 2),
              Text(description),
            ],
            const SizedBox(height: 2),
            Text(
              '${_who(l10n)} · ${_when(l10n, entry.createdAt)}'
              '${entry.workspaceName != null ? ' · ${entry.workspaceName}' : ''}',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
        isThreeLine: description != null,
      ),
    );
  }
}
