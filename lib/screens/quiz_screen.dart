import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument.dart';
import '../services/progress_service.dart';
import '../widgets/category_icon.dart';

class _Question {
  final Instrument answer;
  final List<Instrument> options;

  _Question({required this.answer, required this.options});
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

  const QuizScreen({super.key, this.pool});

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

  bool get _isScoped => widget.pool != null;

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
  }

  List<_Question> _buildQuestions() {
    final rnd = Random();
    final source = widget.pool ?? kInstruments;
    final pool = List<Instrument>.from(source)..shuffle(rnd);
    final selected = pool.take(_questionCount).toList();

    return selected.map((instrument) {
      final sameCategory = kInstruments
          .where((i) => i.category == instrument.category && i.id != instrument.id)
          .toList()
        ..shuffle(rnd);
      final others = kInstruments.where((i) => i.id != instrument.id).toList()
        ..shuffle(rnd);
      final distractors = <Instrument>[];
      distractors.addAll(sameCategory.take(2));
      for (final o in others) {
        if (distractors.length >= 3) break;
        if (!distractors.contains(o)) distractors.add(o);
      }
      final options = [instrument, ...distractors.take(3)]..shuffle(rnd);
      return _Question(answer: instrument, options: options);
    }).toList();
  }

  void _select(Instrument option) {
    if (_selected != null) return;
    setState(() {
      _selected = option;
      if (option.id == _questions[_current].answer.id) _score++;
    });
  }

  void _next() {
    if (_current == _questions.length - 1) {
      if (!_isScoped) ProgressService.instance.saveQuizResult(null, _score, _questions.length);
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
      return Scaffold(body: Center(child: Text(l10n.noCards)));
    }
    if (_finished) {
      final best = _isScoped ? null : ProgressService.instance.quizBestScore(null);
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
      appBar: AppBar(title: Text(l10n.questionCounter(_current + 1, _questions.length))),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: (_current) / _questions.length),
              const SizedBox(height: 24),
              Center(
                // Foto real cuando el catálogo la tiene, mismo criterio que
                // flashcards_screen.dart (identificación visual de verdad,
                // sin atribución -- aquí el objetivo es adivinar).
                child: question.answer.image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: question.answer.image!.url,
                          height: 100,
                          fit: BoxFit.contain,
                          memCacheHeight: (100 * MediaQuery.of(context).devicePixelRatio).round(),
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
                      )
                    : InstrumentIcon(
                        iconKey: question.answer.icon,
                        category: question.answer.category,
                        size: 100,
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.whatInstrumentIsThis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              ...question.options.map((option) {
                final isSelected = _selected == option;
                final isCorrect = option.id == question.answer.id;
                // El color sol no basta -- un usuari daltònic (vermell-verd,
                // la forma més comuna) no distingiria l'opció correcta de la
                // incorrecta: s'afegeix una icona (✓/✗) com a senyal
                // redundant, mai només el color.
                Color? color;
                IconData? icon;
                if (_selected != null) {
                  if (isCorrect) {
                    color = Colors.green;
                    icon = Icons.check_circle;
                  } else if (isSelected) {
                    color = Colors.red;
                    icon = Icons.cancel;
                  }
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: color != null ? BorderSide(color: color, width: 2) : null,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _select(option),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: color, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            option.name.forLanguageCode(Localizations.localeOf(context).languageCode),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
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
    );
  }
}
