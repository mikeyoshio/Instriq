import 'package:flutter_test/flutter_test.dart';
import 'package:instriq/data/clinical_scales_data.dart';

void main() {
  test('scale ids are unique', () {
    expect(kClinicalScales.map((s) => s.id).toSet().length, kClinicalScales.length);
  });

  test('every reachable score of a summed scale has an interpretation', () {
    for (final s in kClinicalScales.where((s) => !s.classification)) {
      for (var score = s.minScore; score <= s.maxScore; score++) {
        expect(s.bandFor(score), isNotNull, reason: '${s.id} score $score');
      }
    }
  });

  test('known totals', () {
    final gcs = kClinicalScales.firstWhere((s) => s.id == 'glasgow');
    expect((gcs.minScore, gcs.maxScore), (3, 15));
    final braden = kClinicalScales.firstWhere((s) => s.id == 'braden');
    expect((braden.minScore, braden.maxScore), (6, 23));
    final aldrete = kClinicalScales.firstWhere((s) => s.id == 'aldrete');
    expect(aldrete.maxScore, 10);
  });
}
