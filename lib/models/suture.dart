import 'instrument.dart' show InstrumentImage, LocalizedText, Specialty;

/// Sutures no son instrumental reutilitzable (`Instrument`): són consumibles
/// d'un sol ús amb propietats pròpies (material, calibre, agulla) que no
/// encaixen als camps d'`Instrument`. Mateix concepte que un instrument —
/// ítem de referència del catàleg estàtic que es busca, s'aprèn i s'enllaça
/// a tècniques — però model i pantalles pròpies, deliberadament no
/// compartides amb `Instrument` (duplicar abans que abstraure prematurament,
/// mateix criteri que la resta del projecte).
enum SutureMaterial { seda, vicryl, monocryl, nylon, pds, catgut, prolene, dexon, altres }

extension SutureMaterialLabel on SutureMaterial {
  String get label {
    switch (this) {
      case SutureMaterial.seda:
        return 'Seda';
      case SutureMaterial.vicryl:
        return 'Vicryl (poliglactina 910)';
      case SutureMaterial.monocryl:
        return 'Monocryl (poliglecaprone 25)';
      case SutureMaterial.nylon:
        return 'Nylon (poliamida)';
      case SutureMaterial.pds:
        return 'PDS (polidioxanona)';
      case SutureMaterial.catgut:
        return 'Catgut';
      case SutureMaterial.prolene:
        return 'Prolene (polipropilè)';
      case SutureMaterial.dexon:
        return 'Dexon (àcid poliglicòlic)';
      case SutureMaterial.altres:
        return 'Altres';
    }
  }
}

enum NeedleType { cortante, redonda, cortanteInversa, tapercut }

extension NeedleTypeLabel on NeedleType {
  String get label {
    switch (this) {
      case NeedleType.cortante:
        return 'Cortant';
      case NeedleType.redonda:
        return 'Rodona (atraumàtica)';
      case NeedleType.cortanteInversa:
        return 'Cortant inversa';
      case NeedleType.tapercut:
        return 'Tapercut (mixta)';
    }
  }
}

class Suture {
  final String id;
  final String name;
  final SutureMaterial material;
  final String gauge;
  final NeedleType needleType;
  final bool absorbable;
  final Specialty specialty;
  final LocalizedText description;
  final LocalizedText use;
  final LocalizedText? tip;
  final InstrumentImage? image;

  const Suture({
    required this.id,
    required this.name,
    required this.material,
    required this.gauge,
    required this.needleType,
    required this.absorbable,
    this.specialty = Specialty.general,
    required this.description,
    required this.use,
    this.tip,
    this.image,
  });
}
