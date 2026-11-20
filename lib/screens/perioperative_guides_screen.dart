import 'package:flutter/material.dart';

import '../data/perioperative_guides_data.dart';
import '../design_system/components/instriq_list_item.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/perioperative_guide.dart';
import '../services/usage_analytics_service.dart';
import '../utils/fuzzy_match.dart';
import '../widgets/related_items_section.dart';
import '../widgets/technique_status_picker.dart';
import '../widgets/report_content_error_button.dart';

String guideAreaLabel(AppLocalizations l10n, GuideArea a) => switch (a) {
      GuideArea.asepsia => l10n.guideAreaAsepsis,
      GuideArea.seguridad => l10n.guideAreaSafety,
      GuideArea.paciente => l10n.guideAreaPatient,
      GuideArea.material => l10n.guideAreaMaterial,
      GuideArea.tecnicas => l10n.guideAreaTechniques,
      GuideArea.urgencias => l10n.guideAreaEmergency,
    };

IconData _areaIcon(GuideArea a) => switch (a) {
      GuideArea.asepsia => Icons.clean_hands_outlined,
      GuideArea.seguridad => Icons.verified_user_outlined,
      GuideArea.paciente => Icons.personal_injury_outlined,
      GuideArea.material => Icons.inventory_2_outlined,
      GuideArea.tecnicas => Icons.vaccines_outlined,
      GuideArea.urgencias => Icons.monitor_heart_outlined,
    };

/// Guies perioperatòries: mateix patró que SurgicalPositionCatalogScreen.
class PerioperativeGuidesScreen extends StatefulWidget {
  const PerioperativeGuidesScreen({super.key});

  @override
  State<PerioperativeGuidesScreen> createState() => _PerioperativeGuidesScreenState();
}

class _PerioperativeGuidesScreenState extends State<PerioperativeGuidesScreen> {
  String _query = '';
  GuideArea? _area;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final filtered = kPerioperativeGuides.where((g) {
      final matchesQuery =
          fuzzyContains(g.name.forLanguageCode(lang), _query) || g.aliases.any((a) => fuzzyContains(a, _query));
      return matchesQuery && (_area == null || g.area == _area);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.guidesCatalogTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.guidesSearchHint,
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
                for (final a in GuideArea.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(guideAreaLabel(l10n, a)),
                      selected: _area == a,
                      onSelected: (_) => setState(() => _area = _area == a ? null : a),
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
                      final g = filtered[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: InstriqSpacing.sm),
                        child: InstriqListItem(
                          icon: _areaIcon(g.area),
                          title: g.name.forLanguageCode(lang),
                          subtitle: guideAreaLabel(l10n, g.area),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => PerioperativeGuideDetailScreen(guide: g)),
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

class PerioperativeGuideDetailScreen extends StatefulWidget {
  final PerioperativeGuide guide;

  const PerioperativeGuideDetailScreen({super.key, required this.guide});

  @override
  State<PerioperativeGuideDetailScreen> createState() => _PerioperativeGuideDetailScreenState();
}

class _PerioperativeGuideDetailScreenState extends State<PerioperativeGuideDetailScreen> {
  @override
  void initState() {
    super.initState();
    UsageAnalyticsService.instance.recordView('perioperative_guide', widget.guide.id);
  }

  @override
  Widget build(BuildContext context) {
    final g = widget.guide;
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(g.name.forLanguageCode(lang))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.positionsDisclaimer, style: theme.textTheme.bodySmall),
            const SizedBox(height: 8),
            Chip(avatar: Icon(_areaIcon(g.area), size: 18), label: Text(guideAreaLabel(l10n, g.area))),
            const SizedBox(height: 12),
            Text(g.summary.forLanguageCode(lang), style: theme.textTheme.bodyLarge),
            for (final s in g.sections) ...[
              const SizedBox(height: 20),
              Text(s.title.forLanguageCode(lang), style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(s.body.forLanguageCode(lang), style: theme.textTheme.bodyLarge),
            ],
            TechniqueStatusPicker(guideId: g.id),
            RelatedItemsSection(ids: g.relatedItems),
            const SizedBox(height: 12),
            ReportContentErrorButton(refType: 'guide', refId: g.id),
          ],
        ),
      ),
    );
  }
}
