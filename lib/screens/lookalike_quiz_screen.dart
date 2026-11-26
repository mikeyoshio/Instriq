import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../data/lookalikes_data.dart';
import '../design_system/components/instriq_answer_option.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument.dart';

/// Pregunta del qüestionari de semblants: una foto i, com a opcions, les
/// peces de la mateixa família (les que de debò es confonen).
typedef LookalikeQuestion = ({Instrument answer, List<Instrument> options, LookalikeFamily family});

/// Separat de la pantalla perquè es pugui provar (test/lookalikes_test.dart).
List<LookalikeQuestion> buildLookalikeQuestions(Random rnd, int count) {
  final byId = {for (final i in kInstruments) i.id: i};
  final playable = [
    for (final f in kLookalikeFamilies)
      if (f.members.where((m) => byId[m.instrumentId]?.image != null).isNotEmpty && f.members.length >= 2) f,
  ];
  return List.generate(count, (_) {
    final family = playable[rnd.nextInt(playable.length)];
    final withPhoto = [for (final m in family.members) if (byId[m.instrumentId]?.image != null) byId[m.instrumentId]!];
    final answer = withPhoto[rnd.nextInt(withPhoto.length)];
    final others = [for (final m in family.members) if (m.instrumentId != answer.id) byId[m.instrumentId]!]..shuffle(rnd);
    return (answer: answer, options: [answer, ...others.take(3)]..shuffle(rnd), family: family);
  });
}

class LookalikeQuizScreen extends StatefulWidget {
  const LookalikeQuizScreen({super.key});

  @override
  State<LookalikeQuizScreen> createState() => _LookalikeQuizScreenState();
}

class _LookalikeQuizScreenState extends State<LookalikeQuizScreen> {
  static const _count = 10;
  late List<LookalikeQuestion> _questions = buildLookalikeQuestions(Random(), _count);
  int _current = 0, _score = 0;
  Instrument? _selected;

  void _select(Instrument option) {
    if (_selected != null) return;
    setState(() {
      _selected = option;
      if (option.id == _questions[_current].answer.id) _score++;
    });
  }

  void _next() => setState(() {
        _current++;
        _selected = null;
      });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    if (_current >= _questions.length) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.lookalikeQuizTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.scoreFraction(_score, _questions.length), style: theme.textTheme.headlineMedium),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => setState(() {
                  _questions = buildLookalikeQuestions(Random(), _count);
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
    final q = _questions[_current];
    final clue = q.family.members.firstWhere((m) => m.instrumentId == q.answer.id).clue;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.questionCounter(_current + 1, _questions.length))),
      body: InstriqAnswerShortcuts(
        count: q.options.length,
        onPick: (i) => _select(q.options[i]),
        onNext: _selected != null ? _next : null,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(q.family.title.forLanguageCode(lang).toUpperCase(),
                  textAlign: TextAlign.center, style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 1.1)),
              const SizedBox(height: 12),
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: q.answer.image!.url,
                    height: 180,
                    fit: BoxFit.contain,
                    memCacheHeight: (180 * MediaQuery.of(context).devicePixelRatio).round(),
                    placeholder: (context, url) => const SizedBox(height: 180, child: Center(child: CircularProgressIndicator())),
                    errorWidget: (context, url, error) => const SizedBox(height: 180, child: Icon(Icons.image_not_supported_outlined)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.whatInstrumentIsThis, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              for (final o in q.options)
                InstriqAnswerOption(
                  label: o.name.forLanguageCode(lang),
                  state: _selected == null
                      ? InstriqAnswerState.idle
                      : o.id == q.answer.id
                          ? InstriqAnswerState.correct
                          : o.id == _selected!.id
                              ? InstriqAnswerState.wrong
                              : InstriqAnswerState.other,
                  onPressed: () => _select(o),
                ),
              if (_selected != null) ...[
                const SizedBox(height: 8),
                Text(clue.forLanguageCode(lang), style: theme.textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(q.family.tip.forLanguageCode(lang), style: theme.textTheme.bodySmall),
                const SizedBox(height: 16),
                FilledButton(onPressed: _next, child: Text(_current == _questions.length - 1 ? l10n.seeResult : l10n.next)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
