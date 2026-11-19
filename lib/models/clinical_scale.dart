import 'instrument.dart' show LocalizedText;

enum ScaleArea { preanestesia, recuperacion, valoracion }

class ScaleOption {
  final int points;
  final LocalizedText text;

  const ScaleOption(this.points, this.text);
}

class ScaleItem {
  final LocalizedText label;
  final List<ScaleOption> options;

  const ScaleItem(this.label, this.options);
}

/// Interpretació per a un rang de puntuació [min, max] (inclosos).
class ScaleBand {
  final int min;
  final int max;
  final LocalizedText label;

  const ScaleBand(this.min, this.max, this.label);
}

/// Escala de valoració amb càlcul guiat. Si [classification] és cert, l'escala
/// és una sola tria (ASA, Mallampati, RASS...) i el resultat és l'opció triada,
/// no una suma. Mai dosis.
class ClinicalScale {
  final String id;
  final LocalizedText name;
  final ScaleArea area;
  final LocalizedText description;
  final List<ScaleItem> items;
  final List<ScaleBand> bands;
  final bool classification;
  final String reference;

  const ClinicalScale({
    required this.id,
    required this.name,
    required this.area,
    required this.description,
    required this.items,
    required this.bands,
    this.classification = false,
    required this.reference,
  });

  int get minScore => items.fold(0, (a, i) => a + i.options.map((o) => o.points).reduce((x, y) => x < y ? x : y));
  int get maxScore => items.fold(0, (a, i) => a + i.options.map((o) => o.points).reduce((x, y) => x > y ? x : y));

  ScaleBand? bandFor(int score) {
    for (final b in bands) {
      if (score >= b.min && score <= b.max) return b;
    }
    return null;
  }
}
