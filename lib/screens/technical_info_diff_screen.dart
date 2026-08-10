import 'package:flutter/material.dart';

import '../design_system/components/instriq_version_diff.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument_sterilization.dart';
import '../services/manufacturer_service.dart';
import '../services/reference_document_service.dart';

/// Comparación campo a campo entre dos versiones de la ficha técnica de un
/// instrumento. Delgado wrapper sobre [InstriqVersionDiff] — calcado de
/// [TrayDiffScreen]. A diferencia de [SterilizationMethodDiffScreen], necesita
/// resolver [InstrumentTechnicalInfoVersion.manufacturerId]/[ifuDocumentId]
/// (FKs) a un nombre visible antes de construir el diff, por eso es un
/// [StatefulWidget] en vez de un [StatelessWidget].
class TechnicalInfoDiffScreen extends StatefulWidget {
  final InstrumentTechnicalInfoVersion oldVersion;
  final InstrumentTechnicalInfoVersion newVersion;

  const TechnicalInfoDiffScreen({
    super.key,
    required this.oldVersion,
    required this.newVersion,
  });

  @override
  State<TechnicalInfoDiffScreen> createState() => _TechnicalInfoDiffScreenState();
}

class _TechnicalInfoDiffScreenState extends State<TechnicalInfoDiffScreen> {
  bool _loading = true;
  final Map<String, String> _manufacturerNames = {};
  final Map<String, String> _ifuTitles = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await ManufacturerService.instance.fetchAll();
    for (final manufacturerId in {widget.oldVersion.manufacturerId, widget.newVersion.manufacturerId}) {
      if (manufacturerId == null) continue;
      final manufacturer = ManufacturerService.instance.byId(manufacturerId);
      if (manufacturer != null) _manufacturerNames[manufacturerId] = manufacturer.name;
    }
    for (final ifuDocumentId in {widget.oldVersion.ifuDocumentId, widget.newVersion.ifuDocumentId}) {
      if (ifuDocumentId == null) continue;
      try {
        final doc = await ReferenceDocumentService.instance.fetchById(ifuDocumentId);
        if (doc != null) _ifuTitles[ifuDocumentId] = doc.title;
      } catch (_) {
        // Metadato accesorio: si falla, el diff cae al id crudo.
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.versionRangeTitle(widget.oldVersion.versionNumber, widget.newVersion.versionNumber)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : InstriqVersionDiff<InstrumentTechnicalInfoVersion>(
              older: widget.oldVersion,
              newer: widget.newVersion,
              noChangesLabel: l10n.noChanges,
              modifiedLabelOf: (itemDisplay) => l10n.modifiedChangeLabel(itemDisplay),
              fields: [
                FieldDiffDescriptor.text(
                  label: l10n.technicalManufacturerLabel,
                  valueOf: (v) => v.manufacturerId == null ? null : (_manufacturerNames[v.manufacturerId] ?? v.manufacturerId),
                ),
                FieldDiffDescriptor.text(
                  label: l10n.technicalIfuLabel,
                  valueOf: (v) => v.ifuDocumentId == null ? null : (_ifuTitles[v.ifuDocumentId] ?? v.ifuDocumentId),
                ),
                FieldDiffDescriptor.text(label: l10n.technicalMaintenanceLabel, valueOf: (v) => v.maintenanceNotes),
                FieldDiffDescriptor.text(label: l10n.technicalInspectionLabel, valueOf: (v) => v.inspectionNotes),
                FieldDiffDescriptor.text(label: l10n.technicalUsefulLifeLabel, valueOf: (v) => v.usefulLifeNotes),
                FieldDiffDescriptor.text(
                  label: l10n.technicalMaintenanceIntervalLabel,
                  valueOf: (v) => v.maintenanceIntervalDays?.toString(),
                ),
                FieldDiffDescriptor.text(
                  label: l10n.technicalLastMaintenanceLabel,
                  valueOf: (v) => v.lastMaintenanceAt == null ? null : _formatDate(v.lastMaintenanceAt!),
                ),
              ],
              sets: const [],
            ),
    );
  }
}
