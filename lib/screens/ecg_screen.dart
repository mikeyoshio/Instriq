import 'dart:math';

import 'package:flutter/material.dart';

import '../data/ecg_rhythms_data.dart';
import '../design_system/components/instriq_answer_option.dart';
import '../l10n/app_localizations.dart';
import '../utils/ecg_waveform.dart';

/// Tira d'ECG dibuixada sobre paper mil·limetrat (25 mm/s, 10 mm/mV).
class EcgStripView extends StatelessWidget {
  final EcgStrip strip;

  const EcgStripView({super.key, required this.strip});

  @override
  Widget build(BuildContext context) => AspectRatio(
        aspectRatio: strip.seconds * 25 / 30,
        child: CustomPaint(painter: _EcgPainter(strip, Theme.of(context).brightness == Brightness.dark)),
      );
}

class _EcgPainter extends CustomPainter {
  final EcgStrip strip;
  final bool dark;

  _EcgPainter(this.strip, this.dark);

  @override
  void paint(Canvas canvas, Size size) {
    final mm = size.width / (strip.seconds * 25);
    canvas.drawRect(Offset.zero & size, Paint()..color = dark ? const Color(0xFF1E1A1A) : const Color(0xFFFFF7F5));
    final minor = Paint()
      ..color = (dark ? const Color(0xFF5A2A2A) : const Color(0xFFF5C6C0))
      ..strokeWidth = 0.5;
    final major = Paint()
      ..color = (dark ? const Color(0xFF8A3A3A) : const Color(0xFFE8968C))
      ..strokeWidth = 1;
    for (var i = 0; i * mm <= size.width; i++) {
      canvas.drawLine(Offset(i * mm, 0), Offset(i * mm, size.height), i % 5 == 0 ? major : minor);
    }
    for (var i = 0; i * mm <= size.height; i++) {
      canvas.drawLine(Offset(0, i * mm), Offset(size.width, i * mm), i % 5 == 0 ? major : minor);
    }
    final baseline = size.height * 0.62;
    final path = Path();
    final steps = size.width.ceil() * 2;
    for (var i = 0; i <= steps; i++) {
      final x = size.width * i / steps;
      final t = x / mm / 25;
      final y = baseline - strip.voltageAt(t) * 10 * mm;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = dark ? Colors.white : Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  @override
  bool shouldRepaint(_EcgPainter old) => old.strip != strip || old.dark != dark;
}

class EcgScreen extends StatelessWidget {
  const EcgScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.ecgTitle),
          bottom: TabBar(tabs: [Tab(text: l10n.ecgRhythms), Tab(text: l10n.ecgPractice)]),
        ),
        body: TabBarView(
          children: [
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(l10n.ecgNote, style: theme.textTheme.bodySmall),
                for (final r in kEcgRhythms)
                  Card(
                    child: ExpansionTile(
                      title: Text(r.name.forLanguageCode(lang)),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedCrossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EcgStripView(strip: ecgStripFor(r.id)),
                        const SizedBox(height: 12),
                        Text(r.recognise.forLanguageCode(lang), style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 8),
                        for (final (k, v) in [
                          (l10n.ecgRate, r.rate),
                          (l10n.ecgRegularity, r.regularity),
                          (l10n.ecgP, r.pWave),
                          (l10n.ecgQrs, r.qrs),
                        ])
                          Text('$k: ${v.forLanguageCode(lang)}'),
                        const SizedBox(height: 8),
                        Text(l10n.ecgWhatYouDo, style: theme.textTheme.titleSmall),
                        Text(r.action.forLanguageCode(lang)),
                      ],
                    ),
                  ),
              ],
            ),
            const _EcgPractice(),
          ],
        ),
      ),
    );
  }
}

class _EcgPractice extends StatefulWidget {
  const _EcgPractice();

  @override
  State<_EcgPractice> createState() => _EcgPracticeState();
}

class _EcgPracticeState extends State<_EcgPractice> {
  final _rnd = Random();
  late int _answer;
  late List<int> _options;
  late int _seed;
  int? _picked;
  int _right = 0, _total = 0;

  @override
  void initState() {
    super.initState();
    _next();
  }

  void _next() {
    _answer = _rnd.nextInt(kEcgRhythms.length);
    final others = [for (var i = 0; i < kEcgRhythms.length; i++) if (i != _answer) i]..shuffle(_rnd);
    _options = [...others.take(3), _answer]..shuffle(_rnd);
    _seed = 1 + _rnd.nextInt(1 << 30); // 0 és la tira de llibre; la pràctica sempre en varia una
    _picked = null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(l10n.ecgPracticePrompt, style: theme.textTheme.titleMedium),
        if (_total > 0) Text(l10n.scoreFraction(_right, _total)),
        const SizedBox(height: 12),
        EcgStripView(strip: ecgStripFor(kEcgRhythms[_answer].id, seed: _seed)),
        const SizedBox(height: 16),
        for (final i in _options)
          InstriqAnswerOption(
            label: kEcgRhythms[i].name.forLanguageCode(lang),
            state: _picked == null
                ? InstriqAnswerState.idle
                : i == _answer
                    ? InstriqAnswerState.correct
                    : i == _picked
                        ? InstriqAnswerState.wrong
                        : InstriqAnswerState.other,
            onPressed: () => setState(() {
              _picked = i;
              _total++;
              if (i == _answer) _right++;
            }),
          ),
        if (_picked != null) ...[
          Text(kEcgRhythms[_answer].recognise.forLanguageCode(lang)),
          const SizedBox(height: 12),
          FilledButton(onPressed: () => setState(_next), child: Text(l10n.next)),
        ],
      ],
    );
  }
}
