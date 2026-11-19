import 'package:flutter/material.dart';

import '../data/surgical_positions_data.dart';
import '../l10n/app_localizations.dart';
import '../models/surgical_position.dart';
import '../services/usage_analytics_service.dart';
import '../utils/fuzzy_match.dart';
import '../widgets/related_items_section.dart';
import '../widgets/report_content_error_button.dart';

String surgicalPositionFamilyLabel(AppLocalizations l10n, SurgicalPositionFamily f) => switch (f) {
      SurgicalPositionFamily.supino => l10n.positionFamilySupine,
      SurgicalPositionFamily.lateral => l10n.positionFamilyLateral,
      SurgicalPositionFamily.prono => l10n.positionFamilyProne,
      SurgicalPositionFamily.sentado => l10n.positionFamilySitting,
    };

/// Catàleg de postures quirúrgiques: cerca i filtre per família, mateix
/// patró (més petit) que WoundClosureCatalogScreen.
class SurgicalPositionCatalogScreen extends StatefulWidget {
  const SurgicalPositionCatalogScreen({super.key});

  @override
  State<SurgicalPositionCatalogScreen> createState() => _SurgicalPositionCatalogScreenState();
}

class _SurgicalPositionCatalogScreenState extends State<SurgicalPositionCatalogScreen> {
  String _query = '';
  SurgicalPositionFamily? _family;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final filtered = kSurgicalPositions.where((p) {
      final matchesQuery = fuzzyContains(p.name.forLanguageCode(lang), _query) ||
          p.aliases.any((a) => fuzzyContains(a, _query));
      return matchesQuery && (_family == null || p.family == _family);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.positionsCatalogTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.positionsSearchHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              scrollDirection: Axis.horizontal,
              children: [
                for (final f in SurgicalPositionFamily.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(surgicalPositionFamilyLabel(l10n, f)),
                      selected: _family == f,
                      onSelected: (_) => setState(() => _family = _family == f ? null : f),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text(l10n.noResultsFilters))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.airline_seat_flat_outlined),
                          title: Text(p.name.forLanguageCode(lang)),
                          subtitle: Text(surgicalPositionFamilyLabel(l10n, p.family)),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => SurgicalPositionDetailScreen(position: p)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class SurgicalPositionDetailScreen extends StatefulWidget {
  final SurgicalPosition position;

  const SurgicalPositionDetailScreen({super.key, required this.position});

  @override
  State<SurgicalPositionDetailScreen> createState() => _SurgicalPositionDetailScreenState();
}

class _SurgicalPositionDetailScreenState extends State<SurgicalPositionDetailScreen> {
  @override
  void initState() {
    super.initState();
    UsageAnalyticsService.instance.recordView('surgical_position', widget.position.id);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.position;
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    Widget section(String label, String text, {IconData? icon, Color? color}) {
      final body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(text, style: theme.textTheme.bodyLarge),
        ],
      );
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: color == null
            ? body
            : Card(
                color: color,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [Icon(icon), const SizedBox(width: 8), Expanded(child: body)],
                  ),
                ),
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(p.name.forLanguageCode(lang))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.positionsDisclaimer, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [Chip(label: Text(surgicalPositionFamilyLabel(l10n, p.family)))]),
            if (p.aliases.isNotEmpty) section(l10n.alsoKnownAs, p.aliases.join(', ')),
            section(l10n.descriptionLabel, p.description.forLanguageCode(lang)),
            section(l10n.positionProceduresLabel, p.procedures.forLanguageCode(lang)),
            section(l10n.positionRisksLabel, p.risks.forLanguageCode(lang),
                icon: Icons.warning_amber_outlined, color: theme.colorScheme.errorContainer),
            section(l10n.positionCareLabel, p.care.forLanguageCode(lang),
                icon: Icons.checklist, color: theme.colorScheme.secondaryContainer),
            RelatedItemsSection(ids: p.relatedItems),
            const SizedBox(height: 12),
            ReportContentErrorButton(refType: 'position', refId: p.id),
          ],
        ),
      ),
    );
  }
}
