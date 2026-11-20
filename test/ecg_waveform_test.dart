import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:instriq/data/ecg_rhythms_data.dart';
import 'package:instriq/utils/ecg_waveform.dart';

/// Comprova que cada variant que pot sortir a la pràctica d'ECG continua
/// sent el ritme que diu ser: freqüència dins del rang, P on toquen, QRS
/// estrets o amples, patrons de bloqueig correctes. Si un canvi al generador
/// fa sortir una tira clínicament incorrecta, aquest test falla.
const _seeds = 300;

List<double> _rr(EcgStrip s) => [for (var i = 1; i < s.qrs.length; i++) s.qrs[i].t - s.qrs[i - 1].t];
double _mean(List<double> x) => x.reduce((a, b) => a + b) / x.length;
double _rate(EcgStrip s) => 60 / _mean(_rr(s));
double _cv(List<double> x) {
  final m = _mean(x);
  return sqrt(_mean([for (final v in x) (v - m) * (v - m)])) / m;
}

/// PR de cada QRS: distància a la P més propera per davant (dins de 0,5 s i
/// sense cap altre QRS entremig), o null si no en té.
List<double?> _pr(EcgStrip s) => [
      for (var i = 0; i < s.qrs.length; i++)
        s.pTimes
            .where((p) => p < s.qrs[i].t && s.qrs[i].t - p <= 0.5 && (i == 0 || p > s.qrs[i - 1].t))
            .fold<double?>(null, (best, p) => best == null || s.qrs[i].t - p < best ? s.qrs[i].t - p : best),
    ];

bool _allNarrow(EcgStrip s) => s.qrs.every((q) => !q.wide && !q.paced);
bool _allWide(EcgStrip s) => s.qrs.every((q) => q.wide);

void _rateIn(EcgStrip s, double lo, double hi, String why) {
  final r = _rate(s);
  expect(r, inInclusiveRange(lo - 0.5, hi + 0.5), reason: '$why: freqüència $r');
}

void _sinusLike(EcgStrip s, double lo, double hi, {double prLo = 0.12, double prHi = 0.20}) {
  _rateIn(s, lo, hi, 'sinusal');
  expect(_allNarrow(s), isTrue);
  for (final pr in _pr(s)) {
    expect(pr, isNotNull, reason: 'cada QRS té la seva P');
    expect(pr!, inInclusiveRange(prLo - 1e-9, prHi + 1e-9), reason: 'PR $pr');
  }
  expect(_cv(_rr(s)), lessThan(0.01), reason: 'regular');
}

final Map<String, void Function(EcgStrip s)> _rules = {
  'sinusal': (s) => _sinusLike(s, 60, 100),
  'bradicardia-sinusal': (s) => _sinusLike(s, 38, 55),
  'taquicardia-sinusal': (s) => _sinusLike(s, 105, 150, prHi: 0.16),
  'arritmia-sinusal': (s) {
    _rateIn(s, 50, 110, 'arítmia sinusal');
    expect(_allNarrow(s), isTrue);
    expect(_pr(s).every((pr) => pr != null && pr >= 0.12 - 1e-9 && pr <= 0.2 + 1e-9), isTrue);
    expect(_cv(_rr(s)), greaterThan(0.04), reason: 'el R-R ha de variar amb la respiració');
  },
  'fibrilacion-auricular': (s) {
    expect(s.pTimes, isEmpty);
    expect(s.baseline, isNotNull);
    expect(_allNarrow(s), isTrue);
    expect(_cv(_rr(s)), greaterThan(0.08), reason: 'irregularment irregular');
    _rateIn(s, 40, 220, 'FA');
  },
  'flutter-auricular': (s) {
    expect(s.pTimes, isEmpty);
    expect(s.baseline, isNotNull);
    expect(_allNarrow(s), isTrue);
    // Cada R-R és 2, 3 o 4 cicles de flutter (280-320/min).
    for (final rr in _rr(s)) {
      final ok = [2, 3, 4].any((k) => rr >= k * 60 / 320 - 1e-9 && rr <= k * 60 / 280 + 1e-9);
      expect(ok, isTrue, reason: 'R-R $rr no és múltiple del cicle de flutter');
    }
  },
  'taquicardia-supraventricular': (s) {
    expect(s.pTimes, isEmpty);
    expect(_allNarrow(s), isTrue);
    _rateIn(s, 150, 220, 'TSV');
    expect(_cv(_rr(s)), lessThan(0.01));
  },
  'extrasistole-ventricular': (s) {
    final wide = s.qrs.where((q) => q.wide).toList();
    expect(wide, isNotEmpty, reason: 'hi ha d\'haver almenys una extrasístole');
    final prs = _pr(s);
    for (var i = 0; i < s.qrs.length; i++) {
      if (s.qrs[i].wide) {
        expect(prs[i], isNull, reason: 'l\'extrasístole ventricular no porta P');
        if (i > 0 && i < s.qrs.length - 1) {
          // Avançada i seguida d'una pausa més llarga.
          expect(s.qrs[i].t - s.qrs[i - 1].t, lessThan(s.qrs[i + 1].t - s.qrs[i].t));
        }
      } else {
        expect(prs[i], isNotNull);
      }
    }
    // Pausa compensadora completa: cada tram normal-extrasístole-normal dura
    // exactament dos cicles sinusals.
    final spans = [
      for (var i = 1; i < s.qrs.length - 1; i++)
        if (s.qrs[i].wide && !s.qrs[i - 1].wide && !s.qrs[i + 1].wide) s.qrs[i + 1].t - s.qrs[i - 1].t,
    ];
    if (spans.length > 1) expect(spans.reduce(max) - spans.reduce(min), lessThan(0.01));
    // I el nòdul sinusal no es reinicia: les P continuen a la seva graella.
    if (spans.isNotEmpty) {
      final cycle = spans.first / 2;
      for (var i = 1; i < s.pTimes.length; i++) {
        final k = (s.pTimes[i] - s.pTimes[i - 1]) / cycle;
        expect((k - k.round()).abs(), lessThan(0.02));
      }
    }
  },
  'extrasistole-auricular': (s) {
    expect(_allNarrow(s), isTrue);
    expect(_pr(s).every((pr) => pr != null), isTrue, reason: 'també l\'extrasístole auricular porta P');
    final rr = _rr(s);
    expect(rr.reduce(min) / rr.reduce(max), lessThan(0.8), reason: 'hi ha d\'haver un batec avançat');
  },
  'ritmo-nodal': (s) {
    expect(s.pTimes, isEmpty);
    expect(_allNarrow(s), isTrue);
    _rateIn(s, 40, 60, 'nodal');
  },
  'ritmo-idioventricular': (s) {
    expect(s.pTimes, isEmpty);
    expect(_allWide(s), isTrue);
    expect(s.qrs.length, greaterThanOrEqualTo(2));
    _rateIn(s, 22, 40, 'idioventricular');
  },
  'taquicardia-ventricular': (s) {
    expect(s.pTimes, isEmpty);
    expect(_allWide(s), isTrue);
    _rateIn(s, 140, 220, 'TV');
  },
  'torsade-pointes': (s) {
    expect(s.qrs, isEmpty);
    expect(s.baseline, isNotNull);
    // L'amplitud es retorça: hi ha trams grans i trams gairebé plans.
    final peaks = [for (var t = 0.0; t < s.seconds; t += 0.25) [for (var u = t; u < t + 0.25; u += 0.005) s.voltageAt(u).abs()].reduce(max)];
    expect(peaks.reduce(max), greaterThan(0.5));
    expect(peaks.reduce(min), lessThan(0.35));
  },
  'fibrilacion-ventricular': (s) {
    expect(s.qrs, isEmpty);
    expect(s.pTimes, isEmpty);
    expect(s.baseline, isNotNull);
  },
  'asistolia': (s) {
    expect(s.qrs, isEmpty);
    for (var t = 0.0; t < s.seconds; t += 0.05) {
      expect(s.voltageAt(t).abs(), lessThan(0.06));
    }
  },
  'bav-primer-grado': (s) => _sinusLike(s, 55, 90, prLo: 0.24, prHi: 0.36),
  'bav-mobitz-1': (s) {
    expect(_allNarrow(s), isTrue);
    expect(s.pTimes.length, greaterThan(s.qrs.length), reason: 'alguna P sense QRS');
    final prs = _pr(s).cast<double>();
    // Dins de cada grup el PR creix; després d'una P bloquejada torna a començar curt.
    var grew = false;
    for (var i = 1; i < prs.length; i++) {
      if (prs[i] > prs[i - 1] + 1e-9) grew = true;
    }
    expect(grew, isTrue, reason: 'el PR s\'ha d\'allargar');
    expect(prs.every((pr) => pr >= 0.14 - 1e-9 && pr <= 0.4), isTrue);
  },
  'bav-mobitz-2': (s) {
    expect(_allNarrow(s), isTrue);
    expect(s.pTimes.length, greaterThan(s.qrs.length), reason: 'alguna P sense QRS');
    final prs = _pr(s).cast<double>();
    expect(prs.reduce(max) - prs.reduce(min), lessThan(1e-9), reason: 'PR constant');
  },
  'bav-completo': (s) {
    final pRate = 60 / _mean([for (var i = 1; i < s.pTimes.length; i++) s.pTimes[i] - s.pTimes[i - 1]]);
    expect(pRate, inInclusiveRange(59.5, 100.5));
    expect(s.qrs.length, greaterThanOrEqualTo(2));
    _rateIn(s, 25, 40, 'escapament');
    expect(s.qrs.map((q) => q.wide).toSet().length, 1, reason: 'tots els QRS iguals');
  },
  'ritmo-marcapasos': (s) {
    expect(s.qrs.every((q) => q.paced && q.wide), isTrue);
    _rateIn(s, 60, 80, 'marcapassos');
  },
};

void main() {
  test('cada ritme del catàleg té generador i regles de test', () {
    expect(kEcgRhythms.map((r) => r.id).toSet(), _rules.keys.toSet());
    expect(kEcgRhythms.length, 20);
  });

  for (final r in kEcgRhythms) {
    test('${r.id}: la tira de llibre i $_seeds variants compleixen el ritme', () {
      final signatures = <String>{};
      for (var seed = 0; seed <= _seeds; seed++) {
        final s = ecgStripFor(r.id, seed: seed);
        for (var t = 0.0; t < s.seconds; t += 0.01) {
          expect(s.voltageAt(t).isFinite, isTrue);
        }
        _rules[r.id]!(s);
        signatures.add([for (var t = 0.0; t < s.seconds; t += 0.1) s.voltageAt(t).toStringAsFixed(3)].join('|'));
      }
      expect(signatures.length, greaterThan(_seeds ~/ 2), reason: 'les variants han de ser diferents entre si');
    });
  }

  test('un id desconegut falla en lloc de dibuixar un sinusal', () {
    expect(() => ecgStripFor('no-existeix'), throwsArgumentError);
  });
}
