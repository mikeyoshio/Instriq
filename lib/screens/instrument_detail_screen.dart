import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../models/instrument.dart';
import '../models/instrument_sterilization.dart';
import '../models/professional_profile.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import '../services/sterilization_service.dart';
import '../widgets/category_icon.dart';

class InstrumentDetailScreen extends StatefulWidget {
  final Instrument instrument;

  const InstrumentDetailScreen({super.key, required this.instrument});

  @override
  State<InstrumentDetailScreen> createState() => _InstrumentDetailScreenState();
}

class _InstrumentDetailScreenState extends State<InstrumentDetailScreen> {
  static const String _refType = 'catalog';

  bool _loadingClinicalData = true;
  List<SterilizationMethodEntry> _methods = [];
  InstrumentTechnicalInfo? _technicalInfo;

  @override
  void initState() {
    super.initState();
    _loadClinicalData();
  }

  Future<void> _loadClinicalData() async {
    try {
      final methods = await SterilizationService.instance.fetchMethods(_refType, widget.instrument.id);
      final technicalInfo =
          await SterilizationService.instance.fetchTechnicalInfo(_refType, widget.instrument.id);
      if (!mounted) return;
      setState(() {
        _methods = methods;
        _technicalInfo = technicalInfo;
        _loadingClinicalData = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingClinicalData = false);
    }
  }

  Future<void> _openEditClinicalDataSheet() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _ClinicalDataFormSheet(
        instrument: widget.instrument,
        methods: _methods,
        technicalInfo: _technicalInfo,
      ),
    );
    if (saved == true) {
      setState(() => _loadingClinicalData = true);
      await _loadClinicalData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final instrument = widget.instrument;

    final builders = <String, Widget Function(BuildContext)>{
      'photo': _buildPhotoSection,
      'specialty': _buildSpecialtySection,
      'aliases': (context) => _buildAliasesSection(context, l10n),
      'description': (context) => _buildDescriptionSection(context, l10n),
      'use': (context) => _buildUseSection(context, l10n),
      'tip': _buildTipSection,
      'sterilization': (context) => _buildSterilizationSection(context, l10n),
      'technical': (context) => _buildTechnicalSection(context, l10n),
    };

    final order = sectionPriorityOrder(ProfileService.instance.professionalProfiles);

    return Scaffold(
      appBar: AppBar(
        title: Text(instrument.name),
        actions: [
          if (ProfileService.instance.isAdmin)
            IconButton(
              icon: const Icon(Icons.edit_note),
              tooltip: l10n.editClinicalDataTooltip,
              onPressed: _openEditClinicalDataSheet,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final key in order) ...[
              builders[key]!(context),
            ],
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: Icon(
                  ProgressService.instance.isLearned(instrument.id)
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                ),
                label: Text(
                  ProgressService.instance.isLearned(instrument.id) ? l10n.learned : l10n.markAsLearned,
                ),
                onPressed: () async {
                  await ProgressService.instance.toggleLearned(instrument.id);
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final instrument = widget.instrument;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: instrument.image != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    instrument.image!.url,
                    height: 200,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return SizedBox(
                        height: 200,
                        child: Center(
                          child: InstrumentIcon(
                            iconKey: instrument.icon,
                            category: instrument.category,
                            size: 120,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) => InstrumentIcon(
                      iconKey: instrument.icon,
                      category: instrument.category,
                      size: 120,
                    ),
                  ),
                )
              : InstrumentIcon(
                  iconKey: instrument.icon,
                  category: instrument.category,
                  size: 120,
                ),
        ),
        if (instrument.image != null) ...[
          const SizedBox(height: 6),
          Center(
            child: GestureDetector(
              onTap: () => launchUrl(Uri.parse(instrument.image!.sourceUrl)),
              child: Text(
                l10n.photoAttribution(instrument.image!.attribution, instrument.image!.license),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(decoration: TextDecoration.underline),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSpecialtySection(BuildContext context) {
    final instrument = widget.instrument;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Wrap(
        spacing: 8,
        children: [
          Chip(label: Text(instrument.specialty.label)),
          Chip(label: Text(instrument.category.label)),
        ],
      ),
    );
  }

  Widget _buildAliasesSection(BuildContext context, AppLocalizations l10n) {
    final instrument = widget.instrument;
    if (instrument.aliases.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.alsoKnownAs, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(instrument.aliases.join(', ')),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context, AppLocalizations l10n) {
    final instrument = widget.instrument;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.descriptionLabel, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(instrument.description, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildUseSection(BuildContext context, AppLocalizations l10n) {
    final instrument = widget.instrument;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.mainUseLabel, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(instrument.use, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  Widget _buildTipSection(BuildContext context) {
    final instrument = widget.instrument;
    if (instrument.tip == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Theme.of(context).colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lightbulb_outline),
              const SizedBox(width: 8),
              Expanded(child: Text(instrument.tip!)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSterilizationSection(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.sterilizationSectionTitle, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          if (_loadingClinicalData)
            const Center(child: CircularProgressIndicator())
          else if (_methods.isEmpty)
            Text(l10n.sterilizationEmptyState, style: Theme.of(context).textTheme.bodyMedium)
          else
            ..._methods.map((method) => _buildMethodCard(context, l10n, method)),
        ],
      ),
    );
  }

  Widget _buildMethodCard(BuildContext context, AppLocalizations l10n, SterilizationMethodEntry method) {
    final details = <String>[
      if (method.temperature != null && method.temperature!.isNotEmpty)
        '${l10n.sterilizationTemperatureLabel}: ${method.temperature}',
      if (method.timeMinutes != null && method.timeMinutes!.isNotEmpty)
        '${l10n.sterilizationTimeLabel}: ${method.timeMinutes}',
      if (method.pressure != null && method.pressure!.isNotEmpty)
        '${l10n.sterilizationPressureLabel}: ${method.pressure}',
      if (method.drying != null && method.drying!.isNotEmpty)
        '${l10n.sterilizationDryingLabel}: ${method.drying}',
      if (method.recommendedCycle != null && method.recommendedCycle!.isNotEmpty)
        '${l10n.sterilizationRecommendedCycleLabel}: ${method.recommendedCycle}',
      if (method.compatibilityNotes != null && method.compatibilityNotes!.isNotEmpty)
        '${l10n.sterilizationCompatibilityLabel}: ${method.compatibilityNotes}',
      if (method.restrictions != null && method.restrictions!.isNotEmpty)
        '${l10n.sterilizationRestrictionsLabel}: ${method.restrictions}',
      if (method.observations != null && method.observations!.isNotEmpty)
        '${l10n.sterilizationObservationsLabel}: ${method.observations}',
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(method.method.label, style: Theme.of(context).textTheme.titleSmall),
            for (final line in details) ...[
              const SizedBox(height: 4),
              Text(line, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalSection(BuildContext context, AppLocalizations l10n) {
    final info = _technicalInfo;
    final lines = <String>[
      if (info?.manufacturer != null && info!.manufacturer!.isNotEmpty)
        '${l10n.technicalManufacturerLabel}: ${info.manufacturer}',
      if (info?.maintenanceNotes != null && info!.maintenanceNotes!.isNotEmpty)
        '${l10n.technicalMaintenanceLabel}: ${info.maintenanceNotes}',
      if (info?.inspectionNotes != null && info!.inspectionNotes!.isNotEmpty)
        '${l10n.technicalInspectionLabel}: ${info.inspectionNotes}',
      if (info?.usefulLifeNotes != null && info!.usefulLifeNotes!.isNotEmpty)
        '${l10n.technicalUsefulLifeLabel}: ${info.usefulLifeNotes}',
    ];
    final hasIfu = info?.ifuUrl != null && info!.ifuUrl!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.technicalInfoSectionTitle, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          if (_loadingClinicalData)
            const Center(child: CircularProgressIndicator())
          else if (lines.isEmpty && !hasIfu)
            Text(l10n.technicalInfoEmptyState, style: Theme.of(context).textTheme.bodyMedium)
          else ...[
            for (final line in lines) ...[
              Text(line, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
            ],
            if (hasIfu)
              GestureDetector(
                onTap: () => launchUrl(Uri.parse(info.ifuUrl!)),
                child: Text(
                  '${l10n.technicalIfuLabel}: ${info.ifuUrl}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(decoration: TextDecoration.underline),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Formulario simple para dar de alta/editar un método de esterilización y la
/// ficha técnica de un instrumento del catálogo global. Solo visible para
/// admins (ver botón en el AppBar de [InstrumentDetailScreen]).
class _ClinicalDataFormSheet extends StatefulWidget {
  final Instrument instrument;
  final List<SterilizationMethodEntry> methods;
  final InstrumentTechnicalInfo? technicalInfo;

  const _ClinicalDataFormSheet({
    required this.instrument,
    required this.methods,
    required this.technicalInfo,
  });

  @override
  State<_ClinicalDataFormSheet> createState() => _ClinicalDataFormSheetState();
}

class _ClinicalDataFormSheetState extends State<_ClinicalDataFormSheet> {
  static const String _refType = 'catalog';

  SterilizationMethod _method = SterilizationMethod.vapor;
  late final TextEditingController _temperatureController;
  late final TextEditingController _timeController;
  late final TextEditingController _pressureController;
  late final TextEditingController _dryingController;
  late final TextEditingController _cycleController;
  late final TextEditingController _compatibilityController;
  late final TextEditingController _restrictionsController;
  late final TextEditingController _observationsController;

  late final TextEditingController _manufacturerController;
  late final TextEditingController _ifuController;
  late final TextEditingController _maintenanceController;
  late final TextEditingController _inspectionController;
  late final TextEditingController _usefulLifeController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existingMethod = widget.methods.isNotEmpty ? widget.methods.first : null;
    _method = existingMethod?.method ?? SterilizationMethod.vapor;
    _temperatureController = TextEditingController(text: existingMethod?.temperature ?? '');
    _timeController = TextEditingController(text: existingMethod?.timeMinutes ?? '');
    _pressureController = TextEditingController(text: existingMethod?.pressure ?? '');
    _dryingController = TextEditingController(text: existingMethod?.drying ?? '');
    _cycleController = TextEditingController(text: existingMethod?.recommendedCycle ?? '');
    _compatibilityController = TextEditingController(text: existingMethod?.compatibilityNotes ?? '');
    _restrictionsController = TextEditingController(text: existingMethod?.restrictions ?? '');
    _observationsController = TextEditingController(text: existingMethod?.observations ?? '');

    final info = widget.technicalInfo;
    _manufacturerController = TextEditingController(text: info?.manufacturer ?? '');
    _ifuController = TextEditingController(text: info?.ifuUrl ?? '');
    _maintenanceController = TextEditingController(text: info?.maintenanceNotes ?? '');
    _inspectionController = TextEditingController(text: info?.inspectionNotes ?? '');
    _usefulLifeController = TextEditingController(text: info?.usefulLifeNotes ?? '');
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
    _manufacturerController.dispose();
    _ifuController.dispose();
    _maintenanceController.dispose();
    _inspectionController.dispose();
    _usefulLifeController.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String value) => value.trim().isEmpty ? null : value.trim();

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final existingMethod = widget.methods.isNotEmpty ? widget.methods.first : null;
      await SterilizationService.instance.upsertMethod(
        SterilizationMethodEntry(
          id: existingMethod?.id,
          instrumentRefType: _refType,
          instrumentRefId: widget.instrument.id,
          method: _method,
          temperature: _nullIfEmpty(_temperatureController.text),
          timeMinutes: _nullIfEmpty(_timeController.text),
          pressure: _nullIfEmpty(_pressureController.text),
          drying: _nullIfEmpty(_dryingController.text),
          recommendedCycle: _nullIfEmpty(_cycleController.text),
          compatibilityNotes: _nullIfEmpty(_compatibilityController.text),
          restrictions: _nullIfEmpty(_restrictionsController.text),
          observations: _nullIfEmpty(_observationsController.text),
        ),
      );
      await SterilizationService.instance.upsertTechnicalInfo(
        InstrumentTechnicalInfo(
          id: widget.technicalInfo?.id,
          instrumentRefType: _refType,
          instrumentRefId: widget.instrument.id,
          manufacturer: _nullIfEmpty(_manufacturerController.text),
          ifuUrl: _nullIfEmpty(_ifuController.text),
          maintenanceNotes: _nullIfEmpty(_maintenanceController.text),
          inspectionNotes: _nullIfEmpty(_inspectionController.text),
          usefulLifeNotes: _nullIfEmpty(_usefulLifeController.text),
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.customInstrumentSaveError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
              DropdownButtonFormField<SterilizationMethod>(
                value: _method,
                decoration: InputDecoration(
                  labelText: l10n.sterilizationMethodLabel,
                  border: const OutlineInputBorder(),
                ),
                items: SterilizationMethod.values
                    .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
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
              const Divider(height: 32),
              Text(l10n.technicalInfoSectionTitle, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextField(
                controller: _manufacturerController,
                decoration: InputDecoration(
                  labelText: l10n.technicalManufacturerLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _ifuController,
                decoration: InputDecoration(
                  labelText: l10n.technicalIfuLabel,
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
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
