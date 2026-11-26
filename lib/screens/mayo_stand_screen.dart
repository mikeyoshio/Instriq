import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../design_system/components/instriq_section_header.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument.dart';
import '../widgets/category_icon.dart';
import 'instrument_detail_screen.dart';

/// Mesa de Mayo: un exemple de muntatge bàsic (cirurgia general) i els
/// principis per muntar-la. Cada peça obre la seva fitxa.
/// Contingut propi, pendent de revisió clínica.
const _zones = <(LocalizedText, List<String>)>[
  (LocalizedText(ca: 'Tall', es: 'Corte', en: 'Cutting'), ['bisturi', 'tijera-mayo', 'tijera-metzenbaum']),
  (
    LocalizedText(ca: 'Dissecció', es: 'Disección', en: 'Dissecting'),
    ['pinza-diseccion-dientes', 'pinza-diseccion-sin-dientes', 'pinza-adson-dientes'],
  ),
  (LocalizedText(ca: 'Hemostàsia', es: 'Hemostasia', en: 'Haemostasis'), ['pinza-mosquito', 'pinza-kelly', 'pinza-kocher']),
  (LocalizedText(ca: 'Sutura i separació', es: 'Sutura y separación', en: 'Suturing and retracting'),
      ['portaagujas-mayo-hegar', 'separador-farabeuf']),
];

const _principles = <LocalizedText>[
  LocalizedText(
    ca: 'Només el que es farà servir de seguida; la resta es queda a la mesa auxiliar.',
    es: 'Solo lo que se va a usar enseguida; el resto se queda en la mesa auxiliar.',
    en: 'Only what will be needed right away; everything else stays on the back table.',
  ),
  LocalizedText(
    ca: "En l'ordre en què es faran servir: tall, dissecció, hemostàsia i sutura.",
    es: 'En el orden en que se van a usar: corte, disección, hemostasia y sutura.',
    en: 'In the order they will be used: cutting, dissecting, haemostasis and suturing.',
  ),
  LocalizedText(
    ca: 'Totes les puntes cap al mateix costat i els anells cap a la instrumentista, per lliurar-les ràpid i bé.',
    es: 'Todas las puntas hacia el mismo lado y las anillas hacia la instrumentista, para entregarlas rápido y bien.',
    en: 'All tips facing the same way and the rings towards the scrub nurse, to hand them over quickly.',
  ),
  LocalizedText(
    ca: 'Fulles muntades amb el portaagulles i agulles carregades i comptades; res tallant fora de lloc.',
    es: 'Hojas montadas con el portaagujas y agujas cargadas y contadas; nada cortante fuera de su sitio.',
    en: 'Blades loaded with a needle holder and needles loaded and counted; nothing sharp left loose.',
  ),
  LocalizedText(
    ca: "Durant tota la intervenció: el que torna es neteja i es deixa al seu lloc.",
    es: 'Durante toda la intervención: lo que vuelve se limpia y se deja en su sitio.',
    en: 'Throughout the operation: whatever comes back is wiped and returned to its place.',
  ),
  LocalizedText(
    ca: 'Cada centre i cada cirurgià té el seu muntatge: segueix el protocol i la targeta de preferència.',
    es: 'Cada centro y cada cirujano tiene su montaje: sigue el protocolo y la tarjeta de preferencia.',
    en: "Every hospital and surgeon sets it up differently: follow the protocol and the preference card.",
  ),
];

class MayoStandScreen extends StatelessWidget {
  const MayoStandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final byId = {for (final i in kInstruments) i.id: i};
    return Scaffold(
      appBar: AppBar(title: Text(l10n.mayoStandTitle)),
      body: ListView(
        padding: const EdgeInsets.all(InstriqSpacing.lg),
        children: [
          Text(l10n.mayoStandIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: InstriqSpacing.lg),
          // La safata: una superfície amb les peces en files, per ordre d'ús.
          DecoratedBox(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant, width: 2),
            ),
            child: Padding(
              padding: const EdgeInsets.all(InstriqSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (label, ids) in _zones) ...[
                    Text(label.forLanguageCode(lang), style: theme.textTheme.labelLarge),
                    const SizedBox(height: InstriqSpacing.xs),
                    Wrap(
                      spacing: InstriqSpacing.sm,
                      runSpacing: InstriqSpacing.sm,
                      children: [for (final id in ids) if (byId[id] case final i?) _Piece(instrument: i)],
                    ),
                    const SizedBox(height: InstriqSpacing.md),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: InstriqSpacing.xl),
          InstriqSectionHeader(l10n.mayoStandPrinciples),
          const SizedBox(height: InstriqSpacing.sm),
          for (final p in _principles)
            Padding(
              padding: const EdgeInsets.only(bottom: InstriqSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: InstriqSpacing.sm),
                  Expanded(child: Text(p.forLanguageCode(lang), style: theme.textTheme.bodyLarge)),
                ],
              ),
            ),
          const SizedBox(height: InstriqSpacing.md),
          Text(l10n.contentInReviewNote, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _Piece extends StatelessWidget {
  final Instrument instrument;
  const _Piece({required this.instrument});

  @override
  Widget build(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final fallback = InstrumentIcon(iconKey: instrument.icon, category: instrument.category, size: 56);
    return Semantics(
      button: true,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => InstrumentDetailScreen(instrument: instrument)),
          ),
          child: SizedBox(
            width: 104,
            child: Padding(
              padding: const EdgeInsets.all(InstriqSpacing.sm),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: instrument.image == null
                        ? fallback
                        : CachedNetworkImage(
                            imageUrl: instrument.image!.url,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => fallback,
                            errorWidget: (context, url, error) => fallback,
                          ),
                  ),
                  const SizedBox(height: InstriqSpacing.xs),
                  Text(
                    instrument.name.forLanguageCode(lang),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
