import 'package:flutter/material.dart';

import '../design_system/components/instriq_version_diff.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument_sterilization.dart';
import '../widgets/sterilization_method_label.dart';

/// Comparación campo a campo entre dos versiones de un método de
/// esterilización. Delgado wrapper sobre [InstriqVersionDiff] — calcado de
/// [TrayDiffScreen]. No hay `sets` (los métodos de esterilización solo tienen
/// campos escalares, no listas de ítems).
class SterilizationMethodDiffScreen extends StatelessWidget {
  final SterilizationMethodVersion oldVersion;
  final SterilizationMethodVersion newVersion;

  const SterilizationMethodDiffScreen({
    super.key,
    required this.oldVersion,
    required this.newVersion,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.versionRangeTitle(oldVersion.versionNumber, newVersion.versionNumber)),
      ),
      body: InstriqVersionDiff<SterilizationMethodVersion>(
        older: oldVersion,
        newer: newVersion,
        noChangesLabel: l10n.noChanges,
        modifiedLabelOf: (itemDisplay) => l10n.modifiedChangeLabel(itemDisplay),
        fields: [
          FieldDiffDescriptor.text(
            label: l10n.sterilizationMethodLabel,
            valueOf: (v) => sterilizationMethodValueLabel(l10n, v.method),
          ),
          FieldDiffDescriptor.text(label: l10n.sterilizationTemperatureLabel, valueOf: (v) => v.temperature),
          FieldDiffDescriptor.text(label: l10n.sterilizationTimeLabel, valueOf: (v) => v.timeMinutes),
          FieldDiffDescriptor.text(label: l10n.sterilizationPressureLabel, valueOf: (v) => v.pressure),
          FieldDiffDescriptor.text(label: l10n.sterilizationDryingLabel, valueOf: (v) => v.drying),
          FieldDiffDescriptor.text(label: l10n.sterilizationRecommendedCycleLabel, valueOf: (v) => v.recommendedCycle),
          FieldDiffDescriptor.text(label: l10n.sterilizationCompatibilityLabel, valueOf: (v) => v.compatibilityNotes),
          FieldDiffDescriptor.text(label: l10n.sterilizationRestrictionsLabel, valueOf: (v) => v.restrictions),
          FieldDiffDescriptor.text(label: l10n.sterilizationObservationsLabel, valueOf: (v) => v.observations),
          FieldDiffDescriptor.boolean(
            label: l10n.lubricationRequiredLabel,
            valueOf: (v) => v.lubricationRequired,
          ),
          FieldDiffDescriptor.text(label: l10n.lubricationTypeLabel, valueOf: (v) => v.lubricationType),
          FieldDiffDescriptor.text(label: l10n.lubricationNotesLabel, valueOf: (v) => v.lubricationNotes),
        ],
        sets: const [],
      ),
    );
  }
}
