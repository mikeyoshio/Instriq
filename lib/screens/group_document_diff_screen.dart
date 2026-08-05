import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../design_system/components/instriq_version_diff.dart';
import '../l10n/app_localizations.dart';
import '../models/group_document_version.dart';
import '../services/tray_service.dart';

/// Comparación campo a campo entre dos versiones: qué cambió, no un diff de
/// texto letra a letra. Suficiente para que un aprobador entienda de un
/// vistazo qué está aprobando. Delgado wrapper sobre [InstriqVersionDiff].
class GroupDocumentDiffScreen extends StatelessWidget {
  final GroupDocumentVersion oldVersion;
  final GroupDocumentVersion newVersion;

  const GroupDocumentDiffScreen({super.key, required this.oldVersion, required this.newVersion});

  /// `related_instrument_ids` solo contiene ids de catálogo (el selector de
  /// la técnica solo ofrece catálogo — ver comentario en
  /// [GroupDocumentDetailScreen._loadClinicalWorkspaceData]), así que
  /// resolver contra [kInstruments] es el mismo mecanismo ya usado ahí y en
  /// [TrayItem.resolveName]. Si el id no se encuentra, fallback etiquetado
  /// en vez de un id crudo (bug antiguo de esta pantalla).
  String _resolveInstrumentName(String id, AppLocalizations l10n) {
    for (final instrument in kInstruments) {
      if (instrument.id == id) return instrument.name;
    }
    return l10n.unknownIdLabel(id);
  }

  /// Mismo mecanismo que usa la ficha de documento para mostrar bandejas
  /// relacionadas: [TrayService.trayById] lee del caché en memoria ya
  /// poblado por quien haya llamado a `fetchTrays` para el workspace (esta
  /// pantalla no recibe `workspaceId` — su constructor está fijado por los
  /// puntos de llamada existentes). Si la bandeja no está en caché, fallback
  /// etiquetado en vez de un id crudo.
  String _resolveTrayName(String id, AppLocalizations l10n) {
    final name = TrayService.instance.trayById(id)?.publishedVersion?.name;
    if (name != null && name.isNotEmpty) return name;
    return l10n.unknownIdLabel(id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.versionRangeTitle(oldVersion.versionNumber, newVersion.versionNumber)),
      ),
      body: InstriqVersionDiff<GroupDocumentVersion>(
        older: oldVersion,
        newer: newVersion,
        noChangesLabel: l10n.noChanges,
        modifiedLabelOf: (itemDisplay) => l10n.modifiedChangeLabel(itemDisplay),
        fields: [
          FieldDiffDescriptor.text(label: l10n.titleFieldLabel, valueOf: (v) => v.title),
          FieldDiffDescriptor.text(label: l10n.specialtyLabel, valueOf: (v) => v.specialty),
          FieldDiffDescriptor.text(label: l10n.descriptionLabel, valueOf: (v) => v.content),
        ],
        sets: [
          SetDiffDescriptor<GroupDocumentVersion, ProtocolStep>(
            label: l10n.stepsLabel,
            itemsOf: (v) => v.steps,
            keyOf: (s) => s.text,
            displayOf: (s) => s.text,
          ),
          SetDiffDescriptor<GroupDocumentVersion, String>(
            label: l10n.relatedInstrumentsLabel,
            itemsOf: (v) => v.relatedInstrumentIds,
            keyOf: (id) => id,
            displayOf: (id) => _resolveInstrumentName(id, l10n),
          ),
          SetDiffDescriptor<GroupDocumentVersion, String>(
            label: l10n.relatedTraysLabel,
            itemsOf: (v) => v.relatedTrayIds,
            keyOf: (id) => id,
            displayOf: (id) => _resolveTrayName(id, l10n),
          ),
        ],
      ),
    );
  }
}
