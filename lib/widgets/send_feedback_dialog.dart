/// Diálogo de feedback/soporte desde la app (ver
/// `lib/services/feedback_service.dart` y
/// `supabase/schema_v56_app_feedback.sql`) -- mismo patrón que los diálogos
/// del flujo CAPA (`instrument_incident_dialogs.dart`): ChoiceChips +
/// TextField, try/catch propio con SnackBar.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/feedback_service.dart';

String _categoryLabel(AppLocalizations l10n, FeedbackCategory category) => switch (category) {
      FeedbackCategory.bug => l10n.feedbackCategoryBug,
      FeedbackCategory.suggestion => l10n.feedbackCategorySuggestion,
      FeedbackCategory.other => l10n.feedbackCategoryOther,
    };

Future<void> showSendFeedbackDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final messageController = TextEditingController();
  FeedbackCategory category = FeedbackCategory.suggestion;
  final send = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(l10n.sendFeedbackDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              children: FeedbackCategory.values
                  .map((c) => ChoiceChip(
                        label: Text(_categoryLabel(l10n, c)),
                        selected: category == c,
                        onSelected: (_) => setDialogState(() => category = c),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              autofocus: true,
              maxLines: 4,
              onChanged: (_) => setDialogState(() {}),
              decoration: InputDecoration(
                labelText: l10n.feedbackMessageLabel,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: messageController.text.trim().isEmpty ? null : () => Navigator.pop(ctx, true),
            child: Text(l10n.sendFeedbackAction),
          ),
        ],
      ),
    ),
  );
  if (send != true || !context.mounted) return;
  final message = messageController.text.trim();
  if (message.isEmpty) return;
  try {
    await FeedbackService.instance.submit(category: category, message: message);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.feedbackSentConfirmation)));
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
    }
  }
}
