import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/connectivity_service.dart';

/// Estado visible del autoguardado de un formulario de borrador.
enum InstriqAutosaveStatus {
  /// No hay nada que guardar todavía (formulario recién cargado, sin
  /// cambios del usuario).
  idle,

  /// Hay cambios pendientes, esperando la pausa de [AutosaveController.delay]
  /// antes de disparar el guardado.
  dirty,

  /// Guardando ahora mismo.
  saving,

  /// Último guardado completado con éxito y en línea.
  saved,

  /// Último guardado completado, pero sin conexión: encolado para
  /// sincronizarse cuando vuelva la red (ver `SyncQueueService`).
  offlineQueued,

  /// El último intento de guardado falló. No es un error bloqueante: el
  /// usuario puede seguir editando y el próximo cambio reintentará.
  error,
}

/// Debounce genérico de autoguardado para formularios de borrador: coalesce
/// cambios rápidos (cada tecla, cada `setState`) en un único guardado tras
/// una pausa de inactividad, y reporta el estado resultante vía
/// [onStatusChanged] para que la pantalla lo pinte con [InstriqAutosaveIndicator].
///
/// Deliberadamente compartido entre los 4 formularios de borrador
/// (técnicas/protocolos, bandejas, tarjetas de preferencia, instrumental
/// personalizado): a diferencia del patrón capçalera+versions de
/// ADR-004 §3 (donde SÍ se evita compartir hasta tener un 4º consumidor real
/// porque cada entidad tiene su propia forma), esto es pura infraestructura
/// de temporización sin nada específico del dominio, y los 4 consumidores ya
/// existen desde el primer día con la misma necesidad exacta.
class AutosaveController {
  AutosaveController({
    required this.save,
    required this.onStatusChanged,
    this.delay = const Duration(seconds: 2),
  });

  final Future<void> Function() save;
  final ValueChanged<InstriqAutosaveStatus> onStatusChanged;
  final Duration delay;

  Timer? _timer;
  bool _running = false;
  bool _pendingWhileRunning = false;

  /// Marca el formulario como modificado y reinicia la cuenta atrás hasta el
  /// próximo guardado automático.
  void markDirty() {
    onStatusChanged(InstriqAutosaveStatus.dirty);
    _timer?.cancel();
    _timer = Timer(delay, _run);
  }

  /// Cancela un guardado pendiente sin ejecutarlo -- se usa antes de un
  /// guardado manual explícito, para no duplicar la llamada.
  void cancelPending() => _timer?.cancel();

  Future<void> _run() async {
    if (_running) {
      // Ya hay un guardado en curso (p.ej. tardó más que [delay]): no
      // solapar llamadas, reintentar en cuanto termine la actual.
      _pendingWhileRunning = true;
      return;
    }
    _running = true;
    onStatusChanged(InstriqAutosaveStatus.saving);
    final wasOffline = !ConnectivityService.instance.isOnline.value;
    try {
      await save();
      onStatusChanged(wasOffline ? InstriqAutosaveStatus.offlineQueued : InstriqAutosaveStatus.saved);
    } catch (_) {
      onStatusChanged(InstriqAutosaveStatus.error);
    } finally {
      _running = false;
      if (_pendingWhileRunning) {
        _pendingWhileRunning = false;
        markDirty();
      }
    }
  }

  void dispose() => _timer?.cancel();
}

/// Texto discreto (pensado para el `actions` de un `AppBar`) que muestra el
/// estado actual de [AutosaveController].
class InstriqAutosaveIndicator extends StatelessWidget {
  final InstriqAutosaveStatus status;

  const InstriqAutosaveIndicator({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    if (status == InstriqAutosaveStatus.idle) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final IconData icon;
    final String label;
    final Color color;
    switch (status) {
      case InstriqAutosaveStatus.idle:
        return const SizedBox.shrink();
      case InstriqAutosaveStatus.dirty:
        icon = Icons.circle;
        label = l10n.autosaveDirty;
        color = theme.colorScheme.outline;
        break;
      case InstriqAutosaveStatus.saving:
        icon = Icons.sync;
        label = l10n.autosaveSaving;
        color = theme.colorScheme.outline;
        break;
      case InstriqAutosaveStatus.saved:
        icon = Icons.check_circle_outline;
        label = l10n.autosaveSaved;
        color = theme.colorScheme.outline;
        break;
      case InstriqAutosaveStatus.offlineQueued:
        icon = Icons.cloud_off_outlined;
        label = l10n.autosaveOffline;
        color = theme.colorScheme.outline;
        break;
      case InstriqAutosaveStatus.error:
        icon = Icons.error_outline;
        label = l10n.autosaveError;
        color = theme.colorScheme.error;
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: status == InstriqAutosaveStatus.dirty ? 8 : 15, color: color),
            const SizedBox(width: 6),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
