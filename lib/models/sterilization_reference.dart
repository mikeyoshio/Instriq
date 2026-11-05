import 'instrument.dart' show LocalizedText;
import 'instrument_sterilization.dart' show SterilizationMethod;

/// Catàleg de referència compilat (mateix criteri que [Drug]/`Suture`): fons
/// educatiu general sobre QUÈ ÉS cada [SterilizationMethod], independent de
/// les dades concretes que cada organització introdueixi al seu propi
/// registre d'esterilització per instrument (`SterilizationMethodEntry`/
/// `SterilizationMethodVersion`, ver instrument_sterilization.dart). No fa
/// falta `id` ([SterilizationMethod.dbValue] ja fa aquesta funció) ni `name`
/// (es mostra amb `sterilizationMethodValueLabel`, reutilitzat tal qual).
class SterilizationMethodReference {
  final SterilizationMethod method;
  final List<String> aliases;
  final LocalizedText description;
  final LocalizedText use;
  final LocalizedText? tip;

  const SterilizationMethodReference({
    required this.method,
    this.aliases = const [],
    required this.description,
    required this.use,
    this.tip,
  });
}
