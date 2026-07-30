import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
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

/// Ficha mínima de una especialidad: instrumental de catálogo (filtro
/// cliente sobre el enum [Specialty]) + contenido del grupo con
/// `specialty_id` igual (documentos, bandejas, instrumental personalizado)
/// — cruza todos los espacios del usuario, mismo patrón de agregación que
/// `home_screen.dart`. Sin edición, se llega aquí tocando el chip de
/// especialidad en otra ficha.
class SpecialtyDetailScreen extends StatefulWidget {
  final SpecialtyEntity specialty;

  const SpecialtyDetailScreen({super.key, required this.specialty});

  @override
  State<SpecialtyDetailScreen> createState() => _SpecialtyDetailScreenState();
}

class _SpecialtyDetailScreenState extends State<SpecialtyDetailScreen> {
  bool _loading = true;
  List<GroupDocument> _documents = [];
  List<Tray> _trays = [];
  List<CustomInstrument> _customInstruments = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<Instrument> get _catalogInstruments =>
      kInstruments.where((i) => i.specialty.name == widget.specialty.slug).toList();

  Future<void> _load() async {
    try {
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
          documents.addAll(
              GroupDocumentService.instance.documentsOfKind(DocumentKind.technique, workspace.id));
          documents
              .addAll(GroupDocumentService.instance.documentsOfKind(DocumentKind.protocol, workspace.id));
          trays.addAll(TrayService.instance.traysOfWorkspace(workspace.id));
          customInstruments.addAll(CustomInstrumentService.instance.instruments);
        } catch (_) {
          // Un espacio fallando (sin acceso, sin conexión puntual) no debe
          // bloquear la agregación del resto de espacios.
        }
      }
      if (!mounted) return;
      setState(() {
        _documents = documents.where((d) => d.publishedVersion?.specialtyId == widget.specialty.id).toList();
        _trays = trays.where((t) => t.publishedVersion?.specialtyId == widget.specialty.id).toList();
        _customInstruments =
            customInstruments.where((c) => c.specialtyId == widget.specialty.id).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _openDocument(GroupDocument document) async {
    final myRole = await WorkspaceService.instance.fetchMyRole(document.workspaceId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GroupDocumentDetailScreen(document: document, myRole: myRole)),
    );
  }

  Future<void> _openTray(Tray tray) async {
    final myRole = await WorkspaceService.instance.fetchMyRole(tray.workspaceId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TrayDetailScreen(tray: tray, myRole: myRole)),
    );
  }

  Future<void> _openCustomInstrument(CustomInstrument instrument) async {
    final myRole = await WorkspaceService.instance.fetchMyRole(instrument.workspaceId);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CustomInstrumentDetailScreen(instrument: instrument, myRole: myRole),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(widget.specialty.label)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _section(
                  l10n.specialtySectionCatalog,
                  _catalogInstruments
                      .map((i) => Card(
                            child: ListTile(
                              title: Text(i.name),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => InstrumentDetailScreen(instrument: i)),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                _section(
                  l10n.specialtySectionDocuments,
                  _documents
                      .map((d) => Card(
                            child: ListTile(
                              title: Text(d.publishedVersion?.title ?? l10n.unpublished),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openDocument(d),
                            ),
                          ))
                      .toList(),
                ),
                _section(
                  l10n.specialtySectionTrays,
                  _trays
                      .map((t) => Card(
                            child: ListTile(
                              title: Text(t.publishedVersion?.name ?? l10n.unpublished),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openTray(t),
                            ),
                          ))
                      .toList(),
                ),
                _section(
                  l10n.specialtySectionCustomInstruments,
                  _customInstruments
                      .map((c) => Card(
                            child: ListTile(
                              title: Text(c.name),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _openCustomInstrument(c),
                            ),
                          ))
                      .toList(),
                ),
                if (_catalogInstruments.isEmpty &&
                    _documents.isEmpty &&
                    _trays.isEmpty &&
                    _customInstruments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(l10n.specialtyDetailEmptyState, textAlign: TextAlign.center),
                  ),
              ],
            ),
    );
  }
}
