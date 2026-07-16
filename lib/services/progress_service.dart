import 'package:shared_preferences/shared_preferences.dart';

import '../data/instruments_data.dart';
import '../models/instrument.dart';

class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  static const _learnedKey = 'learned_ids';
  static const _quizScorePrefix = 'quiz_best_';

  SharedPreferences? _prefs;
  Set<String> _learned = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _learned = (_prefs?.getStringList(_learnedKey) ?? []).toSet();
  }

  bool isLearned(String id) => _learned.contains(id);

  Future<void> toggleLearned(String id) async {
    if (_learned.contains(id)) {
      _learned.remove(id);
    } else {
      _learned.add(id);
    }
    await _prefs?.setStringList(_learnedKey, _learned.toList());
  }

  int get learnedCount => _learned.length;

  int get totalCount => kInstruments.length;

  double get overallProgress =>
      totalCount == 0 ? 0 : learnedCount / totalCount;

  int learnedCountForCategory(InstrumentCategory category) {
    return kInstruments
        .where((i) => i.category == category && _learned.contains(i.id))
        .length;
  }

  int totalCountForCategory(InstrumentCategory category) {
    return kInstruments.where((i) => i.category == category).length;
  }

  Future<void> saveQuizResult(InstrumentCategory? category, int score, int total) async {
    final key = '$_quizScorePrefix${category?.name ?? 'general'}';
    final best = _prefs?.getInt(key) ?? 0;
    if (score > best) {
      await _prefs?.setInt(key, score);
    }
  }

  int quizBestScore(InstrumentCategory? category) {
    final key = '$_quizScorePrefix${category?.name ?? 'general'}';
    return _prefs?.getInt(key) ?? 0;
  }

  Future<void> resetProgress() async {
    _learned.clear();
    await _prefs?.setStringList(_learnedKey, []);
    for (final c in InstrumentCategory.values) {
      await _prefs?.remove('$_quizScorePrefix${c.name}');
    }
    await _prefs?.remove('${_quizScorePrefix}general');
  }
}
