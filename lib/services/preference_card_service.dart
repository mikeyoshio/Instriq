import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/preference_card.dart';
import 'connectivity_service.dart';
import 'offline_cache_service.dart';
import 'profile_service.dart';
import 'sync_queue_service.dart';

class PreferenceCardService {
  PreferenceCardService._();
  static final PreferenceCardService instance = PreferenceCardService._();

  SupabaseClient get _client => Supabase.instance.client;

  List<PreferenceCard> _cards = [];

  /// true si el último [fetchCards] sirvió de [OfflineCacheService] en vez de
  /// red. La UI la lee justo después para decidir si mostrar el aviso offline.
  bool cardsFromCache = false;
  DateTime? cardsCachedAt;

  List<PreferenceCard> get cards => List.unmodifiable(_cards);

  /// Limpia el caché en memoria. Debe llamarse al cambiar de grupo o cerrar
  /// sesión: si no, una tarjeta de un grupo anterior puede quedar cacheada.
  void clear() {
    _cards = [];
  }

  /// Ids (posiblemente null) de los cirujanos con al menos una tarjeta en el
  /// caché actual — la UI resuelve el nombre a mostrar vía [SurgeonService].
  List<String?> get surgeonIds {
    final ids = _cards.map((c) => c.surgeonId).toSet().toList();
    ids.sort((a, b) => (a ?? '').compareTo(b ?? ''));
    return ids;
  }

  List<PreferenceCard> cardsForSurgeon(String? surgeonId) {
    return _cards.where((c) => c.surgeonId == surgeonId).toList();
  }

  /// Trae las tarjetas del espacio indicado (el hospital ya lo filtra RLS en el servidor).
  Future<void> fetchCards(String workspaceId) async {
    Future<void> fallbackToCache() async {
      final cached = await OfflineCacheService.instance.getCachedCards(workspaceId);
      cardsFromCache = true;
      cardsCachedAt = cached?.cachedAt;
      _cards = cached?.data ?? [];
    }

    if (!ConnectivityService.instance.isOnline.value) {
      await fallbackToCache();
      return;
    }
    try {
      final rows = await _client
          .from('preference_cards')
          .select()
          .eq('workspace_id', workspaceId)
          .order('procedure_name');
      _cards = (rows as List<dynamic>)
          .map((r) => PreferenceCard.fromRow(r as Map<String, dynamic>))
          .toList();
      cardsFromCache = false;
      cardsCachedAt = null;
      await OfflineCacheService.instance.cacheCards(workspaceId, _cards);
    } catch (e) {
      if (!ConnectivityService.isNetworkError(e)) rethrow;
      await fallbackToCache();
    }
  }

  Future<void> upsertCard(PreferenceCard card) async {
    if (!ConnectivityService.instance.isOnline.value || SyncQueueService.instance.isPendingLocalId(card.id)) {
      final pending = await SyncQueueService.instance.queueUpsertCard(card);
      final index = _cards.indexWhere((c) => c.id == card.id);
      if (index == -1) {
        _cards.add(pending);
      } else {
        _cards[index] = pending;
      }
      return;
    }
    final organizationId = ProfileService.instance.organizationId;
    if (organizationId == null) {
      throw StateError('El usuario no pertenece a ningún hospital todavía.');
    }
    final row = card.toRow(organizationId: organizationId);
    try {
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
    } catch (e) {
      if (!ConnectivityService.isNetworkError(e)) rethrow;
      final pending = await SyncQueueService.instance.queueUpsertCard(card);
      final index = _cards.indexWhere((c) => c.id == card.id);
      if (index == -1) {
        _cards.add(pending);
      } else {
        _cards[index] = pending;
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

  /// Fetch puntual por id (sin pasar por el caché de workspace) — usado por
  /// `ref_resolver.dart` para resolver un ref `preference_card` (p.ej. desde
  /// la pantalla de una etiqueta) sin haber cargado antes todo el espacio al
  /// que pertenece. Mismo patrón que [CustomInstrumentService.fetchById].
  Future<PreferenceCard> fetchById(String id) async {
    final row = await _client.from('preference_cards').select().eq('id', id).single();
    return PreferenceCard.fromRow(row);
  }

  /// Tarjetas de un cirujano concreto, para [SurgeonDetailScreen] — cruza
  /// workspaces (la RLS ya limita al grupo actual), así que no pasa por el
  /// caché por-workspace de [fetchCards].
  Future<List<PreferenceCard>> fetchForSurgeon(String surgeonId) async {
    final rows = await _client
        .from('preference_cards')
        .select()
        .eq('surgeon_id', surgeonId)
        .order('procedure_name');
    return (rows as List<dynamic>)
        .map((r) => PreferenceCard.fromRow(r as Map<String, dynamic>))
        .toList();
  }
}
