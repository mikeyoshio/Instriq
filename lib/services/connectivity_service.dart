import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Detecta si el dispositivo tiene alguna conexión de red. No garantiza que
/// Supabase sea alcanzable (podría haber wifi sin salida a internet), pero es
/// la señal más barata y fiable de la que disponemos sin hacer una petición
/// de red cada vez que queremos saberlo — suficiente para decidir si se
/// intenta la llamada directa o se pasa por [SyncQueueService]/caché.
class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  final ValueNotifier<bool> isOnline = ValueNotifier(true);

  Future<void> init() async {
    final result = await Connectivity().checkConnectivity();
    isOnline.value = _hasConnection(result);
    Connectivity().onConnectivityChanged.listen((result) {
      isOnline.value = _hasConnection(result);
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  /// true si [error] es un problema de red (sin conexión real, DNS, timeout,
  /// socket) y por tanto merece reintentarse más tarde en vez de tratarse
  /// como un error de negocio (permisos, validación...) que Supabase ya
  /// respondió expresamente. Compartido entre [SyncQueueService] (decide si
  /// reintentar o descartar) y los servicios de lectura (deciden si caer a
  /// [OfflineCacheService]).
  static bool isNetworkError(Object error) {
    if (error is SocketException || error is TimeoutException) return true;
    if (error is AuthException || error is PostgrestException) return false;
    final message = error.toString().toLowerCase();
    return message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('connection') ||
        message.contains('network') ||
        message.contains('clientexception') ||
        message.contains('timeout');
  }
}
