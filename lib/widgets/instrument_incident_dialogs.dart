/// Diálogos compartidos del flujo CAPA (reportar/resolver/verificar una
/// incidencia) -- antes duplicados casi verbatim en
/// `instrument_detail_screen.dart`/`custom_instrument_detail_screen.dart`;
/// extraídos aquí para no triplicarlos/cuadruplicarlos con la cola agregada
/// (`incident_capa_queue_screen.dart`) y el gancho desde una sesión de
/// preparación de bandeja (`tray_preparation_sessions_screen.dart`). Cada
/// función hace su propio try/catch + SnackBar, misma UX que antes.
library;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/instrument_incident.dart';
import '../services/instrument_incident_service.dart';
import 'instrument_incident_label.dart';

Future<void> showReportIncidentDialog(
  BuildContext context, {
  required String refType,
  required String refId,
  String? workspaceId,
  String? trayPreparationSessionId,
  required VoidCallback onDone,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final descriptionController = TextEditingController();
  IncidentSeverity severity = IncidentSeverity.low;
  final reported = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(l10n.reportIncidentDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: descriptionController,
              autofocus: true,
              maxLines: 3,
              onChanged: (_) => setDialogState(() {}),
              decoration: InputDecoration(
                labelText: l10n.incidentDescriptionLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text(l10n.incidentSeverityLabel, style: Theme.of(ctx).textTheme.labelMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: IncidentSeverity.values
                  .map((s) => ChoiceChip(
                        label: Text(incidentSeverityValueLabel(l10n, s)),
                        selected: severity == s,
                        onSelected: (_) => setDialogState(() => severity = s),
                      ))
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: descriptionController.text.trim().isEmpty ? null : () => Navigator.pop(ctx, true),
            child: Text(l10n.reportIncidentAction),
          ),
        ],
      ),
    ),
  );
  if (reported != true || !context.mounted) return;
  final description = descriptionController.text.trim();
  if (description.isEmpty) return;
  try {
    await InstrumentIncidentService.instance.report(
      refType: refType,
      refId: refId,
      workspaceId: workspaceId,
      severity: severity,
      description: description,
      trayPreparationSessionId: trayPreparationSessionId,
    );
    onDone();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
    }
  }
}

Future<void> showResolveIncidentDialog(
  BuildContext context,
  InstrumentIncident incident, {
  required VoidCallback onDone,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final rootCauseController = TextEditingController();
  final correctiveActionController = TextEditingController();
  final notesController = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: Text(l10n.resolveIncidentDialogTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: rootCauseController,
                autofocus: true,
                maxLines: 2,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.rootCauseLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: correctiveActionController,
                maxLines: 2,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(
                  labelText: l10n.correctiveActionLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: l10n.resolutionNotesLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: rootCauseController.text.trim().isEmpty || correctiveActionController.text.trim().isEmpty
                ? null
                : () => Navigator.pop(ctx, true),
            child: Text(l10n.resolveIncidentAction),
          ),
        ],
      ),
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    final notes = notesController.text.trim();
    await InstrumentIncidentService.instance.resolve(
      incident.id!,
      rootCause: rootCauseController.text.trim(),
      correctiveAction: correctiveActionController.text.trim(),
      resolutionNotes: notes.isEmpty ? null : notes,
    );
    onDone();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
    }
  }
}

Future<void> showVerifyIncidentDialog(
  BuildContext context,
  InstrumentIncident incident, {
  required VoidCallback onDone,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final notesController = TextEditingController();
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.verifyIncidentDialogTitle),
      content: TextField(
        controller: notesController,
        autofocus: true,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: l10n.verificationNotesLabel,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.verifyIncidentAction)),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    final notes = notesController.text.trim();
    await InstrumentIncidentService.instance.verify(incident.id!, verificationNotes: notes.isEmpty ? null : notes);
    onDone();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
    }
  }
}
