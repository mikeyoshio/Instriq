import 'package:flutter/material.dart';

import '../design_system/components/instriq_list_item.dart';
import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../utils/clinical_calc.dart';

/// Calculadores de suport sense dosis de fàrmacs: mesures del pacient i
/// càlculs de volum i temps (`utils/clinical_calc.dart`).
class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = <(IconData, String, Widget)>[
      (Icons.monitor_weight_outlined, l10n.calcBodyTitle, const _BodyCalc()),
      (Icons.water_drop_outlined, l10n.calcRenalTitle, const _RenalCalc()),
      (Icons.local_fire_department_outlined, l10n.calcBurnsTitle, const _BurnsCalc()),
      (Icons.pregnant_woman_outlined, l10n.calcGestationTitle, const _GestationCalc()),
      (Icons.opacity, l10n.calcDripTitle, const _DripCalc()),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.calcTitle)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text(l10n.calcNoDoses, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          for (final (icon, title, page) in items)
            Padding(
              padding: const EdgeInsets.only(bottom: InstriqSpacing.sm),
              child: InstriqListItem(
                icon: icon,
                title: title,
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(title)),
                    body: ListView(padding: const EdgeInsets.all(16), children: [page]),
                  ),
                )),
              ),
            ),
        ],
      ),
    );
  }
}

/// Camp numèric que accepta coma o punt.
class _Num extends StatelessWidget {
  final String label;
  final String? suffix;
  final ValueChanged<double?> onChanged;

  const _Num(this.label, this.onChanged, {this.suffix});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, suffixText: suffix, border: const OutlineInputBorder()),
          onChanged: (v) => onChanged(parseNumber(v)),
        ),
      );
}

class _Result extends StatelessWidget {
  final List<String> lines;
  final String? empty;

  const _Result(this.lines, {this.empty});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final ready = lines.isNotEmpty;
    return Card(
      color: ready ? theme.colorScheme.primaryContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          ready ? lines.join('\n') : (empty ?? l10n.calcFillAll),
          style: theme.textTheme.titleMedium?.copyWith(color: ready ? theme.colorScheme.onPrimaryContainer : null),
        ),
      ),
    );
  }
}

Widget _sexPicker(AppLocalizations l10n, bool male, ValueChanged<bool> onChanged) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SegmentedButton<bool>(
        segments: [
          ButtonSegment(value: true, label: Text(l10n.calcMale)),
          ButtonSegment(value: false, label: Text(l10n.calcFemale)),
        ],
        selected: {male},
        onSelectionChanged: (v) => onChanged(v.first),
      ),
    );

String _f(double v, [int digits = 1]) => v.toStringAsFixed(digits);

class _BodyCalc extends StatefulWidget {
  const _BodyCalc();

  @override
  State<_BodyCalc> createState() => _BodyCalcState();
}

class _BodyCalcState extends State<_BodyCalc> {
  double? _kg, _cm;
  bool _male = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ok = _kg != null && _cm != null && _kg! > 0 && _cm! > 0;
    return Column(children: [
      _sexPicker(l10n, _male, (v) => setState(() => _male = v)),
      _Num(l10n.calcWeight, (v) => setState(() => _kg = v), suffix: 'kg'),
      _Num(l10n.calcHeight, (v) => setState(() => _cm = v), suffix: 'cm'),
      _Result(ok
          ? [
              '${l10n.calcBmi}: ${_f(bmi(_kg!, _cm!))} kg/m²',
              '${l10n.calcIdealWeight}: ${_f(idealWeightDevine(heightCm: _cm!, male: _male))} kg',
              '${l10n.calcBsa}: ${_f(bsaMosteller(_kg!, _cm!), 2)} m²',
            ]
          : []),
      const SizedBox(height: 8),
      Text('IMC (OMS) · Devine BJ, 1974 · Mosteller RD, N Engl J Med 1987',
          style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class _RenalCalc extends StatefulWidget {
  const _RenalCalc();

  @override
  State<_RenalCalc> createState() => _RenalCalcState();
}

class _RenalCalcState extends State<_RenalCalc> {
  double? _age, _kg, _cr;
  bool _male = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ok = _age != null && _kg != null && _cr != null && _cr! > 0 && _age! < 140;
    return Column(children: [
      _sexPicker(l10n, _male, (v) => setState(() => _male = v)),
      _Num(l10n.calcAge, (v) => setState(() => _age = v), suffix: l10n.calcYears),
      _Num(l10n.calcWeight, (v) => setState(() => _kg = v), suffix: 'kg'),
      _Num(l10n.calcCreatinine, (v) => setState(() => _cr = v), suffix: 'mg/dl'),
      _Result(ok
          ? [
              '${l10n.calcCrCl}: ${_f(creatinineClearance(age: _age!.round(), weightKg: _kg!, creatinineMgDl: _cr!, male: _male), 0)} ml/min'
            ]
          : []),
      const SizedBox(height: 8),
      Text('Cockcroft DW, Gault MH. Nephron 1976;16:31-41.', style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class _BurnsCalc extends StatefulWidget {
  const _BurnsCalc();

  @override
  State<_BurnsCalc> createState() => _BurnsCalcState();
}

class _BurnsCalcState extends State<_BurnsCalc> {
  final _selected = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = {
      'head': l10n.calcBurnHead,
      'armLeft': l10n.calcBurnArmLeft,
      'armRight': l10n.calcBurnArmRight,
      'trunkFront': l10n.calcBurnTrunkFront,
      'trunkBack': l10n.calcBurnTrunkBack,
      'legLeft': l10n.calcBurnLegLeft,
      'legRight': l10n.calcBurnLegRight,
      'perineum': l10n.calcBurnPerineum,
    };
    final total = _selected.fold<int>(0, (a, k) => a + ruleOfNines[k]!);
    return Column(children: [
      Text(l10n.calcBurnsHint),
      for (final e in ruleOfNines.entries)
        CheckboxListTile(
          value: _selected.contains(e.key),
          onChanged: (v) => setState(() => v! ? _selected.add(e.key) : _selected.remove(e.key)),
          title: Text(labels[e.key]!),
          secondary: Text('${e.value} %'),
          contentPadding: EdgeInsets.zero,
        ),
      _Result(_selected.isEmpty ? [] : ['${l10n.calcBurnTotal}: $total %'], empty: l10n.calcBurnsEmpty),
      const SizedBox(height: 8),
      Text(l10n.calcBurnsNote, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class _GestationCalc extends StatefulWidget {
  const _GestationCalc();

  @override
  State<_GestationCalc> createState() => _GestationCalcState();
}

class _GestationCalcState extends State<_GestationCalc> {
  DateTime? _lmp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loc = MaterialLocalizations.of(context);
    final g = _lmp == null ? null : gestation(_lmp!, DateTime.now());
    return Column(children: [
      OutlinedButton.icon(
        icon: const Icon(Icons.event),
        label: Text(_lmp == null ? l10n.calcLmpPick : '${l10n.calcLmp}: ${loc.formatMediumDate(_lmp!)}'),
        onPressed: () async {
          final now = DateTime.now();
          final d = await showDatePicker(
            context: context,
            initialDate: _lmp ?? now.subtract(const Duration(days: 60)),
            firstDate: now.subtract(const Duration(days: 320)),
            lastDate: now,
          );
          if (d != null) setState(() => _lmp = d);
        },
      ),
      const SizedBox(height: 12),
      _Result(g == null
          ? []
          : [l10n.calcGestationAge(g.weeks, g.days), '${l10n.calcDueDate}: ${loc.formatMediumDate(g.dueDate)}']),
      const SizedBox(height: 8),
      Text(l10n.calcGestationNote, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}

class _DripCalc extends StatefulWidget {
  const _DripCalc();

  @override
  State<_DripCalc> createState() => _DripCalcState();
}

class _DripCalcState extends State<_DripCalc> {
  double? _ml, _hours;
  int _factor = 20;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ok = _ml != null && _hours != null && _ml! > 0 && _hours! > 0;
    final minutes = ok ? _hours! * 60 : 0.0;
    return Column(children: [
      _Num(l10n.calcVolume, (v) => setState(() => _ml = v), suffix: 'ml'),
      _Num(l10n.calcTime, (v) => setState(() => _hours = v), suffix: 'h'),
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SegmentedButton<int>(
          segments: [
            ButtonSegment(value: 20, label: Text(l10n.calcMacrodrip)),
            ButtonSegment(value: 60, label: Text(l10n.calcMicrodrip)),
          ],
          selected: {_factor},
          onSelectionChanged: (v) => setState(() => _factor = v.first),
        ),
      ),
      _Result(ok
          ? [
              '${_f(mlPerHour(_ml!, minutes))} ml/h',
              '${_f(dropsPerMinute(_ml!, minutes, _factor), 0)} ${l10n.calcDropsPerMin}',
            ]
          : []),
      const SizedBox(height: 8),
      Text(l10n.calcDripNote, style: Theme.of(context).textTheme.bodySmall),
    ]);
  }
}
