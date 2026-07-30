import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/tray.dart';

/// Comparación campo a campo entre dos versiones de una bandeja. Calcado de
/// [GroupDocumentDiffScreen].
class TrayDiffScreen extends StatelessWidget {
  final TrayVersion oldVersion;
  final TrayVersion newVersion;
  final List<CustomInstrument> customInstruments;

  const TrayDiffScreen({
    super.key,
    required this.oldVersion,
    required this.newVersion,
    required this.customInstruments,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String itemKey(TrayItem i) => '${i.instrumentRefType.dbValue}:${i.instrumentRefId}';
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
          _FieldDiff(label: l10n.trayNameLabel, oldValue: oldVersion.name, newValue: newVersion.name),
          _FieldDiff(
            label: l10n.specialtyLabel,
            oldValue: oldVersion.specialty ?? '—',
            newValue: newVersion.specialty ?? '—',
          ),
          _FieldDiff(
            label: l10n.descriptionLabel,
            oldValue: oldVersion.description ?? '—',
            newValue: newVersion.description ?? '—',
          ),
          _FieldDiff(
            label: l10n.trayObservationsLabel,
            oldValue: oldVersion.observations ?? '—',
            newValue: newVersion.observations ?? '—',
          ),
          const SizedBox(height: 20),
          Text(l10n.trayItemsLabel, style: Theme.of(context).textTheme.titleMedium),
          if (addedItems.isEmpty && removedItems.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(l10n.noChanges)),
          ...addedItems.map((i) => _ChangeTile(
                icon: Icons.add,
                color: Colors.green,
                text: '${i.resolveName(customInstruments)} (${l10n.expectedQtyValue(i.expectedQty)})',
              )),
          ...removedItems.map((i) => _ChangeTile(
                icon: Icons.remove,
                color: Colors.red,
                text: '${i.resolveName(customInstruments)} (${l10n.expectedQtyValue(i.expectedQty)})',
              )),
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
    return ListTile(leading: Icon(icon, color: color), title: Text(text), dense: true);
  }
}
