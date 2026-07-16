enum InstrumentCategory {
  corte,
  diseccion,
  sutura,
  separacion,
  succion,
  especiales,
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
    }
  }
}

class Instrument {
  final String id;
  final String name;
  final InstrumentCategory category;
  final List<String> aliases;
  final String icon;
  final String description;
  final String use;
  final String? tip;

  const Instrument({
    required this.id,
    required this.name,
    required this.category,
    required this.aliases,
    required this.icon,
    required this.description,
    required this.use,
    this.tip,
  });
}
