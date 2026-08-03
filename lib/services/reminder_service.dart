import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'locale_service.dart';
import 'progress_service.dart';

/// Recordatorio diario de repaso pendiente (EPIC 8 · Contextual Learning):
/// una única notificación local a una hora fija, no una por instrumento (se
/// evita el spam de una notificación por ítem). Se recalcula cada vez que se
/// llama a [refresh] (al reanudar/iniciar sesión, al terminar una sesión de
/// repaso) — sin infraestructura de servidor, es una aproximación simple a
/// propósito (ver docs/BACKLOG.md, EPIC 8 primer tramo).
///
/// El texto va hardcodeado por idioma (no vía `AppLocalizations`): este
/// servicio se llama también desde `main.dart` antes de que haya un
/// `BuildContext` localizado a mano — mismo criterio que `WorkMode.label`
/// (placeholder fijo cuando no hay contexto, la app usa `LocaleService`
/// directamente en vez de forzar un context por aquí).
class ReminderService {
  ReminderService._();
  static final ReminderService instance = ReminderService._();

  static const _notificationId = 1001;
  static const _hour = 9;

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  (String, String) _localizedText() {
    switch (LocaleService.instance.locale.value.languageCode) {
      case 'es':
        return ('Tienes repasos pendientes', 'Hay instrumental esperando un repaso hoy.');
      case 'en':
        return ('You have reviews pending', 'Some instruments are waiting for a review today.');
      case 'ca':
      default:
        return ('Tens repassos pendents', 'Hi ha instrumental esperant un repàs avui.');
    }
  }

  /// Recalcula cuántos instrumentos tienen repaso pendiente y reprograma (o
  /// cancela) el recordatorio diario en consecuencia.
  Future<void> refresh() async {
    if (kIsWeb) return; // notificaciones locales no soportadas en target web
    try {
      await _ensureInitialized();
      if (ProgressService.instance.dueCount() <= 0) {
        await cancel();
        return;
      }
      final (title, body) = _localizedText();
      await _plugin.zonedSchedule(
        _notificationId,
        title,
        body,
        _nextInstanceOfHour(_hour),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'learning_reminders',
            'Recordatoris de repàs',
            importance: Importance.defaultImportance,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.wallClockTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (_) {
      // El recordatorio es un extra: permiso denegado, plataforma no
      // soportada, etc. no debe romper nada más de la app.
    }
  }

  Future<void> cancel() async {
    if (kIsWeb) return;
    try {
      await _ensureInitialized();
      await _plugin.cancel(_notificationId);
    } catch (_) {
      // Ver comentario de refresh().
    }
  }

  tz.TZDateTime _nextInstanceOfHour(int hour) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }
}
