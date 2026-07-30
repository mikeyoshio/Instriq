import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/work_mode.dart';

/// Selector de modo de trabajo (selección única), reutilizado en el
/// registro/alta de grupo y en "Mi modo de trabajo" (ver
/// lib/screens/account_privacy_screen.dart). Puramente una preferencia de
/// visualización (ver [sectionPriorityOrder]), no bloquea ningún flujo si se
/// deja sin seleccionar.
class WorkModePicker extends StatelessWidget {
  final WorkMode? selected;
  final ValueChanged<WorkMode?> onChanged;

  const WorkModePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  static String labelFor(AppLocalizations l10n, WorkMode mode) {
    switch (mode) {
      case WorkMode.instrumentista:
        return l10n.professionalProfileInstrumentista;
      case WorkMode.supervision:
        return l10n.professionalProfileSupervision;
      case WorkMode.esterilizacion:
        return l10n.professionalProfileEsterilizacion;
      case WorkMode.enfermeria:
        return l10n.professionalProfileEnfermeria;
      case WorkMode.cirujano:
        return l10n.professionalProfileCirujano;
      case WorkMode.estudiante:
        return l10n.professionalProfileEstudiante;
      case WorkMode.docente:
        return l10n.professionalProfileDocente;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text(l10n.workModeNoPreference),
          selected: selected == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final mode in WorkMode.values)
          ChoiceChip(
            label: Text(labelFor(l10n, mode)),
            selected: selected == mode,
            onSelected: (_) => onChanged(mode),
          ),
      ],
    );
  }
}
