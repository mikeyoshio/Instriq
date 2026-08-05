import 'package:flutter/material.dart';

import '../design_system/components/instriq_version_diff.dart';
import '../l10n/app_localizations.dart';
import '../models/preference_card.dart';
import '../models/surgeon.dart';

/// Comparación campo a campo entre dos versiones de una tarjeta de
/// preferencia (cirujano, procedimiento, instrumental, notas generales,
/// validación por el cirujano). Delgado wrapper sobre [InstriqVersionDiff] —
/// calcado de [TrayDiffScreen].
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

  String _itemKey(PreferenceCardItem i) => '${i.instrumentId ?? ''}:${i.customName}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.versionRangeTitle(oldVersion.versionNumber, newVersion.versionNumber)),
      ),
      body: InstriqVersionDiff<PreferenceCardVersion>(
        older: oldVersion,
        newer: newVersion,
        noChangesLabel: l10n.noChanges,
        modifiedLabelOf: (itemDisplay) => l10n.modifiedChangeLabel(itemDisplay),
        fields: [
          FieldDiffDescriptor.text(
            label: l10n.surgeonLabel,
            valueOf: (v) => _surgeonName(v.surgeonId, l10n),
          ),
          FieldDiffDescriptor.text(label: l10n.procedureLabel, valueOf: (v) => v.procedureName),
          FieldDiffDescriptor.text(label: l10n.generalNotesLabel, valueOf: (v) => v.generalNotes),
          FieldDiffDescriptor.boolean(
            label: l10n.validatedBySurgeon,
            valueOf: (v) => v.validatedBySurgeon,
          ),
        ],
        sets: [
          SetDiffDescriptor<PreferenceCardVersion, PreferenceCardItem>(
            label: l10n.instrumentsCountTitle(newVersion.items.length),
            itemsOf: (v) => v.items,
            keyOf: _itemKey,
            displayOf: (i) => i.customName,
          ),
        ],
      ),
    );
  }
}
