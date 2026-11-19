import 'dart:math';

/// Generador de tires d'ECG sintètiques (derivació II, 25 mm/s, 10 mm/mV).
/// Són netes a propòsit: ensenyen el patró, no substitueixen tires reals.
///
/// Cada ritme es descriu com una llista de batecs (instants de P i de QRS) i,
/// si cal, una activitat de base (fibril·lació, flutter). [EcgStrip.voltageAt]
/// suma corbes gaussianes per a cada ona.
class EcgStrip {
  final double seconds;
  final List<double> pTimes;
  final List<({double t, bool wide, bool paced})> qrs;
  final double Function(double t)? baseline;

  const EcgStrip({required this.seconds, this.pTimes = const [], this.qrs = const [], this.baseline});

  static double _g(double t, double c, double w, double a) => a * exp(-pow((t - c) / w, 2));

  double voltageAt(double t) {
    var v = baseline?.call(t) ?? 0;
    for (final p in pTimes) {
      if ((t - p).abs() < 0.2) v += _g(t, p, 0.035, 0.15);
    }
    for (final b in qrs) {
      final d = t - b.t;
      if (d < -0.1 || d > 0.6) continue;
      if (b.paced) v += _g(t, b.t - 0.04, 0.003, 1.2);
      if (b.wide) {
        v += _g(t, b.t, 0.045, 1.0) + _g(t, b.t + 0.09, 0.05, -0.35);
        v += _g(t, b.t + 0.36, 0.09, -0.3);
      } else {
        v += _g(t, b.t - 0.025, 0.01, -0.1) + _g(t, b.t, 0.012, 1.0) + _g(t, b.t + 0.03, 0.012, -0.25);
        v += _g(t, b.t + 0.3, 0.07, 0.3);
      }
    }
    return v;
  }
}

List<double> _every(double start, double interval, double end) =>
    [for (var t = start; t < end; t += interval) t];

/// Tira de [seconds] segons per a un ritme (ids de `kEcgRhythms`).
EcgStrip ecgStripFor(String id, {double seconds = 6, int seed = 1}) {
  final rnd = Random(seed);
  ({double t, bool wide, bool paced}) n(double t) => (t: t, wide: false, paced: false);
  ({double t, bool wide, bool paced}) w(double t) => (t: t, wide: true, paced: false);

  EcgStrip sinus(double bpm, {double pr = 0.16}) {
    final beats = _every(0.3, 60 / bpm, seconds);
    return EcgStrip(seconds: seconds, pTimes: [for (final b in beats) b - pr], qrs: [for (final b in beats) n(b)]);
  }

  switch (id) {
    case 'sinusal':
      return sinus(75);
    case 'bradicardia-sinusal':
      return sinus(45);
    case 'taquicardia-sinusal':
      return sinus(125, pr: 0.13);
    case 'fibrilacion-auricular':
      final beats = <double>[];
      for (var t = 0.25; t < seconds; t += 0.4 + rnd.nextDouble() * 0.6) {
        beats.add(t);
      }
      final phases = [for (var i = 0; i < 4; i++) rnd.nextDouble() * 6];
      return EcgStrip(
        seconds: seconds,
        qrs: [for (final b in beats) n(b)],
        baseline: (t) =>
            0.035 * sin(2 * pi * 6.1 * t + phases[0]) +
            0.03 * sin(2 * pi * 7.3 * t + phases[1]) +
            0.025 * sin(2 * pi * 8.9 * t + phases[2]),
      );
    case 'flutter-auricular':
      return EcgStrip(
        seconds: seconds,
        qrs: [for (final b in _every(0.3, 0.8, seconds)) n(b)],
        baseline: (t) {
          final x = (t * 5) % 1; // 300/min
          return x < 0.8 ? -0.18 * x / 0.8 + 0.06 : -0.12 + 0.18 * (x - 0.8) / 0.2;
        },
      );
    case 'taquicardia-supraventricular':
      return EcgStrip(seconds: seconds, qrs: [for (final b in _every(0.2, 60 / 180, seconds)) n(b)]);
    case 'extrasistole-ventricular':
      final p = <double>[];
      final q = <({double t, bool wide, bool paced})>[];
      var t = 0.3;
      var i = 0;
      while (t < seconds) {
        if (i % 4 == 3) {
          q.add(w(t - 0.35));
          t += 0.8 * 2 - 0.35; // pausa compensadora
        } else {
          p.add(t - 0.16);
          q.add(n(t));
          t += 0.8;
        }
        i++;
      }
      return EcgStrip(seconds: seconds, pTimes: p, qrs: q);
    case 'taquicardia-ventricular':
      return EcgStrip(seconds: seconds, qrs: [for (final b in _every(0.2, 60 / 170, seconds)) w(b)]);
    case 'fibrilacion-ventricular':
      final ph = [for (var i = 0; i < 4; i++) rnd.nextDouble() * 6];
      return EcgStrip(
        seconds: seconds,
        baseline: (t) =>
            (0.35 + 0.15 * sin(2 * pi * 0.4 * t)) *
            (sin(2 * pi * 4.6 * t + ph[0]) * 0.6 + sin(2 * pi * 6.3 * t + ph[1]) * 0.4 + sin(2 * pi * 3.1 * t + ph[2]) * 0.3),
      );
    case 'asistolia':
      return EcgStrip(seconds: seconds, baseline: (t) => 0.02 * sin(2 * pi * 0.3 * t));
    case 'bav-primer-grado':
      return sinus(70, pr: 0.32);
    case 'bav-mobitz-1':
      final p = <double>[];
      final q = <({double t, bool wide, bool paced})>[];
      const prs = [0.16, 0.26, 0.34];
      var i = 0;
      for (final pt in _every(0.1, 0.75, seconds)) {
        p.add(pt);
        if (i % 4 < 3) q.add(n(pt + prs[i % 4]));
        i++;
      }
      return EcgStrip(seconds: seconds, pTimes: p, qrs: q);
    case 'bav-mobitz-2':
      final p = <double>[];
      final q = <({double t, bool wide, bool paced})>[];
      var i = 0;
      for (final pt in _every(0.1, 0.75, seconds)) {
        p.add(pt);
        if (i % 3 != 2) q.add(n(pt + 0.18));
        i++;
      }
      return EcgStrip(seconds: seconds, pTimes: p, qrs: q);
    case 'bav-completo':
      return EcgStrip(
        seconds: seconds,
        pTimes: _every(0.15, 60 / 85, seconds),
        qrs: [for (final b in _every(0.5, 60 / 36, seconds)) w(b)],
      );
    case 'ritmo-marcapasos':
      return EcgStrip(
        seconds: seconds,
        qrs: [for (final b in _every(0.4, 60 / 70, seconds)) (t: b, wide: true, paced: true)],
      );
  }
  return sinus(75);
}
