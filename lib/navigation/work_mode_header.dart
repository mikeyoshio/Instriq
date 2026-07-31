import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/work_mode.dart';
import '../services/profile_service.dart';
import '../widgets/work_mode_picker.dart';

/// Centinela para el ítem "Sense preferència" del menú. `PopupMenuButton<T>`
/// conflacia "menú cerrado sin elegir" con "se eligió `value: null`" (ambos
/// casos hacen que `showMenu` devuelva `null` internamente), así que
/// `onSelected` nunca se dispara si un `PopupMenuItem` usa `value: null` —
/// hay que representar "sin preferencia" con un valor no nulo distinto.
const Object _noPreference = Object();

/// Barra prima sobre `navigationShell` (ver app_shell.dart) con el nombre
/// del hospital y el selector de modo de trabajo activo. Escucha
/// [ProfileService.activeWorkModeNotifier] para repintar su propia etiqueta
/// al instante si el modo cambia desde otro sitio (p.ej. Mi cuenta).
/// Amagada del todo sin hospital conectado: el modo de trabajo no tiene
/// sentido para alguien sin grupo (no hay ficha de instrumento con
/// prioridad de secciones ligada a nada que consultar todavía).
class WorkModeHeader extends StatelessWidget {
  const WorkModeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    if (!ProfileService.instance.hasHospital) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ProfileService.instance.organizationName ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                ValueListenableBuilder<WorkMode?>(
                  valueListenable: ProfileService.instance.activeWorkModeNotifier,
                  builder: (context, mode, _) {
                    return PopupMenuButton<Object>(
                      initialValue: mode ?? _noPreference,
                      onSelected: (value) => ProfileService.instance
                          .setActiveWorkMode(identical(value, _noPreference) ? null : value as WorkMode),
                      itemBuilder: (context) => [
                        PopupMenuItem<Object>(
                          value: _noPreference,
                          child: Text(l10n.workModeNoPreference),
                        ),
                        for (final option in WorkMode.values)
                          PopupMenuItem<Object>(
                            value: option,
                            child: Text(WorkModePicker.labelFor(l10n, option)),
                          ),
                      ],
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            mode == null ? l10n.workModeNoPreference : WorkModePicker.labelFor(l10n, mode),
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
