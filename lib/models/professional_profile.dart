/// Perfil profesional de quien usa la app, guardado en
/// `profiles.professional_profiles` (text[], ver
/// supabase/schema_v15_clinical_knowledge_model.sql). Es puramente una
/// preferencia de visualización: decide el orden de las secciones en la
/// ficha de un instrumento ([sectionPriorityOrder]), no afecta a ningún
/// permiso ni policy de RLS. Un usuario puede tener varios perfiles activos
/// a la vez (p.ej. instrumentista + docente).
enum ProfessionalProfile {
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
/// traducido al usuario.
extension ProfessionalProfileLabel on ProfessionalProfile {
  String get label {
    switch (this) {
      case ProfessionalProfile.instrumentista:
        return 'Instrumentista';
      case ProfessionalProfile.supervision:
        return 'Supervisión de quirófano';
      case ProfessionalProfile.esterilizacion:
        return 'Esterilización (CSSD)';
      case ProfessionalProfile.enfermeria:
        return 'Enfermería quirúrgica';
      case ProfessionalProfile.cirujano:
        return 'Cirujano/a';
      case ProfessionalProfile.estudiante:
        return 'Estudiante';
      case ProfessionalProfile.docente:
        return 'Docente';
    }
  }

  String get dbValue => name;

  static ProfessionalProfile? fromDb(String value) {
    for (final profile in ProfessionalProfile.values) {
      if (profile.name == value) return profile;
    }
    return null;
  }
}

/// Claves de sección de la ficha de instrumento, en el orden por defecto
/// (didáctico): foto, especialidad, alias, descripción, uso, consejo,
/// esterilización, ficha técnica.
const List<String> _defaultSectionOrder = [
  'photo',
  'specialty',
  'aliases',
  'description',
  'use',
  'tip',
  'sterilization',
  'technical',
];

/// Orden de prioridad de secciones por cada perfil profesional individual.
/// Nota: el perfil "instrumentista" no incluye todavía secciones de
/// "bandejas donde aparece"/"instrumental relacionado" — esas secciones aún
/// no existen, se añadirán cuando se construya la funcionalidad de Bandejas.
const Map<ProfessionalProfile, List<String>> _profileSectionOrder = {
  ProfessionalProfile.estudiante: _defaultSectionOrder,
  ProfessionalProfile.instrumentista: [
    'use',
    'description',
    'tip',
    'specialty',
    'aliases',
    'photo',
    'sterilization',
    'technical',
  ],
  ProfessionalProfile.supervision: [
    'use',
    'specialty',
    'description',
    'sterilization',
    'technical',
    'tip',
    'aliases',
    'photo',
  ],
  ProfessionalProfile.esterilizacion: [
    'sterilization',
    'technical',
    'use',
    'description',
    'specialty',
    'tip',
    'aliases',
    'photo',
  ],
  ProfessionalProfile.enfermeria: [
    'use',
    'description',
    'tip',
    'specialty',
    'aliases',
    'photo',
    'sterilization',
    'technical',
  ],
  ProfessionalProfile.cirujano: [
    'use',
    'description',
    'specialty',
    'tip',
    'aliases',
    'photo',
    'sterilization',
    'technical',
  ],
  ProfessionalProfile.docente: [
    'description',
    'use',
    'tip',
    'specialty',
    'aliases',
    'photo',
    'sterilization',
    'technical',
  ],
};

/// Orden final de secciones de la ficha de instrumento a partir de los
/// perfiles activos: para cada clave de sección se toma la posición MÍNIMA
/// en la que aparece entre todos los perfiles activos, y se ordenan las
/// claves por esa posición. Sin perfil seleccionado (o ninguno reconocido),
/// se usa el orden por defecto (didáctico). Las claves que no aparezcan en
/// ningún perfil activo van al final, en su orden por defecto.
List<String> sectionPriorityOrder(Set<ProfessionalProfile> profiles) {
  if (profiles.isEmpty) return List.of(_defaultSectionOrder);

  final orders = profiles
      .map((p) => _profileSectionOrder[p])
      .whereType<List<String>>()
      .toList();
  if (orders.isEmpty) return List.of(_defaultSectionOrder);

  final minPosition = <String, int>{};
  for (final order in orders) {
    for (var i = 0; i < order.length; i++) {
      final key = order[i];
      final current = minPosition[key];
      if (current == null || i < current) {
        minPosition[key] = i;
      }
    }
  }

  final keys = List.of(_defaultSectionOrder);
  keys.sort((a, b) {
    final posA = minPosition[a] ?? _defaultSectionOrder.length;
    final posB = minPosition[b] ?? _defaultSectionOrder.length;
    return posA.compareTo(posB);
  });
  return keys;
}
