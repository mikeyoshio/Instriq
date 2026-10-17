import 'package:flutter_test/flutter_test.dart';
import 'package:instriq/models/instrument.dart';
import 'package:instriq/screens/catalog_screen.dart';

const _name = LocalizedText(ca: 'Tisora de Mayo', es: 'Tijera de Mayo', en: 'Mayo scissors');
const _desc = LocalizedText(ca: '', es: '', en: '');

final _instrument = Instrument(
  id: 'tijera-mayo',
  name: _name,
  category: InstrumentCategory.corte,
  specialty: Specialty.general,
  aliases: const ['mayo'],
  icon: 'scissors',
  description: _desc,
  use: _desc,
  isNew: true,
);

void main() {
  group('matchesInstrumentFilters', () {
    test('empty query and no filters always matches', () {
      expect(matchesInstrumentFilters(_instrument, '', 'es'), isTrue);
    });

    test('matches by alias when name does not contain the query', () {
      expect(matchesInstrumentFilters(_instrument, 'mayo', 'es'), isTrue);
    });

    test('category filter excludes a non-matching category', () {
      expect(
        matchesInstrumentFilters(_instrument, '', 'es', categories: {InstrumentCategory.succion}),
        isFalse,
      );
    });

    test('specialty filter excludes a non-matching specialty', () {
      expect(
        matchesInstrumentFilters(_instrument, '', 'es', specialties: {Specialty.andrologia}),
        isFalse,
      );
    });

    test('newOnly excludes an instrument not marked as new', () {
      final old = Instrument(
        id: 'old',
        name: _name,
        category: InstrumentCategory.corte,
        aliases: const [],
        icon: 'scissors',
        description: _desc,
        use: _desc,
      );
      expect(matchesInstrumentFilters(old, '', 'es', newOnly: true), isFalse);
    });

    test('combined matching filters all pass', () {
      expect(
        matchesInstrumentFilters(
          _instrument,
          'tijera',
          'es',
          categories: {InstrumentCategory.corte},
          specialties: {Specialty.general},
          newOnly: true,
        ),
        isTrue,
      );
    });
  });
}
