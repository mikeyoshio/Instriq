import 'package:flutter/material.dart';

import '../design_system/components/instriq_version_diff.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';

/// Comparación campo a campo entre dos versiones de un instrumento
/// personalizado. Delgado wrapper sobre [InstriqVersionDiff] — calcado de
/// [TrayDiffScreen], con las variantes como set (mismo criterio que los
/// items de una bandeja: una variante con el mismo id pero nombre/foto/nota
/// distinta se detecta como "Modificada", no como alta+baja).
class CustomInstrumentDiffScreen extends StatelessWidget {
  final CustomInstrumentVersion oldVersion;
  final CustomInstrumentVersion newVersion;

  const CustomInstrumentDiffScreen({
    super.key,
    required this.oldVersion,
    required this.newVersion,
  });

  String _variantFingerprint(CustomInstrumentVariant v) => '${v.name}|${v.note ?? ''}|${v.photoPath ?? ''}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.versionRangeTitle(oldVersion.versionNumber, newVersion.versionNumber)),
      ),
      body: InstriqVersionDiff<CustomInstrumentVersion>(
        older: oldVersion,
        newer: newVersion,
        noChangesLabel: l10n.noChanges,
        modifiedLabelOf: (itemDisplay) => l10n.modifiedChangeLabel(itemDisplay),
        fields: [
          FieldDiffDescriptor.text(label: l10n.customInstrumentNameLabel, valueOf: (v) => v.name),
          FieldDiffDescriptor.text(label: l10n.customInstrumentCategoryLabel, valueOf: (v) => v.category),
          FieldDiffDescriptor.text(label: l10n.customInstrumentSpecialtyLabel, valueOf: (v) => v.specialty),
          FieldDiffDescriptor.text(label: l10n.customInstrumentDescriptionLabel, valueOf: (v) => v.description),
          FieldDiffDescriptor.text(label: l10n.customInstrumentUseLabel, valueOf: (v) => v.useText),
          FieldDiffDescriptor.text(label: l10n.customInstrumentTipLabel, valueOf: (v) => v.tip),
        ],
        sets: [
          SetDiffDescriptor<CustomInstrumentVersion, CustomInstrumentVariant>(
            label: l10n.customInstrumentVariantsTitle,
            itemsOf: (v) => v.variants,
            keyOf: (variant) => variant.id,
            displayOf: (variant) => variant.name,
            fingerprintOf: _variantFingerprint,
          ),
        ],
      ),
    );
  }
}
