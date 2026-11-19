import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/catalog_content_report_service.dart';

/// "Reportar un error" en una fitxa del contingut compilat (instrumental,
/// postures, guies): va a la cua de l'Editorial Board, ver
/// supabase/schema_v45_catalog_content_reports.sql i schema_v73.
class ReportContentErrorButton extends StatelessWidget {
  final String refType;
  final String refId;

  const ReportContentErrorButton({super.key, required this.refType, required this.refId});

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final reported = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.reportContentErrorDialogTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            onChanged: (_) => setDialogState(() {}),
            decoration: InputDecoration(
              labelText: l10n.contentErrorDescriptionLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: controller.text.trim().isEmpty ? null : () => Navigator.pop(ctx, true),
              child: Text(l10n.reportContentErrorAction),
            ),
          ],
        ),
      ),
    );
    final description = controller.text.trim();
    controller.dispose();
    if (reported != true || description.isEmpty || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await CatalogContentReportService.instance.report(refType: refType, refId: refId, description: description);
      messenger.showSnackBar(SnackBar(content: Text(l10n.reportContentErrorSubmitSuccess)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (AuthService.instance.currentUser == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _open(context),
        icon: const Icon(Icons.flag_outlined, size: 18),
        label: Text(AppLocalizations.of(context)!.reportContentErrorAction),
      ),
    );
  }
}
