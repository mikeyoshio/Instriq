import 'package:flutter_test/flutter_test.dart';

import 'package:instriq/services/progress_service.dart';

/// nextLeitnerBox es la única cuenta con la que la app calcula el próximo
/// intervalo de repaso espaciado. Un edit del tope del clamp o de qué rama
/// resetea a 1 rompería la repetición espaciada (o directamente crashearía
/// con un RangeError al indexar kLeitnerIntervalsDays) la primera vez que
/// alguien acertara varias veces seguidas (hallazgo de auditoría de cara
/// a la v1.0).
void main() {
  group('nextLeitnerBox', () {
    test('a correct result advances the box by one', () {
      expect(nextLeitnerBox(1, true), 2);
      expect(nextLeitnerBox(2, true), 3);
      expect(nextLeitnerBox(3, true), 4);
      expect(nextLeitnerBox(4, true), 5);
    });

    test('a correct result at the last box stays at the last box (no RangeError)', () {
      expect(nextLeitnerBox(kLeitnerIntervalsDays.length, true), kLeitnerIntervalsDays.length);
    });

    test('an incorrect result always resets to box 1, regardless of current box', () {
      for (var box = 1; box <= kLeitnerIntervalsDays.length; box++) {
        expect(nextLeitnerBox(box, false), 1);
      }
    });

    test('every reachable box has a valid interval to index into kLeitnerIntervalsDays', () {
      var box = 1;
      for (var i = 0; i < kLeitnerIntervalsDays.length + 2; i++) {
        // No debe lanzar: kLeitnerIntervalsDays[box - 1] siempre en rango.
        expect(() => kLeitnerIntervalsDays[box - 1], returnsNormally);
        box = nextLeitnerBox(box, true);
      }
    });
  });
}
