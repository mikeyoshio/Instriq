import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../design_system/components/instriq_async_view.dart';
import '../design_system/components/instriq_entity_usage_list.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_instrument.dart';
import '../models/group_document.dart';
import '../models/instrument.dart';
import '../models/specialty_entity.dart';
import '../models/tray.dart';
import '../services/custom_instrument_service.dart';
import '../services/group_document_service.dart';
import '../services/tray_service.dart';
import '../services/workspace_service.dart';
import 'custom_instrument_detail_screen.dart';
import 'group_document_detail_screen.dart';
import 'instrument_detail_screen.dart';
import 'tray_detail_screen.dart';

/// Datos de uso de una especialidad ya agregados entre todos los espacios de
/// trabajo del usuario — todo salvo el instrumental de catálogo, que es
/// puramente cliente y no necesita fetch (ver [SpecialtyDetailScreen._catalogInstruments]).
class _SpecialtyUsageData {
  final List<GroupDocument> documents;
  final List<Tray> trays;
  final List<CustomInstrument> customInstruments;

  const _SpecialtyUsageData({
    required this.documents,
    required this.trays,
    required this.customInstruments,
  });
}

/// Ficha mínima de una especialidad: instrumental de catálogo (filtro
/// cliente sobre el enum [Specialty]) + contenido del grupo con
/// `specialty_id` igual (documentos, bandejas, instrumental personalizado)
/// — cruza todos los espacios del usuario, mismo patrón de agregación que
/// `home_screen.dart`. Sin edición, se llega aquí tocando el chip de
/// especialidad en otra ficha.
class SpecialtyDetailScreen extends StatelessWidget {
  final SpecialtyEntity specialty;

  const SpecialtyDetailScreen({super.key, required this.specialty});

  List<Instrument> get _catalogInstruments =>
      kInstruments.where((i) => i.specialty.name == specialty.slug).toList();

  Future<_SpecialtyUsageData> _load() async {
    await WorkspaceService.instance.fetchWorkspaces();
    final workspaces = WorkspaceService.instance.workspaces;
    final documents = <GroupDocument>[];
    final trays = <Tray>[];
    final customInstruments = <CustomInstrument>[];
    for (final workspace in workspaces) {
      try {
        await GroupDocumentService.instance.fetchDocuments(DocumentKind.technique, workspace.id);
        await GroupDocumentService.instance.fetchDocuments(DocumentKind.protocol, workspace.id);
        await TrayService.instance.fetchTrays(workspace.id);
        await CustomInstrumentService.instance.fetchForWorkspace(workspace.id);
        // Copia explícita inmediatamente después del fetch: a diferencia de
        // `documentsOfKind(kind, workspaceId)`/`traysOfWorkspace(workspaceId)`,
        // el getter `instruments` no toma `workspaceId` — solo refleja el
        // último workspace fetcheado. Sin esta copia, el resultado dependería
        // implícitamente del orden secuencial del bucle y dejaría el servicio
        // apuntando al último workspace como efecto lateral para cualquier
        // otra pantalla que lo lea después.
        final workspaceCustomInstruments = List.of(CustomInstrumentService.instance.instruments);
        documents.addAll(
            GroupDocumentService.instance.documentsOfKind(DocumentKind.technique, workspace.id));
        documents
            .addAll(GroupDocumentService.instance.documentsOfKind(DocumentKind.protocol, workspace.id));
        trays.addAll(TrayService.instance.traysOfWorkspace(workspace.id));
        customInstruments.addAll(workspaceCustomInstruments);
      } catch (_) {
        // Un espacio fallando (sin acceso, sin conexión puntual) no debe
        // bloquear la agregación del resto de espacios.
      }
    }
    return _SpecialtyUsageData(
      documents: documents.where((d) => d.publishedVersion?.specialtyId == specialty.id).toList(),
      trays: trays.where((t) => t.publishedVersion?.specialtyId == specialty.id).toList(),
      customInstruments:
          customInstruments.where((c) => c.specialtyId == specialty.id).toList(),
    );
  }

  Future<void> _openDocument(BuildContext context, GroupDocument document) async {
    final myRole = await WorkspaceService.instance.fetchMyRole(document.workspaceId);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GroupDocumentDetailScreen(document: document, myRole: myRole)),
    );
  }

  Future<void> _openTray(BuildContext context, Tray tray) async {
    final myRole = await WorkspaceService.instance.fetchMyRole(tray.workspaceId);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TrayDetailScreen(tray: tray, myRole: myRole)),
    );
  }

  Future<void> _openCustomInstrument(BuildContext context, CustomInstrument instrument) async {
    final myRole = await WorkspaceService.instance.fetchMyRole(instrument.workspaceId);
    if (!context.mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomInstrumentDetailScreen(instrument: instrument, myRole: myRole),
      ),
    );
  }

  IconData _documentIcon(GroupDocument document) {
    return document.kind == DocumentKind.technique ? Icons.menu_book_outlined : Icons.fact_check_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(specialty.label)),
      body: InstriqAsyncView<_SpecialtyUsageData>(
        load: _load,
        errorMessage: (error) => l10n.entityUsageLoadError(error.toString()),
        retryLabel: l10n.retry,
        isEmpty: (data) =>
            _catalogInstruments.isEmpty &&
            data.documents.isEmpty &&
            data.trays.isEmpty &&
            data.customInstruments.isEmpty,
        emptyBuilder: (context) => Center(child: Text(l10n.specialtyDetailEmptyState)),
        builder: (context, data) => InstriqEntityUsageList(
          sections: [
            EntityUsageSection(
              label: l10n.specialtySectionCatalog,
              rows: _catalogInstruments
                  .map((i) => EntityUsageRow(
                        icon: Icons.build_outlined,
                        title: i.name,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => InstrumentDetailScreen(instrument: i)),
                        ),
                      ))
                  .toList(),
            ),
            EntityUsageSection(
              label: l10n.specialtySectionDocuments,
              rows: data.documents
                  .map((d) => EntityUsageRow(
                        icon: _documentIcon(d),
                        title: d.publishedVersion?.title ?? l10n.unpublished,
                        onTap: () => _openDocument(context, d),
                      ))
                  .toList(),
            ),
            EntityUsageSection(
              label: l10n.specialtySectionTrays,
              rows: data.trays
                  .map((t) => EntityUsageRow(
                        icon: Icons.inventory_2_outlined,
                        title: t.publishedVersion?.name ?? l10n.unpublished,
                        onTap: () => _openTray(context, t),
                      ))
                  .toList(),
            ),
            EntityUsageSection(
              label: l10n.specialtySectionCustomInstruments,
              rows: data.customInstruments
                  .map((c) => EntityUsageRow(
                        icon: Icons.precision_manufacturing_outlined,
                        title: c.name,
                        onTap: () => _openCustomInstrument(context, c),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
