/// Modo de trabajo activo de quien usa la app, guardado en
/// `profiles.active_work_mode` (text, ver
/// supabase/schema_v18_work_mode_favorites_recent.sql). Es puramente una
/// preferencia de visualización: decide el orden de las secciones en la
/// ficha de un instrumento ([sectionPriorityOrder]) y de la pantalla de
/// Inicio, no afecta a ningún permiso ni policy de RLS. A diferencia del
/// antiguo perfil profesional (ver git history), solo puede haber UNO activo
/// a la vez — sustituye a `ProfessionalProfile`, que permitía varios.
enum WorkMode {
  instrumentista,
  supervision,
  esterilizacion,
  enfermeria,
  cirujano,
  estudiante,
  docente,
}

/// [.label] es un placeholder en español, para depuración o para contextos
/// sin [BuildContext] a mano. Igual que [InstrumentCategory]/[Specialty] en
/// `lib/models/instrument.dart`, no usa AppLocalizations aquí: las pantallas
/// deben preferir `l10n.professionalProfileX` para mostrar el valor
/// traducido al usuario (mismas claves que el modelo antiguo, no se
/// duplican).
extension WorkModeLabel on WorkMode {
  String get label {
    switch (this) {
      case WorkMode.instrumentista:
        return 'Instrumentista';
      case WorkMode.supervision:
        return 'Supervisión de quirófano';
      case WorkMode.esterilizacion:
        return 'Esterilización (CSSD)';
      case WorkMode.enfermeria:
        return 'Enfermería quirúrgica';
      case WorkMode.cirujano:
        return 'Cirujano/a';
      case WorkMode.estudiante:
        return 'Estudiante';
      case WorkMode.docente:
        return 'Docente';
    }
  }

  String get dbValue => name;

  static WorkMode? fromDb(String? value) {
    if (value == null) return null;
    for (final mode in WorkMode.values) {
      if (mode.name == value) return mode;
    }
    return null;
  }
}

/// Claves de sección de la ficha de instrumento, en el orden por defecto
/// (didáctico): foto, especialidad, alias, descripción, uso, consejo,
/// esterilización, ficha técnica, dónde se usa (EPIC 1, grafo de conocimiento).
const List<String> _defaultSectionOrder = [
  'photo',
  'specialty',
  'aliases',
  'description',
  'use',
  'tip',
  'sterilization',
  'technical',
  'usedIn',
];

/// Orden de prioridad de secciones por cada modo de trabajo.
const Map<WorkMode, List<String>> _modeSectionOrder = {
  WorkMode.estudiante: _defaultSectionOrder,
  WorkMode.instrumentista: [
    'use',
    'description',
    'tip',
    'specialty',
    'aliases',
    'photo',
    'sterilization',
    'technical',
    'usedIn',
  ],
  WorkMode.supervision: [
    'use',
    'specialty',
    'description',
    'sterilization',
    'technical',
    'tip',
    'aliases',
    'photo',
    'usedIn',
  ],
  WorkMode.esterilizacion: [
    'sterilization',
    'technical',
    'use',
    'description',
    'specialty',
    'tip',
    'aliases',
    'photo',
    'usedIn',
  ],
  WorkMode.enfermeria: [
    'use',
    'description',
    'tip',
    'specialty',
    'aliases',
    'photo',
    'sterilization',
    'technical',
    'usedIn',
  ],
  WorkMode.cirujano: [
    'use',
    'description',
    'specialty',
    'tip',
    'aliases',
    'photo',
    'sterilization',
    'technical',
    'usedIn',
  ],
  WorkMode.docente: [
    'description',
    'use',
    'tip',
    'specialty',
    'aliases',
    'photo',
    'sterilization',
    'technical',
    'usedIn',
  ],
};

/// Orden final de secciones de la ficha de instrumento para el modo de
/// trabajo activo. Sin modo seleccionado (o ninguno reconocido), se usa el
/// orden por defecto (didáctico). A diferencia del antiguo
/// `sectionPriorityOrder(Set<ProfessionalProfile>)`, no hace falta fusionar
/// nada: solo hay un modo activo a la vez.
List<String> sectionPriorityOrder(WorkMode? mode) {
  if (mode == null) return List.of(_defaultSectionOrder);
  return List.of(_modeSectionOrder[mode] ?? _defaultSectionOrder);
}
