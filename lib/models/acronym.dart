import 'instrument.dart' show LocalizedText;

enum AcronymArea { quirofano, anestesia, monitorizacion, procedimientos, general }

/// Sigla del glossari: catàleg compilat, mateix criteri que les guies.
class Acronym {
  final String abbr;
  final AcronymArea area;
  final LocalizedText meaning;

  const Acronym(this.abbr, this.area, this.meaning);
}
