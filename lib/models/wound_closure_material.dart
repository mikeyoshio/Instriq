import 'instrument.dart' show InstrumentImage, LocalizedText;

/// Referència educativa de material de tancament de ferides i hemostàtics:
/// mai inclou quantitats, concentracions ni dosis — mateix criteri que
/// [Drug]/[Drug.tip] (`lib/models/drug.dart`). Catàleg compilat separat
/// d'`Instrument`/`Drug` (mateix criteri: duplicar abans que abstraure
/// prematurament) perquè té una categoria pròpia que no encaixa als camps
/// d'`Instrument` ni de `Drug`. No editable des de l'app, només canvia amb
/// un commit.
enum WoundClosureCategory {
  hemostaticoAbsorbible,
  hemostaticoActivo,
  sellanteTisular,
  adhesivoCutaneo,
  grapaCutanea,
  tiraAdhesivaCutanea,
  ceraOsea,
}

/// `.label` es texto fijo en castellano, solo para depuración o contextos
/// sin `AppLocalizations` a mano -- mismo criterio que `DrugClassLabel`
/// (ver `lib/models/drug.dart`): la traducción real vive en
/// `woundClosureCategoryValueLabel` (lib/widgets/wound_closure_labels.dart),
/// no en el modelo.
extension WoundClosureCategoryLabel on WoundClosureCategory {
  String get label {
    switch (this) {
      case WoundClosureCategory.hemostaticoAbsorbible:
        return 'Hemostático absorbible';
      case WoundClosureCategory.hemostaticoActivo:
        return 'Hemostático activo';
      case WoundClosureCategory.sellanteTisular:
        return 'Sellante tisular';
      case WoundClosureCategory.adhesivoCutaneo:
        return 'Adhesivo cutáneo';
      case WoundClosureCategory.grapaCutanea:
        return 'Grapa cutánea';
      case WoundClosureCategory.tiraAdhesivaCutanea:
        return 'Tira adhesiva cutánea';
      case WoundClosureCategory.ceraOsea:
        return 'Cera ósea';
    }
  }
}

class WoundClosureMaterial {
  final String id;
  final LocalizedText name;
  final List<String> aliases;
  final WoundClosureCategory category;
  final LocalizedText description;
  final LocalizedText use;
  final LocalizedText? tip;
  final InstrumentImage? image;

  const WoundClosureMaterial({
    required this.id,
    required this.name,
    this.aliases = const [],
    required this.category,
    required this.description,
    required this.use,
    this.tip,
    this.image,
  });
}
