import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../design_system/components/instriq_responsive_content.dart';
import '../design_system/components/instriq_section_header.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/group_document.dart';
import '../models/preference_card.dart';
import '../models/procedure.dart';
import '../models/tray.dart';
import '../services/group_document_service.dart';
import '../services/preference_card_service.dart';
import '../services/procedure_service.dart';
import '../services/surgeon_service.dart';
import '../services/tray_service.dart';

enum ProcedureFormResult { saved, archived }

/// Crea o edita un procediment: nom, descripció i quin contingut publicat de
/// l'espai agrupa. Escriptura directa via RPC (sense versionat, decisió del
/// propietari); el servidor valida rol i que tot sigui del mateix espai.
class ProcedureFormScreen extends StatefulWidget {
  final String workspaceId;
  final Procedure? existing;

  const ProcedureFormScreen({super.key, required this.workspaceId, this.existing});

  @override
  State<ProcedureFormScreen> createState() => _ProcedureFormScreenState();
}

class _ProcedureFormScreenState extends State<ProcedureFormScreen> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  bool _loading = true;
  bool _saving = false;

  List<Tray> _trays = [];
  List<GroupDocument> _documents = [];
  List<PreferenceCard> _cards = [];

  // Ordre d'inserció = ordre de selecció (LinkedHashSet), que és l'ordre
  // en què es mostren a la pàgina del procediment.
  final Set<String> _trayIds = {};
  final Set<String> _documentIds = {};
  final Set<String> _cardIds = {};

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _description = TextEditingController(text: p?.description ?? '');
    if (p != null) {
      _trayIds.addAll(p.idsOf(ProcedureItemType.tray));
      _documentIds.addAll(p.idsOf(ProcedureItemType.groupDocument));
      _cardIds.addAll(p.idsOf(ProcedureItemType.preferenceCard));
    }
    _loadOptions();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    final ws = widget.workspaceId;
    await Future.wait([
      TrayService.instance.fetchTrays(ws),
      GroupDocumentService.instance.fetchDocuments(DocumentKind.technique, ws),
      GroupDocumentService.instance.fetchDocuments(DocumentKind.protocol, ws),
      PreferenceCardService.instance.fetchCards(ws),
      SurgeonService.instance.fetchForOrganization(),
    ]);
    _trays = TrayService.instance.traysOfWorkspace(ws).where((t) => t.publishedVersion != null).toList();
    _documents = [
      ...GroupDocumentService.instance.documentsOfKind(DocumentKind.technique, ws),
      ...GroupDocumentService.instance.documentsOfKind(DocumentKind.protocol, ws),
    ].where((d) => d.publishedVersion != null).toList();
    _cards = PreferenceCardService.instance.cardsOfWorkspace(ws).where((c) => c.publishedVersion != null).toList();
    if (mounted) setState(() => _loading = false);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final name = _name.text.trim();
    if (name.isEmpty) {
      _snack(l10n.procedureNameRequired);
      return;
    }
    setState(() => _saving = true);
    try {
      final procedure = await ProcedureService.instance.upsert(
        id: widget.existing?.id,
        workspaceId: widget.workspaceId,
        name: name,
        description: _description.text.trim().isEmpty ? null : _description.text.trim(),
        specialtyId: widget.existing?.specialtyId,
      );
      await ProcedureService.instance.setItems(procedure.id, [
        for (final id in _trayIds) ProcedureItem(type: ProcedureItemType.tray, itemId: id),
        for (final id in _documentIds) ProcedureItem(type: ProcedureItemType.groupDocument, itemId: id),
        for (final id in _cardIds) ProcedureItem(type: ProcedureItemType.preferenceCard, itemId: id),
      ]);
      if (mounted) Navigator.of(context).pop(ProcedureFormResult.saved);
    } on PostgrestException catch (e) {
      _snack(e.message);
    } catch (e) {
      _snack(l10n.genericError(e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _archive() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.procedureArchiveAction),
        content: Text(l10n.procedureArchiveConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.procedureArchiveAction)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ProcedureService.instance.archive(widget.existing!.id);
      if (mounted) Navigator.of(context).pop(ProcedureFormResult.archived);
    } on PostgrestException catch (e) {
      _snack(e.message);
    }
  }

  Widget _checklist<T>({
    required String title,
    required List<T> options,
    required Set<String> selected,
    required String Function(T) idOf,
    required String Function(T) labelOf,
    String? Function(T)? subtitleOf,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: InstriqSpacing.lg),
        InstriqSectionHeader(title),
        if (options.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: InstriqSpacing.sm),
            child: Text(l10n.procedureNoPublishedContent, style: Theme.of(context).textTheme.bodySmall),
          ),
        for (final option in options)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: selected.contains(idOf(option)),
            title: Text(labelOf(option)),
            subtitle: subtitleOf?.call(option) == null ? null : Text(subtitleOf!(option)!),
            onChanged: (checked) => setState(() {
              if (checked == true) {
                selected.add(idOf(option));
              } else {
                selected.remove(idOf(option));
              }
            }),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = widget.existing == null ? l10n.procedureNew : l10n.procedureEdit;
    if (_loading) {
      return Scaffold(appBar: AppBar(title: Text(title)), body: const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: InstriqResponsiveContent(
          child: ListView(
            padding: const EdgeInsets.all(InstriqSpacing.lg),
            children: [
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.procedureNameLabel, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: InstriqSpacing.md),
              TextField(
                controller: _description,
                minLines: 2,
                maxLines: 5,
                decoration:
                    InputDecoration(labelText: l10n.procedureDescriptionLabel, border: const OutlineInputBorder()),
              ),
              const SizedBox(height: InstriqSpacing.lg),
              Text(l10n.procedureLinkedContentHelp, style: Theme.of(context).textTheme.bodySmall),
              _checklist<Tray>(
                title: l10n.traysTitle,
                options: _trays,
                selected: _trayIds,
                idOf: (t) => t.id,
                labelOf: (t) => t.publishedVersion!.name,
              ),
              _checklist<GroupDocument>(
                title: l10n.procedureDocumentsSection,
                options: _documents,
                selected: _documentIds,
                idOf: (d) => d.id,
                labelOf: (d) => d.publishedVersion!.title,
                subtitleOf: (d) => d.kind == DocumentKind.technique ? l10n.techniquesTitle : l10n.protocolsTitle,
              ),
              _checklist<PreferenceCard>(
                title: l10n.preferenceCardsTitle,
                options: _cards,
                selected: _cardIds,
                idOf: (c) => c.id,
                labelOf: (c) => c.publishedVersion!.procedureName,
                subtitleOf: (c) => SurgeonService.instance.byId(c.publishedVersion!.surgeonId ?? '')?.name,
              ),
              const SizedBox(height: InstriqSpacing.xl),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.save),
              ),
              if (widget.existing != null) ...[
                const SizedBox(height: InstriqSpacing.md),
                OutlinedButton(onPressed: _saving ? null : _archive, child: Text(l10n.procedureArchiveAction)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
