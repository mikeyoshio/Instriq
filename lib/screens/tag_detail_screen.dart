import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/tag.dart';
import '../services/tag_service.dart';
import '../utils/ref_resolver.dart';

/// "Todo lo etiquetado con X": agrupado por tipo de entidad, cada fila
/// resuelta a un título humano vía `ref_resolver.dart` y navegable a su
/// ficha — se llega aquí tocando un chip de etiqueta, nunca desde un menú
/// propio.
class TagDetailScreen extends StatefulWidget {
  final Tag tag;

  const TagDetailScreen({super.key, required this.tag});

  @override
  State<TagDetailScreen> createState() => _TagDetailScreenState();
}

class _TagDetailScreenState extends State<TagDetailScreen> {
  bool _loading = true;
  final Map<String, List<ResolvedRef>> _byRefType = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final entries = await TagService.instance.fetchEntriesForTag(widget.tag.id);
      final grouped = <String, List<ResolvedRef>>{};
      for (final entry in entries) {
        final resolved = await resolveRef(entry.refType, entry.refId);
        if (resolved == null) continue;
        grouped.putIfAbsent(entry.refType, () => []).add(resolved);
      }
      if (!mounted) return;
      setState(() {
        _byRefType
          ..clear()
          ..addAll(grouped);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final refTypes = _byRefType.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(title: Text(widget.tag.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : refTypes.isEmpty
              ? Center(child: Text(l10n.tagDetailEmptyState))
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    for (final refType in refTypes) ...[
                      Text(_sectionLabel(l10n, refType), style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      for (final ref in _byRefType[refType]!)
                        Card(
                          child: ListTile(
                            title: Text(ref.title),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => navigateToResolvedRef(context, ref),
                          ),
                        ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
    );
  }
}
