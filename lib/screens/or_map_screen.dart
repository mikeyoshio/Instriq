import 'package:flutter/material.dart';

import '../design_system/tokens.dart';
import '../l10n/app_localizations.dart';
import '../models/instrument.dart' show LocalizedText;

/// Pla del quiròfan vist des de dalt: qui és on i què és cada cosa, en una
/// disposició habitual (laparotomia, pacient en decúbit supí). Varia segons
/// la intervenció i el centre. Contingut propi, pendent de revisió clínica.
enum _Kind { person, equipment, zone }

class _Spot {
  final double x, y; // 0..1 sobre el pla (amplada) i 0..1.3 (alçada)
  final _Kind kind;
  final LocalizedText title, text;
  const _Spot(this.x, this.y, this.kind, this.title, this.text);
}

const _spots = <_Spot>[
  _Spot(0.5, 0.12, _Kind.person,
      LocalizedText(ca: 'Anestesiòleg i màquina d\'anestèsia', es: 'Anestesiólogo y máquina de anestesia', en: 'Anaesthetist and anaesthetic machine'),
      LocalizedText(
        ca: 'Al cap del pacient: via aèria, monitoratge i fàrmacs. La pantalla d\'anestèsia separa aquesta zona del camp estèril.',
        es: 'En la cabecera del paciente: vía aérea, monitorización y fármacos. El arco de anestesia separa esta zona del campo estéril.',
        en: "At the patient's head: airway, monitoring and drugs. The anaesthetic screen separates this area from the sterile field.",
      )),
  _Spot(0.5, 0.55, _Kind.equipment,
      LocalizedText(ca: 'Taula quirúrgica i làmpada', es: 'Mesa quirúrgica y lámpara', en: 'Operating table and light'),
      LocalizedText(
        ca: 'El pacient al centre. Les nanses de la làmpada són estèrils per poder-la orientar sense sortir del camp.',
        es: 'El paciente en el centro. Los mangos de la lámpara son estériles para poder orientarla sin salir del campo.',
        en: 'The patient in the middle. The light handles are sterile so it can be aimed without leaving the field.',
      )),
  _Spot(0.26, 0.55, _Kind.person,
      LocalizedText(ca: 'Cirurgià', es: 'Cirujano', en: 'Surgeon'),
      LocalizedText(
        ca: 'Normalment al costat on queda la zona que s\'opera; en una laparotomia, sovint a la dreta del pacient.',
        es: 'Normalmente en el lado de la zona que se opera; en una laparotomía, a menudo a la derecha del paciente.',
        en: "Usually on the side of the operative area; in a laparotomy, often on the patient's right.",
      )),
  _Spot(0.74, 0.55, _Kind.person,
      LocalizedText(ca: 'Ajudant', es: 'Ayudante', en: 'Assistant'),
      LocalizedText(
        ca: 'Davant del cirurgià: separa, aspira i exposa el camp.',
        es: 'Frente al cirujano: separa, aspira y expone el campo.',
        en: 'Opposite the surgeon: retracts, suctions and exposes the field.',
      )),
  _Spot(0.5, 0.92, _Kind.equipment,
      LocalizedText(ca: 'Mesa de Mayo', es: 'Mesa de Mayo', en: 'Mayo stand'),
      LocalizedText(
        ca: 'Damunt de les cames del pacient, amb el que es fa servir de seguida, a l\'abast de la instrumentista.',
        es: 'Sobre las piernas del paciente, con lo que se usa enseguida, al alcance de la instrumentista.',
        en: "Over the patient's legs, holding what is needed right away, within the scrub nurse's reach.",
      )),
  _Spot(0.74, 0.86, _Kind.person,
      LocalizedText(ca: 'Instrumentista', es: 'Instrumentista', en: 'Scrub nurse'),
      LocalizedText(
        ca: 'Estèril, entre la mesa de Mayo i la mesa auxiliar: prepara, lliura i compta material, i vigila l\'esterilitat del camp.',
        es: 'Estéril, entre la mesa de Mayo y la mesa auxiliar: prepara, entrega y cuenta material, y vigila la esterilidad del campo.',
        en: 'Sterile, between the Mayo stand and the back table: prepares, passes and counts items, and guards the sterile field.',
      )),
  _Spot(0.86, 1.08, _Kind.equipment,
      LocalizedText(ca: 'Mesa auxiliar (d\'instrumental)', es: 'Mesa auxiliar (de instrumental)', en: 'Back table'),
      LocalizedText(
        ca: 'Tot el material estèril de la intervenció, ordenat. Només la toca personal estèril.',
        es: 'Todo el material estéril de la intervención, ordenado. Solo la toca personal estéril.',
        en: 'All the sterile supplies for the case, laid out in order. Only sterile staff touch it.',
      )),
  _Spot(0.14, 0.98, _Kind.person,
      LocalizedText(ca: 'Infermera circulant', es: 'Enfermera circulante', en: 'Circulating nurse'),
      LocalizedText(
        ca: 'No estèril: obre material, registra, porta mostres, connecta aparells i fa el recompte amb la instrumentista.',
        es: 'No estéril: abre material, registra, lleva muestras, conecta aparatos y hace el recuento con la instrumentista.',
        en: 'Non-sterile: opens supplies, documents, handles specimens, connects equipment and counts with the scrub nurse.',
      )),
  _Spot(0.1, 0.42, _Kind.equipment,
      LocalizedText(ca: 'Bisturí elèctric', es: 'Bisturí eléctrico', en: 'Electrosurgical unit'),
      LocalizedText(
        ca: 'Fora del camp estèril. La placa del pacient, lluny de metalls i ben adherida; vegeu la guia de seguretat.',
        es: 'Fuera del campo estéril. La placa del paciente, lejos de metales y bien adherida; consulta la guía de seguridad.',
        en: "Outside the sterile field. The patient plate well stuck down and away from metal; see the safety guide.",
      )),
  _Spot(0.1, 0.7, _Kind.equipment,
      LocalizedText(ca: 'Aspirador', es: 'Aspirador', en: 'Suction unit'),
      LocalizedText(
        ca: 'Fora del camp; el tub estèril baixa des del camp. Vigila el volum aspirat per calcular pèrdues.',
        es: 'Fuera del campo; el tubo estéril baja desde el campo. Vigila el volumen aspirado para calcular pérdidas.',
        en: 'Outside the field; the sterile tubing runs down from it. Watch the volume collected to estimate losses.',
      )),
  _Spot(0.5, 1.24, _Kind.zone,
      LocalizedText(ca: 'Porta', es: 'Puerta', en: 'Door'),
      LocalizedText(
        ca: 'Tancada durant la intervenció: cada obertura altera el flux d\'aire i augmenta el risc d\'infecció.',
        es: 'Cerrada durante la intervención: cada apertura altera el flujo de aire y aumenta el riesgo de infección.',
        en: 'Kept closed during the case: every opening disturbs airflow and raises the infection risk.',
      )),
  _Spot(0.38, 0.75, _Kind.zone,
      LocalizedText(ca: 'Camp estèril', es: 'Campo estéril', en: 'Sterile field'),
      LocalizedText(
        ca: 'La zona puntejada: només hi entra personal i material estèril. Si hi ha dubte, es considera contaminat.',
        es: 'La zona punteada: solo entra personal y material estéril. Ante la duda, se considera contaminado.',
        en: 'The dotted area: only sterile staff and items. If in doubt, consider it contaminated.',
      )),
];

class OrMapScreen extends StatefulWidget {
  const OrMapScreen({super.key});

  @override
  State<OrMapScreen> createState() => _OrMapScreenState();
}

class _OrMapScreenState extends State<OrMapScreen> {
  int _selected = 0;

  Color _color(ColorScheme s, _Kind k) => switch (k) {
        _Kind.person => s.primary,
        _Kind.equipment => s.tertiary,
        _Kind.zone => s.onSurfaceVariant,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final spot = _spots[_selected];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.orMapTitle)),
      body: ListView(
        padding: const EdgeInsets.all(InstriqSpacing.lg),
        children: [
          Text(l10n.orMapIntro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: InstriqSpacing.lg),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: AspectRatio(
                aspectRatio: 1 / 1.3,
                child: LayoutBuilder(
                  builder: (context, c) {
                    final w = c.maxWidth, h = c.maxHeight;
                    return Stack(
                      children: [
                        Positioned.fill(child: CustomPaint(painter: _RoomPainter(scheme))),
                        for (var i = 0; i < _spots.length; i++)
                          Positioned(
                            left: _spots[i].x * w - 20,
                            top: _spots[i].y / 1.3 * h - 20,
                            child: Semantics(
                              button: true,
                              selected: i == _selected,
                              label: _spots[i].title.forLanguageCode(lang),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: () => setState(() => _selected = i),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i == _selected ? _color(scheme, _spots[i].kind) : scheme.surface,
                                    border: Border.all(color: _color(scheme, _spots[i].kind), width: 2),
                                  ),
                                  child: Text(
                                    '${i + 1}',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: i == _selected ? scheme.surface : _color(scheme, _spots[i].kind),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: InstriqSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(InstriqSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_selected + 1}. ${spot.title.forLanguageCode(lang)}', style: theme.textTheme.titleMedium),
                  const SizedBox(height: InstriqSpacing.xs),
                  Text(spot.text.forLanguageCode(lang), style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          const SizedBox(height: InstriqSpacing.md),
          for (var i = 0; i < _spots.length; i++)
            ListTile(
              dense: true,
              selected: i == _selected,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: _color(scheme, _spots[i].kind),
                child: Text('${i + 1}', style: TextStyle(color: scheme.surface, fontSize: 12, fontWeight: FontWeight.w700)),
              ),
              title: Text(_spots[i].title.forLanguageCode(lang)),
              onTap: () => setState(() => _selected = i),
            ),
          const SizedBox(height: InstriqSpacing.md),
          Text(l10n.orMapNote, style: theme.textTheme.bodySmall),
          const SizedBox(height: InstriqSpacing.xs),
          Text(l10n.contentInReviewNote, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Sala, taula, pantalla d'anestèsia i camp estèril, en el mateix sistema de
/// coordenades que els punts (x 0..1, y 0..1.3).
class _RoomPainter extends CustomPainter {
  final ColorScheme scheme;
  _RoomPainter(this.scheme);

  @override
  void paint(Canvas canvas, Size size) {
    Offset p(double x, double y) => Offset(x * size.width, y / 1.3 * size.height);
    Rect r(double x1, double y1, double x2, double y2) => Rect.fromPoints(p(x1, y1), p(x2, y2));
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = scheme.outlineVariant;
    final fill = Paint()..color = scheme.surfaceContainerHigh;
    // Sala
    canvas.drawRRect(RRect.fromRectAndRadius(r(0.02, 0.02, 0.98, 1.28), const Radius.circular(12)), Paint()..color = scheme.surfaceContainerLow);
    canvas.drawRRect(RRect.fromRectAndRadius(r(0.02, 0.02, 0.98, 1.28), const Radius.circular(12)), line);
    // Camp estèril (puntejat): taula + mesa de Mayo + mesa auxiliar
    final sterile = Path()..addRRect(RRect.fromRectAndRadius(r(0.2, 0.3, 0.97, 1.16), const Radius.circular(16)));
    final dash = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = scheme.primary.withValues(alpha: 0.6);
    for (final metric in sterile.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 12) {
        canvas.drawPath(metric.extractPath(d, d + 6), dash);
      }
    }
    canvas.drawRRect(RRect.fromRectAndRadius(r(0.2, 0.3, 0.97, 1.16), const Radius.circular(16)),
        Paint()..color = scheme.primary.withValues(alpha: 0.05));
    // Taula quirúrgica
    canvas.drawRRect(RRect.fromRectAndRadius(r(0.4, 0.2, 0.6, 0.98), const Radius.circular(10)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(r(0.4, 0.2, 0.6, 0.98), const Radius.circular(10)), line);
    // Pantalla d'anestèsia
    canvas.drawLine(p(0.3, 0.28), p(0.7, 0.28), Paint()
      ..strokeWidth = 4
      ..color = scheme.outline);
    // Làmpada
    canvas.drawCircle(p(0.5, 0.55), size.width * 0.13, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = scheme.outlineVariant);
    // Mesa de Mayo i mesa auxiliar
    canvas.drawRRect(RRect.fromRectAndRadius(r(0.38, 0.86, 0.62, 0.98), const Radius.circular(6)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(r(0.38, 0.86, 0.62, 0.98), const Radius.circular(6)), line);
    canvas.drawRRect(RRect.fromRectAndRadius(r(0.72, 1.0, 0.95, 1.14), const Radius.circular(6)), fill);
    canvas.drawRRect(RRect.fromRectAndRadius(r(0.72, 1.0, 0.95, 1.14), const Radius.circular(6)), line);
    // Porta
    canvas.drawLine(p(0.4, 1.28), p(0.6, 1.28), Paint()
      ..strokeWidth = 6
      ..color = scheme.surface);
  }

  @override
  bool shouldRepaint(covariant _RoomPainter old) => old.scheme != scheme;
}
