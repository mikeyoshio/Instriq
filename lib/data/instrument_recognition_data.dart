import '../models/instrument.dart' show LocalizedText;
import 'lookalikes_data.dart';

/// «Com reconèixer-lo»: el tret visual que identifica cada peça. Les que
/// pertanyen a una família de semblants fan servir la pista de la família
/// (lookalikes_data.dart); aquí hi ha la resta de peces bàsiques.
/// Contingut propi, pendent de revisió clínica.
const Map<String, LocalizedText> kInstrumentRecognition = {
  'bisturi': LocalizedText(
    ca: 'Mànec pla i numerat amb una ranura on encaixa la fulla: el núm. 3 porta fulles petites (10, 11, 15) i el 4, grans (20-24).',
    es: 'Mango plano y numerado con una ranura donde encaja la hoja: el n.º 3 lleva hojas pequeñas (10, 11, 15) y el 4, grandes (20-24).',
    en: 'Flat, numbered handle with a slot for the blade: a No. 3 takes small blades (10, 11, 15) and a No. 4 large ones (20-24).',
  ),
  'hoja-bisturi': LocalizedText(
    ca: "Fulla d'un sol ús amb el número gravat: la 10 té la vora corba, la 11 és punxeguda i la 15 és una corba petita.",
    es: 'Hoja desechable con el número grabado: la 10 tiene el filo curvo, la 11 es puntiaguda y la 15 es una curva pequeña.',
    en: 'Disposable blade with the number stamped on it: the 10 has a curved edge, the 11 is pointed and the 15 is a small curve.',
  ),
  'pinza-backhaus': LocalizedText(
    ca: 'Anelles i cremallera, i dues puntes corbes i esmolades que es creuen.',
    es: 'Anillas y cremallera, y dos puntas curvas y afiladas que se cruzan.',
    en: 'Finger rings and a ratchet, with two curved, sharp tips that cross.',
  ),
  'separador-gancho': LocalizedText(
    ca: 'Mànec amb un o diversos ganxos a la punta, sense pala.',
    es: 'Mango con uno o varios ganchos en la punta, sin pala.',
    en: 'A handle with one or more hooks at the tip, no blade.',
  ),
  'separador-roux': LocalizedText(
    ca: 'Placa en forma de S de doble extrem, més petita que el Farabeuf.',
    es: 'Placa en forma de S de doble extremo, más pequeña que el Farabeuf.',
    en: 'Double-ended S-shaped plate, smaller than a Farabeuf.',
  ),
  'separador-senn-miller': LocalizedText(
    ca: "Doble extrem: tres puntes en rasclet a un costat i una petita pala a l'altre.",
    es: 'Doble extremo: tres puntas en rastrillo en un lado y una pequeña pala en el otro.',
    en: 'Double-ended: a three-prong rake at one end and a small blade at the other.',
  ),
  'separador-volkmann': LocalizedText(
    ca: 'Rasclet de mà amb diverses puntes, romes o esmolades.',
    es: 'Rastrillo de mano con varias puntas, romas o afiladas.',
    en: 'Hand-held rake with several prongs, blunt or sharp.',
  ),
  'separador-hohmann': LocalizedText(
    ca: "Pala estreta amb la punta corbada i afilada que s'ancora sota l'os.",
    es: 'Pala estrecha con la punta curvada y afilada que se ancla bajo el hueso.',
    en: 'Narrow blade with a curved, pointed tip that hooks under bone.',
  ),
  'separador-harrington': LocalizedText(
    ca: 'Pala ampla en forma de cor: separar fetge o diafragma.',
    es: 'Pala ancha en forma de corazón: separar hígado o diafragma.',
    en: 'Wide, heart-shaped blade: retracting the liver or diaphragm.',
  ),
  'separador-gosset': LocalizedText(
    ca: 'Autoestàtic de dues valves profundes que llisquen sobre una barra.',
    es: 'Autoestático de dos valvas profundas que se deslizan sobre una barra.',
    en: 'Self-retaining, with two deep blades that slide along a bar.',
  ),
  'separador-tuffier': LocalizedText(
    ca: 'Autoestàtic de cremallera amb dues valves curtes: obrir costelles o incisions petites.',
    es: 'Autoestático de cremallera con dos valvas cortas: abrir costillas o incisiones pequeñas.',
    en: 'Self-retaining rack with two short blades: spreading ribs or small incisions.',
  ),
  'legra': LocalizedText(
    ca: "Mànec amb una fulla plana i ampla de tall rom: desprendre el periosti de l'os.",
    es: 'Mango con una hoja plana y ancha de filo romo: despegar el periostio del hueso.',
    en: 'Handle with a flat, wide, blunt-edged blade: lifting periosteum off bone.',
  ),
  'pinza-intestinal-doyen': LocalizedText(
    ca: 'Mossegada llarga i elàstica amb estries longitudinals: clampar budell sense esclafar-lo.',
    es: 'Mordida larga y elástica con estrías longitudinales: clampar intestino sin aplastarlo.',
    en: 'Long, flexible jaws with longitudinal serrations: clamping bowel without crushing it.',
  ),
  'pinza-payr': LocalizedText(
    ca: "Clamp d'esclafament gran i fort, de branques articulades: estómac o budell que es resecarà.",
    es: 'Clamp de aplastamiento grande y fuerte, de ramas articuladas: estómago o intestino que se va a resecar.',
    en: 'Large, heavy crushing clamp with hinged jaws: stomach or bowel that will be resected.',
  ),
  'pinza-bolsa-tabaco': LocalizedText(
    ca: "Mossegada dentada que guia l'agulla recta per fer la sutura en bossa de tabac.",
    es: 'Mordida dentada que guía la aguja recta para hacer la sutura en bolsa de tabaco.',
    en: 'Toothed jaws that guide a straight needle to place a purse-string suture.',
  ),
  'pinza-pozzi': LocalizedText(
    ca: 'Pinça llarga amb dues puntes corbes i esmolades: subjectar el coll uterí.',
    es: 'Pinza larga con dos puntas curvas y afiladas: sujetar el cuello uterino.',
    en: 'Long forceps with two curved, sharp points: grasping the cervix.',
  ),
  'cureta-uterina': LocalizedText(
    ca: "Mànec llarg amb un anell tallant a la punta: rascar l'endometri.",
    es: 'Mango largo con un anillo cortante en la punta: raspar el endometrio.',
    en: 'Long handle with a sharp loop at the tip: scraping the endometrium.',
  ),
  'pinza-randall': LocalizedText(
    ca: 'Pinça llarga i corbada amb punta en cullera fenestrada: extreure càlculs.',
    es: 'Pinza larga y curvada con punta en cuchara fenestrada: extraer cálculos.',
    en: 'Long, curved forceps with fenestrated spoon tips: removing stones.',
  ),
  'pinza-satinsky': LocalizedText(
    ca: 'Clamp vascular corbat en forma de cullera amb estries atraumàtiques: clampar parcialment un vas gran.',
    es: 'Clamp vascular curvado en forma de cuchara con estrías atraumáticas: clampar parcialmente un vaso grande.',
    en: 'Curved, spoon-shaped vascular clamp with atraumatic serrations: partial clamping of a large vessel.',
  ),
  'clamp-bulldog': LocalizedText(
    ca: 'Clamp vascular molt petit de molla, sense anelles: es queda sol sobre el vas.',
    es: 'Clamp vascular muy pequeño de muelle, sin anillas: se queda solo sobre el vaso.',
    en: 'Very small spring vascular clamp with no rings: stays on the vessel by itself.',
  ),
  'tijera-potts-smith': LocalizedText(
    ca: 'Tisora angulada amb puntes molt fines: obrir vasos (arteriotomia).',
    es: 'Tijera angulada con puntas muy finas: abrir vasos (arteriotomía).',
    en: 'Angled scissors with very fine tips: opening vessels (arteriotomy).',
  ),
  'pinza-kerrison': LocalizedText(
    ca: "Gúbia amb mànec de pistola que mossega l'os amb un peu que llisca.",
    es: 'Gubia con mango de pistola que muerde el hueso con un pie que se desliza.',
    en: 'Pistol-grip punch that bites bone with a sliding footplate.',
  ),
  'pinza-hipofisaria': LocalizedText(
    ca: 'Mànec llarg i recte amb una mossegada petita en cullera: treure teixit en espais estrets.',
    es: 'Mango largo y recto con una mordida pequeña en cuchara: retirar tejido en espacios estrechos.',
    en: 'Long, straight shaft with small cup jaws: removing tissue in narrow spaces.',
  ),
  'disector-penfield': LocalizedText(
    ca: 'Mànec prim amb una espàtula roma a cada extrem: dissecció delicada en neurocirurgia.',
    es: 'Mango fino con una espátula roma en cada extremo: disección delicada en neurocirugía.',
    en: 'Slim handle with a blunt spatula at each end: delicate dissection in neurosurgery.',
  ),
  'pinza-magill': LocalizedText(
    ca: 'Pinça amb anelles i branques angulades: guiar el tub per la boca o el nas.',
    es: 'Pinza con anillas y ramas anguladas: guiar el tubo por la boca o la nariz.',
    en: 'Ringed forceps with angled shanks: guiding a tube through the mouth or nose.',
  ),
  'canula-guedel': LocalizedText(
    ca: "Peça corbada i rígida amb una vora a l'extrem: la mida va de la comissura de la boca a l'angle de la mandíbula.",
    es: 'Pieza curvada y rígida con un reborde en el extremo: la talla va de la comisura de la boca al ángulo de la mandíbula.',
    en: 'Rigid curved piece with a flange at one end: size it from the corner of the mouth to the angle of the jaw.',
  ),
  'pinza-maryland': LocalizedText(
    ca: 'Instrument laparoscòpic llarg amb mossegada corba i estriada: dissecció.',
    es: 'Instrumento laparoscópico largo con mordida curva y estriada: disección.',
    en: 'Long laparoscopic instrument with curved, serrated jaws: dissection.',
  ),
};

/// Com reconèixer una peça: la descripció pròpia o, si no en té, la pista
/// de la seva família de semblants.
LocalizedText? recognitionOf(String instrumentId) => kInstrumentRecognition[instrumentId] ?? lookalikeClueOf(instrumentId);
