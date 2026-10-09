import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../data/sutures_data.dart';
import '../design_system/components/instriq_badge.dart';
import '../design_system/components/instriq_count_badge.dart';
import '../design_system/components/instriq_responsive_content.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument.dart';
import '../models/suture.dart';
import '../services/catalog_community_photo_service.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import '../utils/fuzzy_match.dart';
import '../widgets/category_icon.dart';
import '../widgets/suture_labels.dart';
import 'community_photos_review_screen.dart';
import 'instrument_detail_screen.dart';
import 'suture_detail_screen.dart';

/// Qué tipo de material de referencia se está explorando -- antes `Suture`
/// vivía en su propia pantalla/acceso directo separados (`SutureCatalogScreen`),
/// asimétrico respecto a gasas/paños/EPI, que siempre fueron `Instrument`
/// normales dentro de este mismo catálogo. Un solo catálogo con un segmento
/// de "tipo de material" resuelve esa asimetría sin forzar un modelo de
/// datos compartido entre `Instrument` (categoría/especialidad) y `Suture`
/// (material/calibre) -- que tienen formas genuinamente distintas.
enum _CatalogKind { instrumentos, suturas }

/// Predicado de filtro extraído como función pura (no closure sobre estado
/// privado) para que sea testeable desde `test/catalog_filter_test.dart`.
bool matchesInstrumentFilters(
  Instrument instrument,
  String query,
  String languageCode, {
  Set<InstrumentCategory> categories = const {},
  Set<Specialty> specialties = const {},
  bool newOnly = false,
}) {
  final matchesQuery = fuzzyContains(instrument.name.forLanguageCode(languageCode), query) ||
      instrument.aliases.any((a) => fuzzyContains(a, query));
  final matchesCategory = categories.isEmpty || categories.contains(instrument.category);
  final matchesSpecialty = specialties.isEmpty || specialties.contains(instrument.specialty);
  final matchesNew = !newOnly || instrument.isNew;
  return matchesQuery && matchesCategory && matchesSpecialty && matchesNew;
}

/// Mismo motivo que [matchesInstrumentFilters].
bool matchesSutureFilters(
  Suture suture,
  String query,
  String languageCode, {
  Set<SutureMaterial> materials = const {},
}) {
  final matchesQuery = fuzzyContains(suture.name.forLanguageCode(languageCode), query);
  final matchesMaterial = materials.isEmpty || materials.contains(suture.material);
  return matchesQuery && matchesMaterial;
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const String _refType = 'catalog';

  _CatalogKind _kind = _CatalogKind.instrumentos;
  String _query = '';
  final Set<InstrumentCategory> _categoryFilters = {};
  final Set<Specialty> _specialtyFilters = {};
  bool _newOnlyFilter = false;
  final Set<SutureMaterial> _materialFilters = {};
  Set<String> _approvedCommunityPhotoIds = {};

  int get _activeFilterCount => _kind == _CatalogKind.instrumentos
      ? _categoryFilters.length + _specialtyFilters.length + (_newOnlyFilter ? 1 : 0)
      : _materialFilters.length;

  @override
  void initState() {
    super.initState();
    _loadApprovedCommunityPhotoIds();
  }

  Future<void> _loadApprovedCommunityPhotoIds() async {
    try {
      final ids = await CatalogCommunityPhotoService.instance.fetchApprovedInstrumentIds(_refType);
      if (!mounted) return;
      setState(() => _approvedCommunityPhotoIds = ids);
    } catch (_) {
      // Sin conexión o sin sesión: el badge de "sin foto" simplemente no
      // tiene en cuenta las fotos de la comunidad, no bloquea el catálogo.
    }
  }

  bool _hasAnyPhoto(Instrument instrument) =>
      instrument.image != null || _approvedCommunityPhotoIds.contains(instrument.id);

  void _toggleSpecialty(Specialty s) {
    setState(() {
      if (!_specialtyFilters.add(s)) _specialtyFilters.remove(s);
    });
  }

  void _toggleCategory(InstrumentCategory c) {
    setState(() {
      if (!_categoryFilters.add(c)) _categoryFilters.remove(c);
    });
  }

  void _toggleNewOnly() {
    setState(() => _newOnlyFilter = !_newOnlyFilter);
  }

  void _toggleMaterial(SutureMaterial m) {
    setState(() {
      if (!_materialFilters.add(m)) _materialFilters.remove(m);
    });
  }

  void _clearFilters() {
    setState(() {
      if (_kind == _CatalogKind.instrumentos) {
        _specialtyFilters.clear();
        _categoryFilters.clear();
        _newOnlyFilter = false;
      } else {
        _materialFilters.clear();
      }
    });
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final l10n = AppLocalizations.of(sheetContext)!;
            void toggle(VoidCallback mutate) {
              mutate();
              setSheetState(() {});
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_kind == _CatalogKind.instrumentos) ...[
                        _FilterChipRow(
                          chips: [
                            _MultiFilterChip(
                              label: l10n.catalogNewOnlyFilterLabel,
                              selected: _newOnlyFilter,
                              onTap: () => toggle(_toggleNewOnly),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.specialtyFilterLabel, style: Theme.of(sheetContext).textTheme.labelMedium),
                        const SizedBox(height: 4),
                        _FilterChipRow(
                          chips: [
                            for (final s in Specialty.values)
                              _MultiFilterChip(
                                label: s.label(l10n),
                                selected: _specialtyFilters.contains(s),
                                onTap: () => toggle(() => _toggleSpecialty(s)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.categoryFilterLabel, style: Theme.of(sheetContext).textTheme.labelMedium),
                        const SizedBox(height: 4),
                        _FilterChipRow(
                          chips: [
                            for (final c in InstrumentCategory.values)
                              _MultiFilterChip(
                                label: c.label(l10n),
                                selected: _categoryFilters.contains(c),
                                onTap: () => toggle(() => _toggleCategory(c)),
                              ),
                          ],
                        ),
                      ] else
                        _FilterChipRow(
                          chips: [
                            for (final m in SutureMaterial.values)
                              _MultiFilterChip(
                                label: sutureMaterialValueLabel(l10n, m),
                                selected: _materialFilters.contains(m),
                                onTap: () => toggle(() => _toggleMaterial(m)),
                              ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _activeFilterCount > 0 ? () => toggle(_clearFilters) : null,
                        child: Text(l10n.clearFilters),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final languageCode = Localizations.localeOf(context).languageCode;
    final isInstruments = _kind == _CatalogKind.instrumentos;

    final filteredInstruments = isInstruments
        ? kInstruments
            .where((i) => matchesInstrumentFilters(
                  i,
                  _query,
                  languageCode,
                  categories: _categoryFilters,
                  specialties: _specialtyFilters,
                  newOnly: _newOnlyFilter,
                ))
            .toList()
        : const <Instrument>[];

    final filteredSutures = !isInstruments
        ? kSutures
            .where((s) => matchesSutureFilters(s, _query, languageCode, materials: _materialFilters))
            .toList()
        : const <Suture>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.catalogTitle),
        actions: [
          if (isInstruments && ProfileService.instance.isAdmin)
            IconButton(
              icon: const Icon(Icons.rate_review_outlined),
              tooltip: l10n.communityPhotoReviewTooltip,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CommunityPhotosReviewScreen()),
              ),
            ),
          if (_activeFilterCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(child: InstriqCountBadge(count: _activeFilterCount)),
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            tooltip: l10n.catalogFiltersTooltip,
            onPressed: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: InstriqResponsiveContent(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: isInstruments ? l10n.catalogSearchHint : l10n.searchSutureHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: SegmentedButton<_CatalogKind>(
                segments: [
                  ButtonSegment(
                    value: _CatalogKind.instrumentos,
                    label: Text(l10n.catalogMaterialTypeInstruments),
                  ),
                  ButtonSegment(
                    value: _CatalogKind.suturas,
                    label: Text(l10n.sutureCatalogTitle),
                  ),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
            ),
            const SizedBox(height: 8),
            if (isInstruments) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.instrumentsCount(filteredInstruments.length),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
            Expanded(
              child: isInstruments
                  ? (filteredInstruments.isEmpty
                      ? _EmptyFiltered(
                          activeFilterCount: _activeFilterCount,
                          onClear: _clearFilters,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredInstruments.length,
                          itemBuilder: (context, index) {
                            final instrument = filteredInstruments[index];
                            final learned = ProgressService.instance.isLearned(instrument.id);
                            return Card(
                              child: ListTile(
                                leading: InstrumentIcon(
                                  iconKey: instrument.icon,
                                  category: instrument.category,
                                  size: 48,
                                ),
                                title: Row(
                                  children: [
                                    Flexible(child: Text(instrument.name.forLanguageCode(languageCode))),
                                    if (instrument.isNew) ...[
                                      const SizedBox(width: 6),
                                      InstriqBadge(label: l10n.catalogNewInstrumentBadge, color: InstriqColors.accent),
                                    ],
                                    if (!_hasAnyPhoto(instrument)) ...[
                                      const SizedBox(width: 6),
                                      Tooltip(
                                        message: l10n.noPhotoBadgeTooltip,
                                        child: Icon(
                                          Icons.no_photography_outlined,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.outline,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle:
                                    Text('${instrument.specialty.label(l10n)} · ${instrument.category.label(l10n)}'),
                                trailing: learned
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : const Icon(Icons.chevron_right),
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => InstrumentDetailScreen(instrument: instrument),
                                    ),
                                  );
                                  setState(() {});
                                  _loadApprovedCommunityPhotoIds();
                                },
                              ),
                            );
                          },
                        ))
                  : (filteredSutures.isEmpty
                      ? _EmptyFiltered(
                          activeFilterCount: _activeFilterCount,
                          onClear: _clearFilters,
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredSutures.length,
                          itemBuilder: (context, index) {
                            final suture = filteredSutures[index];
                            return Card(
                              child: ListTile(
                                leading: const Icon(Icons.line_style),
                                title: Text(suture.name.forLanguageCode(languageCode)),
                                subtitle: Text('${sutureMaterialValueLabel(l10n, suture.material)} · ${suture.gauge}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => SutureDetailScreen(suture: suture)),
                                ),
                              ),
                            );
                          },
                        )),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFiltered extends StatelessWidget {
  final int activeFilterCount;
  final VoidCallback onClear;

  const _EmptyFiltered({required this.activeFilterCount, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.noResultsFilters),
          if (activeFilterCount > 0) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onClear, child: Text(l10n.clearFilters)),
          ],
        ],
      ),
    );
  }
}

/// Fila de chips de filtro: en ample d'escriptori (mateix llindar que
/// `app_shell.dart`) es reparteixen en `Wrap` perquè es vegin tots sense
/// necessitat de descobrir que es pot arrossegar horitzontalment — en
/// mòbil, on el gest de swipe és obvi, es manté el `ListView` horitzontal
/// original per no perdre espai vertical.
class _FilterChipRow extends StatelessWidget {
  final List<Widget> chips;

  const _FilterChipRow({required this.chips});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= InstriqBreakpoints.tablet) {
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chips,
          );
        }
        return SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final chip in chips) Padding(padding: const EdgeInsets.only(right: 8), child: chip),
            ],
          ),
        );
      },
    );
  }
}

class _MultiFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MultiFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: true,
    );
  }
}
