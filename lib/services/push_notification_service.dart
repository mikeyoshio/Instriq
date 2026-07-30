import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Registro de notificaciones push (FCM). El servidor (Edge Function
/// `send-push`, ver supabase/functions/send-push) decide cuándo avisar
/// (contenido enviado a revisión, aprobado o rechazado) a partir del log de
/// auditoría; este servicio solo se encarga de pedir permiso, obtener el
/// token del dispositivo y mantenerlo sincronizado en `device_tokens`
/// mientras haya sesión iniciada.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final SupabaseClient _client = Supabase.instance.client;
  String? _registeredToken;

  /// Pide permiso y registra el token actual. Se llama una vez que hay
  /// sesión iniciada (sin usuario no hay a quién asociar el token). No
  /// lanza si algo falla -- las notificaciones son un extra, nunca deben
  /// bloquear el uso de la app.
  Future<void> initForCurrentUser() async {
    if (_client.auth.currentUser == null) return;
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await messaging.getToken();
      if (token != null) await _registerToken(token);

      messaging.onTokenRefresh.listen(_registerToken);

      FirebaseMessaging.onMessage.listen((_) {
        // Notificación en primer plano: FCM no muestra un banner nativo
        // automáticamente en Android/iOS cuando la app está abierta. De
        // momento no mostramos nada propio (evita depender de una librería
        // de notificaciones locales adicional) -- el usuario ya ve el
        // contenido actualizado la próxima vez que entra en la pantalla
        // correspondiente. Ampliable más adelante con flutter_local_notifications
        // si hace falta un aviso visible en primer plano.
      });
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('PushNotificationService.initForCurrentUser: $e');
      }
    }
  }

  Future<void> _registerToken(String token) async {
    if (token == _registeredToken) return;
    try {
      await _client.rpc('register_device_token', params: {
        'p_fcm_token': token,
        'p_platform': _platformName(),
      });
      _registeredToken = token;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('PushNotificationService._registerToken: $e');
      }
    }
  }

  /// Al cerrar sesión, se desregistra el token de este dispositivo para que
  /// deje de recibir avisos de un hospital/cuenta que ya no le corresponde.
  Future<void> unregisterCurrentToken() async {
    final token = _registeredToken;
    if (token == null) return;
    try {
      await _client.rpc('unregister_device_token', params: {'p_fcm_token': token});
    } catch (_) {
      // No crítico: si falla, el token queda huérfano y la Edge Function lo
      // limpiará sola la próxima vez que un envío le devuelva UNREGISTERED.
    } finally {
      _registeredToken = null;
    }
  }

  String _platformName() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    return 'android';
  }
}
