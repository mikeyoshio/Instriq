import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TechniqueStatus { notYet, practising, confident }

/// "Les meves tècniques": què ha fet ja l'estudiant o la persona nova al
/// bloc, i com s'hi sent. Es guarda només en aquest dispositiu: no s'envia
/// enlloc ni el veu el docent.
class TechniqueLogService {
  TechniqueLogService._();
  static final TechniqueLogService instance = TechniqueLogService._();

  static const _key = 'technique_log';

  /// id de la guia -> estat; les que no hi són, `notYet`.
  final ValueNotifier<Map<String, TechniqueStatus>> statuses = ValueNotifier({});

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    statuses.value = {
      for (final e in raw)
        if (e.contains('|'))
          e.split('|').first: TechniqueStatus.values.firstWhere(
            (s) => s.name == e.split('|').last,
            orElse: () => TechniqueStatus.notYet,
          ),
    };
  }

  TechniqueStatus statusOf(String guideId) => statuses.value[guideId] ?? TechniqueStatus.notYet;

  Future<void> set(String guideId, TechniqueStatus status) async {
    final next = {...statuses.value};
    if (status == TechniqueStatus.notYet) {
      next.remove(guideId);
    } else {
      next[guideId] = status;
    }
    statuses.value = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, [for (final e in next.entries) '${e.key}|${e.value.name}']);
  }
}
