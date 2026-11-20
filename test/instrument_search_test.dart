import 'package:flutter_test/flutter_test.dart';
import 'package:instriq/data/instruments_data.dart';
import 'package:instriq/utils/instrument_search.dart';

String _first(String query, String lang) =>
    rankInstruments(kInstruments, query, lang).first.name.forLanguageCode(lang);

void main() {
  test('el nom que comença per la cerca guanya (cas real: "porta")', () {
    final results = rankInstruments(kInstruments, 'porta', 'es');
    expect(results.first.name.forLanguageCode('es').toLowerCase(), startsWith('porta'));
  });

  test('sense accents i amb errates d\'una lletra', () {
    expect(_first('bisturi', 'es').toLowerCase(), contains('bisturí'));
    expect(_first('metzembaum', 'ca').toLowerCase(), contains('metzenbaum'));
  });

  test('diverses paraules: totes han de coincidir', () {
    expect(_first('pinza koch', 'es'), 'Pinza de Kocher');
  });

  test('una coincidència només a la descripció queda per sota de les del nom', () {
    final results = rankInstruments(kInstruments, 'porta', 'es', extraText: (i) => i.description.forLanguageCode('es'));
    final firstDescriptionOnly = results.indexWhere((i) => !i.name.forLanguageCode('es').toLowerCase().contains('porta') &&
        !i.aliases.any((a) => a.toLowerCase().contains('porta')));
    final lastByName = results.lastIndexWhere((i) => i.name.forLanguageCode('es').toLowerCase().contains('porta'));
    if (firstDescriptionOnly != -1) expect(firstDescriptionOnly, greaterThan(lastByName));
  });

  test('cerca buida retorna tot el catàleg en ordre', () {
    expect(rankInstruments(kInstruments, '', 'ca').length, kInstruments.length);
  });
}
