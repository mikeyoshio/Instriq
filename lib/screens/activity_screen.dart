import 'package:flutter/material.dart';

import '../design_system/components/instriq_list_item.dart';
import '../l10n/app_localizations.dart';
import '../services/profile_service.dart';
import 'audit_log_screen.dart';
import 'group_document_review_queue_screen.dart';

/// Índice a auditoría y cola de revisión — ambas ya gateadas por admin igual
/// que antes en `home_screen.dart` (la RLS de servidor lo garantiza además
/// para auditoría, ver audit_log_screen.dart).
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  Future<void> _openReviewQueue() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ReviewQueueScreen()),
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
    final isAdmin = ProfileService.instance.isAdmin;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navActivity)),
      body: SafeArea(
        child: isAdmin
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
                    const SizedBox(height: 8),
                    InstriqListItem(
                      icon: Icons.history_outlined,
                      title: l10n.auditLogTitle,
                      subtitle: l10n.auditLogSubtitle,
                      onTap: _openAuditLog,
                    ),
                  ],
                ),
              )
            : Center(child: Text(l10n.activityAdminOnly)),
      ),
    );
  }
}
