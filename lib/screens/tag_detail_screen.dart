import 'package:flutter/material.dart';

import '../design_system/components/instriq_async_view.dart';
import '../design_system/components/instriq_entity_usage_list.dart';
import '../l10n/app_localizations.dart';
import '../models/tag.dart';
import '../services/tag_service.dart';
import '../utils/ref_resolver.dart';

/// "Todo lo etiquetado con X": agrupado por tipo de entidad, cada fila
/// resuelta a un título humano vía `ref_resolver.dart` y navegable a su
/// ficha — se llega aquí tocando un chip de etiqueta, nunca desde un menú
/// propio.
class TagDetailScreen extends StatelessWidget {
  final Tag tag;

  const TagDetailScreen({super.key, required this.tag});

  Future<Map<String, List<ResolvedRef>>> _load() async {
    final entries = await TagService.instance.fetchEntriesForTag(tag.id);
    final grouped = <String, List<ResolvedRef>>{};
    for (final entry in entries) {
      final resolved = await resolveRef(entry.refType, entry.refId);
      if (resolved == null) continue;
      grouped.putIfAbsent(entry.refType, () => []).add(resolved);
    }
    return grouped;
  }

  String _sectionLabel(AppLocalizations l10n, String refType) {
    switch (refType) {
      case 'catalog':
      case 'custom':
        return l10n.tagSectionInstruments;
      case 'group_document':
        return l10n.tagSectionDocuments;
      case 'tray':
        return l10n.tagSectionTrays;
      case 'preference_card':
        return l10n.tagSectionPreferenceCards;
      case 'surgeon':
        return l10n.tagSectionSurgeons;
      case 'manufacturer':
        return l10n.tagSectionManufacturers;
      case 'specialty':
        return l10n.tagSectionSpecialties;
      default:
        return refType;
    }
  }

  IconData _sectionIcon(String refType) {
    switch (refType) {
      case 'catalog':
        return Icons.build_outlined;
      case 'custom':
        return Icons.precision_manufacturing_outlined;
      case 'group_document':
        return Icons.menu_book_outlined;
      case 'tray':
        return Icons.inventory_2_outlined;
      case 'preference_card':
        return Icons.assignment_outlined;
      case 'surgeon':
        return Icons.person_outline;
      case 'manufacturer':
        return Icons.factory_outlined;
      case 'specialty':
        return Icons.category_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(tag.name)),
      body: InstriqAsyncView<Map<String, List<ResolvedRef>>>(
        load: _load,
        errorMessage: (error) => l10n.entityUsageLoadError(error.toString()),
        retryLabel: l10n.retry,
        isEmpty: (data) => data.isEmpty,
        emptyBuilder: (context) => Center(child: Text(l10n.tagDetailEmptyState)),
        builder: (context, byRefType) {
          // Se ordena por la etiqueta ya traducida que ve el usuario, no por
          // la clave técnica (en inglés) usada como key del mapa — así el
          // orden de las secciones coincide con lo que se lee en pantalla.
          final refTypes = byRefType.keys.toList()
            ..sort((a, b) => _sectionLabel(l10n, a).compareTo(_sectionLabel(l10n, b)));
          return InstriqEntityUsageList(
            sections: [
              for (final refType in refTypes)
                EntityUsageSection(
                  label: _sectionLabel(l10n, refType),
                  rows: byRefType[refType]!
                      .map((ref) => EntityUsageRow(
                            icon: _sectionIcon(refType),
                            title: ref.title,
                            onTap: () => navigateToResolvedRef(context, ref),
                          ))
                      .toList(),
                ),
            ],
          );
        },
      ),
    );
  }
}
