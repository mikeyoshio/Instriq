import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/instruments_data.dart';
import '../models/instrument.dart';
import 'auth_service.dart';

/// Intervalos fijos (en días) de un Leitner de 5 cajas — repetición espaciada
/// simple (EPIC 8), no un algoritmo adaptativo tipo SM-2. Índice = caja - 1.
const List<int> kLeitnerIntervalsDays = [1, 3, 7, 14, 30];

class _LearningEntry {
  bool learned;
  int box;
  DateTime? nextReviewAt;

  _LearningEntry({this.learned = false, this.box = 1, this.nextReviewAt});
}

/// Progreso de aprendizaje (instrumentos marcados como aprendidos, mejores
/// puntuaciones de quiz, y programación de repetición espaciada). Backend
/// dual, calcado del criterio de todo el resto de la app:
///
/// - **Invitado** (sin sesión): igual que siempre, solo `shared_preferences`
///   — no regresiona una función que hoy funciona sin cuenta.
/// - **Con sesión**: `learning_progress` (Supabase) es la fuente de verdad,
///   cacheada en memoria (mismo patrón que [TrayService]/[GroupDocumentService]);
///   escritura directa por RLS, sin RPC — no es una acción sensible que
///   necesite auditoría (mismo criterio que `active_work_mode`).
///
/// Migración única: la primera vez que hay sesión y el servidor no tiene
/// filas pero sí había progreso local (invitado que crea/entra en una
/// cuenta), se sube una vez — ver [syncFromServer].
class ProgressService {
  ProgressService._();
  static final ProgressService instance = ProgressService._();

  static const _learnedKey = 'learned_ids';
  static const _quizScorePrefix = 'quiz_best_';

  SupabaseClient get _client => Supabase.instance.client;
  bool get _authenticated => AuthService.instance.currentUser != null;

  SharedPreferences? _prefs;
  Set<String> _localLearned = {};

  Map<String, _LearningEntry> _serverEntries = {};
  Map<String, int> _serverQuizScores = {};

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _localLearned = (_prefs?.getStringList(_learnedKey) ?? []).toSet();
  }

  /// Carga el progreso del servidor tras iniciar sesión (o al reanudar una
  /// sesión persistida) — se llama desde el listener de `authStateChanges`
  /// en `main.dart`, en `signedIn` e `initialSession`.
  Future<void> syncFromServer() async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    try {
      final rows = await _client.from('learning_progress').select().eq('user_id', userId);
      final entries = <String, _LearningEntry>{};
      for (final r in (rows as List<dynamic>)) {
        final row = r as Map<String, dynamic>;
        if (row['ref_type'] != 'catalog') continue; // la UI actual solo opera sobre catálogo
        entries[row['ref_id'] as String] = _LearningEntry(
          learned: row['learned_at'] != null,
          box: row['box'] as int? ?? 1,
          nextReviewAt:
              row['next_review_at'] != null ? DateTime.tryParse(row['next_review_at'] as String) : null,
        );
      }

      // Migración única invitado -> primera sesión: si el servidor no tenía
      // filas todavía y había progreso local, se sube una vez para no
      // perder lo ya hecho como invitado.
      if (entries.isEmpty && _localLearned.isNotEmpty) {
        for (final id in _localLearned) {
          entries[id] = _LearningEntry(learned: true);
          try {
            await _client.from('learning_progress').upsert({
              'user_id': userId,
              'ref_type': 'catalog',
              'ref_id': id,
              'learned_at': DateTime.now().toIso8601String(),
            }, onConflict: 'user_id,ref_type,ref_id');
          } catch (_) {
            // Un id fallando no bloquea el resto de la migración.
          }
        }
      }

      final profileRow =
          await _client.from('profiles').select('quiz_best_scores').eq('id', userId).maybeSingle();
      final quizScores = <String, int>{};
      final rawScores = (profileRow?['quiz_best_scores'] as Map<String, dynamic>?) ?? const {};
      rawScores.forEach((k, v) => quizScores[k] = (v as num).toInt());

      _serverEntries = entries;
      _serverQuizScores = quizScores;
    } catch (_) {
      // Sin bloquear el arranque si falla: se conserva el estado anterior.
    }
  }

  /// Al cerrar sesión: se vacía la caché de servidor, las lecturas vuelven a
  /// caer en modo invitado (`shared_preferences`) hasta el próximo login.
  void clear() {
    _serverEntries = {};
    _serverQuizScores = {};
  }

  bool isLearned(String id) {
    if (_authenticated) return _serverEntries[id]?.learned ?? false;
    return _localLearned.contains(id);
  }

  Future<void> toggleLearned(String id) async {
    if (_authenticated) {
      final userId = AuthService.instance.currentUser!.id;
      final wasLearned = _serverEntries[id]?.learned ?? false;
      final entry = _serverEntries.putIfAbsent(id, () => _LearningEntry());
      entry.learned = !wasLearned;
      try {
        if (entry.learned) {
          await _client.from('learning_progress').upsert({
            'user_id': userId,
            'ref_type': 'catalog',
            'ref_id': id,
            'learned_at': DateTime.now().toIso8601String(),
          }, onConflict: 'user_id,ref_type,ref_id');
        } else {
          await _client
              .from('learning_progress')
              .update({'learned_at': null})
              .eq('user_id', userId)
              .eq('ref_type', 'catalog')
              .eq('ref_id', id);
        }
      } catch (_) {
        // Metadato de progreso: no crítico, no se reintenta con una cola.
      }
      return;
    }
    if (_localLearned.contains(id)) {
      _localLearned.remove(id);
    } else {
      _localLearned.add(id);
    }
    await _prefs?.setStringList(_learnedKey, _localLearned.toList());
  }

  int get learnedCount => _authenticated
      ? _serverEntries.values.where((e) => e.learned).length
      : _localLearned.length;

  int get totalCount => kInstruments.length;

  double get overallProgress => totalCount == 0 ? 0 : learnedCount / totalCount;

  int learnedCountForCategory(InstrumentCategory category) {
    if (_authenticated) {
      return kInstruments
          .where((i) => i.category == category && (_serverEntries[i.id]?.learned ?? false))
          .length;
    }
    return kInstruments.where((i) => i.category == category && _localLearned.contains(i.id)).length;
  }

  int totalCountForCategory(InstrumentCategory category) {
    return kInstruments.where((i) => i.category == category).length;
  }

  Future<void> saveQuizResult(InstrumentCategory? category, int score, int total) async {
    final key = category?.name ?? 'general';
    if (_authenticated) {
      final best = _serverQuizScores[key] ?? 0;
      if (score <= best) return;
      _serverQuizScores[key] = score;
      final userId = AuthService.instance.currentUser!.id;
      try {
        await _client
            .from('profiles')
            .update({'quiz_best_scores': Map<String, dynamic>.from(_serverQuizScores)}).eq('id', userId);
      } catch (_) {
        // Metadato de progreso: no crítico, no se reintenta con una cola.
      }
      return;
    }
    final localKey = '$_quizScorePrefix$key';
    final best = _prefs?.getInt(localKey) ?? 0;
    if (score > best) {
      await _prefs?.setInt(localKey, score);
    }
  }

  int quizBestScore(InstrumentCategory? category) {
    final key = category?.name ?? 'general';
    if (_authenticated) return _serverQuizScores[key] ?? 0;
    return _prefs?.getInt('$_quizScorePrefix$key') ?? 0;
  }

  /// Caja Leitner actual de un instrumento (1-5, por defecto 1 si nunca se
  /// ha repasado) — EPIC 8 · Contextual Learning. Solo con sesión: la
  /// repetición espaciada exige estado de servidor (ver contexto del plan).
  int boxFor(String id) => _serverEntries[id]?.box ?? 1;

  DateTime? nextReviewAt(String id) => _serverEntries[id]?.nextReviewAt;

  /// Cuántos instrumentos tienen un repaso pendiente hoy o antes. `0` sin
  /// sesión (no hay programación de servidor que consultar en modo invitado).
  int dueCount() {
    if (!_authenticated) return 0;
    final now = DateTime.now();
    return _serverEntries.values.where((e) => e.nextReviewAt != null && !e.nextReviewAt!.isAfter(now)).length;
  }

  /// Registra el resultado de una sesión de repaso y reprograma la caja
  /// Leitner correspondiente. Requiere sesión — no-op si no hay usuario.
  Future<void> recordReviewResult(String id, bool correct) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) return;
    final currentBox = _serverEntries[id]?.box ?? 1;
    final newBox = correct ? (currentBox + 1).clamp(1, kLeitnerIntervalsDays.length) : 1;
    final nextReview = DateTime.now().add(Duration(days: kLeitnerIntervalsDays[newBox - 1]));
    final entry = _serverEntries.putIfAbsent(id, () => _LearningEntry());
    entry.box = newBox;
    entry.nextReviewAt = nextReview;
    try {
      await _client.from('learning_progress').upsert({
        'user_id': userId,
        'ref_type': 'catalog',
        'ref_id': id,
        'box': newBox,
        'next_review_at': nextReview.toIso8601String(),
      }, onConflict: 'user_id,ref_type,ref_id');
    } catch (_) {
      // Metadato de progreso: no crítico, no se reintenta con una cola.
    }
  }

  Future<void> resetProgress() async {
    if (_authenticated) {
      final userId = AuthService.instance.currentUser!.id;
      _serverEntries = {};
      _serverQuizScores = {};
      try {
        await _client.from('learning_progress').delete().eq('user_id', userId);
        await _client.from('profiles').update({'quiz_best_scores': <String, dynamic>{}}).eq('id', userId);
      } catch (_) {
        // Metadato de progreso: no crítico.
      }
      return;
    }
    _localLearned.clear();
    await _prefs?.setStringList(_learnedKey, []);
    for (final c in InstrumentCategory.values) {
      await _prefs?.remove('$_quizScorePrefix${c.name}');
    }
    await _prefs?.remove('${_quizScorePrefix}general');
  }
}
