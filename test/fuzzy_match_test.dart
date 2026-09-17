import 'package:flutter_test/flutter_test.dart';
import 'package:instriq/utils/fuzzy_match.dart';

void main() {
  group('fuzzyContains', () {
    test('exact substring always matches', () {
      expect(fuzzyContains('Tijera de Mayo', 'mayo'), isTrue);
    });

    test('empty needle always matches', () {
      expect(fuzzyContains('Tijera de Mayo', ''), isTrue);
    });

    test('tolerates a single-letter typo in a short word', () {
      expect(fuzzyContains('Tijera de Mayo', 'tigera'), isTrue);
    });

    test('tolerates a missing accent', () {
      expect(fuzzyContains('Bisturí (mango + hoja)', 'bisturi'), isTrue);
    });

    test('tolerates a missing accent the other way round', () {
      expect(fuzzyContains('Cirugia general', 'cirugía'), isTrue);
    });

    test('does not match an unrelated word', () {
      expect(fuzzyContains('Tijera de Mayo', 'separador'), isFalse);
    });

    test('does not tolerate more errors than the length allows', () {
      expect(fuzzyContains('Tijera de Mayo', 'xyzabc'), isFalse);
    });

    test('allows two edits on longer words', () {
      expect(fuzzyContains('Electrobisturí', 'elektrobisturi'), isTrue);
    });
  });
}
