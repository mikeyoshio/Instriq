/// Fuente de información + validación clínica sobre contenido privado (ver
/// `lib/services/content_trust_service.dart` y
/// `supabase/schema_v58_content_trust_metadata.sql`). Un único diálogo con
/// las 2 acciones porque comparten contexto (mismo refType/refId) y el
/// usuario normalmente mira las dos cosas a la vez, no una sin la otra.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/content_trust_service.dart';

// Sin `package:intl` a propósito (mismo motivo que pdf_export.dart: no es
// una dependencia directa del pubspec, solo transitiva vía
// flutter_localizations -- importarla aquí dispara el lint
// depend_on_referenced_packages).
String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}

Future<void> showContentTrustDialog(
  BuildContext context, {
  required String refType,
  required String refId,
  required String? currentSourceReference,
  required DateTime? clinicallyReviewedAt,
  required String? clinicalReviewNotes,
  required bool canEditSource,
  required bool canMarkReviewed,
  required VoidCallback onDone,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final sourceController = TextEditingController(text: currentSourceReference ?? '');
  final notesController = TextEditingController();
  var changed = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(l10n.contentTrustDialogTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.sourceReferenceLabel, style: Theme.of(ctx).textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: sourceController,
                enabled: canEditSource,
                maxLines: 2,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              if (canEditSource) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await ContentTrustService.instance.setSourceReference(
                        refType: refType,
                        refId: refId,
                        sourceReference: sourceController.text.trim().isEmpty ? null : sourceController.text.trim(),
                      );
                      changed = true;
                    },
                    child: Text(l10n.saveAction),
                  ),
                ),
              ],
              const Divider(height: 32),
              Text(l10n.clinicalReviewLabel, style: Theme.of(ctx).textTheme.labelLarge),
              const SizedBox(height: 8),
              Text(
                clinicallyReviewedAt != null
                    ? l10n.clinicallyReviewedOn(_formatDate(clinicallyReviewedAt))
                    : l10n.notYetClinicallyReviewedLabel,
              ),
              if (clinicalReviewNotes != null && clinicalReviewNotes.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(clinicalReviewNotes, style: Theme.of(ctx).textTheme.bodySmall),
              ],
              if (canMarkReviewed) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l10n.clinicalReviewNotesLabel, border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: () async {
                      await ContentTrustService.instance.markClinicallyReviewed(
                        refType: refType,
                        refId: refId,
                        notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                      );
                      changed = true;
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(l10n.markClinicallyReviewedAction),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
        ],
      ),
    ),
  );
  if (changed) onDone();
}
