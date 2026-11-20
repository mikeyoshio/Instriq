import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:instriq/data/instruments_data.dart';
import 'package:instriq/screens/quiz_screen.dart';

void main() {
  test('quiz global: totes les preguntes tenen foto, 4 opcions diferents i plausibles', () {
    for (var seed = 0; seed < 200; seed++) {
      for (final q in buildQuizQuestions(null, Random(seed), 10)) {
        expect(q.answer.image, isNotNull, reason: 'sense foto la pregunta no té resposta');
        expect(q.options.length, 4);
        expect(q.options.map((o) => o.id).toSet().length, 4);
        expect(q.options.map((o) => o.name.ca).toSet().length, 4, reason: 'dues opcions amb el mateix nom');
        expect(q.options.where((o) => o.id == q.answer.id).length, 1);
        final sameCategory = q.options.where((o) => o.category == q.answer.category).length;
        final peers = kInstruments.where((i) => i.category == q.answer.category).length;
        if (peers >= 4) expect(sameCategory, 4, reason: 'distractors de la mateixa categoria quan n\'hi ha prou');
      }
    }
  });

  test('amb una safata: pregunta pels instruments de la safata, tinguin foto o no', () {
    final tray = kInstruments.where((i) => i.image == null).take(5).toList();
    final qs = buildQuizQuestions(tray, Random(1), 10);
    expect(qs.length, 5);
    expect(qs.every((q) => tray.contains(q.answer)), isTrue);
  });
}
