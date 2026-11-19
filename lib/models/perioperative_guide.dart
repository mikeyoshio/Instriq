import 'instrument.dart' show LocalizedText;

enum GuideArea { asepsia, seguridad, paciente, material }

class GuideSection {
  final LocalizedText title;
  final LocalizedText body;

  const GuideSection(this.title, this.body);
}

/// Guia perioperatòria (rentat quirúrgic, recompte, checklist de l'OMS...):
/// referència educativa de catàleg compilat, mateix criteri que
/// `SurgicalPosition`. Text propi; mai dosis de fàrmacs.
class PerioperativeGuide {
  final String id;
  final LocalizedText name;
  final List<String> aliases;
  final GuideArea area;
  final LocalizedText summary;
  final List<GuideSection> sections;

  /// Ids de `kInstruments` del material que la guia esmenta.
  final List<String> relatedItems;

  const PerioperativeGuide({
    required this.id,
    required this.name,
    this.aliases = const [],
    required this.area,
    required this.summary,
    required this.sections,
    this.relatedItems = const [],
  });
}
