import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:instriq/data/instrument_recognition_data.dart';
import 'package:instriq/data/instruments_data.dart';
import 'package:instriq/data/lookalikes_data.dart';
import 'package:instriq/screens/lookalike_quiz_screen.dart';

void main() {
  final ids = {for (final i in kInstruments) i.id};

  test('cada peça de les famílies i de «com reconèixer-lo» existeix al catàleg, amb text en 3 idiomes', () {
    for (final f in kLookalikeFamilies) {
      expect(f.members.length, greaterThanOrEqualTo(2), reason: f.id);
      for (final m in f.members) {
        expect(ids, contains(m.instrumentId), reason: '${f.id}: ${m.instrumentId}');
        for (final t in [m.clue.ca, m.clue.es, m.clue.en]) {
          expect(t.trim(), isNotEmpty);
        }
      }
    }
    for (final e in kInstrumentRecognition.entries) {
      expect(ids, contains(e.key));
      expect([e.value.ca, e.value.es, e.value.en].every((t) => t.trim().isNotEmpty), isTrue, reason: e.key);
    }
    expect(kLookalikeFamilies.map((f) => f.id).toSet().length, kLookalikeFamilies.length);
  });

  test('qüestionari de semblants: foto, opcions de la mateixa família i sense repetir', () {
    for (var seed = 0; seed < 300; seed++) {
      for (final q in buildLookalikeQuestions(Random(seed), 10)) {
        expect(q.answer.image, isNotNull);
        expect(q.options.map((o) => o.id).toSet().length, q.options.length);
        expect(q.options.length, inInclusiveRange(2, 4));
        final familyIds = q.family.members.map((m) => m.instrumentId).toSet();
        expect(q.options.every((o) => familyIds.contains(o.id)), isTrue);
        expect(q.options.where((o) => o.id == q.answer.id).length, 1);
      }
    }
  });
}
