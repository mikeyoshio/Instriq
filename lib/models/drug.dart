import 'instrument.dart' show InstrumentImage, LocalizedText;

/// Referència educativa de farmacologia d'anestèsia: mai inclou dosis, mai
/// calculadora, mai taula d'interaccions — el camp [Drug.tip] és com a molt
/// una única consideració d'alt nivell. Catàleg compilat separat
/// d'`Instrument`/`Suture` (mateix criteri: duplicar abans que abstraure
/// prematurament) perquè té propietats pròpies (classe farmacològica, vies
/// d'administració) que no encaixen als camps d'`Instrument`. No editable
/// des de l'app, només canvia amb un commit.
enum DrugClass {
  inductor,
  relajanteNeuromuscular,
  opioide,
  anestesicoLocal,
  agenteReversion,
  vasopresor,
  antiemetico,
  sedante,
}

/// `.label` es texto fijo en castellano, solo para depuración o contextos
/// sin `AppLocalizations` a mano -- mismo criterio que `SutureMaterialLabel`
/// (ver `lib/models/suture.dart`): la traducción real vive en
/// `drugClassValueLabel` (lib/widgets/drug_labels.dart), no en el modelo.
extension DrugClassLabel on DrugClass {
  String get label {
    switch (this) {
      case DrugClass.inductor:
        return 'Inductor anestèsic';
      case DrugClass.relajanteNeuromuscular:
        return 'Relaxant neuromuscular';
      case DrugClass.opioide:
        return 'Opioide';
      case DrugClass.anestesicoLocal:
        return 'Anestèsic local';
      case DrugClass.agenteReversion:
        return 'Agent de reversió';
      case DrugClass.vasopresor:
        return 'Vasopressor / inotròpic';
      case DrugClass.antiemetico:
        return 'Antiemètic';
      case DrugClass.sedante:
        return 'Sedant';
    }
  }
}

class Drug {
  final String id;
  final LocalizedText name;
  final List<String> aliases;
  final DrugClass drugClass;
  final List<String> routes;
  final LocalizedText description;
  final LocalizedText use;
  final LocalizedText? tip;
  final InstrumentImage? image;

  const Drug({
    required this.id,
    required this.name,
    this.aliases = const [],
    required this.drugClass,
    required this.routes,
    required this.description,
    required this.use,
    this.tip,
    this.image,
  });
}
