enum InstrumentCategory {
  corte,
  diseccion,
  sutura,
  separacion,
  succion,
  especiales,
  equipos,
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
      case InstrumentCategory.equipos:
        return 'Equipos y máquinas';
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
  vascular,
  maxilofacial,
  pediatrica,
  plastica,
  toracica,
  dermatologia,
  oftalmologia,
  anestesiologiaReanimacio,
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
      case Specialty.vascular:
        return 'Angiología y Cirugía Vascular';
      case Specialty.maxilofacial:
        return 'Cirugía Oral y Maxilofacial';
      case Specialty.pediatrica:
        return 'Cirugía Pediátrica';
      case Specialty.plastica:
        return 'Cirugía Plástica, Estética y Reparadora';
      case Specialty.toracica:
        return 'Cirugía Torácica';
      case Specialty.dermatologia:
        return 'Dermatología Médico-Quirúrgica y Venereología';
      case Specialty.oftalmologia:
        return 'Oftalmología';
      case Specialty.anestesiologiaReanimacio:
        return 'Anestesiología y Reanimación';
    }
  }
}

/// Texto de instrumento en los 3 idiomas soportados por la app (ca/es/en).
/// [forLanguageCode] evita depender de `Locale` (widgets.dart) en un modelo
/// de datos puro; el llamante ya resuelve el locale activo con lo que tenga.
class LocalizedText {
  final String ca;
  final String es;
  final String en;
  const LocalizedText({required this.ca, required this.es, required this.en});

  String forLanguageCode(String languageCode) {
    switch (languageCode) {
      case 'ca':
        return ca;
      case 'en':
        return en;
      default:
        return es;
    }
  }
}

/// Foto real de referencia con licencia libre verificada (Wikimedia Commons).
/// [attribution] y [sourceUrl] deben mostrarse junto a la imagen: la mayoría
/// de licencias CC exigen atribución visible, no solo en un fichero aparte.
class InstrumentImage {
  final String url;
  final String license;
  final String attribution;
  final String sourceUrl;

  const InstrumentImage({
    required this.url,
    required this.license,
    required this.attribution,
    required this.sourceUrl,
  });
}

class Instrument {
  final String id;
  final String name;
  final InstrumentCategory category;
  final Specialty specialty;
  final List<String> aliases;
  final String icon;
  final LocalizedText description;
  final LocalizedText use;
  final LocalizedText? tip;
  final InstrumentImage? image;

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
    this.image,
  });
}
