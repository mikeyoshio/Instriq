import 'package:flutter/material.dart';

import '../data/clinical_scales_data.dart';
import '../design_system/components/instriq_list_item.dart';
import '../design_system/components/instriq_section_header.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/clinical_scale.dart';
import '../services/usage_analytics_service.dart';

String scaleAreaLabel(AppLocalizations l10n, ScaleArea a) => switch (a) {
      ScaleArea.preanestesia => l10n.scaleAreaPreanaesthesia,
      ScaleArea.recuperacion => l10n.scaleAreaRecovery,
      ScaleArea.valoracion => l10n.scaleAreaAssessment,
    };

/// Escales de valoració (ASA, Aldrete, Glasgow, Braden...) agrupades per moment.
class ClinicalScalesScreen extends StatelessWidget {
  const ClinicalScalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scalesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final area in ScaleArea.values) ...[
            InstriqSectionHeader(scaleAreaLabel(l10n, area)),
            for (final s in kClinicalScales.where((s) => s.area == area))
              Padding(
                padding: const EdgeInsets.only(bottom: InstriqSpacing.sm),
                child: InstriqListItem(
                  icon: Icons.calculate_outlined,
                  title: s.name.forLanguageCode(lang),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ClinicalScaleDetailScreen(scale: s)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class ClinicalScaleDetailScreen extends StatefulWidget {
  final ClinicalScale scale;

  const ClinicalScaleDetailScreen({super.key, required this.scale});

  @override
  State<ClinicalScaleDetailScreen> createState() => _ClinicalScaleDetailScreenState();
}

class _ClinicalScaleDetailScreenState extends State<ClinicalScaleDetailScreen> {
  /// Opció triada per ítem (índex dins de `options`), o null.
  late List<int?> _picked = List.filled(widget.scale.items.length, null);

  @override
  void initState() {
    super.initState();
    UsageAnalyticsService.instance.recordView('clinical_scale', widget.scale.id);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.scale;
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final complete = !_picked.contains(null);
    final score = complete
        ? [for (var i = 0; i < s.items.length; i++) s.items[i].options[_picked[i]!].points].fold(0, (a, b) => a + b)
        : null;
    final band = score == null ? null : s.bandFor(score);
    final answered = _picked.where((p) => p != null).length;
    final partial = [for (var i = 0; i < s.items.length; i++) if (_picked[i] != null) s.items[i].options[_picked[i]!].points]
        .fold(0, (a, b) => a + b);

    String resultText() {
      if (score == null) return l10n.scaleIncomplete;
      if (s.classification) {
        final chosen = s.items.first.options[_picked.first!].text.forLanguageCode(lang);
        return band == null ? chosen : '$chosen\n${band.label.forLanguageCode(lang)}';
      }
      final head = l10n.scaleScore(score, s.maxScore);
      return band == null ? head : '$head\n${band.label.forLanguageCode(lang)}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(s.name.forLanguageCode(lang)),
        actions: [
          IconButton(
            tooltip: l10n.scaleReset,
            icon: const Icon(Icons.restart_alt),
            onPressed: () => setState(() => _picked = List.filled(s.items.length, null)),
          ),
        ],
      ),
      // El resultat (o el parcial) sempre a la vista, també mentre es puntua
      // un ítem que queda per sota de la pantalla.
      bottomNavigationBar: Material(
        color: complete ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHigh,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Text(
              complete || s.classification ? resultText() : l10n.scalePartial(partial, answered, s.items.length),
              style: theme.textTheme.titleMedium?.copyWith(color: complete ? theme.colorScheme.onPrimaryContainer : null),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s.description.forLanguageCode(lang), style: theme.textTheme.bodyLarge),
          for (var i = 0; i < s.items.length; i++) ...[
            const SizedBox(height: 16),
            if (s.items.length > 1 || !s.classification)
              Text(s.items[i].label.forLanguageCode(lang), style: theme.textTheme.titleMedium),
            RadioGroup<int>(
              groupValue: _picked[i],
              onChanged: (v) => setState(() => _picked[i] = v),
              child: Column(
                children: [
                  for (var j = 0; j < s.items[i].options.length; j++)
                    RadioListTile<int>(
                      value: j,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.items[i].options[j].text.forLanguageCode(lang)),
                      secondary: s.classification ? null : Text('${s.items[i].options[j].points}'),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(l10n.scaleDisclaimer, style: theme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text('${l10n.scaleReference}: ${s.reference}', style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
