import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/group_document.dart';
import '../models/group_document_version.dart';
import '../models/instrument_sterilization.dart';
import '../models/preference_card.dart';
import '../models/tray.dart';

/// Envuelve un resultado que puede venir de red o de caché, para que la UI
/// pueda distinguir y mostrar el aviso "sin conexión" cuando corresponda.
class CachedResult<T> {
  final T data;
  final bool isFromCache;
  final DateTime? cachedAt;

  const CachedResult({required this.data, required this.isFromCache, this.cachedAt});
}

/// Guarda en `shared_preferences` (como JSON, mismo patrón que
/// [ThemeService]/[LocaleService]) el último resultado conocido de red para
/// técnicas/protocolos/bandejas/tarjetas, para que las pantallas de lectura
/// sigan funcionando sin conexión con el último contenido sincronizado. No es
/// una base de datos: solo el último snapshot por workspace/documento,
/// suficiente para el volumen de datos de la app.
///
/// ADR-003 (`docs/ADR_003_OFFLINE_STRATEGY.md`, punto 3): la lectura offline
/// es la prioridad real de EPIC 7 -- consultar una bandeja o tarjeta durante
/// una intervención sin wifi importa más que poder editarla sin conexión.
/// Esterilización/ficha técnica se cachean por instrumento (`refType`/`refId`),
/// no por workspace como el resto -- no hay una pantalla de listado navegable,
/// se consultan siempre desde la ficha de un instrumento concreto.
class OfflineCacheService {
  OfflineCacheService._();
  static final OfflineCacheService instance = OfflineCacheService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sp async => _prefs ??= await SharedPreferences.getInstance();

  static String _documentsKey(String workspaceId) => 'cache_group_documents_$workspaceId';
  static String _versionHistoryKey(String documentId) => 'cache_group_document_versions_$documentId';
  static String _traysKey(String workspaceId) => 'cache_trays_$workspaceId';
  static String _preferenceCardsKey(String workspaceId) => 'cache_preference_cards_$workspaceId';
  static String _sterilizationMethodsKey(String refType, String refId) =>
      'cache_sterilization_methods_${refType}_$refId';
  static String _technicalInfoKey(String refType, String refId) => 'cache_technical_info_${refType}_$refId';
  static const _timestampSuffix = '_cached_at';

  Future<void> _write(String key, dynamic jsonValue) async {
    final prefs = await _sp;
    await prefs.setString(key, jsonEncode(jsonValue));
    await prefs.setString('$key$_timestampSuffix', DateTime.now().toIso8601String());
  }

  DateTime? _timestampFor(SharedPreferences prefs, String key) {
    final raw = prefs.getString('$key$_timestampSuffix');
    return raw != null ? DateTime.tryParse(raw) : null;
  }

  // --- Técnicas / protocolos: lista por workspace (filtrada por kind al leer) ---

  Future<void> cacheDocuments(String workspaceId, List<GroupDocument> documents) async {
    await _write(_documentsKey(workspaceId), documents.map((d) => d.toCacheRow()).toList());
  }

  Future<CachedResult<List<GroupDocument>>?> getCachedDocuments(String workspaceId) async {
    final prefs = await _sp;
    final key = _documentsKey(workspaceId);
    final raw = prefs.getString(key);
    if (raw == null) return null;
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((r) => GroupDocument.fromRow((r as Map).cast<String, dynamic>()))
        .toList();
    return CachedResult(data: list, isFromCache: true, cachedAt: _timestampFor(prefs, key));
  }

  // --- Historial de versiones de un documento concreto ---

  Future<void> cacheVersionHistory(String documentId, List<GroupDocumentVersion> versions) async {
    await _write(_versionHistoryKey(documentId), versions.map((v) => v.toCacheRow()).toList());
  }

  Future<CachedResult<List<GroupDocumentVersion>>?> getCachedVersionHistory(String documentId) async {
    final prefs = await _sp;
    final key = _versionHistoryKey(documentId);
    final raw = prefs.getString(key);
    if (raw == null) return null;
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((r) => GroupDocumentVersion.fromRow((r as Map).cast<String, dynamic>()))
        .toList();
    return CachedResult(data: list, isFromCache: true, cachedAt: _timestampFor(prefs, key));
  }

  // --- Bandejas: lista por workspace (solo cabecera + versión publicada) ---

  Future<void> cacheTrays(String workspaceId, List<Tray> trays) async {
    await _write(_traysKey(workspaceId), trays.map((t) => t.toCacheRow()).toList());
  }

  Future<CachedResult<List<Tray>>?> getCachedTrays(String workspaceId) async {
    final prefs = await _sp;
    final key = _traysKey(workspaceId);
    final raw = prefs.getString(key);
    if (raw == null) return null;
    final list =
        (jsonDecode(raw) as List<dynamic>).map((r) => Tray.fromRow((r as Map).cast<String, dynamic>())).toList();
    return CachedResult(data: list, isFromCache: true, cachedAt: _timestampFor(prefs, key));
  }

  // --- Tarjetas de preferencia: lista por workspace (cabecera + publicada) ---

  Future<void> cachePreferenceCards(String workspaceId, List<PreferenceCard> cards) async {
    await _write(_preferenceCardsKey(workspaceId), cards.map((c) => c.toCacheRow()).toList());
  }

  Future<CachedResult<List<PreferenceCard>>?> getCachedPreferenceCards(String workspaceId) async {
    final prefs = await _sp;
    final key = _preferenceCardsKey(workspaceId);
    final raw = prefs.getString(key);
    if (raw == null) return null;
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((r) => PreferenceCard.fromRow((r as Map).cast<String, dynamic>()))
        .toList();
    return CachedResult(data: list, isFromCache: true, cachedAt: _timestampFor(prefs, key));
  }

  // --- Esterilización / ficha técnica: por instrumento (refType/refId), no por workspace ---

  Future<void> cacheSterilizationMethods(String refType, String refId, List<SterilizationMethodEntry> methods) async {
    await _write(_sterilizationMethodsKey(refType, refId), methods.map((m) => m.toCacheRow()).toList());
  }

  Future<CachedResult<List<SterilizationMethodEntry>>?> getCachedSterilizationMethods(
    String refType,
    String refId,
  ) async {
    final prefs = await _sp;
    final key = _sterilizationMethodsKey(refType, refId);
    final raw = prefs.getString(key);
    if (raw == null) return null;
    final list = (jsonDecode(raw) as List<dynamic>)
        .map((r) => SterilizationMethodEntry.fromRow((r as Map).cast<String, dynamic>()))
        .toList();
    return CachedResult(data: list, isFromCache: true, cachedAt: _timestampFor(prefs, key));
  }

  /// [InstrumentTechnicalInfo] es opcional por instrumento -- `null` es un
  /// valor cacheado válido (confirma "sin ficha técnica"), distinto de "nunca
  /// se cacheó" (`raw == null`, sin ir nunca online). `_write` serializa
  /// `null` como el string JSON `"null"`, no como ausencia de la clave.
  Future<void> cacheTechnicalInfo(String refType, String refId, InstrumentTechnicalInfo? info) async {
    await _write(_technicalInfoKey(refType, refId), info?.toCacheRow());
  }

  Future<CachedResult<InstrumentTechnicalInfo?>?> getCachedTechnicalInfo(String refType, String refId) async {
    final prefs = await _sp;
    final key = _technicalInfoKey(refType, refId);
    final raw = prefs.getString(key);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    final info = decoded == null ? null : InstrumentTechnicalInfo.fromRow((decoded as Map).cast<String, dynamic>());
    return CachedResult(data: info, isFromCache: true, cachedAt: _timestampFor(prefs, key));
  }
}
