import 'package:flutter/material.dart';

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
    final addedSteps = newVersion.steps.where((s) => !oldVersion.steps.contains(s)).toList();
    final removedSteps = oldVersion.steps.where((s) => !newVersion.steps.contains(s)).toList();
    final addedInstruments = newVersion.relatedInstrumentIds
        .where((s) => !oldVersion.relatedInstrumentIds.contains(s))
        .toList();
    final removedInstruments = oldVersion.relatedInstrumentIds
        .where((s) => !newVersion.relatedInstrumentIds.contains(s))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Versión ${oldVersion.versionNumber} → ${newVersion.versionNumber}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _FieldDiff(label: 'Título', oldValue: oldVersion.title, newValue: newVersion.title),
          _FieldDiff(
            label: 'Especialidad',
            oldValue: oldVersion.specialty ?? '—',
            newValue: newVersion.specialty ?? '—',
          ),
          _FieldDiff(
            label: 'Descripción',
            oldValue: oldVersion.content ?? '—',
            newValue: newVersion.content ?? '—',
          ),
          const SizedBox(height: 20),
          Text('Pasos', style: Theme.of(context).textTheme.titleMedium),
          if (addedSteps.isEmpty && removedSteps.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Sin cambios')),
          ...addedSteps.map((s) => _ChangeTile(icon: Icons.add, color: Colors.green, text: s)),
          ...removedSteps.map((s) => _ChangeTile(icon: Icons.remove, color: Colors.red, text: s)),
          const SizedBox(height: 20),
          Text('Instrumental relacionado', style: Theme.of(context).textTheme.titleMedium),
          if (addedInstruments.isEmpty && removedInstruments.isEmpty)
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Sin cambios')),
          ...addedInstruments.map((s) => _ChangeTile(icon: Icons.add, color: Colors.green, text: s)),
          ...removedInstruments.map((s) => _ChangeTile(icon: Icons.remove, color: Colors.red, text: s)),
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
