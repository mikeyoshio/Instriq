import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/preference_card.dart';
import '../models/surgeon.dart';

/// Comparación campo a campo entre dos versiones de una tarjeta de
/// preferencia (cirujano, procedimiento, instrumental, notas generales,
/// validación por el cirujano). Calcado de [TrayDiffScreen].
class PreferenceCardDiffScreen extends StatelessWidget {
  final PreferenceCardVersion oldVersion;
  final PreferenceCardVersion newVersion;
  final List<Surgeon> surgeons;

  const PreferenceCardDiffScreen({
    super.key,
    required this.oldVersion,
    required this.newVersion,
    required this.surgeons,
  });

  String _surgeonName(String? id, AppLocalizations l10n) {
    if (id == null) return l10n.noSurgeonAssignedLabel;
    for (final s in surgeons) {
      if (s.id == id) return s.name;
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String itemKey(PreferenceCardItem i) => '${i.instrumentId ?? ''}:${i.customName}';
    final oldKeys = oldVersion.items.map(itemKey).toSet();
    final newKeys = newVersion.items.map(itemKey).toSet();
    final addedItems = newVersion.items.where((i) => !oldKeys.contains(itemKey(i))).toList();
    final removedItems = oldVersion.items.where((i) => !newKeys.contains(itemKey(i))).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.versionRangeTitle(oldVersion.versionNumber, newVersion.versionNumber)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _FieldDiff(
            label: l10n.surgeonLabel,
            oldValue: _surgeonName(oldVersion.surgeonId, l10n),
            newValue: _surgeonName(newVersion.surgeonId, l10n),
          ),
          _FieldDiff(
            label: l10n.procedureLabel,
            oldValue: oldVersion.procedureName,
            newValue: newVersion.procedureName,
          ),
          _FieldDiff(
            label: l10n.generalNotesLabel,
            oldValue: oldVersion.generalNotes ?? '—',
            newValue: newVersion.generalNotes ?? '—',
          ),
          _BoolFieldDiff(
            label: l10n.validatedBySurgeon,
            oldValue: oldVersion.validatedBySurgeon,
            newValue: newVersion.validatedBySurgeon,
          ),
          const SizedBox(height: 20),
          Text(l10n.instrumentsCountTitle(newVersion.items.length), style: Theme.of(context).textTheme.titleMedium),
          if (addedItems.isEmpty && removedItems.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l10n.noChanges)),
          ...addedItems.map((i) => _ChangeTile(icon: Icons.add, color: Colors.green, text: i.customName)),
          ...removedItems.map((i) => _ChangeTile(icon: Icons.remove, color: Colors.red, text: i.customName)),
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

class _BoolFieldDiff extends StatelessWidget {
  final String label;
  final bool oldValue;
  final bool newValue;

  const _BoolFieldDiff({required this.label, required this.oldValue, required this.newValue});

  Widget _icon(bool value) => Icon(
        value ? Icons.check_circle : Icons.cancel_outlined,
        color: value ? Colors.green : Colors.grey,
        size: 20,
      );

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
          Row(
            children: [
              _icon(oldValue),
              if (changed) ...[
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 16),
                const SizedBox(width: 8),
                _icon(newValue),
              ],
            ],
          ),
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
    return ListTile(leading: Icon(icon, color: color), title: Text(text), dense: true);
  }
}
