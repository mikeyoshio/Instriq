import 'package:flutter_test/flutter_test.dart';
import 'package:instriq/utils/clinical_calc.dart';

void main() {
  test('bmi and body surface', () {
    expect(bmi(70, 175), closeTo(22.86, 0.01));
    expect(bsaMosteller(70, 175), closeTo(1.84, 0.01));
  });

  test('Devine ideal weight', () {
    expect(idealWeightDevine(heightCm: 175, male: true), closeTo(70.5, 0.1));
    expect(idealWeightDevine(heightCm: 165, male: false), closeTo(56.9, 0.1));
  });

  test('Cockcroft-Gault', () {
    expect(creatinineClearance(age: 60, weightKg: 72, creatinineMgDl: 1, male: true), closeTo(80, 0.01));
    expect(creatinineClearance(age: 60, weightKg: 72, creatinineMgDl: 1, male: false), closeTo(68, 0.01));
  });

  test('rule of nines adds up to 100', () {
    expect(ruleOfNines.values.reduce((a, b) => a + b), 100);
  });

  test('gestation and due date', () {
    final g = gestation(DateTime(2026, 1, 1), DateTime(2026, 3, 5));
    expect((g.weeks, g.days), (9, 0));
    expect(g.dueDate, DateTime(2026, 10, 8));
  });

  test('drip rates', () {
    expect(dropsPerMinute(500, 240, 20), closeTo(41.67, 0.01));
    expect(mlPerHour(500, 240), closeTo(125, 1e-9));
    expect(durationMinutes(500, 125), closeTo(240, 1e-9));
    expect(parseNumber('1,5'), 1.5);
  });
}
