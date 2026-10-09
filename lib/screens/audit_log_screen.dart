import 'package:flutter/material.dart';

import '../design_system/components/instriq_responsive_content.dart';
import '../l10n/app_localizations.dart';
import '../models/audit_entry.dart';
import '../services/audit_service.dart';
import '../utils/audit_label.dart';

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
                    : InstriqResponsiveContent(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _entries.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 4),
                          itemBuilder: (context, index) => _AuditEntryTile(entry: _entries[index]),
                        ),
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
    'document_version_submitted': Icons.send_outlined,
    'document_created': Icons.note_add_outlined,
    'document_deleted': Icons.delete_outline,
    'document_duplicated': Icons.copy_outlined,
    'workspace_member_role_changed': Icons.manage_accounts_outlined,
    'hospital_ownership_transferred': Icons.swap_horiz,
    'hospital_admin_changed': Icons.admin_panel_settings_outlined,
    'user_signed_in': Icons.login,
    'preference_card_created': Icons.list_alt_outlined,
    'preference_card_version_submitted': Icons.send_outlined,
    'preference_card_version_approved': Icons.check_circle_outline,
    'preference_card_version_rejected': Icons.cancel_outlined,
    'preference_card_duplicated': Icons.copy_outlined,
    'custom_instrument_created': Icons.build_outlined,
    'custom_instrument_deleted': Icons.delete_outline,
    'custom_instrument_duplicated': Icons.copy_outlined,
    'custom_instrument_version_submitted': Icons.send_outlined,
    'custom_instrument_version_approved': Icons.check_circle_outline,
    'custom_instrument_version_rejected': Icons.cancel_outlined,
    'tray_created': Icons.inventory_2_outlined,
    'tray_duplicated': Icons.copy_outlined,
    'tray_adopted': Icons.download_outlined,
    'tray_stopped_following_upstream': Icons.link_off,
    'tray_updated_from_upstream': Icons.sync,
    'tray_version_submitted': Icons.send_outlined,
    'tray_version_approved': Icons.check_circle_outline,
    'tray_version_rejected': Icons.cancel_outlined,
    'tray_preparation_created': Icons.checklist_outlined,
    'tray_preparation_qc': Icons.fact_check_outlined,
    'sterilization_method_created': Icons.local_fire_department_outlined,
    'sterilization_method_version_submitted': Icons.send_outlined,
    'sterilization_method_version_approved': Icons.check_circle_outline,
    'sterilization_method_version_rejected': Icons.cancel_outlined,
    'sterilization_method_version_restored': Icons.restore,
    'technical_info_created': Icons.description_outlined,
    'technical_info_version_submitted': Icons.send_outlined,
    'technical_info_version_approved': Icons.check_circle_outline,
    'technical_info_version_rejected': Icons.cancel_outlined,
    'technical_info_version_restored': Icons.restore,
    'invitation_sent': Icons.mail_outline,
    'invitation_revoked': Icons.mail_lock_outlined,
    'invitation_accepted': Icons.mark_email_read_outlined,
    'community_photo_approved': Icons.check_circle_outline,
    'community_photo_rejected': Icons.cancel_outlined,
    'catalog_content_report_resolved': Icons.flag_outlined,
    'contributor_application_approved': Icons.check_circle_outline,
    'contributor_application_rejected': Icons.cancel_outlined,
    'contributor_level_changed': Icons.military_tech_outlined,
  };

  IconData get _icon => _actionIcons[entry.action] ?? Icons.history;

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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final description = auditEntityDescription(l10n, entry);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Icon(_icon, size: 18, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(auditActionLabel(l10n, entry), style: theme.textTheme.titleSmall),
                  if (description != null) ...[
                    const SizedBox(height: 2),
                    Text(description, style: theme.textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${_who(l10n)} · ${_when(l10n, entry.createdAt)}'
                    '${entry.workspaceName != null ? ' · ${entry.workspaceName}' : ''}',
                    style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
