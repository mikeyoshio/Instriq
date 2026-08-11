import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/group_document_version.dart';
import '../models/preference_card.dart';
import 'auth_service.dart';
import 'connectivity_service.dart';
import 'offline_cache_service.dart';
import 'sync_queue_service.dart';

/// CRUD y workflow (borrador -> en revisión -> publicada -> archivada) de
/// tarjetas de preferencia. Calcado de [TrayService], vía funciones
/// `security definer` en Supabase (ver
/// supabase/schema_v22_preference_card_versioning.sql) para que la
/// validación de permisos viva en un único sitio de confianza.
///
/// EPIC 7 (offline first, ver `docs/ADR_003_OFFLINE_STRATEGY.md`): sigue al
/// pie de la letra el patrón ya probado en [GroupDocumentService] — lectura
/// offline vía [OfflineCacheService] siempre, y creación/edición de borrador
/// en cola vía [SyncQueueService] cuando no hay conexión (abrir un borrador
/// nuevo a partir de una versión publicada, en [startEditing], sigue
/// exigiendo conexión: es un punto de coordinación de números de versión).
class PreferenceCardService {
  PreferenceCardService._();
  static final PreferenceCardService instance = PreferenceCardService._();

  SupabaseClient get _client => Supabase.instance.client;

  static const _publishedJoin = '*, published_version:published_version_id(*)';

  List<PreferenceCard> _cards = [];

  /// true si el último [fetchCards] sirvió de [OfflineCacheService] en vez de
  /// red (sin conexión, o la petición falló por un problema de red). La UI
  /// la lee justo después para decidir si mostrar el aviso offline.
  bool cardsFromCache = false;
  DateTime? cardsCachedAt;

  void clear() {
    _cards = [];
  }

  List<PreferenceCard> cardsOfWorkspace(String workspaceId) =>
      _cards.where((c) => c.workspaceId == workspaceId).toList();

  Future<void> fetchCards(String workspaceId) async {
    Future<void> fallbackToCache() async {
      final cached = await OfflineCacheService.instance.getCachedPreferenceCards(workspaceId);
      cardsFromCache = true;
      cardsCachedAt = cached?.cachedAt;
      final fetched = cached?.data ?? [];
      _cards = [
        ..._cards.where((c) => c.workspaceId != workspaceId),
        ...fetched,
      ];
    }

    if (!ConnectivityService.instance.isOnline.value) {
      await fallbackToCache();
      return;
    }
    try {
      final rows =
          await _client.from('preference_cards').select(_publishedJoin).eq('workspace_id', workspaceId);
      final fetched =
          (rows as List<dynamic>).map((r) => PreferenceCard.fromRow(r as Map<String, dynamic>)).toList();
      fetched.sort(
          (a, b) => (a.publishedVersion?.procedureName ?? '').compareTo(b.publishedVersion?.procedureName ?? ''));
      cardsFromCache = false;
      cardsCachedAt = null;
      _cards = [
        ..._cards.where((c) => c.workspaceId != workspaceId),
        ...fetched,
      ];
      await OfflineCacheService.instance
          .cachePreferenceCards(workspaceId, _cards.where((c) => c.workspaceId == workspaceId).toList());
    } catch (e) {
      if (!ConnectivityService.isNetworkError(e)) rethrow;
      await fallbackToCache();
    }
  }

  PreferenceCard? cardById(String id) {
    for (final c in _cards) {
      if (c.id == id) return c;
    }
    return null;
  }

  Future<PreferenceCard> fetchCard(String id) async {
    final row = await _client.from('preference_cards').select(_publishedJoin).eq('id', id).single();
    return PreferenceCard.fromRow(row);
  }

  Future<List<PreferenceCardVersion>> fetchVersionHistory(String cardId) async {
    final rows = await _client
        .from('preference_card_versions')
        .select()
        .eq('card_id', cardId)
        .order('version_number', ascending: false);
    return (rows as List<dynamic>).map((r) => PreferenceCardVersion.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// Crea una tarjeta nueva con su primera versión en borrador.
  Future<PreferenceCardVersion> createCard(String workspaceId) async {
    if (!ConnectivityService.instance.isOnline.value) {
      return SyncQueueService.instance.queueCreatePreferenceCard(workspaceId);
    }
    final versionRow = await _client.rpc('create_preference_card', params: {'p_workspace_id': workspaceId});
    return PreferenceCardVersion.fromRow(versionRow as Map<String, dynamic>);
  }

  /// Devuelve el borrador propio en curso para [card] si existe, o crea uno
  /// nuevo a partir de la versión publicada.
  Future<PreferenceCardVersion> startEditing(PreferenceCard card) async {
    final userId = AuthService.instance.currentUser?.id;
    if (userId == null) {
      throw StateError('Tu usuario no pertenece a ningún grupo todavía.');
    }
    final existing = await _client
        .from('preference_card_versions')
        .select()
        .eq('card_id', card.id)
        .eq('author_id', userId)
        .inFilter('status', ['draft', 'in_review'])
        .order('version_number', ascending: false)
        .limit(1)
        .maybeSingle();
    if (existing != null) {
      final version = PreferenceCardVersion.fromRow(existing);
      // Ver la nota equivalente en GroupDocumentService.startEditing: una
      // versión en revisión no es continuable (la política de UPDATE exige
      // status = 'draft'), así que hay que avisar aquí, no dejar que falle
      // al guardar con un error de Postgres críptico.
      if (version.status == GroupDocumentVersionStatus.inReview) {
        throw StateError('Ya tienes una versión enviada a revisión: no se puede editar hasta que se apruebe, se rechace o se retire.');
      }
      return version;
    }

    final published = card.publishedVersion;
    if (published == null) {
      throw StateError('Esta tarjeta todavía no tiene una versión publicada.');
    }
    final versions = await fetchVersionHistory(card.id);
    final nextVersionNumber =
        versions.isEmpty ? 1 : versions.map((v) => v.versionNumber).reduce((a, b) => a > b ? a : b) + 1;

    final versionRow = await _client
        .from('preference_card_versions')
        .insert({
          'card_id': card.id,
          'version_number': nextVersionNumber,
          'status': GroupDocumentVersionStatus.draft.dbValue,
          'surgeon_id': published.surgeonId,
          'procedure_name': published.procedureName,
          'items': published.items.map((i) => i.toJson()).toList(),
          'general_notes': published.generalNotes,
          'validated_by_surgeon': published.validatedBySurgeon,
          'author_id': userId,
          'based_on_version_id': published.id,
        })
        .select()
        .single();
    return PreferenceCardVersion.fromRow(versionRow);
  }

  Future<PreferenceCardVersion> saveDraft(PreferenceCardVersion version) async {
    if (!ConnectivityService.instance.isOnline.value || SyncQueueService.instance.isPendingLocalId(version.id)) {
      // Un id "local_..." significa que ni la tarjeta llegó a crearse en el
      // servidor todavía (createCard también está en cola): no hay fila real
      // que actualizar, así que esto también se encola.
      return SyncQueueService.instance.queueSavePreferenceCardDraft(version);
    }
    try {
      final row = await _client
          .from('preference_card_versions')
          .update(version.toRow())
          .eq('id', version.id)
          .select()
          .single();
      return PreferenceCardVersion.fromRow(row);
    } catch (e) {
      if (!ConnectivityService.isNetworkError(e)) rethrow;
      return SyncQueueService.instance.queueSavePreferenceCardDraft(version);
    }
  }

  Future<void> submitForReview(String versionId) async {
    if (!ConnectivityService.instance.isOnline.value || SyncQueueService.instance.isPendingLocalId(versionId)) {
      return SyncQueueService.instance.queueSubmitPreferenceCardForReview(versionId);
    }
    try {
      await _client.rpc('submit_preference_card_version_for_review', params: {'p_version_id': versionId});
    } catch (e) {
      if (!ConnectivityService.isNetworkError(e)) rethrow;
      await SyncQueueService.instance.queueSubmitPreferenceCardForReview(versionId);
    }
  }

  Future<void> approve(String versionId, {String? comment}) async {
    await _client.rpc('approve_preference_card_version', params: {
      'p_version_id': versionId,
      'p_review_comment': comment,
    });
  }

  Future<void> reject(String versionId, {String? comment}) async {
    await _client.rpc('reject_preference_card_version', params: {
      'p_version_id': versionId,
      'p_review_comment': comment,
    });
  }

  Future<String> restore(String versionId) async {
    final newId = await _client.rpc('restore_preference_card_version', params: {'p_version_id': versionId});
    return newId as String;
  }

  /// Versiones en revisión de todo el grupo, para la cola de aprobación.
  Future<List<PreferenceCardVersion>> fetchReviewQueue() async {
    final rows = await _client
        .from('preference_card_versions')
        .select()
        .eq('status', GroupDocumentVersionStatus.inReview.dbValue)
        .order('created_at');
    return (rows as List<dynamic>).map((r) => PreferenceCardVersion.fromRow(r as Map<String, dynamic>)).toList();
  }

  /// Nombre del espacio de cada tarjeta, para mostrar contexto en la cola de revisión.
  Future<Map<String, String>> fetchWorkspaceNamesForCards(List<String> cardIds) async {
    if (cardIds.isEmpty) return {};
    final rows =
        await _client.from('preference_cards').select('id, workspaces(name)').inFilter('id', cardIds);
    final result = <String, String>{};
    for (final r in (rows as List<dynamic>)) {
      final row = r as Map<String, dynamic>;
      final workspaceRow = row['workspaces'] as Map<String, dynamic>?;
      if (workspaceRow?['name'] != null) {
        result[row['id'] as String] = workspaceRow!['name'] as String;
      }
    }
    return result;
  }

  Future<void> deleteCard(String id) async {
    await _client.from('preference_cards').delete().eq('id', id);
    _cards.removeWhere((c) => c.id == id);
  }

  /// Marca/desmarca "validado por el cirujano" directamente sobre la versión
  /// publicada, sin pasar por el workflow de borrador/revisión: es una
  /// anotación posterior (no cambia qué instrumental pide la tarjeta), a
  /// diferencia del resto de campos que si son contenido clínico versionado.
  /// NOTA: no queda registrado en el historial de versiones como un cambio
  /// propio — a revisar si en el uso real se necesita más trazabilidad aquí.
  Future<void> setValidatedBySurgeon(String versionId, bool validated) async {
    await _client
        .from('preference_card_versions')
        .update({'validated_by_surgeon': validated}).eq('id', versionId);
  }

  /// Tarjetas de un cirujano concreto (por su versión PUBLICADA), para
  /// [SurgeonDetailScreen] — cruza workspaces (la RLS ya limita al grupo
  /// actual).
  Future<List<PreferenceCard>> fetchForSurgeon(String surgeonId) async {
    final rows = await _client
        .from('preference_card_versions')
        .select('*, preference_cards(*)')
        .eq('surgeon_id', surgeonId)
        .eq('status', GroupDocumentVersionStatus.published.dbValue)
        .order('procedure_name');
    final result = <PreferenceCard>[];
    for (final r in (rows as List<dynamic>)) {
      final row = r as Map<String, dynamic>;
      final cardRow = row['preference_cards'] as Map<String, dynamic>?;
      if (cardRow == null) continue;
      final version = PreferenceCardVersion.fromRow(row);
      result.add(PreferenceCard.fromRow(cardRow).copyWith(publishedVersion: version));
    }
    return result;
  }
}
