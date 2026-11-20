import 'dart:math';

/// Generador de tires d'ECG sintètiques (derivació II, 25 mm/s, 10 mm/mV).
/// Són netes a propòsit: ensenyen el patró, no substitueixen tires reals.
///
/// Cada ritme es descriu com una llista de batecs (instants de P i de QRS) i,
/// si cal, una activitat de base (fibril·lació, flutter, torsade).
/// [EcgStrip.voltageAt] suma corbes gaussianes per a cada ona.
///
/// `seed: 0` dona la tira de llibre (la que es mostra a «Ritmes»); qualsevol
/// altra llavor tria valors dins del rang clínic de cada ritme (freqüència,
/// PR, conducció, patró d'extrasístoles…), de manera que la pràctica no
/// repeteix mai el mateix dibuix. `test/ecg_waveform_test.dart` comprova
/// centenars de llavors per ritme contra aquests rangs.
class EcgStrip {
  final double seconds;
  final List<double> pTimes;
  final List<({double t, bool wide, bool paced})> qrs;
  final double Function(double t)? baseline;
  final double gain;

  const EcgStrip({required this.seconds, this.pTimes = const [], this.qrs = const [], this.baseline, this.gain = 1});

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
    return v * gain;
  }
}

typedef _Beat = ({double t, bool wide, bool paced});

List<double> _every(double start, double interval, double end) =>
    [for (var t = start; t < end; t += interval) t];

/// Tira de [seconds] segons per a un ritme (ids de `kEcgRhythms`).
EcgStrip ecgStripFor(String id, {double seconds = 6, int seed = 0}) {
  final rnd = Random(seed);
  final canon = seed == 0;
  // Valor dins de [a, b], o el valor de llibre si seed == 0.
  double pick(double a, double b, double book) => canon ? book : a + rnd.nextDouble() * (b - a);
  T choose<T>(List<T> options, T book) => canon ? book : options[rnd.nextInt(options.length)];
  final start = pick(0.15, 0.6, 0.3);
  final gain = pick(0.9, 1.1, 1);
  _Beat n(double t) => (t: t, wide: false, paced: false);
  _Beat w(double t) => (t: t, wide: true, paced: false);
  EcgStrip strip({List<double> p = const [], List<_Beat> q = const [], double Function(double)? base}) =>
      EcgStrip(seconds: seconds, pTimes: p, qrs: q, baseline: base, gain: gain);

  EcgStrip sinus(double lo, double hi, double book, {double prLo = 0.12, double prHi = 0.20, double prBook = 0.16}) {
    final rr = 60 / pick(lo, hi, book);
    final pr = pick(prLo, prHi, prBook);
    final beats = _every(start + pr, rr, seconds);
    return strip(p: [for (final b in beats) b - pr], q: [for (final b in beats) n(b)]);
  }

  // Ritme sinusal de base amb un batec substituït cada tant (extrasístoles).
  List<int> ectopicSlots(int count) {
    final pattern = choose(['isolated', 'bigeminy', 'trigeminy'], 'isolated');
    return switch (pattern) {
      'bigeminy' => [for (var k = 1; k < count; k += 2) k],
      'trigeminy' => [for (var k = 2; k < count; k += 3) k],
      _ => canon ? [3] : {1 + rnd.nextInt(max(1, count - 2)), if (count > 6) 1 + rnd.nextInt(count - 2)}.toList(),
    };
  }

  switch (id) {
    case 'sinusal':
      return sinus(60, 100, 75);
    case 'bradicardia-sinusal':
      return sinus(38, 55, 45);
    case 'taquicardia-sinusal':
      return sinus(105, 150, 125, prHi: 0.16, prBook: 0.13);
    case 'arritmia-sinusal':
      // L'interval R-R puja i baixa amb la respiració (cicle de 3-5 s).
      final mean = 60 / pick(60, 90, 70);
      final depth = pick(0.12, 0.2, 0.16);
      final period = pick(3, 5, 4);
      final pr = pick(0.12, 0.2, 0.16);
      final beats = <double>[];
      for (var t = start + pr; t < seconds; t += mean * (1 + depth * sin(2 * pi * t / period))) {
        beats.add(t);
      }
      return strip(p: [for (final b in beats) b - pr], q: [for (final b in beats) n(b)]);
    case 'fibrilacion-auricular':
      // Resposta ventricular lenta, controlada o ràpida; R-R sempre irregular.
      final mean = 60 / pick(60, 150, 100);
      // Cada R-R difereix almenys un 15 % de l'anterior: mai no surt "regular" per atzar.
      final beats = <double>[];
      var prev = 1.0;
      for (var t = start; t < seconds;) {
        beats.add(t);
        var f = 0.55 + rnd.nextDouble() * 0.9;
        while ((f - prev).abs() < 0.15) {
          f = 0.55 + rnd.nextDouble() * 0.9;
        }
        prev = f;
        t += mean * f;
      }
      final f = [for (var i = 0; i < 3; i++) 5 + rnd.nextDouble() * 4];
      final ph = [for (var i = 0; i < 3; i++) rnd.nextDouble() * 6];
      final amp = pick(0.6, 1.3, 1);
      return strip(
        q: [for (final b in beats) n(b)],
        base: (t) =>
            amp *
            (0.035 * sin(2 * pi * f[0] * t + ph[0]) + 0.03 * sin(2 * pi * f[1] * t + ph[1]) + 0.025 * sin(2 * pi * f[2] * t + ph[2])),
      );
    case 'flutter-auricular':
      // Ones F a ~300/min; condueix 2:1, 3:1, 4:1 o de manera variable.
      final cycle = 60 / pick(280, 320, 300);
      final mode = choose(['2', '3', '4', 'v'], '4');
      final beats = <double>[];
      var t = start;
      while (t < seconds) {
        beats.add(t);
        t += cycle * (mode == 'v' ? 2 + rnd.nextInt(3) : int.parse(mode));
      }
      final phase = rnd.nextDouble();
      return strip(
        q: [for (final b in beats) n(b)],
        base: (t) {
          final x = (t / cycle + phase) % 1;
          return x < 0.8 ? -0.18 * x / 0.8 + 0.06 : -0.12 + 0.18 * (x - 0.8) / 0.2;
        },
      );
    case 'taquicardia-supraventricular':
      return strip(q: [for (final b in _every(start, 60 / pick(150, 220, 180), seconds)) n(b)]);
    case 'extrasistole-ventricular':
      // Batec ample avançat, sense P, i pausa compensadora completa.
      final rr = 60 / pick(60, 90, 75);
      final grid = _every(start + 0.16, rr, seconds);
      final slots = ectopicSlots(grid.length).toSet();
      final p = <double>[];
      final q = <_Beat>[];
      for (var k = 0; k < grid.length; k++) {
        if (slots.contains(k) && k > 0) {
          q.add(w(grid[k - 1] + rr * pick(0.5, 0.65, 0.55)));
        } else {
          p.add(grid[k] - 0.16);
          q.add(n(grid[k]));
        }
      }
      return strip(p: p, q: q);
    case 'extrasistole-auricular':
      // Batec estret avançat AMB P, i el sinus es reinicia (pausa no compensadora).
      final rr = 60 / pick(60, 90, 75);
      final pr = pick(0.12, 0.2, 0.16);
      final slots = ectopicSlots(((seconds - start) / rr).floor()).toSet();
      final p = <double>[];
      final q = <_Beat>[];
      var t = start + pr;
      for (var k = 0; t < seconds; k++) {
        if (slots.contains(k) && k > 0) t = q.last.t + rr * pick(0.6, 0.75, 0.65);
        if (t >= seconds) break;
        p.add(t - pr);
        q.add(n(t));
        t += rr;
      }
      return strip(p: p, q: q);
    case 'ritmo-nodal':
      return strip(q: [for (final b in _every(start, 60 / pick(40, 60, 50), seconds)) n(b)]);
    case 'ritmo-idioventricular':
      return strip(q: [for (final b in _every(start, 60 / pick(22, 40, 32), seconds)) w(b)]);
    case 'taquicardia-ventricular':
      return strip(q: [for (final b in _every(start, 60 / pick(140, 220, 170), seconds)) w(b)]);
    case 'torsade-pointes':
      // TV polimòrfica: l'amplitud creix, s'apaga i canvia de signe ("es retorça").
      final f = pick(200, 250, 225) / 60;
      final twist = pick(1.6, 2.6, 2.2);
      final ph = rnd.nextDouble() * pi;
      return strip(base: (t) => 0.9 * sin(pi * t / twist + ph) * sin(2 * pi * f * t));
    case 'fibrilacion-ventricular':
      // Gruixuda o fina.
      final amp = pick(0.15, 0.5, 0.35);
      final f = [for (final c in [4.6, 6.3, 3.1]) canon ? c : c * (0.85 + rnd.nextDouble() * 0.3)];
      final ph = [for (var i = 0; i < 3; i++) rnd.nextDouble() * 6];
      return strip(
        base: (t) =>
            (amp + 0.15 * sin(2 * pi * 0.4 * t)) *
            (sin(2 * pi * f[0] * t + ph[0]) * 0.6 + sin(2 * pi * f[1] * t + ph[1]) * 0.4 + sin(2 * pi * f[2] * t + ph[2]) * 0.3),
      );
    case 'asistolia':
      final amp = pick(0.01, 0.04, 0.02);
      final ph = rnd.nextDouble() * 6;
      return strip(base: (t) => amp * sin(2 * pi * 0.3 * t + ph));
    case 'bav-primer-grado':
      return sinus(55, 90, 70, prLo: 0.24, prHi: 0.36, prBook: 0.32);
    case 'bav-mobitz-1':
      // Cicles 3:2, 4:3 o 5:4: el PR s'allarga (cada cop menys) fins que una P no condueix.
      final pp = 60 / pick(70, 90, 80);
      final cycle = choose([3, 4, 5], 4);
      final pr0 = pick(0.14, 0.18, 0.16);
      final p = <double>[];
      final q = <_Beat>[];
      var i = 0;
      for (final pt in _every(start - 0.2, pp, seconds)) {
        p.add(pt);
        final k = i % cycle;
        if (k < cycle - 1) q.add(n(pt + pr0 + 0.2 * (1 - pow(0.5, k))));
        i++;
      }
      return strip(p: p, q: q);
    case 'bav-mobitz-2':
      // PR constant i, de sobte, una P sense QRS (3:2 o 4:3).
      final pp = 60 / pick(70, 100, 80);
      final cycle = choose([3, 4], 3);
      final pr = pick(0.14, 0.2, 0.18);
      final p = <double>[];
      final q = <_Beat>[];
      var i = 0;
      for (final pt in _every(start - 0.2, pp, seconds)) {
        p.add(pt);
        if (i % cycle != cycle - 1) q.add(n(pt + pr));
        i++;
      }
      return strip(p: p, q: q);
    case 'bav-completo':
      // P i QRS dissociats; escapament estret o ample, sempre lent.
      final wide = choose([true, false], true);
      return strip(
        p: _every(start - 0.1, 60 / pick(60, 100, 85), seconds),
        q: [for (final b in _every(start + 0.2 + rnd.nextDouble() * 0.3, 60 / pick(25, 40, 36), seconds)) (t: b, wide: wide, paced: false)],
      );
    case 'ritmo-marcapasos':
      return strip(q: [for (final b in _every(start, 60 / pick(60, 80, 70), seconds)) (t: b, wide: true, paced: true)]);
  }
  throw ArgumentError.value(id, 'id', 'Ritme sense generador');
}
