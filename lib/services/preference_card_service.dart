import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/preference_card.dart';

class PreferenceCardService {
  PreferenceCardService._();
  static final PreferenceCardService instance = PreferenceCardService._();

  static const _cardsKey = 'preference_cards';

  SharedPreferences? _prefs;
  List<PreferenceCard> _cards = [];

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_cardsKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _cards = decoded
          .map((e) => PreferenceCard.fromJson(e as Map<String, dynamic>))
          .toList();
    }
  }

  List<PreferenceCard> get cards => List.unmodifiable(_cards);

  List<String> get surgeonNames {
    final names = _cards.map((c) => c.surgeonName).toSet().toList();
    names.sort();
    return names;
  }

  List<PreferenceCard> cardsForSurgeon(String surgeonName) {
    return _cards.where((c) => c.surgeonName == surgeonName).toList();
  }

  Future<void> _persist() async {
    final encoded = jsonEncode(_cards.map((c) => c.toJson()).toList());
    await _prefs?.setString(_cardsKey, encoded);
  }

  Future<void> upsertCard(PreferenceCard card) async {
    final index = _cards.indexWhere((c) => c.id == card.id);
    if (index == -1) {
      _cards.add(card);
    } else {
      _cards[index] = card;
    }
    await _persist();
  }

  Future<void> deleteCard(String id) async {
    _cards.removeWhere((c) => c.id == id);
    await _persist();
  }
}
