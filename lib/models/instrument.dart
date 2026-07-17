enum InstrumentCategory {
  corte,
  diseccion,
  sutura,
  separacion,
  succion,
  especiales,
}

extension InstrumentCategoryLabel on InstrumentCategory {
  String get label {
    switch (this) {
      case InstrumentCategory.corte:
        return 'Corte';
      case InstrumentCategory.diseccion:
        return 'Disección y prensión';
      case InstrumentCategory.sutura:
        return 'Sutura';
      case InstrumentCategory.separacion:
        return 'Separación';
      case InstrumentCategory.succion:
        return 'Succión';
      case InstrumentCategory.especiales:
        return 'Especiales';
    }
  }
}

enum Specialty {
  general,
  laparoscopiaEnergia,
  roboticaAsistida,
  ortopediaTrauma,
  neurocirugia,
  cardiovascular,
  ginecologiaObstetricia,
  urologia,
  otorrino,
}

extension SpecialtyLabel on Specialty {
  String get label {
    switch (this) {
      case Specialty.general:
        return 'Cirugía general';
      case Specialty.laparoscopiaEnergia:
        return 'Laparoscopia y energía avanzada';
      case Specialty.roboticaAsistida:
        return 'Cirugía robótica';
      case Specialty.ortopediaTrauma:
        return 'Traumatología y ortopedia';
      case Specialty.neurocirugia:
        return 'Neurocirugía';
      case Specialty.cardiovascular:
        return 'Cardiovascular';
      case Specialty.ginecologiaObstetricia:
        return 'Ginecología y obstetricia';
      case Specialty.urologia:
        return 'Urología';
      case Specialty.otorrino:
        return 'Otorrinolaringología';
    }
  }
}

class Instrument {
  final String id;
  final String name;
  final InstrumentCategory category;
  final Specialty specialty;
  final List<String> aliases;
  final String icon;
  final String description;
  final String use;
  final String? tip;

  const Instrument({
    required this.id,
    required this.name,
    required this.category,
    this.specialty = Specialty.general,
    required this.aliases,
    required this.icon,
    required this.description,
    required this.use,
    this.tip,
  });
}
