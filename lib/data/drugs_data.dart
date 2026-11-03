import '../models/drug.dart';
import '../models/instrument.dart' show LocalizedText;

const List<Drug> kDrugs = [
  // Inductores anestésicos
  Drug(
    id: 'propofol',
    name: LocalizedText(ca: 'Propofol', es: 'Propofol', en: 'Propofol'),
    aliases: ['Diprivan'],
    drugClass: DrugClass.inductor,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Agent hipnòtic intravenós d\'inici d\'acció ràpid i durada curta, amb un cert efecte antiemètic.',
      es: 'Agente hipnótico intravenoso de inicio de acción rápido y duración corta, con cierto efecto antiemético.',
      en: 'Intravenous hypnotic agent with a rapid onset and short duration, with some antiemetic effect.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a la inducció i el manteniment de l\'anestèsia general, i també per a la sedació.',
      es: 'Se emplea en la inducción y el mantenimiento de la anestesia general, y también para la sedación.',
      en: 'Used for induction and maintenance of general anesthesia, and for sedation.',
    ),
    tip: LocalizedText(
      ca: 'Provoca dolor freqüent al punt d\'injecció.',
      es: 'Causa dolor frecuente en el punto de inyección.',
      en: 'Frequently causes pain at the injection site.',
    ),
  ),
  Drug(
    id: 'etomidato',
    name: LocalizedText(ca: 'Etomidat', es: 'Etomidato', en: 'Etomidate'),
    aliases: ['Hypnomidate'],
    drugClass: DrugClass.inductor,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Agent hipnòtic intravenós d\'inducció, amb bona estabilitat hemodinàmica.',
      es: 'Agente hipnótico intravenoso de inducción, con buena estabilidad hemodinámica.',
      en: 'Intravenous induction hypnotic agent with good hemodynamic stability.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza sovint per a la inducció anestèsica en pacients amb inestabilitat cardiovascular.',
      es: 'Se usa a menudo para la inducción anestésica en pacientes con inestabilidad cardiovascular.',
      en: 'Often used for anesthetic induction in patients with cardiovascular instability.',
    ),
    tip: LocalizedText(
      ca: 'L\'ús repetit o perllongat s\'associa a supressió de la producció de cortisol suprarenal.',
      es: 'Su uso repetido o prolongado se asocia a supresión de la producción de cortisol suprarrenal.',
      en: 'Repeated or prolonged use is associated with suppression of adrenal cortisol production.',
    ),
  ),
  Drug(
    id: 'ketamina',
    name: LocalizedText(ca: 'Ketamina', es: 'Ketamina', en: 'Ketamine'),
    aliases: ['Ketolar'],
    drugClass: DrugClass.inductor,
    routes: ['IV', 'IM'],
    description: LocalizedText(
      ca: 'Anestèsic dissociatiu amb propietats analgèsiques, que preserva millor els reflexos de la via aèria i l\'estabilitat hemodinàmica que altres agents inductors.',
      es: 'Anestésico disociativo con propiedades analgésicas, que preserva mejor los reflejos de la vía aérea y la estabilidad hemodinámica que otros agentes inductores.',
      en: 'Dissociative anesthetic with analgesic properties, which preserves airway reflexes and hemodynamic stability better than other induction agents.',
    ),
    use: LocalizedText(
      ca: 'Resulta útil en situacions de trauma o xoc.',
      es: 'Resulta útil en situaciones de trauma o shock.',
      en: 'Useful in trauma or shock situations.',
    ),
    tip: LocalizedText(
      ca: 'Pot produir reaccions d\'emergència, com al·lucinacions o agitació, en despertar.',
      es: 'Puede producir reacciones de emergencia, como alucinaciones o agitación, al despertar.',
      en: 'May cause emergence reactions, such as hallucinations or agitation, on waking.',
    ),
  ),

  // Relajantes neuromusculares
  Drug(
    id: 'rocuronio',
    name: LocalizedText(ca: 'Rocuroni', es: 'Rocuronio', en: 'Rocuronium'),
    aliases: ['Esmeron'],
    drugClass: DrugClass.relajanteNeuromuscular,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Bloquejant neuromuscular no despolaritzant de durada intermèdia.',
      es: 'Bloqueante neuromuscular no despolarizante de duración intermedia.',
      en: 'Non-depolarizing neuromuscular blocking agent of intermediate duration.',
    ),
    use: LocalizedText(
      ca: 'A dosis més altes té un inici d\'acció ràpid, per la qual cosa s\'utilitza en la inducció de seqüència ràpida.',
      es: 'A dosis más altas tiene un inicio de acción rápido, por lo que se usa en la inducción de secuencia rápida.',
      en: 'At higher doses it has a rapid onset of action, so it is used for rapid sequence induction.',
    ),
    tip: LocalizedText(
      ca: 'És l\'únic bloquejant neuromuscular revertit específicament per sugammadex.',
      es: 'Es el único bloqueante neuromuscular revertido específicamente por sugammadex.',
      en: 'It is the only neuromuscular blocker specifically reversed by sugammadex.',
    ),
  ),
  Drug(
    id: 'cisatracurio',
    name: LocalizedText(ca: 'Cisatracuri', es: 'Cisatracurio', en: 'Cisatracurium'),
    aliases: ['Nimbex'],
    drugClass: DrugClass.relajanteNeuromuscular,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Bloquejant neuromuscular no despolaritzant de durada intermèdia, que s\'elimina per degradació de Hofmann, un procés químic independent de la funció renal o hepàtica.',
      es: 'Bloqueante neuromuscular no despolarizante de duración intermedia, que se elimina por degradación de Hofmann, un proceso químico independiente de la función renal o hepática.',
      en: 'Non-depolarizing neuromuscular blocking agent of intermediate duration, eliminated by Hofmann degradation, a chemical process independent of renal or hepatic function.',
    ),
    use: LocalizedText(
      ca: 'Resulta útil en pacients amb insuficiència renal o hepàtica.',
      es: 'Resulta útil en pacientes con insuficiencia renal o hepática.',
      en: 'Useful in patients with renal or hepatic impairment.',
    ),
  ),
  Drug(
    id: 'succinilcolina',
    name: LocalizedText(ca: 'Succinilcolina', es: 'Succinilcolina', en: 'Succinylcholine'),
    aliases: ['Anectine', 'Succinilcolina'],
    drugClass: DrugClass.relajanteNeuromuscular,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Únic bloquejant neuromuscular despolaritzant d\'ús habitual, amb un inici d\'acció molt ràpid i una durada molt curta.',
      es: 'Único bloqueante neuromuscular despolarizante de uso habitual, con un inicio de acción muy rápido y una duración muy corta.',
      en: 'The only depolarizing neuromuscular blocker in common use, with a very rapid onset and very short duration.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en la inducció de seqüència ràpida quan es preveu una via aèria difícil d\'assegurar amb rapidesa.',
      es: 'Se usa en la inducción de secuencia rápida cuando se prevé una vía aérea difícil de asegurar con rapidez.',
      en: 'Used for rapid sequence induction when a difficult airway is anticipated and needs to be secured quickly.',
    ),
    tip: LocalizedText(
      ca: 'S\'associa a risc d\'hiperpotassèmia i és un desencadenant conegut d\'hipertèrmia maligna.',
      es: 'Se asocia a riesgo de hiperpotasemia y es un desencadenante conocido de hipertermia maligna.',
      en: 'Associated with a risk of hyperkalemia and is a known trigger of malignant hyperthermia.',
    ),
  ),

  // Opioides / analgésicos
  Drug(
    id: 'fentanilo',
    name: LocalizedText(ca: 'Fentanil', es: 'Fentanilo', en: 'Fentanyl'),
    aliases: ['Fentanest'],
    drugClass: DrugClass.opioide,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Opioide sintètic molt potent, d\'inici ràpid i durada curta-intermèdia.',
      es: 'Opioide sintético muy potente, de inicio rápido y duración corta-intermedia.',
      en: 'Very potent synthetic opioid, with rapid onset and short-to-intermediate duration.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza com a analgèsic i com a coadjuvant en la inducció i el manteniment de l\'anestèsia general.',
      es: 'Se usa como analgésico y como coadyuvante en la inducción y el mantenimiento de la anestesia general.',
      en: 'Used as an analgesic and as an adjuvant for induction and maintenance of general anesthesia.',
    ),
  ),
  Drug(
    id: 'remifentanilo',
    name: LocalizedText(ca: 'Remifentanil', es: 'Remifentanilo', en: 'Remifentanil'),
    aliases: ['Ultiva'],
    drugClass: DrugClass.opioide,
    routes: ['IV', 'continuous infusion'],
    description: LocalizedText(
      ca: 'Opioide d\'acció ultracurta, metabolitzat per esterases plasmàtiques, un procés independent de la funció renal o hepàtica.',
      es: 'Opioide de acción ultracorta, metabolizado por esterasas plasmáticas, un proceso independiente de la función renal o hepática.',
      en: 'Ultra-short-acting opioid, metabolized by plasma esterases, a process independent of renal or hepatic function.',
    ),
    use: LocalizedText(
      ca: 'S\'administra en infusió contínua durant l\'anestèsia.',
      es: 'Se administra en infusión continua durante la anestesia.',
      en: 'Administered as a continuous infusion during anesthesia.',
    ),
    tip: LocalizedText(
      ca: 'El seu efecte desapareix molt ràpid en suspendre\'l.',
      es: 'Su efecto desaparece muy rápido al suspenderlo.',
      en: 'Its effect wears off very quickly once stopped.',
    ),
  ),
  Drug(
    id: 'morfina',
    name: LocalizedText(ca: 'Morfina', es: 'Morfina', en: 'Morphine'),
    drugClass: DrugClass.opioide,
    routes: ['IV', 'IM', 'subcutaneous'],
    description: LocalizedText(
      ca: 'Opioide de referència per al tractament del dolor, de durada més perllongada que el fentanil.',
      es: 'Opioide de referencia para el tratamiento del dolor, de duración más prolongada que el fentanilo.',
      en: 'Reference opioid for pain management, with a longer duration than fentanyl.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza sobretot per a l\'analgèsia postoperatòria.',
      es: 'Se usa sobre todo para la analgesia postoperatoria.',
      en: 'Used mainly for postoperative analgesia.',
    ),
  ),

  // Anestésicos locales
  Drug(
    id: 'lidocaina',
    name: LocalizedText(ca: 'Lidocaïna', es: 'Lidocaína', en: 'Lidocaine'),
    aliases: ['Xylocaína'],
    drugClass: DrugClass.anestesicoLocal,
    routes: ['local infiltration', 'epidural', 'topical', 'IV'],
    description: LocalizedText(
      ca: 'Anestèsic local de tipus amida, d\'inici ràpid i durada intermèdia.',
      es: 'Anestésico local de tipo amida, de inicio rápido y duración intermedia.',
      en: 'Amide-type local anesthetic, with rapid onset and intermediate duration.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a anestèsia local i regional; també s\'empra com a antiarítmic en altres contextos.',
      es: 'Se usa para anestesia local y regional; también se emplea como antiarrítmico en otros contextos.',
      en: 'Used for local and regional anesthesia; also used as an antiarrhythmic in other contexts.',
    ),
  ),
  Drug(
    id: 'bupivacaina',
    name: LocalizedText(ca: 'Bupivacaïna', es: 'Bupivacaína', en: 'Bupivacaine'),
    aliases: ['Marcaine'],
    drugClass: DrugClass.anestesicoLocal,
    routes: ['local infiltration', 'epidural', 'nerve block'],
    description: LocalizedText(
      ca: 'Anestèsic local de tipus amida de llarga durada.',
      es: 'Anestésico local de tipo amida de larga duración.',
      en: 'Long-acting amide-type local anesthetic.',
    ),
    use: LocalizedText(
      ca: 'Molt utilitzat en bloquejos regionals i epidurals.',
      es: 'Muy usado en bloqueos regionales y epidurales.',
      en: 'Widely used in regional and epidural blocks.',
    ),
    tip: LocalizedText(
      ca: 'Té més risc de toxicitat cardíaca que altres anestèsics locals si s\'administra per error al torrent sanguini.',
      es: 'Tiene mayor riesgo de toxicidad cardíaca que otros anestésicos locales si se administra por error en el torrente sanguíneo.',
      en: 'Carries a higher risk of cardiac toxicity than other local anesthetics if accidentally administered into the bloodstream.',
    ),
  ),
  Drug(
    id: 'ropivacaina',
    name: LocalizedText(ca: 'Ropivacaïna', es: 'Ropivacaína', en: 'Ropivacaine'),
    aliases: ['Naropin'],
    drugClass: DrugClass.anestesicoLocal,
    routes: ['epidural', 'nerve block'],
    description: LocalizedText(
      ca: 'Anestèsic local de tipus amida, similar a la bupivacaïna en durada però amb un perfil de menys toxicitat cardíaca.',
      es: 'Anestésico local de tipo amida, similar a la bupivacaína en duración pero con un perfil de menor toxicidad cardíaca.',
      en: 'Amide-type local anesthetic, similar to bupivacaine in duration but with a lower cardiac toxicity profile.',
    ),
    use: LocalizedText(
      ca: 'Molt utilitzat en analgèsia regional postoperatòria.',
      es: 'Muy usado en analgesia regional postoperatoria.',
      en: 'Widely used for postoperative regional analgesia.',
    ),
  ),

  // Agentes de reversión
  Drug(
    id: 'sugammadex',
    name: LocalizedText(ca: 'Sugammadex', es: 'Sugammadex', en: 'Sugammadex'),
    aliases: ['Bridion'],
    drugClass: DrugClass.agenteReversion,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Agent de reversió que actua encapsulant selectivament la molècula del bloquejant neuromuscular.',
      es: 'Agente de reversión que actúa encapsulando selectivamente la molécula del bloqueante neuromuscular.',
      en: 'Reversal agent that works by selectively encapsulating the neuromuscular blocker molecule.',
    ),
    use: LocalizedText(
      ca: 'Reverteix específicament el rocuroni i el vecuroni.',
      es: 'Revierte específicamente el rocuronio y el vecuronio.',
      en: 'Specifically reverses rocuronium and vecuronium.',
    ),
    tip: LocalizedText(
      ca: 'No actua sobre bloquejants neuromusculars despolaritzants com la succinilcolina.',
      es: 'No actúa sobre bloqueantes neuromusculares despolarizantes como la succinilcolina.',
      en: 'Does not act on depolarizing neuromuscular blockers such as succinylcholine.',
    ),
  ),
  Drug(
    id: 'neostigmina',
    name: LocalizedText(ca: 'Neostigmina', es: 'Neostigmina', en: 'Neostigmine'),
    drugClass: DrugClass.agenteReversion,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Inhibidor de l\'acetilcolinesterasa que reverteix de forma indirecta el bloqueig neuromuscular no despolaritzant.',
      es: 'Inhibidor de la acetilcolinesterasa que revierte de forma indirecta el bloqueo neuromuscular no despolarizante.',
      en: 'Acetylcholinesterase inhibitor that indirectly reverses non-depolarizing neuromuscular block.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per revertir el bloqueig neuromuscular no despolaritzant al final de l\'anestèsia.',
      es: 'Se usa para revertir el bloqueo neuromuscular no despolarizante al final de la anestesia.',
      en: 'Used to reverse non-depolarizing neuromuscular blockade at the end of anesthesia.',
    ),
    tip: LocalizedText(
      ca: 'S\'administra habitualment juntament amb un antimuscarínic, com atropina o glicopirroni, per contrarestar els seus efectes colinèrgics secundaris.',
      es: 'Se administra habitualmente junto con un antimuscarínico, como atropina o glicopirronio, para contrarrestar sus efectos colinérgicos secundarios.',
      en: 'Usually given together with an antimuscarinic, such as atropine or glycopyrronium, to counteract its secondary cholinergic effects.',
    ),
  ),
  Drug(
    id: 'naloxona',
    name: LocalizedText(ca: 'Naloxona', es: 'Naloxona', en: 'Naloxone'),
    aliases: ['Narcan'],
    drugClass: DrugClass.agenteReversion,
    routes: ['IV', 'IM', 'intranasal'],
    description: LocalizedText(
      ca: 'Antagonista opioide que reverteix la depressió respiratòria induïda per opioides.',
      es: 'Antagonista opioide que revierte la depresión respiratoria inducida por opioides.',
      en: 'Opioid antagonist that reverses opioid-induced respiratory depression.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per revertir la depressió respiratòria causada per opioides.',
      es: 'Se usa para revertir la depresión respiratoria causada por opioides.',
      en: 'Used to reverse respiratory depression caused by opioids.',
    ),
    tip: LocalizedText(
      ca: 'La seva durada d\'acció és més curta que la de molts opioides, per la qual cosa hi ha risc que l\'efecte de l\'opioide reaparegui un cop passa l\'efecte de la naloxona.',
      es: 'Su duración de acción es más corta que la de muchos opioides, por lo que existe riesgo de que el efecto del opioide reaparezca una vez pasa el efecto de la naloxona.',
      en: 'Its duration of action is shorter than that of many opioids, so the opioid\'s effect can reappear once naloxone\'s effect wears off.',
    ),
  ),

  // Vasopresores / inotrópicos
  Drug(
    id: 'efedrina',
    name: LocalizedText(ca: 'Efedrina', es: 'Efedrina', en: 'Ephedrine'),
    drugClass: DrugClass.vasopresor,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Simpaticomimètic d\'acció indirecta, amb efecte vasopressor i un cert efecte inotròpic que augmenta la força de contracció cardíaca.',
      es: 'Simpaticomimético de acción indirecta, con efecto vasopresor y un cierto efecto inotrópico que aumenta la fuerza de contracción cardíaca.',
      en: 'Indirect-acting sympathomimetic, with a vasopressor effect and some inotropic effect that increases the force of cardiac contraction.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per tractar la hipotensió associada a l\'anestèsia.',
      es: 'Se usa para tratar la hipotensión asociada a la anestesia.',
      en: 'Used to treat hypotension associated with anesthesia.',
    ),
  ),
  Drug(
    id: 'fenilefrina',
    name: LocalizedText(ca: 'Fenilefrina', es: 'Fenilefrina', en: 'Phenylephrine'),
    drugClass: DrugClass.vasopresor,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Agonista alfa-1 d\'acció directa, vasopressor pur sense efecte inotròpic rellevant.',
      es: 'Agonista alfa-1 de acción directa, vasopresor puro sin efecto inotrópico relevante.',
      en: 'Direct-acting alpha-1 agonist, a pure vasopressor without a relevant inotropic effect.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per tractar la hipotensió, especialment quan interessa evitar un augment reflex de la freqüència cardíaca, o quan es tolera bé una freqüència cardíaca més baixa.',
      es: 'Se usa para tratar la hipotensión, especialmente cuando interesa evitar un aumento reflejo de la frecuencia cardíaca, o cuando se tolera bien una frecuencia cardíaca más baja.',
      en: 'Used to treat hypotension, particularly when avoiding a reflex increase in heart rate matters, or when a lower heart rate is well tolerated.',
    ),
  ),
  Drug(
    id: 'noradrenalina',
    name: LocalizedText(ca: 'Noradrenalina', es: 'Noradrenalina', en: 'Norepinephrine'),
    aliases: ['Norepinefrina'],
    drugClass: DrugClass.vasopresor,
    routes: ['IV', 'continuous infusion'],
    description: LocalizedText(
      ca: 'Vasopressor i inotròpic potent.',
      es: 'Vasopresor e inotrópico potente.',
      en: 'Potent vasopressor and inotrope.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en la hipotensió greu o el xoc.',
      es: 'Se usa en la hipotensión grave o el shock.',
      en: 'Used in severe hypotension or shock.',
    ),
    tip: LocalizedText(
      ca: 'S\'administra habitualment en infusió contínua amb monitorització hemodinàmica estreta.',
      es: 'Se administra habitualmente en infusión continua con monitorización hemodinámica estrecha.',
      en: 'Usually given as a continuous infusion with close hemodynamic monitoring.',
    ),
  ),

  // Antieméticos
  Drug(
    id: 'ondansetron',
    name: LocalizedText(ca: 'Ondansetron', es: 'Ondansetrón', en: 'Ondansetron'),
    aliases: ['Zofran'],
    drugClass: DrugClass.antiemetico,
    routes: ['IV', 'oral'],
    description: LocalizedText(
      ca: 'Antagonista dels receptors 5-HT3.',
      es: 'Antagonista de los receptores 5-HT3.',
      en: '5-HT3 receptor antagonist.',
    ),
    use: LocalizedText(
      ca: 'És de primera línia per a la prevenció i el tractament de les nàusees i els vòmits postoperatoris.',
      es: 'Es de primera línea para la prevención y el tratamiento de las náuseas y vómitos postoperatorios.',
      en: 'First-line agent for the prevention and treatment of postoperative nausea and vomiting.',
    ),
  ),
  Drug(
    id: 'droperidol',
    name: LocalizedText(ca: 'Droperidol', es: 'Droperidol', en: 'Droperidol'),
    drugClass: DrugClass.antiemetico,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Antagonista dopaminèrgic amb efecte antiemètic.',
      es: 'Antagonista dopaminérgico con efecto antiemético.',
      en: 'Dopamine antagonist with an antiemetic effect.',
    ),
    use: LocalizedText(
      ca: 'S\'ha utilitzat històricament per a les nàusees i els vòmits postoperatoris.',
      es: 'Se ha usado históricamente para las náuseas y vómitos postoperatorios.',
      en: 'Historically used for postoperative nausea and vomiting.',
    ),
    tip: LocalizedText(
      ca: 'La seva fitxa tècnica inclou una advertència sobre prolongació de l\'interval QT.',
      es: 'Su ficha técnica incluye una advertencia sobre prolongación del intervalo QT.',
      en: 'Its product label carries a warning about QT interval prolongation.',
    ),
  ),

  // Sedantes
  Drug(
    id: 'midazolam',
    name: LocalizedText(ca: 'Midazolam', es: 'Midazolam', en: 'Midazolam'),
    aliases: ['Dormicum'],
    drugClass: DrugClass.sedante,
    routes: ['IV', 'IM', 'oral', 'intranasal'],
    description: LocalizedText(
      ca: 'Benzodiazepina de durada curta-intermèdia.',
      es: 'Benzodiacepina de duración corta-intermedia.',
      en: 'Short-to-intermediate-acting benzodiazepine.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a la premedicació, la sedació i per produir amnèsia.',
      es: 'Se usa para premedicación, sedación y para producir amnesia.',
      en: 'Used for premedication, sedation, and to produce amnesia.',
    ),
    tip: LocalizedText(
      ca: 'El seu efecte es pot revertir amb flumazenil.',
      es: 'Su efecto puede revertirse con flumazenilo.',
      en: 'Its effect can be reversed with flumazenil.',
    ),
  ),
  Drug(
    id: 'dexmedetomidina',
    name: LocalizedText(ca: 'Dexmedetomidina', es: 'Dexmedetomidina', en: 'Dexmedetomidine'),
    aliases: ['Precedex'],
    drugClass: DrugClass.sedante,
    routes: ['IV', 'continuous infusion'],
    description: LocalizedText(
      ca: 'Agonista alfa-2 utilitzat per a la sedació, amb menys depressió respiratòria que altres sedants.',
      es: 'Agonista alfa-2 usado para la sedación, con menor depresión respiratoria que otros sedantes.',
      en: 'Alpha-2 agonist used for sedation, with less respiratory depression than other sedatives.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en la sedació per a procediments, a cures intensives i com a coadjuvant de l\'anestèsia.',
      es: 'Se usa en la sedación para procedimientos, en cuidados intensivos y como coadyuvante de la anestesia.',
      en: 'Used for procedural sedation, in intensive care, and as an anesthesia adjuvant.',
    ),
  ),
];
