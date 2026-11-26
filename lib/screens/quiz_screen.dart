import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../design_system/components/instriq_answer_option.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument.dart';
import '../services/progress_service.dart';
import '../widgets/category_icon.dart';
import '../widgets/deck_filter.dart';

class _Question {
  final Instrument answer;
  final List<Instrument> options;

  _Question({required this.answer, required this.options});
}

/// Preguntes del quiz, separat de la pantalla perquè es pugui provar
/// (`test/quiz_questions_test.dart`).
///
/// - Al quiz global només entren instruments amb foto: "Quin instrument és
///   aquest?" sense foto no té resposta.
/// - Amb [pool] (una safata), els que no tenen foto es pregunten pel seu ús.
/// - Els distractors surten de la mateixa categoria i especialitat i, si no
///   n'hi ha prou, de la mateixa categoria o la mateixa especialitat: mai un
///   robot com a alternativa a un separador.
List<({Instrument answer, List<Instrument> options})> buildQuizQuestions(List<Instrument>? pool, Random rnd, int count) {
  final source = List<Instrument>.from(pool ?? kInstruments.where((i) => i.image != null))..shuffle(rnd);
  return source.take(count).map((instrument) {
    final distractors = <Instrument>[];
    for (final ok in <bool Function(Instrument)>[
      (i) => i.category == instrument.category && i.specialty == instrument.specialty,
      (i) => i.category == instrument.category,
      (i) => i.specialty == instrument.specialty,
      (i) => true,
    ]) {
      final candidates = kInstruments
          .where((i) => i.id != instrument.id && !distractors.contains(i) && ok(i))
          // Noms iguals en l'idioma de l'usuari farien dues opcions idèntiques.
          .where((i) => i.name.ca != instrument.name.ca && !distractors.any((d) => d.name.ca == i.name.ca))
          .toList()
        ..shuffle(rnd);
      distractors.addAll(candidates.take(3 - distractors.length));
      if (distractors.length == 3) break;
    }
    return (answer: instrument, options: [instrument, ...distractors]..shuffle(rnd));
  }).toList();
}

class QuizScreen extends StatefulWidget {
  /// Ámbito del quiz: `null` es el catálogo global de siempre. Pasar la
  /// composición de una bandeja (solo instrumentos de catálogo -- el
  /// instrumental personalizado del equipo no tiene aquí el mismo conjunto
  /// de campos, ver docs/BACKLOG.md) permite "aprendizaje por bandejas"
  /// (identificar el conjunto) reutilizando toda esta pantalla en vez de
  /// duplicarla. Los distractores siguen saliendo del catálogo global
  /// completo tanto si hay ámbito como si no (una bandeja de 3-4 ítems no
  /// da para generar 4 opciones ella sola).
  final List<Instrument>? pool;

  /// Clave bajo la que se guarda/lee la mejor puntuación (ver
  /// [ProgressService.saveQuizResult]/[quizBestScore]) -- por ejemplo
  /// `TeamQuiz.scopeKey`, para que el panel de progreso del docente la vea
  /// (`team_learning_progress` ya expone todo `profiles.quiz_best_scores`).
  /// `null` con [pool] informado (p.ej. practicar una bandeja) es la única
  /// combinación que NO guarda puntuación -- es un ejercicio de repaso
  /// puntual, no algo que deba aparecer en ningún progreso.
  final String? scopeKey;

  const QuizScreen({super.key, this.pool, this.scopeKey});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  static const _questionCount = 10;

  late List<_Question> _questions;
  int _current = 0;
  int _score = 0;
  Instrument? _selected;
  bool _finished = false;

  DeckFilter _filter = DeckFilter.all;

  // Un quiz filtrat per bloc o especialitat és un repàs, no compta com a
  // millor puntuació del quiz general.
  bool get _savesScore => (widget.pool == null && _filter.isAll) || widget.scopeKey != null;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
  }

  List<_Question> _buildQuestions() => buildQuizQuestions(
        widget.pool ?? (_filter.isAll ? null : kInstruments.where((i) => i.image != null && _filter.matches(i)).toList()),
        Random(),
        _questionCount,
      )
      .map((q) => _Question(answer: q.answer, options: q.options))
      .toList();

  void _select(Instrument option) {
    if (_selected != null) return;
    setState(() {
      _selected = option;
      if (option.id == _questions[_current].answer.id) _score++;
    });
  }

  void _next() {
    if (_current == _questions.length - 1) {
      if (_savesScore) ProgressService.instance.saveQuizResult(widget.scopeKey, _score, _questions.length);
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _current++;
      _selected = null;
    });
  }

  void _restart() {
    setState(() {
      _questions = _buildQuestions();
      _current = 0;
      _score = 0;
      _selected = null;
      _finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_questions.isEmpty) {
      // Un filtre sense instruments amb foto: es pot canviar sense sortir.
      return Scaffold(
        appBar: AppBar(actions: [
          if (widget.pool == null)
            DeckFilterButton(value: _filter, onChanged: (f) {
              _filter = f;
              _restart();
            }),
        ]),
        body: Center(child: Text(l10n.noCards)),
      );
    }
    if (_finished) {
      final best = _savesScore ? ProgressService.instance.quizBestScore(widget.scopeKey) : null;
      return Scaffold(
        appBar: AppBar(title: Text(l10n.resultTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, size: 72, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  l10n.scoreFraction(_score, _questions.length),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                if (best != null) Text(l10n.bestScoreLabel(best, _questions.length)),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.repeatQuiz),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.backToHome),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _questions[_current];

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.questionCounter(_current + 1, _questions.length)),
        actions: [
          if (widget.pool == null)
            DeckFilterButton(
              value: _filter,
              onChanged: (f) {
                _filter = f;
                _restart();
              },
            ),
        ],
      ),
      body: InstriqAnswerShortcuts(
        count: question.options.length,
        onPick: (i) => _select(question.options[i]),
        onNext: _selected != null ? _next : null,
        child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(
                value: (_current + (_selected != null ? 1 : 0)) / _questions.length,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              const SizedBox(height: 24),
              Center(
                // Foto real cuando el catálogo la tiene, mismo criterio que
                // flashcards_screen.dart (identificación visual de verdad,
                // sin atribución -- aquí el objetivo es adivinar).
                child: question.answer.image == null
                    ? const SizedBox.shrink()
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: question.answer.image!.url,
                          height: 180,
                          fit: BoxFit.contain,
                          memCacheHeight: (180 * MediaQuery.of(context).devicePixelRatio).round(),
                          placeholder: (context, url) => InstrumentIcon(
                            iconKey: question.answer.icon,
                            category: question.answer.category,
                            size: 100,
                          ),
                          errorWidget: (context, url, error) => InstrumentIcon(
                            iconKey: question.answer.icon,
                            category: question.answer.category,
                            size: 100,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                question.answer.image != null
                    ? l10n.whatInstrumentIsThis
                    : l10n.quizWhichIsUsedFor(question.answer.use.forLanguageCode(Localizations.localeOf(context).languageCode)),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              for (final option in question.options)
                InstriqAnswerOption(
                  label: option.name.forLanguageCode(Localizations.localeOf(context).languageCode),
                  state: _selected == null
                      ? InstriqAnswerState.idle
                      : option.id == question.answer.id
                          ? InstriqAnswerState.correct
                          : _selected == option
                              ? InstriqAnswerState.wrong
                              : InstriqAnswerState.other,
                  onPressed: () => _select(option),
                ),
              const Spacer(),
              if (_selected != null)
                FilledButton(
                  onPressed: _next,
                  child: Text(
                    _current == _questions.length - 1 ? l10n.seeResult : l10n.next,
                  ),
                ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}
