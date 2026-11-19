import 'dart:math';

/// Fórmules de les calculadores. Cap no calcula dosis de fàrmacs (norma
/// d'Instriq): són mesures del pacient i càlculs de volum i temps.

/// IMC (kg/m²).
double bmi(double weightKg, double heightCm) => weightKg / pow(heightCm / 100, 2);

/// Pes ideal de Devine (kg). Fiable a partir d'uns 152 cm d'alçada.
double idealWeightDevine({required double heightCm, required bool male}) =>
    (male ? 50 : 45.5) + 0.9055 * (heightCm - 152.4);

/// Superfície corporal de Mosteller (m²).
double bsaMosteller(double weightKg, double heightCm) => sqrt(weightKg * heightCm / 3600);

/// Aclariment de creatinina de Cockcroft-Gault (ml/min), creatinina en mg/dl.
double creatinineClearance({
  required int age,
  required double weightKg,
  required double creatinineMgDl,
  required bool male,
}) =>
    (140 - age) * weightKg / (72 * creatinineMgDl) * (male ? 1 : 0.85);

/// Regla dels 9 de Wallace (adult): percentatge de superfície per zona.
const ruleOfNines = <String, int>{
  'head': 9,
  'armLeft': 9,
  'armRight': 9,
  'trunkFront': 18,
  'trunkBack': 18,
  'legLeft': 18,
  'legRight': 18,
  'perineum': 1,
};

/// Gestació a partir de la data de l'última regla (regla de Naegele).
({int weeks, int days, DateTime dueDate}) gestation(DateTime lastPeriod, DateTime today) {
  // En UTC: amb hora local, el canvi d'horari d'estiu fa que un dia duri 23 o
  // 25 hores i desquadra la resta i la data provable de part.
  final lmp = DateTime.utc(lastPeriod.year, lastPeriod.month, lastPeriod.day);
  final now = DateTime.utc(today.year, today.month, today.day);
  final d = now.difference(lmp).inDays;
  return (weeks: d ~/ 7, days: d % 7, dueDate: DateTime(lmp.year, lmp.month, lmp.day + 280));
}

/// Gotes per minut per passar [volumeMl] en [minutes] amb un equip de
/// [dropsPerMl] gotes/ml (macrogoteig 20, microgoteig 60).
double dropsPerMinute(double volumeMl, double minutes, int dropsPerMl) => volumeMl * dropsPerMl / minutes;

/// ml/h per passar [volumeMl] en [minutes].
double mlPerHour(double volumeMl, double minutes) => volumeMl / minutes * 60;

/// Minuts que trigarà [volumeMl] a [mlPerHourRate].
double durationMinutes(double volumeMl, double mlPerHourRate) => volumeMl / mlPerHourRate * 60;

/// Llegeix un número escrit amb coma o punt decimal.
double? parseNumber(String s) => double.tryParse(s.trim().replaceAll(',', '.'));
