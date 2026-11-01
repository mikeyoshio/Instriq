import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../design_system/components/instriq_responsive_content.dart';
import '../l10n/app_localizations.dart';
import '../models/group_document.dart';
import '../models/preference_card.dart';
import '../models/surgeon.dart';
import '../models/surgical_slot.dart';
import '../models/tray.dart';
import '../models/workspace_role.dart';
import '../services/group_document_service.dart';
import '../services/preference_card_service.dart';
import '../services/surgeon_service.dart';
import '../services/surgical_slot_service.dart';
import '../services/tray_service.dart';
import 'group_document_detail_screen.dart';
import 'preference_card_detail_screen.dart';
import 'tray_detail_screen.dart';

/// Crea, edita o muestra (solo lectura) un hueco de agenda quirúrgica. Una
/// sola pantalla para los 3 modos -- igual criterio que
/// [PreferenceCardFormScreen]: sin versionado que justifique una vista de
/// detalle separada (ver `kind-spinning-comet.md`).
///
/// Cuando el slot enlaza una tarjeta de preferencia/técnica-protocolo/
/// bandeja, cada uno se muestra como un elemento pulsable que navega a su
/// ficha real: el instrumentista necesita ver el material de verdad, no solo
/// una etiqueta en un desplegable deshabilitado.
class SurgicalSlotFormScreen extends StatefulWidget {
  final String workspaceId;
  final SurgicalSlot? existingSlot; // null = crear, no-null = editar/ver
  final WorkspaceRole? myRole;

  const SurgicalSlotFormScreen({
    super.key,
    required this.workspaceId,
    this.existingSlot,
    required this.myRole,
  });

  @override
  State<SurgicalSlotFormScreen> createState() => _SurgicalSlotFormScreenState();
}

class _SurgicalSlotFormScreenState extends State<SurgicalSlotFormScreen> {
  final TextEditingController _surgeonFieldController = TextEditingController();
  late final TextEditingController _procedureController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;

  String? _selectedSurgeonId;
  String? _selectedPreferenceCardId;
  String? _selectedDocumentId;
  String? _selectedTrayId;
  DateTime? _startsAt;
  DateTime? _endsAt;

  bool _loading = true;
  bool _saving = false;

  List<PreferenceCard> _preferenceCards = [];
  List<GroupDocument> _documents = [];
  List<Tray> _trays = [];

  bool get isEditing => widget.existingSlot != null;
  bool get canEdit => widget.myRole?.canEdit == true;

  @override
  void initState() {
    super.initState();
    final slot = widget.existingSlot;
    _procedureController = TextEditingController(text: slot?.procedureName ?? '');
    _locationController = TextEditingController(text: slot?.location ?? '');
    _notesController = TextEditingController(text: slot?.notes ?? '');
    _selectedPreferenceCardId = slot?.preferenceCardId;
    _selectedDocumentId = slot?.documentId;
    _selectedTrayId = slot?.trayId;
    _startsAt = slot?.startsAt;
    _endsAt = slot?.endsAt;
    _loadOptions();
  }

  @override
  void dispose() {
    _surgeonFieldController.dispose();
    _procedureController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    await Future.wait([
      SurgeonService.instance.fetchForOrganization(),
      PreferenceCardService.instance.fetchCards(widget.workspaceId),
      GroupDocumentService.instance.fetchDocuments(DocumentKind.technique, widget.workspaceId),
      GroupDocumentService.instance.fetchDocuments(DocumentKind.protocol, widget.workspaceId),
      TrayService.instance.fetchTrays(widget.workspaceId),
    ]);
    final slot = widget.existingSlot;
    if (slot != null) {
      final surgeon = SurgeonService.instance.byId(slot.surgeonId);
      _selectedSurgeonId = slot.surgeonId;
      _surgeonFieldController.text = surgeon?.name ?? '';
    }
    _preferenceCards =
        PreferenceCardService.instance.cardsOfWorkspace(widget.workspaceId).where((c) => c.publishedVersion != null).toList();
    _documents = [
      ...GroupDocumentService.instance.documentsOfKind(DocumentKind.technique, widget.workspaceId),
      ...GroupDocumentService.instance.documentsOfKind(DocumentKind.protocol, widget.workspaceId),
    ].where((d) => d.publishedVersion != null).toList();
    _trays = TrayService.instance.traysOfWorkspace(widget.workspaceId).where((t) => t.publishedVersion != null).toList();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initial = (isStart ? _startsAt : _endsAt) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(initial.year - 5),
      lastDate: DateTime(initial.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null || !mounted) return;
    final combined = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startsAt = combined;
      } else {
        _endsAt = combined;
      }
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedSurgeonId == null || _startsAt == null || _endsAt == null) {
      _showSnackBar(l10n.errorLabel);
      return;
    }
    if (!_endsAt!.isAfter(_startsAt!)) {
      _showSnackBar(l10n.errorLabel);
      return;
    }
    setState(() => _saving = true);
    try {
      if (isEditing) {
        await SurgicalSlotService.instance.updateSlot(
          slotId: widget.existingSlot!.id,
          surgeonId: _selectedSurgeonId!,
          startsAt: _startsAt!,
          endsAt: _endsAt!,
          preferenceCardId: _selectedPreferenceCardId,
          documentId: _selectedDocumentId,
          trayId: _selectedTrayId,
          procedureName: _emptyToNull(_procedureController.text),
          location: _emptyToNull(_locationController.text),
          notes: _emptyToNull(_notesController.text),
        );
      } else {
        await SurgicalSlotService.instance.createSlot(
          workspaceId: widget.workspaceId,
          surgeonId: _selectedSurgeonId!,
          startsAt: _startsAt!,
          endsAt: _endsAt!,
          preferenceCardId: _selectedPreferenceCardId,
          documentId: _selectedDocumentId,
          trayId: _selectedTrayId,
          procedureName: _emptyToNull(_procedureController.text),
          location: _emptyToNull(_locationController.text),
          notes: _emptyToNull(_notesController.text),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on PostgrestException catch (e) {
      _showSnackBar(e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _emptyToNull(String value) => value.trim().isEmpty ? null : value.trim();

  Future<void> _confirmCancelSlot() async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    // Mismo patrón que el diálogo de QC en tray_preparation_sessions_screen.dart:
    // el diálogo solo recoge la confirmación y se cierra con Navigator.pop(ctx, _);
    // la llamada de red se hace después, ya sin el diálogo de por medio.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.surgicalSlotCancelConfirmTitle),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(labelText: l10n.surgicalSlotCancelReasonLabel, border: const OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.surgicalSlotCancelSlotAction)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await SurgicalSlotService.instance.cancelSlot(widget.existingSlot!.id, reason: _emptyToNull(reasonController.text));
    } on PostgrestException catch (e) {
      _showSnackBar(e.message);
      return;
    }
    // Pop #1 ya ocurrió al cerrar el diálogo arriba; pop #2 cierra esta
    // pantalla y vuelve a la lista con `true` para que refresque.
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(isEditing ? l10n.surgicalSlotFormTitleEdit : l10n.surgicalSlotFormTitleCreate)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final slot = widget.existingSlot;
    final canCancelSlot = canEdit && isEditing && slot!.status != SurgicalSlotStatus.cancelled;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? l10n.surgicalSlotFormTitleEdit : l10n.surgicalSlotFormTitleCreate)),
      body: SafeArea(
        child: InstriqResponsiveContent(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildSurgeonField(l10n),
              const SizedBox(height: 12),
              _buildDateTimeRow(isStart: true, value: _startsAt, label: l10n.surgicalSlotStartLabel),
              const SizedBox(height: 12),
              _buildDateTimeRow(isStart: false, value: _endsAt, label: l10n.surgicalSlotEndLabel),
              const SizedBox(height: 12),
              _buildTextField(_procedureController, l10n.surgicalSlotProcedureLabel),
              const SizedBox(height: 12),
              _buildTextField(_locationController, l10n.surgicalSlotLocationLabel),
              const SizedBox(height: 12),
              _buildPreferenceCardField(l10n),
              const SizedBox(height: 12),
              _buildDocumentField(l10n),
              const SizedBox(height: 12),
              _buildTrayField(l10n),
              const SizedBox(height: 12),
              _buildNotesField(l10n),
              const SizedBox(height: 24),
              if (canEdit)
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(l10n.surgicalSlotSaveAction),
                ),
              if (canCancelSlot) ...[
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _confirmCancelSlot, child: Text(l10n.surgicalSlotCancelSlotAction)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurgeonField(AppLocalizations l10n) {
    if (!canEdit) {
      return TextField(
        controller: _surgeonFieldController,
        enabled: false,
        decoration: InputDecoration(labelText: l10n.surgicalSlotSurgeonLabel, border: const OutlineInputBorder()),
      );
    }
    return Autocomplete<Surgeon>(
      optionsBuilder: (value) {
        if (value.text.trim().isEmpty) return const Iterable<Surgeon>.empty();
        return SurgeonService.instance.searchByName(value.text);
      },
      displayStringForOption: (s) => s.name,
      initialValue: TextEditingValue(text: _surgeonFieldController.text),
      onSelected: (s) {
        _selectedSurgeonId = s.id;
        _surgeonFieldController.text = s.name;
      },
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: l10n.surgicalSlotSurgeonLabel, border: const OutlineInputBorder()),
          onChanged: (value) {
            _surgeonFieldController.text = value;
            final cached = _selectedSurgeonId == null ? null : SurgeonService.instance.byId(_selectedSurgeonId!);
            if (cached != null && cached.name != value) {
              _selectedSurgeonId = null;
            }
          },
        );
      },
    );
  }

  Widget _buildDateTimeRow({required bool isStart, required DateTime? value, required String label}) {
    final text = value == null ? '—' : '${value.day}/${value.month}/${value.year} ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: canEdit ? () => _pickDateTime(isStart: isStart) : null,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        child: Text(text),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      enabled: canEdit,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }

  Widget _buildNotesField(AppLocalizations l10n) {
    return TextField(
      controller: _notesController,
      enabled: canEdit,
      maxLines: 4,
      minLines: 2,
      decoration: InputDecoration(
        labelText: l10n.surgicalSlotNotesLabel,
        helperText: l10n.surgicalSlotNotesWarning,
        helperMaxLines: 2,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPreferenceCardField(AppLocalizations l10n) {
    return _buildLinkedField<PreferenceCard>(
      label: l10n.surgicalSlotPreferenceCardLabel,
      selectedId: _selectedPreferenceCardId,
      options: _preferenceCards,
      idOf: (c) => c.id,
      nameOf: (c) => c.publishedVersion?.procedureName ?? '',
      findById: PreferenceCardService.instance.cardById,
      onChanged: (id) => setState(() => _selectedPreferenceCardId = id),
      viewLabel: l10n.surgicalSlotViewPreferenceCard,
      notAvailableLabel: l10n.surgicalSlotLinkedNotAvailable,
      onView: (card) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PreferenceCardDetailScreen(card: card, myRole: widget.myRole)),
      ),
    );
  }

  Widget _buildDocumentField(AppLocalizations l10n) {
    return _buildLinkedField<GroupDocument>(
      label: l10n.surgicalSlotTechniqueLabel,
      selectedId: _selectedDocumentId,
      options: _documents,
      idOf: (d) => d.id,
      nameOf: (d) => '${d.publishedVersion?.title ?? ''} (${d.kind.label})',
      findById: GroupDocumentService.instance.documentById,
      onChanged: (id) => setState(() => _selectedDocumentId = id),
      viewLabel: l10n.surgicalSlotViewTechnique,
      notAvailableLabel: l10n.surgicalSlotLinkedNotAvailable,
      onView: (doc) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GroupDocumentDetailScreen(document: doc, myRole: widget.myRole)),
      ),
    );
  }

  Widget _buildTrayField(AppLocalizations l10n) {
    return _buildLinkedField<Tray>(
      label: l10n.surgicalSlotTrayLabel,
      selectedId: _selectedTrayId,
      options: _trays,
      idOf: (t) => t.id,
      nameOf: (t) => t.publishedVersion?.name ?? '',
      findById: TrayService.instance.trayById,
      onChanged: (id) => setState(() => _selectedTrayId = id),
      viewLabel: l10n.surgicalSlotViewTray,
      notAvailableLabel: l10n.surgicalSlotLinkedNotAvailable,
      onView: (tray) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => TrayDetailScreen(tray: tray, myRole: widget.myRole)),
      ),
    );
  }

  /// Desplegable opcional (valor = id, o null para "ninguno/a") + botón
  /// pulsable visible siempre que haya un valor seleccionado, tanto en modo
  /// edición como en modo solo-lectura -- es lo que permite al instrumentista
  /// sin permiso de edición ver el material real de la cirugía.
  ///
  /// [findById] resuelve contra el caché COMPLETO del servicio (no la lista
  /// [options], que solo trae contenido ya publicado): si el slot quedó
  /// enlazado a una tarjeta/técnica/bandeja que después se despublicó, el
  /// botón de ver sigue funcionando -- solo deja de ser una opción nueva
  /// seleccionable en el desplegable.
  Widget _buildLinkedField<T>({
    required String label,
    required String? selectedId,
    required List<T> options,
    required String Function(T) idOf,
    required String Function(T) nameOf,
    required T? Function(String) findById,
    required ValueChanged<String?> onChanged,
    required String viewLabel,
    required String notAvailableLabel,
    required void Function(T) onView,
  }) {
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('—')),
      ...options.map((o) => DropdownMenuItem<String?>(value: idOf(o), child: Text(nameOf(o)))),
    ];
    // Si el valor actual ya no está entre las opciones cargadas (p.ej.
    // contenido sin publicar o de otro espacio), el Dropdown no puede
    // mostrarlo seleccionado -- se añade igualmente como opción fantasma
    // para no perder el valor guardado ni romper el widget.
    final hasSelected = selectedId != null && options.any((o) => idOf(o) == selectedId);
    if (selectedId != null && !hasSelected) {
      items.insert(1, DropdownMenuItem<String?>(value: selectedId, child: Text(notAvailableLabel)));
    }
    final found = selectedId == null ? null : findById(selectedId);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String?>(
          initialValue: selectedId,
          isExpanded: true,
          decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
          items: items,
          onChanged: canEdit ? onChanged : null,
        ),
        if (selectedId != null && found != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: TextButton.icon(
              onPressed: () => onView(found),
              icon: const Icon(Icons.open_in_new),
              label: Text(viewLabel),
            ),
          ),
      ],
    );
  }
}
