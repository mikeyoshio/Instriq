import 'package:shared_preferences/shared_preferences.dart';

/// Últimes fitxes d'instrument obertes, guardades només al dispositiu.
/// Funciona també en mode convidat i sense connexió (a diferència de
/// [RecentActivityService], que viu a Supabase i necessita compte): és el
/// que Omnihub ensenya a dalt per tornar a una peça en un toc.
class RecentInstrumentsService {
  RecentInstrumentsService._();
  static final RecentInstrumentsService instance = RecentInstrumentsService._();

  static const _key = 'recent_instruments';
  static const _max = 6;

  Future<void> add(String instrumentId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ids = prefs.getStringList(_key) ?? [];
      ids
        ..remove(instrumentId)
        ..insert(0, instrumentId);
      await prefs.setStringList(_key, ids.take(_max).toList());
    } catch (_) {
      // Només és una drecera: si falla, no passa res.
    }
  }

  Future<List<String>> ids() async {
    try {
      return (await SharedPreferences.getInstance()).getStringList(_key) ?? [];
    } catch (_) {
      return [];
    }
  }
}
