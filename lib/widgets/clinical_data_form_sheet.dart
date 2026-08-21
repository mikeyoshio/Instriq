import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/instrument_sterilization.dart';
import '../models/manufacturer.dart';
import '../services/connectivity_service.dart';
import '../services/manufacturer_service.dart';
import '../services/reference_document_service.dart';
import '../services/sterilization_service.dart';
import 'sterilization_method_label.dart';
import 'tag_picker.dart';

/// Formulario de esterilización/ficha técnica de un instrumento -- del
/// catálogo global (`refType: 'catalog'`, `organizationId`/`workspaceId`
/// nulos) o del instrumental propio de un equipo (`refType: 'custom'`,
/// `organizationId`/`workspaceId` de ese espai, para que la cabecera quede
/// scoped y la apruebi qui té rol d'aprovador d'aquell espai). Cada mètode
/// d'esterilització i la fitxa tècnica són parelles capçalera+versions (ver
/// supabase/schema_v32_cssd_workspace.sql): aquest sheet mai edita la versió
/// publicada directament, sempre demana-o-crea l'esborrany propi
/// (`startEditingMethod`/`startEditingTechnicalInfo`, mateix patró que
/// [PreferenceCardService.startEditing]) i separa "Desa com a esborrany" de
/// "Envia a revisió" (mateix patró `_saveDraft({bool andSubmit})` que
/// [TrayFormScreen]).
class ClinicalDataFormSheet extends StatefulWidget {
  final String refType;
  final String refId;
  final String? organizationId;
  final String? workspaceId;
  final List<SterilizationMethodEntry> methods;
  final InstrumentTechnicalInfo? technicalInfo;

  const ClinicalDataFormSheet({
    super.key,
    required this.refType,
    required this.refId,
    this.organizationId,
    this.workspaceId,
    required this.methods,
    required this.technicalInfo,
  });

  @override
  State<ClinicalDataFormSheet> createState() => _ClinicalDataFormSheetState();
}

class _ClinicalDataFormSheetState extends State<ClinicalDataFormSheet> {
  // Copia local mutable: al crear una cabecera de método nueva se añade aquí
  // para que el selector de chips la vea sin recargar todo el sheet desde
  // el padre.
  late List<SterilizationMethodEntry> _methods;

  // `null` significa "nueva fila" (se creará al guardar vía
  // `createSterilizationMethod`); si no, es el `id` de una de `_methods` que
  // se está editando. Ver bug independent 6 del plan de refactor original:
  // antes el sheet solo leía/escribía `methods.first`, dejando invisibles el
  // resto de filas cuando un instrumento tenía 2+ métodos registrados.
  String? _selectedMethodId;
  SterilizationMethodVersion? _methodDraft;
  bool _loadingMethodDraft = false;

  SterilizationMethod _method = SterilizationMethod.vapor;
  late final TextEditingController _temperatureController;
  late final TextEditingController _timeController;
  late final TextEditingController _pressureController;
  late final TextEditingController _dryingController;
  late final TextEditingController _cycleController;
  late final TextEditingController _compatibilityController;
  late final TextEditingController _restrictionsController;
  late final TextEditingController _observationsController;
  bool _lubricationRequired = false;
  late final TextEditingController _lubricationTypeController;
  late final TextEditingController _lubricationNotesController;
  late final TextEditingController _methodCommentController;

  InstrumentTechnicalInfoVersion? _infoDraft;
  bool _loadingInfoDraft = false;

  // Texto libre "espejo" del campo de autocompletar de fabricante — mismo
  // patrón que `preference_card_form_screen.dart` para el cirujano.
  final TextEditingController _manufacturerFieldController = TextEditingController();
  String? _selectedManufacturerId;
  late final TextEditingController _ifuTitleController;
  late final TextEditingController _ifuUrlController;
  late final TextEditingController _maintenanceController;
  late final TextEditingController _inspectionController;
  late final TextEditingController _usefulLifeController;
  late final TextEditingController _maintenanceIntervalController;
  DateTime? _lastMaintenanceAt;
  late final TextEditingController _infoCommentController;

  final _tagPickerKey = GlobalKey<TagPickerState>();

  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _methods = List.of(widget.methods);

    _temperatureController = TextEditingController();
    _timeController = TextEditingController();
    _pressureController = TextEditingController();
    _dryingController = TextEditingController();
    _cycleController = TextEditingController();
    _compatibilityController = TextEditingController();
    _restrictionsController = TextEditingController();
    _observationsController = TextEditingController();
    _lubricationTypeController = TextEditingController();
    _lubricationNotesController = TextEditingController();
    _methodCommentController = TextEditingController();

    _ifuTitleController = TextEditingController();
    _ifuUrlController = TextEditingController();
    _maintenanceController = TextEditingController();
    _inspectionController = TextEditingController();
    _usefulLifeController = TextEditingController();
    _maintenanceIntervalController = TextEditingController();
    _infoCommentController = TextEditingController();

    final firstMethod = _methods.isNotEmpty ? _methods.first : null;
    _selectedMethodId = firstMethod?.id;
    _loadMethodDraft(firstMethod?.id);
    _loadInfoDraft();
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _timeController.dispose();
    _pressureController.dispose();
    _dryingController.dispose();
    _cycleController.dispose();
    _compatibilityController.dispose();
    _restrictionsController.dispose();
    _observationsController.dispose();
    _lubricationTypeController.dispose();
    _lubricationNotesController.dispose();
    _methodCommentController.dispose();
    _manufacturerFieldController.dispose();
    _ifuTitleController.dispose();
    _ifuUrlController.dispose();
    _maintenanceController.dispose();
    _inspectionController.dispose();
    _usefulLifeController.dispose();
    _maintenanceIntervalController.dispose();
    _infoCommentController.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String value) => value.trim().isEmpty ? null : value.trim();

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  void _applyMethodFields(SterilizationMethodVersion? draft) {
    _method = draft?.method ?? SterilizationMethod.vapor;
    _temperatureController.text = draft?.temperature ?? '';
    _timeController.text = draft?.timeMinutes ?? '';
    _pressureController.text = draft?.pressure ?? '';
    _dryingController.text = draft?.drying ?? '';
    _cycleController.text = draft?.recommendedCycle ?? '';
    _compatibilityController.text = draft?.compatibilityNotes ?? '';
    _restrictionsController.text = draft?.restrictions ?? '';
    _observationsController.text = draft?.observations ?? '';
    _lubricationRequired = draft?.lubricationRequired ?? false;
    _lubricationTypeController.text = draft?.lubricationType ?? '';
    _lubricationNotesController.text = draft?.lubricationNotes ?? '';
    _methodCommentController.text = '';
  }

  /// Cambia qué cabecera de `_methods` se está editando (o pasa a "nueva
  /// fila" si [headerId] es `null`): pide-o-crea el borrador propio del
  /// método seleccionado -- nunca se edita la versión publicada directamente.
  Future<void> _loadMethodDraft(String? headerId) async {
    setState(() {
      _selectedMethodId = headerId;
      _loadingMethodDraft = true;
    });
    try {
      if (headerId == null) {
        _methodDraft = null;
        _applyMethodFields(null);
      } else {
        final draft = await SterilizationService.instance.startEditingMethod(headerId);
        _methodDraft = draft;
        _applyMethodFields(draft);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loadingMethodDraft = false);
    }
  }

  Future<void> _loadInfoDraft() async {
    setState(() => _loadingInfoDraft = true);
    try {
      // Fetch auxiliar para el autocompletar de fabricante -- se aísla en su
      // propio try/catch (mismo criterio que TrayFormScreen._init) para que
      // un fallo de red aquí NO tumbe la carga del borrador real de más
      // abajo, que sí es la llamada que importa. Sin red se sigue con lo que
      // ya hubiera en memoria (o vacío si es la primera carga de la sesión).
      try {
        await ManufacturerService.instance.fetchAll();
      } catch (e) {
        if (!ConnectivityService.isNetworkError(e)) rethrow;
      }
      final infoId = widget.technicalInfo?.id;
      final draft =
          infoId == null ? null : await SterilizationService.instance.startEditingTechnicalInfo(infoId);
      _infoDraft = draft;
      _selectedManufacturerId = draft?.manufacturerId;
      final manufacturerId = draft?.manufacturerId;
      if (manufacturerId != null) {
        final existing = ManufacturerService.instance.byId(manufacturerId);
        if (existing != null) _manufacturerFieldController.text = existing.name;
      }
      final ifuDocumentId = draft?.ifuDocumentId;
      if (ifuDocumentId != null) {
        // Otro fetch auxiliar (título/URL de la IFU para rellenar el
        // formulario) -- ReferenceDocumentService no cachea nada en memoria,
        // así que sin red simplemente se deja el campo vacío en vez de
        // abortar la carga del resto del borrador.
        try {
          final doc = await ReferenceDocumentService.instance.fetchById(ifuDocumentId);
          if (doc != null) {
            _ifuTitleController.text = doc.title;
            _ifuUrlController.text = doc.url;
          }
        } catch (e) {
          if (!ConnectivityService.isNetworkError(e)) rethrow;
        }
      }
      _maintenanceController.text = draft?.maintenanceNotes ?? '';
      _inspectionController.text = draft?.inspectionNotes ?? '';
      _usefulLifeController.text = draft?.usefulLifeNotes ?? '';
      _maintenanceIntervalController.text = draft?.maintenanceIntervalDays?.toString() ?? '';
      _lastMaintenanceAt = draft?.lastMaintenanceAt;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loadingInfoDraft = false);
    }
  }

  Future<void> _pickLastMaintenanceDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _lastMaintenanceAt ?? now,
      firstDate: DateTime(2000),
      lastDate: now,
    );
    if (picked != null) setState(() => _lastMaintenanceAt = picked);
  }

  /// Crea la cabecera (si `_methodDraft` es `null`, o sea "nueva fila") o
  /// actualiza el borrador existente con los valores actuales del formulario.
  /// Devuelve la versión guardada, para poder encadenar el envío a revisión.
  Future<SterilizationMethodVersion> _persistMethodDraft() async {
    var draft = _methodDraft;
    draft ??= await SterilizationService.instance.createSterilizationMethod(
      refType: widget.refType,
      refId: widget.refId,
      organizationId: widget.organizationId,
      workspaceId: widget.workspaceId,
      method: _method,
    );

    final temperature = _nullIfEmpty(_temperatureController.text);
    final timeMinutes = _nullIfEmpty(_timeController.text);
    final pressure = _nullIfEmpty(_pressureController.text);
    final drying = _nullIfEmpty(_dryingController.text);
    final recommendedCycle = _nullIfEmpty(_cycleController.text);
    final compatibilityNotes = _nullIfEmpty(_compatibilityController.text);
    final restrictions = _nullIfEmpty(_restrictionsController.text);
    final observations = _nullIfEmpty(_observationsController.text);
    final lubricationType = _nullIfEmpty(_lubricationTypeController.text);
    final lubricationNotes = _nullIfEmpty(_lubricationNotesController.text);

    final updated = draft.copyWith(
      method: _method,
      temperature: temperature,
      clearTemperature: temperature == null,
      timeMinutes: timeMinutes,
      clearTimeMinutes: timeMinutes == null,
      pressure: pressure,
      clearPressure: pressure == null,
      drying: drying,
      clearDrying: drying == null,
      recommendedCycle: recommendedCycle,
      clearRecommendedCycle: recommendedCycle == null,
      compatibilityNotes: compatibilityNotes,
      clearCompatibilityNotes: compatibilityNotes == null,
      restrictions: restrictions,
      clearRestrictions: restrictions == null,
      observations: observations,
      clearObservations: observations == null,
      lubricationRequired: _lubricationRequired,
      lubricationType: lubricationType,
      clearLubricationType: lubricationType == null,
      lubricationNotes: lubricationNotes,
      clearLubricationNotes: lubricationNotes == null,
      comment: _nullIfEmpty(_methodCommentController.text),
    );
    final saved = await SterilizationService.instance.saveMethodDraft(updated);
    _methodDraft = saved;
    _selectedMethodId = saved.methodId;
    if (!_methods.any((m) => m.id == saved.methodId)) {
      _methods = [
        ..._methods,
        SterilizationMethodEntry(
          id: saved.methodId,
          instrumentRefType: widget.refType,
          instrumentRefId: widget.refId,
        ),
      ];
    }
    return saved;
  }

  /// Ver [_persistMethodDraft] -- mismo criterio, entidad distinta (la ficha
  /// técnica es una cabecera única por instrumento, no una lista).
  Future<InstrumentTechnicalInfoVersion> _persistInfoDraft() async {
    var draft = _infoDraft;
    draft ??= await SterilizationService.instance.createTechnicalInfo(
      refType: widget.refType,
      refId: widget.refId,
      organizationId: widget.organizationId,
      workspaceId: widget.workspaceId,
    );

    final manufacturerName = _manufacturerFieldController.text.trim();
    String? manufacturerId = draft.manufacturerId;
    if (manufacturerName.isNotEmpty) {
      final cached =
          _selectedManufacturerId == null ? null : ManufacturerService.instance.byId(_selectedManufacturerId!);
      if (cached != null && cached.name == manufacturerName) {
        manufacturerId = cached.id;
      } else {
        // Dar de alta un fabricante NUEVO exige conexión (igual que abrir una
        // cabecera nueva, ver doc de SterilizationService) -- pero si falla
        // por estar offline no debe tumbar el resto del guardado, que sí se
        // encola vía saveTechnicalInfoDraft más abajo. Se conserva el
        // fabricante que ya tuviera el borrador.
        try {
          manufacturerId = (await ManufacturerService.instance.createOrGet(manufacturerName)).id;
        } catch (e) {
          if (!ConnectivityService.isNetworkError(e)) rethrow;
        }
      }
    } else {
      manufacturerId = null;
    }

    final ifuTitle = _ifuTitleController.text.trim();
    final ifuUrl = _ifuUrlController.text.trim();
    String? ifuDocumentId = draft.ifuDocumentId;
    if (ifuTitle.isNotEmpty && ifuUrl.isNotEmpty) {
      // ReferenceDocumentService.createOrGet SIEMPRE inserta (no dedup, ver
      // su doc) así que esto corre en CADA guardado con IFU rellenada -- de
      // ahí que aislarlo importe tanto: sin este try/catch, un guardado
      // offline de campos que no tienen nada que ver con la IFU (notas de
      // mantenimiento, etc.) se abortaría entero antes de llegar a
      // saveTechnicalInfoDraft, que es la llamada que sí sabe encolarse.
      try {
        final doc = await ReferenceDocumentService.instance.createOrGet(
          ifuTitle,
          ifuUrl,
          docType: 'ifu',
          manufacturerId: manufacturerId,
        );
        ifuDocumentId = doc.id;
      } catch (e) {
        if (!ConnectivityService.isNetworkError(e)) rethrow;
      }
    } else if (ifuTitle.isEmpty && ifuUrl.isEmpty) {
      ifuDocumentId = null;
    }

    final maintenanceNotes = _nullIfEmpty(_maintenanceController.text);
    final inspectionNotes = _nullIfEmpty(_inspectionController.text);
    final usefulLifeNotes = _nullIfEmpty(_usefulLifeController.text);
    final maintenanceIntervalDays = int.tryParse(_maintenanceIntervalController.text.trim());

    final updated = draft.copyWith(
      manufacturerId: manufacturerId,
      clearManufacturerId: manufacturerId == null,
      ifuDocumentId: ifuDocumentId,
      clearIfuDocumentId: ifuDocumentId == null,
      maintenanceNotes: maintenanceNotes,
      clearMaintenanceNotes: maintenanceNotes == null,
      inspectionNotes: inspectionNotes,
      clearInspectionNotes: inspectionNotes == null,
      usefulLifeNotes: usefulLifeNotes,
      clearUsefulLifeNotes: usefulLifeNotes == null,
      maintenanceIntervalDays: maintenanceIntervalDays,
      clearMaintenanceIntervalDays: maintenanceIntervalDays == null,
      lastMaintenanceAt: _lastMaintenanceAt,
      clearLastMaintenanceAt: _lastMaintenanceAt == null,
      comment: _nullIfEmpty(_infoCommentController.text),
    );
    final saved = await SterilizationService.instance.saveTechnicalInfoDraft(updated);
    _infoDraft = saved;
    return saved;
  }

  /// Guarda ambos borradores (método + ficha técnica) y, si [submit] es
  /// `true`, los envía a revisión a continuación -- mismo patrón
  /// `_saveDraft({bool andSubmit})` que [TrayFormScreen._saveDraft].
  Future<void> _save({required bool submit}) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final savedMethod = await _persistMethodDraft();
      if (submit) {
        await SterilizationService.instance.submitMethodVersionForReview(savedMethod.id);
      }
      final savedInfo = await _persistInfoDraft();
      if (submit) {
        await SterilizationService.instance.submitTechnicalInfoVersionForReview(savedInfo.id);
      }
      await _tagPickerKey.currentState?.save();
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = AppLocalizations.of(context)!.saveError(e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Selector de qué cabecera de `_methods` se edita en el formulario de
  /// esterilización (o "añadir nuevo método" para insertar una fila más).
  /// Si el instrumento no tiene ninguna fila registrada todavía, no hay nada
  /// que elegir: el formulario ya arranca en modo "nuevo" y este selector no
  /// se muestra. Ver bug independent 6 del plan de refactor original.
  Widget _buildMethodSelector(BuildContext context, AppLocalizations l10n) {
    if (_methods.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.sterilizationSelectMethodToEditLabel, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in _methods)
                ChoiceChip(
                  label: Text(
                    entry.publishedVersion != null
                        ? sterilizationMethodValueLabel(l10n, entry.publishedVersion!.method)
                        : l10n.sterilizationUnpublishedMethodLabel,
                  ),
                  selected: _selectedMethodId == entry.id,
                  onSelected: (_) => _loadMethodDraft(entry.id),
                ),
              ChoiceChip(
                label: Text(l10n.sterilizationAddNewMethodOption),
                avatar: const Icon(Icons.add, size: 18),
                selected: _selectedMethodId == null,
                onSelected: (_) => _loadMethodDraft(null),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loadingDraft = _loadingMethodDraft || _loadingInfoDraft;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.editClinicalDataTooltip, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 16),
              Text(l10n.sterilizationSectionTitle, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              _buildMethodSelector(context, l10n),
              DropdownButtonFormField<SterilizationMethod>(
                key: ValueKey('method-dropdown-${_selectedMethodId ?? 'new'}'),
                initialValue: _method,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationMethodLabel,
                  border: const OutlineInputBorder(),
                ),
                items: SterilizationMethod.values
                    .map((m) => DropdownMenuItem(value: m, child: Text(sterilizationMethodValueLabel(l10n, m))))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _method = value);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _temperatureController,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationTemperatureLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationTimeLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pressureController,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationPressureLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _dryingController,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationDryingLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _cycleController,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationRecommendedCycleLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _compatibilityController,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationCompatibilityLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _restrictionsController,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationRestrictionsLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _observationsController,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationObservationsLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _lubricationRequired,
                onChanged: (value) => setState(() => _lubricationRequired = value),
                title: Text(l10n.lubricationRequiredLabel),
              ),
              if (_lubricationRequired) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _lubricationTypeController,
                  decoration: InputDecoration(
                    labelText: l10n.lubricationTypeLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lubricationNotesController,
                  decoration: InputDecoration(
                    labelText: l10n.lubricationNotesLabel,
                    border: const OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _methodCommentController,
                decoration: InputDecoration(
                  labelText: l10n.changeCommentLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const Divider(height: 32),
              Text(l10n.technicalInfoSectionTitle, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Autocomplete<Manufacturer>(
                optionsBuilder: (value) {
                  if (value.text.trim().isEmpty) return const Iterable<Manufacturer>.empty();
                  return ManufacturerService.instance.searchByName(value.text);
                },
                displayStringForOption: (m) => m.name,
                initialValue: TextEditingValue(text: _manufacturerFieldController.text),
                onSelected: (m) {
                  _selectedManufacturerId = m.id;
                  _manufacturerFieldController.text = m.name;
                },
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: l10n.technicalManufacturerLabel,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _manufacturerFieldController.text = value;
                      final cached = _selectedManufacturerId == null
                          ? null
                          : ManufacturerService.instance.byId(_selectedManufacturerId!);
                      if (cached != null && cached.name != value) {
                        _selectedManufacturerId = null;
                      }
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ifuTitleController,
                decoration: InputDecoration(
                  labelText: l10n.technicalIfuTitleLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ifuUrlController,
                decoration: InputDecoration(
                  labelText: l10n.technicalIfuUrlLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maintenanceController,
                decoration: InputDecoration(
                  labelText: l10n.technicalMaintenanceLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _inspectionController,
                decoration: InputDecoration(
                  labelText: l10n.technicalInspectionLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _usefulLifeController,
                decoration: InputDecoration(
                  labelText: l10n.technicalUsefulLifeLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maintenanceIntervalController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.technicalMaintenanceIntervalLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickLastMaintenanceDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.technicalLastMaintenanceLabel,
                    border: const OutlineInputBorder(),
                  ),
                  child: Text(_lastMaintenanceAt == null ? '—' : _formatDate(_lastMaintenanceAt!)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _infoCommentController,
                decoration: InputDecoration(
                  labelText: l10n.changeCommentLabel,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const Divider(height: 32),
              Text(l10n.tagsLabel, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TagPicker(
                key: _tagPickerKey,
                refType: widget.refType,
                refId: widget.refId,
                organizationId: widget.organizationId,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: (_saving || loadingDraft) ? null : () => _save(submit: true),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.submitForReview),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: (_saving || loadingDraft) ? null : () => _save(submit: false),
                child: Text(l10n.saveAsDraft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
