import 'package:flutter/material.dart';

import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_responsive_content.dart';
import '../l10n/app_localizations.dart';
import '../services/profile_service.dart';
import 'audit_log_screen.dart';
import 'review_inbox_screen.dart';

/// Índice a cola de revisión y auditoría. La pestaña en sí es accesible para
/// `isAdmin || canApproveAnyWorkspace` (ver `canAccessActivity`), pero el
/// enlace a auditoría se muestra solo con `isAdmin`: `AuditLogScreen` es
/// admin/owner-only por RLS de servidor (ver audit_log_screen.dart), así que
/// un approver que no es admin de organización llegaría a un enlace muerto
/// si se le mostrara.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  Future<void> _openReviewQueue() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReviewInboxScreen()),
    );
    setState(() {});
  }

  Future<void> _openAuditLog() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AuditLogScreen(organizationId: ProfileService.instance.organizationId),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Misma condición combinada que app_shell.dart._visibleBranchIndices():
    // isAdmin o approver en algún espacio (workspace_members).
    final canAccessActivity =
        ProfileService.instance.isAdmin || ProfileService.instance.canApproveAnyWorkspace;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navActivity)),
      body: SafeArea(
        child: InstriqResponsiveContent(
        child: canAccessActivity
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InstriqListItem(
                      icon: Icons.rate_review_outlined,
                      title: l10n.reviewQueueTitle,
                      subtitle: l10n.reviewQueueSubtitle,
                      onTap: _openReviewQueue,
                    ),
                    if (ProfileService.instance.isAdmin) ...[
                      const SizedBox(height: 8),
                      InstriqListItem(
                        icon: Icons.history_outlined,
                        title: l10n.auditLogTitle,
                        subtitle: l10n.auditLogSubtitle,
                        onTap: _openAuditLog,
                      ),
                    ],
                  ],
                ),
              )
            : Center(child: Text(l10n.activityAdminOnly)),
        ),
      ),
    );
  }
}
