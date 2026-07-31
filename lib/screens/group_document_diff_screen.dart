import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/group_document_version.dart';

/// Comparación campo a campo entre dos versiones: qué cambió, no un diff de
/// texto letra a letra. Suficiente para que un aprobador entienda de un
/// vistazo qué está aprobando.
class GroupDocumentDiffScreen extends StatelessWidget {
  final GroupDocumentVersion oldVersion;
  final GroupDocumentVersion newVersion;

  const GroupDocumentDiffScreen({super.key, required this.oldVersion, required this.newVersion});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final oldStepTexts = oldVersion.steps.map((s) => s.text).toSet();
    final newStepTexts = newVersion.steps.map((s) => s.text).toSet();
    final addedSteps = newVersion.steps.where((s) => !oldStepTexts.contains(s.text)).toList();
    final removedSteps = oldVersion.steps.where((s) => !newStepTexts.contains(s.text)).toList();
    final addedInstruments = newVersion.relatedInstrumentIds
        .where((s) => !oldVersion.relatedInstrumentIds.contains(s))
        .toList();
    final removedInstruments = oldVersion.relatedInstrumentIds
        .where((s) => !newVersion.relatedInstrumentIds.contains(s))
        .toList();
    final addedTrays =
        newVersion.relatedTrayIds.where((s) => !oldVersion.relatedTrayIds.contains(s)).toList();
    final removedTrays =
        oldVersion.relatedTrayIds.where((s) => !newVersion.relatedTrayIds.contains(s)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.versionRangeTitle(oldVersion.versionNumber, newVersion.versionNumber)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _FieldDiff(label: l10n.titleFieldLabel, oldValue: oldVersion.title, newValue: newVersion.title),
          _FieldDiff(
            label: l10n.specialtyLabel,
            oldValue: oldVersion.specialty ?? '—',
            newValue: newVersion.specialty ?? '—',
          ),
          _FieldDiff(
            label: l10n.descriptionLabel,
            oldValue: oldVersion.content ?? '—',
            newValue: newVersion.content ?? '—',
          ),
          const SizedBox(height: 20),
          Text(l10n.stepsLabel, style: Theme.of(context).textTheme.titleMedium),
          if (addedSteps.isEmpty && removedSteps.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l10n.noChanges)),
          ...addedSteps.map((s) => _ChangeTile(icon: Icons.add, color: Colors.green, text: s.text)),
          ...removedSteps.map((s) => _ChangeTile(icon: Icons.remove, color: Colors.red, text: s.text)),
          const SizedBox(height: 20),
          Text(l10n.relatedInstrumentsLabel, style: Theme.of(context).textTheme.titleMedium),
          if (addedInstruments.isEmpty && removedInstruments.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l10n.noChanges)),
          ...addedInstruments.map((s) => _ChangeTile(icon: Icons.add, color: Colors.green, text: s)),
          ...removedInstruments.map((s) => _ChangeTile(icon: Icons.remove, color: Colors.red, text: s)),
          const SizedBox(height: 20),
          Text(l10n.relatedTraysLabel, style: Theme.of(context).textTheme.titleMedium),
          if (addedTrays.isEmpty && removedTrays.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l10n.noChanges)),
          ...addedTrays.map((s) => _ChangeTile(icon: Icons.add, color: Colors.green, text: s)),
          ...removedTrays.map((s) => _ChangeTile(icon: Icons.remove, color: Colors.red, text: s)),
        ],
      ),
    );
  }
}

class _FieldDiff extends StatelessWidget {
  final String label;
  final String oldValue;
  final String newValue;

  const _FieldDiff({required this.label, required this.oldValue, required this.newValue});

  @override
  Widget build(BuildContext context) {
    final changed = oldValue != newValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          if (!changed)
            Text(newValue)
          else ...[
            Text(oldValue, style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.red)),
            Text(newValue, style: const TextStyle(color: Colors.green)),
          ],
        ],
      ),
    );
  }
}

class _ChangeTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _ChangeTile({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(text),
      dense: true,
    );
  }
}
