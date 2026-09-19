import '../l10n/app_localizations.dart';

enum InstrumentCategory {
  corte,
  diseccion,
  sutura,
  separacion,
  succion,
  especiales,
  equipos,
}

/// Antes esto era un `get label` con el texto en castellano fijo -- el
/// catalogo global es el unico contenido de la app que se sirve en los 3
/// idiomas (ver [LocalizedText] mas abajo, para nombre/descripcion/uso), pero
/// categoria y especialidad se habian quedado fuera de ese criterio. Ahora
/// requiere `l10n` como cualquier otra etiqueta de la interfaz.
extension InstrumentCategoryLabel on InstrumentCategory {
  String label(AppLocalizations l10n) {
    switch (this) {
      case InstrumentCategory.corte:
        return l10n.catalogCategoryCorte;
      case InstrumentCategory.diseccion:
        return l10n.catalogCategoryDiseccion;
      case InstrumentCategory.sutura:
        return l10n.catalogCategorySutura;
      case InstrumentCategory.separacion:
        return l10n.catalogCategorySeparacion;
      case InstrumentCategory.succion:
        return l10n.catalogCategorySuccion;
      case InstrumentCategory.especiales:
        return l10n.catalogCategoryEspeciales;
      case InstrumentCategory.equipos:
        return l10n.catalogCategoryEquipos;
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

/// Mismo criterio que [InstrumentCategoryLabel]: requiere `l10n` en vez de
/// devolver texto fijo en castellano.
extension SpecialtyLabel on Specialty {
  String label(AppLocalizations l10n) {
    switch (this) {
      case Specialty.general:
        return l10n.catalogSpecialtyGeneral;
      case Specialty.laparoscopiaEnergia:
        return l10n.catalogSpecialtyLaparoscopiaEnergia;
      case Specialty.roboticaAsistida:
        return l10n.catalogSpecialtyRoboticaAsistida;
      case Specialty.ortopediaTrauma:
        return l10n.catalogSpecialtyOrtopediaTrauma;
      case Specialty.neurocirugia:
        return l10n.catalogSpecialtyNeurocirugia;
      case Specialty.cardiovascular:
        return l10n.catalogSpecialtyCardiovascular;
      case Specialty.ginecologiaObstetricia:
        return l10n.catalogSpecialtyGinecologiaObstetricia;
      case Specialty.urologia:
        return l10n.catalogSpecialtyUrologia;
      case Specialty.otorrino:
        return l10n.catalogSpecialtyOtorrino;
      case Specialty.vascular:
        return l10n.catalogSpecialtyVascular;
      case Specialty.maxilofacial:
        return l10n.catalogSpecialtyMaxilofacial;
      case Specialty.pediatrica:
        return l10n.catalogSpecialtyPediatrica;
      case Specialty.plastica:
        return l10n.catalogSpecialtyPlastica;
      case Specialty.toracica:
        return l10n.catalogSpecialtyToracica;
      case Specialty.dermatologia:
        return l10n.catalogSpecialtyDermatologia;
      case Specialty.oftalmologia:
        return l10n.catalogSpecialtyOftalmologia;
      case Specialty.anestesiologiaReanimacio:
        return l10n.catalogSpecialtyAnestesiologiaReanimacio;
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
