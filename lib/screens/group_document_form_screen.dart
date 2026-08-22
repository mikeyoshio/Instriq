import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../data/sutures_data.dart';
import '../l10n/app_localizations.dart';
import '../models/group_document.dart';
import '../models/group_document_version.dart';
import '../models/instrument.dart';
import '../models/specialty_entity.dart';
import '../models/suture.dart';
import '../models/tray.dart';
import '../services/connectivity_service.dart';
import '../services/group_document_service.dart';
import '../services/profile_service.dart';
import '../services/specialty_service.dart';
import '../services/tray_service.dart';
import '../widgets/catalog_picker_sheet.dart';
import '../widgets/category_icon.dart';
import '../widgets/suture_picker_sheet.dart';
import '../widgets/tag_picker.dart';
import '../widgets/tray_picker_sheet.dart';

/// Edita el borrador de una versión ([existingDraft]) o crea un documento
/// nuevo. Nunca edita directamente el contenido publicado: guardar solo
/// persiste el borrador, "Enviar a revisión" además dispara el workflow de
/// aprobación (ver GroupDocumentService).
class GroupDocumentFormScreen extends StatefulWidget {
  final DocumentKind kind;
  final String workspaceId;
  final GroupDocument? existingDocument;
  final GroupDocumentVersion? existingDraft;

  const GroupDocumentFormScreen({
    super.key,
    required this.kind,
    required this.workspaceId,
    this.existingDocument,
    this.existingDraft,
  });

  @override
  State<GroupDocumentFormScreen> createState() => _GroupDocumentFormScreenState();
}

class _GroupDocumentFormScreenState extends State<GroupDocumentFormScreen> {
  late final TextEditingController _titleController;
  String? _specialtyId;
  // Solo lectura: texto de la antigua columna `specialty`, se muestra como
  // pista cuando la fila todavía no se ha migrado a `specialty_id`.
  String? _legacySpecialtyText;
  List<SpecialtyEntity> _specialties = [];
  late final TextEditingController _contentController;
  late final TextEditingController _commentController;
  late List<ProtocolStep> _steps;
  late List<String> _relatedInstrumentIds;
  late List<String> _relatedTrayIds;
  late List<ConsumableItem> _consumables;
  late final TextEditingController _positioningController;
  late final TextEditingController _anesthesiaController;
  late List<String> _relatedSutureIds;
  GroupDocumentVersion? _draft;
  final _tagPickerKey = GlobalKey<TagPickerState>();
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _commentController = TextEditingController();
    _positioningController = TextEditingController();
    _anesthesiaController = TextEditingController();
    _steps = [];
    _relatedInstrumentIds = [];
    _relatedTrayIds = [];
    _consumables = [];
    _relatedSutureIds = [];
    _init();
  }

  Future<void> _init() async {
    try {
      // Especialidades y bandejas relacionadas son datos auxiliares para los
      // selectores del formulario, no el borrador en sí -- si fallan por
      // falta de red, no debe impedir crear/seguir editando el borrador (que
      // sí sabe encolarse sin conexión, ver GroupDocumentService). Antes
      // estaban en el mismo Future.wait que _loadDraft(): si cualquiera de
      // estos dos fallaba, Future.wait rechazaba entero y _applyDraft nunca
      // se llamaba, aunque el borrador real ya se hubiera creado/encolado.
      // Se capturan aparte para no abortar el _init entero; el picker
      // simplemente se queda con lo que ya hubiera en memoria (o vacío). Ver
      // la nota equivalente en TrayFormScreen._init.
      try {
        _specialties = await SpecialtyService.instance.fetchAll();
      } catch (e) {
        if (!ConnectivityService.isNetworkError(e)) rethrow;
      }
      try {
        await TrayService.instance.fetchTrays(widget.workspaceId);
      } catch (e) {
        if (!ConnectivityService.isNetworkError(e)) rethrow;
      }
      final draft = await _loadDraft();
      _applyDraft(draft);
    } catch (e) {
      setState(() => _error = AppLocalizations.of(context)!.formPrepareDraftError(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<GroupDocumentVersion> _loadDraft() async {
    if (widget.existingDraft != null) {
      return widget.existingDraft!;
    } else if (widget.existingDocument != null) {
      return GroupDocumentService.instance.startEditing(widget.existingDocument!);
    }
    return GroupDocumentService.instance.createDocument(widget.kind, widget.workspaceId);
  }

  void _applyDraft(GroupDocumentVersion draft) {
    _draft = draft;
    _titleController.text = draft.title;
    _specialtyId = draft.specialtyId;
    _legacySpecialtyText = draft.specialtyId == null ? draft.specialty : null;
    _contentController.text = draft.content ?? '';
    _steps = List.of(draft.steps);
    _relatedInstrumentIds = List.of(draft.relatedInstrumentIds);
    _relatedTrayIds = List.of(draft.relatedTrayIds);
    _consumables = List.of(draft.consumables);
    _positioningController.text = draft.patientPositioning ?? '';
    _anesthesiaController.text = draft.anesthesiaNotes ?? '';
    _relatedSutureIds = List.of(draft.relatedSutureIds);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _commentController.dispose();
    _positioningController.dispose();
    _anesthesiaController.dispose();
    super.dispose();
  }

  Instrument? _instrumentFor(String id) {
    for (final i in kInstruments) {
      if (i.id == id) return i;
    }
    return null;
  }

  Tray? _trayFor(String id) => TrayService.instance.trayById(id);

  Suture? _sutureFor(String id) {
    for (final s in kSutures) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<String> _stepCategorySuggestions(AppLocalizations l10n) => [
        l10n.stepCategoryPreop,
        l10n.stepCategoryAnesthesia,
        l10n.stepCategoryEquipment,
        l10n.stepCategoryInstruments,
        l10n.stepCategorySafety,
      ];

  Future<void> _addStep() async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final suggestions = _stepCategorySuggestions(l10n);
    const otherValue = '__other__';
    String? category;
    final otherController = TextEditingController();
    final step = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.addStepTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: controller, autofocus: true, maxLines: 3),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l10n.stepCategoryLabel,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem<String?>(value: null, child: Text(l10n.stepCategoryNone)),
                    ...suggestions.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s))),
                    DropdownMenuItem<String?>(value: otherValue, child: Text(l10n.stepCategoryOther)),
                  ],
                  onChanged: (value) => setDialogState(() => category = value),
                ),
                if (category == otherValue) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: otherController,
                    decoration: InputDecoration(
                      labelText: l10n.stepCategoryOtherFieldLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, controller.text.trim()),
              child: Text(l10n.addAction),
            ),
          ],
        ),
      ),
    );
    if (step != null && step.isNotEmpty) {
      final resolvedCategory = category == otherValue ? otherController.text.trim() : category;
      setState(() => _steps.add(ProtocolStep(
            category: (resolvedCategory == null || resolvedCategory.isEmpty) ? null : resolvedCategory,
            text: step,
          )));
    }
  }

  Future<void> _addInstrument() async {
    final selected = await showModalBottomSheet<Instrument>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CatalogPickerSheet(),
    );
    if (selected != null && !_relatedInstrumentIds.contains(selected.id)) {
      setState(() => _relatedInstrumentIds.add(selected.id));
    }
  }

  Future<void> _addTray() async {
    final selected = await showModalBottomSheet<Tray>(
      context: context,
      isScrollControlled: true,
      builder: (context) => TrayPickerSheet(workspaceId: widget.workspaceId),
    );
    if (selected != null && !_relatedTrayIds.contains(selected.id)) {
      setState(() => _relatedTrayIds.add(selected.id));
    }
  }

  Future<void> _addSuture() async {
    final selected = await showModalBottomSheet<Suture>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const SuturePickerSheet(),
    );
    if (selected != null && !_relatedSutureIds.contains(selected.id)) {
      setState(() => _relatedSutureIds.add(selected.id));
    }
  }

  Future<void> _addConsumable() async {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l10n.addConsumableTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                onChanged: (_) => setDialogState(() {}),
                decoration: InputDecoration(labelText: l10n.consumableNameLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(labelText: l10n.consumableQuantityLabel),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                decoration: InputDecoration(labelText: l10n.consumableNotesLabel),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
            FilledButton(
              onPressed: nameController.text.trim().isEmpty ? null : () => Navigator.pop(ctx, true),
              child: Text(l10n.addAction),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true && nameController.text.trim().isNotEmpty) {
      setState(() => _consumables.add(ConsumableItem(
            name: nameController.text.trim(),
            quantity: quantityController.text.trim().isEmpty ? null : quantityController.text.trim(),
            notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
          )));
    }
  }

  GroupDocumentVersion _draftWithFormValues() {
    final title = _titleController.text.trim();
    return _draft!.copyWith(
      title: title,
      specialtyId: _specialtyId,
      clearSpecialtyId: _specialtyId == null,
      content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
      clearContent: _contentController.text.trim().isEmpty,
      steps: _steps,
      relatedInstrumentIds: _relatedInstrumentIds,
      relatedTrayIds: _relatedTrayIds,
      consumables: _consumables,
      patientPositioning:
          _positioningController.text.trim().isEmpty ? null : _positioningController.text.trim(),
      clearPatientPositioning: _positioningController.text.trim().isEmpty,
      anesthesiaNotes: _anesthesiaController.text.trim().isEmpty ? null : _anesthesiaController.text.trim(),
      clearAnesthesiaNotes: _anesthesiaController.text.trim().isEmpty,
      relatedSutureIds: _relatedSutureIds,
      comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
    );
  }

  Future<void> _saveDraft({bool andSubmit = false}) async {
    final l10n = AppLocalizations.of(context)!;
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = l10n.titleRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final wasOffline = !ConnectivityService.instance.isOnline.value;
      final updated = await GroupDocumentService.instance.saveDraft(_draftWithFormValues());
      await _tagPickerKey.currentState?.save();
      if (andSubmit) {
        await GroupDocumentService.instance.submitForReview(updated.id);
      }
      if (mounted) {
        if (wasOffline) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.savedOfflineSnackbar)));
          await Future.delayed(const Duration(milliseconds: 900));
        }
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _error = l10n.saveError(e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildSpecialtyDropdown(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          initialValue: _specialtyId,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: l10n.specialtyLabel,
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem<String?>(value: null, child: Text(l10n.noSpecialty)),
            ..._specialties.map((s) => DropdownMenuItem<String?>(value: s.id, child: Text(s.label))),
          ],
          onChanged: (value) => setState(() => _specialtyId = value),
        ),
        if (_legacySpecialtyText != null && _legacySpecialtyText!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            l10n.legacySpecialtySuffix(_legacySpecialtyText!),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final kindLabel = widget.kind.label;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(kindLabel)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_draft == null) {
      return Scaffold(
        appBar: AppBar(title: Text(kindLabel)),
        body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error ?? l10n.errorLabel))),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editDraftAppBarTitle(kindLabel))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: l10n.titleFieldLabel, border: const OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            _buildSpecialtyDropdown(l10n),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: l10n.descriptionLabel,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(l10n.stepsLabel, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addStep,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addStepTitle),
                ),
              ],
            ),
            if (_steps.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.noStepsYet),
              ),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _steps.length,
              onReorderItem: (oldIndex, newIndex) {
                setState(() {
                  final step = _steps.removeAt(oldIndex);
                  _steps.insert(newIndex, step);
                });
              },
              itemBuilder: (context, index) {
                final step = _steps[index];
                return ListTile(
                  key: ValueKey('step_${index}_${step.category}_${step.text}'),
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(step.text),
                  subtitle: step.category != null ? Text(step.category!) : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    tooltip: l10n.removeStepTooltip,
                    onPressed: () => setState(() => _steps.removeAt(index)),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(l10n.relatedInstrumentsLabel, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addInstrument,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addAction),
                ),
              ],
            ),
            if (_relatedInstrumentIds.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.noInstrumentsLinked),
              ),
            ..._relatedInstrumentIds.map((id) {
              final instrument = _instrumentFor(id);
              return ListTile(
                leading: instrument != null
                    ? InstrumentIcon(iconKey: instrument.icon, category: instrument.category, size: 36)
                    : const Icon(Icons.build_outlined),
                title: Text(instrument?.name ?? id),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.removeRelatedInstrumentTooltip,
                  onPressed: () => setState(() => _relatedInstrumentIds.remove(id)),
                ),
              );
            }),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(l10n.relatedTraysLabel, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addTray,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addAction),
                ),
              ],
            ),
            if (_relatedTrayIds.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.noTraysLinked),
              ),
            ..._relatedTrayIds.map((id) {
              final tray = _trayFor(id);
              return ListTile(
                leading: const Icon(Icons.inventory_2_outlined),
                title: Text(tray?.publishedVersion?.name ?? id),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.removeRelatedTrayTooltip,
                  onPressed: () => setState(() => _relatedTrayIds.remove(id)),
                ),
              );
            }),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(l10n.relatedSuturesLabel, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addSuture,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addAction),
                ),
              ],
            ),
            if (_relatedSutureIds.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.noSuturesLinked),
              ),
            ..._relatedSutureIds.map((id) {
              final suture = _sutureFor(id);
              return ListTile(
                leading: const Icon(Icons.line_style),
                title: Text(suture?.name ?? id),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.removeRelatedSutureTooltip,
                  onPressed: () => setState(() => _relatedSutureIds.remove(id)),
                ),
              );
            }),
            const SizedBox(height: 20),
            Row(
              children: [
                Text(l10n.consumablesLabel, style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: _addConsumable,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addAction),
                ),
              ],
            ),
            if (_consumables.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(l10n.noConsumablesYet),
              ),
            ..._consumables.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return ListTile(
                leading: const Icon(Icons.inventory_outlined),
                title: Text(item.quantity == null || item.quantity!.isEmpty
                    ? item.name
                    : '${item.name} · ${item.quantity}'),
                subtitle: item.notes != null && item.notes!.isNotEmpty ? Text(item.notes!) : null,
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.removeConsumableTooltip,
                  onPressed: () => setState(() => _consumables.removeAt(index)),
                ),
              );
            }),
            const SizedBox(height: 20),
            TextField(
              controller: _positioningController,
              decoration: InputDecoration(
                labelText: l10n.patientPositioningLabel,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _anesthesiaController,
              decoration: InputDecoration(
                labelText: l10n.anesthesiaNotesLabel,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            Text(l10n.tagsLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TagPicker(
              key: _tagPickerKey,
              refType: 'group_document',
              refId: _draft!.documentId,
              organizationId: ProfileService.instance.organizationId,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _commentController,
              decoration: InputDecoration(
                labelText: l10n.changeCommentLabel,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 2,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : () => _saveDraft(andSubmit: true),
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l10n.submitForReview),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _saving ? null : () => _saveDraft(),
              child: Text(l10n.saveAsDraft),
            ),
          ],
        ),
      ),
    );
  }
}
