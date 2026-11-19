import 'instrument.dart' show LocalizedText;

/// Família de la postura: la posició base de la qual deriva cada variant.
enum SurgicalPositionFamily { supino, lateral, prono, sentado }

/// Postura quirúrgica del pacient: referència educativa de catàleg compilat
/// (mateix criteri que `WoundClosureMaterial`: no editable des de l'app,
/// només canvia amb un commit). Text propi, no copiat de cap font.
class SurgicalPosition {
  final String id;
  final LocalizedText name;
  final List<String> aliases;
  final SurgicalPositionFamily family;

  /// Com es col·loca el pacient.
  final LocalizedText description;

  /// Intervencions on s'utilitza habitualment.
  final LocalizedText procedures;

  /// Punts de pressió, nervis i efectes fisiològics a vigilar.
  final LocalizedText risks;

  /// Cures i comprovacions d'infermeria.
  final LocalizedText care;

  /// Ids de `kInstruments` amb els accessoris de posicionament.
  final List<String> relatedItems;

  const SurgicalPosition({
    required this.id,
    required this.name,
    this.aliases = const [],
    required this.family,
    required this.description,
    required this.procedures,
    required this.risks,
    required this.care,
    this.relatedItems = const [],
  });
}
