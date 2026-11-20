import 'dart:math';

import 'package:flutter/material.dart';

import '../data/perioperative_guides_data.dart';
import '../data/surgical_positions_data.dart';
import '../design_system/components/instriq_answer_option.dart';
import '../l10n/app_localizations.dart';
import '../models/surgical_position.dart';
import '../widgets/flip_deck.dart';
import 'perioperative_guides_screen.dart';
import 'surgical_position_catalog_screen.dart';

/// Targetes de postures i guies perioperatòries: l'anvers és el nom (i, a
/// les guies, l'apartat), el revers el contingut. Sense progrés desat:
/// `ProgressService` és per a l'instrumental.
class ReferenceFlashcardsScreen extends StatefulWidget {
  const ReferenceFlashcardsScreen({super.key});

  @override
  State<ReferenceFlashcardsScreen> createState() => _ReferenceFlashcardsScreenState();
}

class _ReferenceFlashcardsScreenState extends State<ReferenceFlashcardsScreen> {
  bool _guides = false;

  List<(String, String, String)> _cards(AppLocalizations l10n, String lang) => _guides
      ? [
          for (final g in kPerioperativeGuides)
            for (final s in g.sections)
              (guideAreaLabel(l10n, g.area), '${g.name.forLanguageCode(lang)}\n\n${s.title.forLanguageCode(lang)}',
                  s.body.forLanguageCode(lang)),
        ]
      : [
          for (final p in kSurgicalPositions)
            (
              surgicalPositionFamilyLabel(l10n, p.family),
              p.name.forLanguageCode(lang),
              '${l10n.positionProceduresLabel}: ${p.procedures.forLanguageCode(lang)}\n\n'
                  '${l10n.positionRisksLabel}: ${p.risks.forLanguageCode(lang)}',
            ),
        ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.referenceStudyTitle)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text(l10n.positionsCatalogTitle)),
                  ButtonSegment(value: true, label: Text(l10n.guidesCatalogTitle)),
                ],
                selected: {_guides},
                onSelectionChanged: (v) => setState(() => _guides = v.first),
              ),
              const SizedBox(height: 12),
              Expanded(child: FlipDeck(key: ValueKey(_guides), cards: _cards(l10n, lang))),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Quina postura?": les intervencions d'una postura i quatre opcions.
class PositionQuizScreen extends StatefulWidget {
  const PositionQuizScreen({super.key});

  @override
  State<PositionQuizScreen> createState() => _PositionQuizScreenState();
}

class _PositionQuizScreenState extends State<PositionQuizScreen> {
  static const _length = 10;
  final _rnd = Random();
  late List<(SurgicalPosition, List<SurgicalPosition>)> _questions = _build();
  int _current = 0;
  int _score = 0;
  SurgicalPosition? _selected;

  List<(SurgicalPosition, List<SurgicalPosition>)> _build() {
    final pool = List.of(kSurgicalPositions)..shuffle(_rnd);
    return [
      for (final answer in pool.take(_length))
        (
          answer,
          ([...(kSurgicalPositions.where((p) => p.id != answer.id).toList()..shuffle(_rnd)).take(3), answer]
            ..shuffle(_rnd)),
        ),
    ];
  }

  void _select(SurgicalPosition p) {
    if (_selected != null) return;
    setState(() {
      _selected = p;
      if (p.id == _questions[_current].$1.id) _score++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);

    if (_current >= _questions.length) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.resultTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.scoreFraction(_score, _questions.length), style: theme.textTheme.headlineMedium),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => setState(() {
                  _questions = _build();
                  _current = 0;
                  _score = 0;
                  _selected = null;
                }),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.repeatQuiz),
              ),
            ],
          ),
        ),
      );
    }

    final (answer, options) = _questions[_current];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.questionCounter(_current + 1, _questions.length))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(l10n.positionQuizPrompt, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(answer.procedures.forLanguageCode(lang), style: theme.textTheme.bodyLarge),
            const SizedBox(height: 20),
            for (final o in options)
              InstriqAnswerOption(
                label: o.name.forLanguageCode(lang),
                state: _selected == null
                    ? InstriqAnswerState.idle
                    : o.id == answer.id
                        ? InstriqAnswerState.correct
                        : o.id == _selected!.id
                            ? InstriqAnswerState.wrong
                            : InstriqAnswerState.other,
                onPressed: () => _select(o),
              ),
            if (_selected != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => setState(() {
                  _current++;
                  _selected = null;
                }),
                child: Text(l10n.next),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
