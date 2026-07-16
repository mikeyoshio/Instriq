import 'dart:math';

import 'package:flutter/material.dart';

import '../data/instruments_data.dart';
import '../models/instrument.dart';
import '../services/progress_service.dart';
import '../widgets/category_icon.dart';

class _Question {
  final Instrument answer;
  final List<Instrument> options;

  _Question({required this.answer, required this.options});
}

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
  }

  List<_Question> _buildQuestions() {
    final rnd = Random();
    final pool = List<Instrument>.from(kInstruments)..shuffle(rnd);
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
      ProgressService.instance.saveQuizResult(null, _score, _questions.length);
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
    if (_finished) {
      final best = ProgressService.instance.quizBestScore(null);
      return Scaffold(
        appBar: AppBar(title: const Text('Resultado')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.emoji_events, size: 72, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  '$_score / ${_questions.length}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text('Mejor puntuación: $best / ${_questions.length}'),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _restart,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Repetir quiz'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Volver al inicio'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _questions[_current];

    return Scaffold(
      appBar: AppBar(title: Text('Pregunta ${_current + 1} / ${_questions.length}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LinearProgressIndicator(value: (_current) / _questions.length),
              const SizedBox(height: 24),
              Center(
                child: InstrumentIcon(
                  iconKey: question.answer.icon,
                  category: question.answer.category,
                  size: 100,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '¿Qué instrumento es este?',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              ...question.options.map((option) {
                final isSelected = _selected == option;
                final isCorrect = option.id == question.answer.id;
                Color? color;
                if (_selected != null) {
                  if (isCorrect) {
                    color = Colors.green;
                  } else if (isSelected) {
                    color = Colors.red;
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
                    child: Text(option.name, textAlign: TextAlign.center),
                  ),
                );
              }),
              const Spacer(),
              if (_selected != null)
                FilledButton(
                  onPressed: _next,
                  child: Text(
                    _current == _questions.length - 1 ? 'Ver resultado' : 'Siguiente',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
