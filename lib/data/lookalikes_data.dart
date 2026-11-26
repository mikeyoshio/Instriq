import '../models/instrument.dart' show LocalizedText;

/// Famílies d'instruments que es confonen entre si, amb la pista visual que
/// distingeix cada peça dins de la família. Alimenta «No confondre amb» a la
/// fitxa, el qüestionari de semblants i les comparatives del Vademècum
/// (`tool/generate_vademecum.dart` llegeix aquest fitxer com a text: mantenir
/// el format `LookalikeMember('id', LocalizedText(...))`).
///
/// Contingut propi, pendent de revisió clínica: l'app el marca "en revisió".
class LookalikeMember {
  final String instrumentId;
  final LocalizedText clue;
  const LookalikeMember(this.instrumentId, this.clue);
}

class LookalikeFamily {
  final String id;
  final LocalizedText title;
  final LocalizedText tip;
  final List<LookalikeMember> members;
  const LookalikeFamily(this.id, this.title, this.tip, this.members);
}

const List<LookalikeFamily> kLookalikeFamilies = [
  LookalikeFamily(
    'tisores',
    LocalizedText(ca: 'Tisores de dissecció', es: 'Tijeras de disección', en: 'Dissecting scissors'),
    LocalizedText(
      ca: 'Mira la proporció entre mànec i fulla i el gruix de les fulles.',
      es: 'Fíjate en la proporción entre mango y hoja y en el grosor de las hojas.',
      en: 'Look at the handle-to-blade ratio and how thick the blades are.',
    ),
    [
      LookalikeMember('tijera-mayo', LocalizedText(
        ca: 'Curta i robusta, de fulles gruixudes: teixit dens i tallar sutures.',
        es: 'Corta y robusta, de hojas gruesas: tejido denso y cortar suturas.',
        en: 'Short and sturdy with heavy blades: dense tissue and cutting sutures.',
      )),
      LookalikeMember('tijera-metzenbaum', LocalizedText(
        ca: 'Mànecs llargs i fulles curtes i fines: teixit delicat, mai fil.',
        es: 'Mangos largos y hojas cortas y finas: tejido delicado, nunca hilo.',
        en: 'Long handles and short, fine blades: delicate tissue, never suture.',
      )),
      LookalikeMember('tijera-iris', LocalizedText(
        ca: 'Petita i de puntes molt fines: teixit fi, oftalmologia i plàstica.',
        es: 'Pequeña y de puntas muy finas: tejido fino, oftalmología y plástica.',
        en: 'Small with very fine tips: fine tissue, ophthalmic and plastic surgery.',
      )),
    ],
  ),
  LookalikeFamily(
    'pinces-disseccio',
    LocalizedText(ca: 'Pinces de dissecció', es: 'Pinzas de disección', en: 'Dissecting forceps'),
    LocalizedText(
      ca: 'Primer la punta (dents o no) i després la mida.',
      es: 'Primero la punta (dientes o no) y después el tamaño.',
      en: 'First the tip (teeth or not), then the size.',
    ),
    [
      LookalikeMember('pinza-diseccion-dientes', LocalizedText(
        ca: 'Dents a la punta: agafen pell i teixit ferm sense que rellisqui.',
        es: 'Dientes en la punta: sujetan piel y tejido firme sin que resbale.',
        en: 'Teeth at the tip: hold skin and firm tissue without slipping.',
      )),
      LookalikeMember('pinza-diseccion-sin-dientes', LocalizedText(
        ca: 'Estries transversals i cap dent: teixit delicat.',
        es: 'Estrías transversales y ningún diente: tejido delicado.',
        en: 'Cross serrations and no teeth: delicate tissue.',
      )),
      LookalikeMember('pinza-adson-dientes', LocalizedText(
        ca: 'Curta, mànec ample i punta estreta amb dents: pell.',
        es: 'Corta, mango ancho y punta estrecha con dientes: piel.',
        en: 'Short, broad grip and a narrow toothed tip: skin.',
      )),
      LookalikeMember('pinza-adson-sin-dientes', LocalizedText(
        ca: "Com l'Adson amb dents, però la punta és estriada: teixit fi.",
        es: 'Como la Adson con dientes, pero la punta es estriada: tejido fino.',
        en: 'Like the toothed Adson, but with a serrated tip: fine tissue.',
      )),
      LookalikeMember('pinza-debakey', LocalizedText(
        ca: 'Llarga, amb estries longitudinals fines i atraumàtiques: vasos i budell.',
        es: 'Larga, con estrías longitudinales finas y atraumáticas: vasos e intestino.',
        en: 'Long, with fine atraumatic longitudinal serrations: vessels and bowel.',
      )),
    ],
  ),
  LookalikeFamily(
    'hemostatiques',
    LocalizedText(ca: 'Pinces hemostàtiques', es: 'Pinzas hemostáticas', en: 'Haemostatic forceps'),
    LocalizedText(
      ca: 'Ordena-les per mida i mira la punta: dents (Kocher), angle recte (Mixter) o estries només a la meitat (Kelly).',
      es: 'Ordénalas por tamaño y mira la punta: dientes (Kocher), ángulo recto (Mixter) o estrías solo en la mitad (Kelly).',
      en: 'Sort them by size and check the tip: teeth (Kocher), right angle (Mixter) or serrations on half the jaw (Kelly).',
    ),
    [
      LookalikeMember('pinza-mosquito', LocalizedText(
        ca: 'La més petita, de puntes fines i estries a tota la mossegada: vasos petits.',
        es: 'La más pequeña, de puntas finas y estrías en toda la mordida: vasos pequeños.',
        en: 'The smallest, with fine tips and fully serrated jaws: small vessels.',
      )),
      LookalikeMember('pinza-kelly', LocalizedText(
        ca: 'Mida mitjana; la Kelly clàssica només té estries a la meitat distal de la mossegada.',
        es: 'Tamaño mediano; la Kelly clásica solo tiene estrías en la mitad distal de la mordida.',
        en: 'Medium size; the classic Kelly is serrated only on the distal half of the jaw.',
      )),
      LookalikeMember('pinza-rochester-pean', LocalizedText(
        ca: 'Gran i robusta, estries a tota la mossegada i sense dents: pedicles i teixit gruixut.',
        es: 'Grande y robusta, estrías en toda la mordida y sin dientes: pedículos y tejido grueso.',
        en: 'Large and strong, fully serrated jaw without teeth: pedicles and thick tissue.',
      )),
      LookalikeMember('pinza-kocher', LocalizedText(
        ca: 'Com una Pean, però amb dents 1x2 a la punta: teixit fibrós, no vasos delicats.',
        es: 'Como una Pean, pero con dientes 1x2 en la punta: tejido fibroso, no vasos delicados.',
        en: 'Like a Pean, but with 1x2 teeth at the tip: fibrous tissue, not delicate vessels.',
      )),
      LookalikeMember('pinza-mixter', LocalizedText(
        ca: 'Punta en angle recte: passar lligadures per darrere de vasos i conductes.',
        es: 'Punta en ángulo recto: pasar ligaduras por detrás de vasos y conductos.',
        en: 'Right-angled tip: passing ties behind vessels and ducts.',
      )),
    ],
  ),
  LookalikeFamily(
    'prensio',
    LocalizedText(ca: 'Pinces de prensió', es: 'Pinzas de prensión', en: 'Tissue graspers'),
    LocalizedText(
      ca: 'Dents a la punta vol dir que el teixit es pot fer malbé; una finestra arrodonida, que és atraumàtica.',
      es: 'Dientes en la punta significa que el tejido se puede dañar; una ventana redondeada, que es atraumática.',
      en: 'Teeth at the tip mean the tissue may be damaged; a rounded window means atraumatic.',
    ),
    [
      LookalikeMember('pinza-allis', LocalizedText(
        ca: 'Punta amb petites dents entrecreuades: agafada ferma, per a teixit que es resecarà.',
        es: 'Punta con pequeños dientes entrecruzados: agarre firme, para tejido que se va a resecar.',
        en: 'Tip with small interlocking teeth: firm grip, for tissue that will be removed.',
      )),
      LookalikeMember('pinza-babcock', LocalizedText(
        ca: 'Punta arrodonida i fenestrada, sense dents: atraumàtica, per a budell i trompes.',
        es: 'Punta redondeada y fenestrada, sin dientes: atraumática, para intestino y trompas.',
        en: 'Rounded, fenestrated tip without teeth: atraumatic, for bowel and tubes.',
      )),
      LookalikeMember('pinza-duval', LocalizedText(
        ca: 'Punta triangular, ampla i fenestrada: agafar el pulmó en cirurgia toràcica.',
        es: 'Punta triangular, ancha y fenestrada: sujetar el pulmón en cirugía torácica.',
        en: 'Wide, triangular, fenestrated tip: holding lung tissue in thoracic surgery.',
      )),
      LookalikeMember('pinza-foerster', LocalizedText(
        ca: "Anelles ovalades a la punta: muntar una gasa o agafar el coll uterí.",
        es: 'Anillas ovaladas en la punta: montar una gasa o sujetar el cuello uterino.',
        en: 'Oval rings at the tip: holding a swab or grasping the cervix.',
      )),
    ],
  ),
  LookalikeFamily(
    'portaagulles',
    LocalizedText(ca: 'Portaagulles', es: 'Portaagujas', en: 'Needle holders'),
    LocalizedText(
      ca: "Anelles o no, i la mida. I no el confonguis amb una hemostàtica: el portaagulles té la mossegada molt més curta i ampla.",
      es: 'Anillas o no, y el tamaño. Y no lo confundas con una hemostática: el portaagujas tiene la mordida mucho más corta y ancha.',
      en: 'Rings or not, and size. And don’t mistake it for a haemostat: a needle holder has a much shorter, wider jaw.',
    ),
    [
      LookalikeMember('portaagujas-mayo-hegar', LocalizedText(
        ca: 'Anelles i cremallera, mossegada curta amb estries en creu: el portaagulles general.',
        es: 'Anillas y cremallera, mordida corta con estrías en cruz: el portaagujas general.',
        en: 'Finger rings and ratchet, short cross-hatched jaw: the general needle holder.',
      )),
      LookalikeMember('portaagujas-mathieu', LocalizedText(
        ca: 'Sense anelles: mànecs corbats amb molla i el tancament al final del mànec.',
        es: 'Sin anillas: mangos curvados con muelle y el cierre al final del mango.',
        en: 'No finger rings: curved spring handles with the lock at the end.',
      )),
      LookalikeMember('portaagujas-castroviejo', LocalizedText(
        ca: 'Petit, de molla i mànecs plans: microcirurgia i oftalmologia.',
        es: 'Pequeño, de muelle y mangos planos: microcirugía y oftalmología.',
        en: 'Small, spring-loaded with flat handles: microsurgery and ophthalmology.',
      )),
    ],
  ),
  LookalikeFamily(
    'separadors-manuals',
    LocalizedText(ca: 'Separadors manuals', es: 'Separadores manuales', en: 'Hand-held retractors'),
    LocalizedText(
      ca: 'Mira la mida de la pala i com està corbada: com més profund és el pla, més llarga i corbada.',
      es: 'Mira el tamaño de la pala y cómo está curvada: cuanto más profundo es el plano, más larga y curvada.',
      en: 'Check the size and curve of the blade: the deeper the layer, the longer and more curved.',
    ),
    [
      LookalikeMember('separador-farabeuf', LocalizedText(
        ca: 'Placa en forma de C i de dos extrems: plans superficials.',
        es: 'Placa en forma de C y de dos extremos: planos superficiales.',
        en: 'C-shaped, double-ended plate: superficial layers.',
      )),
      LookalikeMember('separador-langenbeck', LocalizedText(
        ca: 'Una sola pala en angle recte amb mànec llarg: plans superficials i mitjans.',
        es: 'Una sola pala en ángulo recto con mango largo: planos superficiales y medios.',
        en: 'A single right-angled blade on a long handle: superficial and middle layers.',
      )),
      LookalikeMember('separador-richardson', LocalizedText(
        ca: 'Pala gran en angle recte i mànec ample: paret abdominal.',
        es: 'Pala grande en ángulo recto y mango ancho: pared abdominal.',
        en: 'Large right-angled blade with a broad handle: abdominal wall.',
      )),
      LookalikeMember('separador-deaver', LocalizedText(
        ca: "Fulla llarga corbada com un signe d'interrogació: abdomen profund.",
        es: 'Hoja larga curvada como un signo de interrogación: abdomen profundo.',
        en: 'Long blade curved like a question mark: deep abdomen.',
      )),
      LookalikeMember('separador-maleable', LocalizedText(
        ca: 'Làmina plana que es doblega a mà amb la forma que calgui.',
        es: 'Lámina plana que se dobla a mano con la forma que haga falta.',
        en: 'A flat strip that is bent by hand into whatever shape is needed.',
      )),
    ],
  ),
  LookalikeFamily(
    'separadors-autoestatics',
    LocalizedText(ca: 'Separadors autoestàtics', es: 'Separadores autoestáticos', en: 'Self-retaining retractors'),
    LocalizedText(
      ca: 'Rasclets (Weitlaner), una sola punta (Gelpi), marc abdominal (Balfour) o manovella toràcica (Finochietto).',
      es: 'Rastrillos (Weitlaner), una sola punta (Gelpi), marco abdominal (Balfour) o manivela torácica (Finochietto).',
      en: 'Rakes (Weitlaner), a single point (Gelpi), an abdominal frame (Balfour) or a thoracic crank (Finochietto).',
    ),
    [
      LookalikeMember('separador-weitlaner', LocalizedText(
        ca: 'Dues branques amb diverses puntes en rasclet i cremallera.',
        es: 'Dos ramas con varias puntas en rastrillo y cremallera.',
        en: 'Two arms with several rake-like prongs and a ratchet.',
      )),
      LookalikeMember('separador-gelpi', LocalizedText(
        ca: 'Una sola punta esmolada a cada branca: incisions petites i profundes.',
        es: 'Una sola punta afilada en cada rama: incisiones pequeñas y profundas.',
        en: 'A single sharp point on each arm: small, deep incisions.',
      )),
      LookalikeMember('separador-balfour', LocalizedText(
        ca: 'Marc amb dues valves laterals i una central: manté oberta la laparotomia.',
        es: 'Marco con dos valvas laterales y una central: mantiene abierta la laparotomía.',
        en: 'A frame with two side blades and a central one: holds the laparotomy open.',
      )),
      LookalikeMember('separador-finochietto', LocalizedText(
        ca: "Cremallera de manovella amb valves: obre l'espai entre costelles o l'estèrnum.",
        es: 'Cremallera de manivela con valvas: abre el espacio entre costillas o el esternón.',
        en: 'Crank-driven rack with blades: spreads the ribs or the sternum.',
      )),
    ],
  ),
  LookalikeFamily(
    'aspiracio',
    LocalizedText(ca: "Cànules d'aspiració", es: 'Cánulas de aspiración', en: 'Suction tips'),
    LocalizedText(
      ca: 'Mira la punta i si té un forat per regular la succió amb el dit.',
      es: 'Mira la punta y si tiene un orificio para regular la succión con el dedo.',
      en: 'Look at the tip and whether it has a hole to control suction with a finger.',
    ),
    [
      LookalikeMember('canula-yankauer', LocalizedText(
        ca: 'Rígida i corbada, amb punta de bulb: camp obert i boca.',
        es: 'Rígida y curvada, con punta de bulbo: campo abierto y boca.',
        en: 'Rigid and curved, with a bulb tip: open field and mouth.',
      )),
      LookalikeMember('canula-frazier', LocalizedText(
        ca: 'Fina i angulada, amb un forat al mànec per regular la succió: neurocirurgia i ORL.',
        es: 'Fina y angulada, con un orificio en el mango para regular la succión: neurocirugía y ORL.',
        en: 'Fine and angled, with a thumb hole to control suction: neurosurgery and ENT.',
      )),
      LookalikeMember('canula-poole', LocalizedText(
        ca: "Funda multiperforada: aspirar molt líquid a l'abdomen sense enganxar teixit.",
        es: 'Funda multiperforada: aspirar mucho líquido en el abdomen sin enganchar tejido.',
        en: 'Multi-perforated sleeve: suctioning large volumes in the abdomen without catching tissue.',
      )),
    ],
  ),
];

/// Famílies a les quals pertany un instrument.
List<LookalikeFamily> lookalikeFamiliesOf(String instrumentId) =>
    [for (final f in kLookalikeFamilies) if (f.members.any((m) => m.instrumentId == instrumentId)) f];

/// Pista visual d'un instrument dins de la seva família, o null.
LocalizedText? lookalikeClueOf(String instrumentId) {
  for (final f in kLookalikeFamilies) {
    for (final m in f.members) {
      if (m.instrumentId == instrumentId) return m.clue;
    }
  }
  return null;
}
