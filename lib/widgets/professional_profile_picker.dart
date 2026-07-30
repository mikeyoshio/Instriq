import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/professional_profile.dart';

/// Selector de perfil profesional (selección múltiple), reutilizado en el
/// registro/alta de grupo y en "Mi perfil profesional" (ver
/// lib/screens/account_privacy_screen.dart). Puramente una preferencia de
/// visualización (ver [sectionPriorityOrder]), no bloquea ningún flujo si se
/// deja vacío.
class ProfessionalProfilePicker extends StatelessWidget {
  final Set<ProfessionalProfile> selected;
  final ValueChanged<Set<ProfessionalProfile>> onChanged;

  const ProfessionalProfilePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  String _labelFor(AppLocalizations l10n, ProfessionalProfile profile) {
    switch (profile) {
      case ProfessionalProfile.instrumentista:
        return l10n.professionalProfileInstrumentista;
      case ProfessionalProfile.supervision:
        return l10n.professionalProfileSupervision;
      case ProfessionalProfile.esterilizacion:
        return l10n.professionalProfileEsterilizacion;
      case ProfessionalProfile.enfermeria:
        return l10n.professionalProfileEnfermeria;
      case ProfessionalProfile.cirujano:
        return l10n.professionalProfileCirujano;
      case ProfessionalProfile.estudiante:
        return l10n.professionalProfileEstudiante;
      case ProfessionalProfile.docente:
        return l10n.professionalProfileDocente;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ProfessionalProfile.values.map((profile) {
        final isSelected = selected.contains(profile);
        return FilterChip(
          label: Text(_labelFor(l10n, profile)),
          selected: isSelected,
          onSelected: (value) {
            final next = Set<ProfessionalProfile>.of(selected);
            if (value) {
              next.add(profile);
            } else {
              next.remove(profile);
            }
            onChanged(next);
          },
        );
      }).toList(),
    );
  }
}
