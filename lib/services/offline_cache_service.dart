import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/group_document.dart';
import '../models/group_document_version.dart';

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
/// técnicas/protocolos, para que las pantallas de lectura sigan funcionando
/// sin conexión con el último contenido sincronizado. No es una base de
/// datos: solo el último snapshot por workspace/documento, suficiente para
/// el volumen de datos de la app.
///
/// Las tarjetas de preferencia ya no se cachean aquí: con el modelo de
/// versiones (Fase E) una tarjeta es cabecera + versión publicada, no una
/// fila plana — ver la nota de regresión offline en
/// [PreferenceCardService].
class OfflineCacheService {
  OfflineCacheService._();
  static final OfflineCacheService instance = OfflineCacheService._();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _sp async => _prefs ??= await SharedPreferences.getInstance();

  static String _documentsKey(String workspaceId) => 'cache_group_documents_$workspaceId';
  static String _versionHistoryKey(String documentId) => 'cache_group_document_versions_$documentId';
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
}
