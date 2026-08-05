import 'package:flutter/material.dart';

import '../design_system/components/instriq_version_diff.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/tray.dart';

/// Comparación campo a campo entre dos versiones de una bandeja. Delgado
/// wrapper sobre [InstriqVersionDiff] — calcado de [GroupDocumentDiffScreen].
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

  String _itemKey(TrayItem i) => '${i.instrumentRefType.dbValue}:${i.instrumentRefId}';

  /// Fingerprint de cantidad/posición: un ítem con la misma key (tipo+id de
  /// instrumento) pero distinto qty/posición entre versiones se detecta como
  /// "Modificado" en vez de desaparecer silenciosamente en "sin cambios"
  /// (bug antiguo: el diff solo miraba altas/bajas por tipo+id).
  String _itemFingerprint(TrayItem i) => '${i.expectedQty}|${i.position ?? ''}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.versionRangeTitle(oldVersion.versionNumber, newVersion.versionNumber)),
      ),
      body: InstriqVersionDiff<TrayVersion>(
        older: oldVersion,
        newer: newVersion,
        noChangesLabel: l10n.noChanges,
        modifiedLabelOf: (itemDisplay) => l10n.modifiedChangeLabel(itemDisplay),
        fields: [
          FieldDiffDescriptor.text(label: l10n.trayNameLabel, valueOf: (v) => v.name),
          FieldDiffDescriptor.text(label: l10n.specialtyLabel, valueOf: (v) => v.specialty),
          FieldDiffDescriptor.text(label: l10n.descriptionLabel, valueOf: (v) => v.description),
          FieldDiffDescriptor.text(label: l10n.trayObservationsLabel, valueOf: (v) => v.observations),
        ],
        sets: [
          SetDiffDescriptor<TrayVersion, TrayItem>(
            label: l10n.trayItemsLabel,
            itemsOf: (v) => v.items,
            keyOf: _itemKey,
            displayOf: (i) => '${i.resolveName(customInstruments)} (${l10n.expectedQtyValue(i.expectedQty)})',
            fingerprintOf: _itemFingerprint,
          ),
        ],
      ),
    );
  }
}
