import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/preference_card.dart';
import 'profile_service.dart';

class PreferenceCardService {
  PreferenceCardService._();
  static final PreferenceCardService instance = PreferenceCardService._();

  SupabaseClient get _client => Supabase.instance.client;

  List<PreferenceCard> _cards = [];

  List<PreferenceCard> get cards => List.unmodifiable(_cards);

  List<String> get surgeonNames {
    final names = _cards.map((c) => c.surgeonName).toSet().toList();
    names.sort();
    return names;
  }

  List<PreferenceCard> cardsForSurgeon(String surgeonName) {
    return _cards.where((c) => c.surgeonName == surgeonName).toList();
  }

  /// Trae las tarjetas del espacio indicado (el hospital ya lo filtra RLS en el servidor).
  Future<void> fetchCards(String workspaceId) async {
    final rows = await _client
        .from('preference_cards')
        .select()
        .eq('workspace_id', workspaceId)
        .order('surgeon_name')
        .order('procedure_name');
    _cards = (rows as List<dynamic>)
        .map((r) => PreferenceCard.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  Future<void> upsertCard(PreferenceCard card) async {
    final hospitalId = ProfileService.instance.hospitalId;
    if (hospitalId == null) {
      throw StateError('El usuario no pertenece a ningún hospital todavía.');
    }
    final row = card.toRow(hospitalId: hospitalId);
    if (card.id.isEmpty) {
      final inserted = await _client.from('preference_cards').insert(row).select().single();
      _cards.add(PreferenceCard.fromRow(inserted));
    } else {
      final updated = await _client
          .from('preference_cards')
          .update(row)
          .eq('id', card.id)
          .select()
          .single();
      final index = _cards.indexWhere((c) => c.id == card.id);
      final saved = PreferenceCard.fromRow(updated);
      if (index == -1) {
        _cards.add(saved);
      } else {
        _cards[index] = saved;
      }
    }
  }

  Future<void> setValidated(String id, bool validated) async {
    await _client.from('preference_cards').update({'validated': validated}).eq('id', id);
    final index = _cards.indexWhere((c) => c.id == id);
    if (index != -1) {
      _cards[index] = _cards[index].copyWith(validated: validated);
    }
  }

  Future<void> deleteCard(String id) async {
    await _client.from('preference_cards').delete().eq('id', id);
    _cards.removeWhere((c) => c.id == id);
  }
}
