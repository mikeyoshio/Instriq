import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:instriq/services/connectivity_service.dart';

/// isNetworkError es el único punto de decisión compartido entre
/// SyncQueueService y los servicios de lectura para "reintentar más tarde"
/// vs. "error de negocio, no reintentar". El orden de sus comprobaciones
/// importa: SocketException/TimeoutException siempre son red; en cambio
/// AuthException/PostgrestException son SIEMPRE negocio, aunque su mensaje
/// contenga palabras como "timeout" o "network" (p.ej. una RLS que rechaza
/// con un mensaje que menciona la palabra "conexión") -- un reordenamiento
/// futuro que comprobara los substrings antes que el tipo invertiría ese
/// comportamiento en silencio (hallazgo de auditoría de cara a la v1.0).
void main() {
  group('ConnectivityService.isNetworkError', () {
    test('SocketException is always a network error', () {
      expect(ConnectivityService.isNetworkError(const SocketException('Failed host lookup')), true);
    });

    test('TimeoutException is always a network error', () {
      expect(ConnectivityService.isNetworkError(TimeoutException('timed out')), true);
    });

    test('PostgrestException is never treated as a network error, even mentioning network words', () {
      const error = PostgrestException(message: 'connection refused by RLS policy: network access denied');
      expect(ConnectivityService.isNetworkError(error), false);
    });

    test('AuthException is never treated as a network error, even mentioning network words', () {
      const error = AuthException('network timeout while validating token');
      expect(ConnectivityService.isNetworkError(error), false);
    });

    test('a generic exception with a network-ish message is a network error', () {
      expect(ConnectivityService.isNetworkError(Exception('Failed host lookup: no address associated')), true);
      expect(ConnectivityService.isNetworkError(Exception('Connection timeout')), true);
      expect(ConnectivityService.isNetworkError(Exception('ClientException: Connection reset')), true);
    });

    test('a generic exception with an unrelated message is not a network error', () {
      expect(ConnectivityService.isNetworkError(Exception('permission denied')), false);
      expect(ConnectivityService.isNetworkError(Exception('invalid uuid')), false);
    });
  });
}
