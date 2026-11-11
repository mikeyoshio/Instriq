import '../models/drug.dart';
import '../models/instrument.dart' show InstrumentImage, LocalizedText;

const List<Drug> kDrugs = [
  // Inductores anestésicos
  Drug(
    id: 'propofol',
    name: LocalizedText(ca: 'Propofol', es: 'Propofol', en: 'Propofol'),
    aliases: ['Diprivan', 'Propofol Lipuro'],
    drugClass: DrugClass.inductor,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Agent hipnòtic intravenós d\'inici d\'acció ràpid i durada curta, amb un cert efecte antiemètic; actua principalment potenciant la neurotransmissió gabaèrgica als receptors GABA-A.',
      es: 'Agente hipnótico intravenoso de inicio de acción rápido y duración corta, con cierto efecto antiemético; actúa principalmente potenciando la neurotransmisión gabaérgica en los receptores GABA-A.',
      en: 'Intravenous hypnotic agent with a rapid onset and short duration, with some antiemetic effect; it works mainly by enhancing GABAergic neurotransmission at GABA-A receptors.',
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
    image: InstrumentImage(
      url: 'https://upload.wikimedia.org/wikipedia/commons/6/6d/Propofol.jpg',
      license: 'Public domain',
      attribution: 'Erich Schulz, Wikimedia Commons',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Propofol.jpg',
    ),
  ),
  Drug(
    id: 'etomidato',
    name: LocalizedText(ca: 'Etomidat', es: 'Etomidato', en: 'Etomidate'),
    aliases: ['Hypnomidate', 'Etomidato-Lipuro'],
    drugClass: DrugClass.inductor,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Agent hipnòtic intravenós d\'inducció, amb bona estabilitat hemodinàmica; és un derivat imidazòlic, estructuralment diferent d\'altres hipnòtics com els barbitúrics o el propofol.',
      es: 'Agente hipnótico intravenoso de inducción, con buena estabilidad hemodinámica; es un derivado imidazólico, estructuralmente distinto de otros hipnóticos como los barbitúricos o el propofol.',
      en: 'Intravenous induction hypnotic agent with good hemodynamic stability; it is an imidazole derivative, structurally distinct from other hypnotics such as barbiturates or propofol.',
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
    image: InstrumentImage(
      url: 'https://upload.wikimedia.org/wikipedia/commons/c/c6/Etomidate_1_%28cropped%29.jpg',
      license: 'CC BY-SA 4.0',
      attribution: 'Mark Oniffrey, Wikimedia Commons',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Etomidate_1_(cropped).jpg',
    ),
  ),
  Drug(
    id: 'ketamina',
    name: LocalizedText(ca: 'Ketamina', es: 'Ketamina', en: 'Ketamine'),
    aliases: ['Ketolar', 'Ketalar'],
    drugClass: DrugClass.inductor,
    routes: ['IV', 'IM'],
    description: LocalizedText(
      ca: 'Anestèsic dissociatiu amb propietats analgèsiques, que preserva millor els reflexos de la via aèria i l\'estabilitat hemodinàmica que altres agents inductors; actua com a antagonista dels receptors NMDA, a diferència de la majoria d\'agents inductors, que actuen sobre receptors GABA-A.',
      es: 'Anestésico disociativo con propiedades analgésicas, que preserva mejor los reflejos de la vía aérea y la estabilidad hemodinámica que otros agentes inductores; actúa como antagonista de los receptores NMDA, a diferencia de la mayoría de agentes inductores, que actúan sobre receptores GABA-A.',
      en: 'Dissociative anesthetic with analgesic properties, which preserves airway reflexes and hemodynamic stability better than other induction agents; it acts as an NMDA receptor antagonist, unlike most induction agents, which act on GABA-A receptors.',
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
      ca: 'Bloquejant neuromuscular no despolaritzant de durada intermèdia; pertany a la família dels bloquejants neuromusculars aminoesteroïdals, a diferència de compostos benzilisoquinolínics com el cisatracuri.',
      es: 'Bloqueante neuromuscular no despolarizante de duración intermedia; pertenece a la familia de los bloqueantes neuromusculares aminoesteroideos, a diferencia de compuestos bencilisoquinolínicos como el cisatracurio.',
      en: 'Non-depolarizing neuromuscular blocking agent of intermediate duration; it belongs to the aminosteroid family of neuromuscular blockers, unlike benzylisoquinolinium compounds such as cisatracurium.',
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
    tip: LocalizedText(
      ca: 'És l\'isòmer cis-cis de l\'atracuri, amb més potència i un alliberament d\'histamina mínim en comparació amb aquest.',
      es: 'Es el isómero cis-cis del atracurio, con mayor potencia y una liberación de histamina mínima en comparación con este.',
      en: 'It is the cis-cis isomer of atracurium, with greater potency and minimal histamine release compared to it.',
    ),
    image: InstrumentImage(
      url: 'https://upload.wikimedia.org/wikipedia/commons/2/24/Ampoule_Cisatracurium.jpg',
      license: 'CC BY-SA 4.0',
      attribution: 'CYP3A42D6, Wikimedia Commons',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Ampoule_Cisatracurium.jpg',
    ),
  ),
  Drug(
    id: 'succinilcolina',
    name: LocalizedText(ca: 'Succinilcolina', es: 'Succinilcolina', en: 'Succinylcholine'),
    aliases: ['Anectine', 'Zennux'],
    drugClass: DrugClass.relajanteNeuromuscular,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Únic bloquejant neuromuscular despolaritzant d\'ús habitual, amb un inici d\'acció molt ràpid i una durada molt curta; actua com a agonista dels receptors nicotínics d\'acetilcolina, produint una despolarització mantinguda de la placa motora, a diferència dels bloquejants no despolaritzants.',
      es: 'Único bloqueante neuromuscular despolarizante de uso habitual, con un inicio de acción muy rápido y una duración muy corta; actúa como agonista de los receptores nicotínicos de acetilcolina, produciendo una despolarización mantenida de la placa motora, a diferencia de los bloqueantes no despolarizantes.',
      en: 'The only depolarizing neuromuscular blocker in common use, with a very rapid onset and very short duration; it acts as a nicotinic acetylcholine receptor agonist, producing a sustained depolarization of the motor end plate, unlike non-depolarizing blockers.',
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
    image: InstrumentImage(
      url: 'https://upload.wikimedia.org/wikipedia/commons/1/15/Succinylcholine_1%28cropped%29.jpg',
      license: 'CC BY-SA 4.0',
      attribution: 'Mark Oniffrey, Wikimedia Commons',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Succinylcholine_1(cropped).jpg',
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
    aliases: ['Morfina B. Braun'],
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
    image: InstrumentImage(
      url: 'https://upload.wikimedia.org/wikipedia/commons/d/d2/Morphin_1%25_vial_on_white_background.jpg',
      license: 'CC BY 4.0',
      attribution: 'Wesalius, Wikimedia Commons',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Morphin_1%25_vial_on_white_background.jpg',
    ),
  ),

  // Anestésicos locales
  Drug(
    id: 'lidocaina',
    name: LocalizedText(ca: 'Lidocaïna', es: 'Lidocaína', en: 'Lidocaine'),
    aliases: ['Xylocaína', 'Xilonibsa'],
    drugClass: DrugClass.anestesicoLocal,
    routes: ['local infiltration', 'epidural', 'topical', 'IV'],
    description: LocalizedText(
      ca: 'Anestèsic local de tipus amida, d\'inici ràpid i durada intermèdia; com la resta d\'anestèsics locals, actua bloquejant els canals de sodi dependents de voltatge de la membrana nerviosa, cosa que impedeix la propagació de l\'impuls elèctric.',
      es: 'Anestésico local de tipo amida, de inicio rápido y duración intermedia; como el resto de anestésicos locales, actúa bloqueando los canales de sodio dependientes de voltaje de la membrana nerviosa, lo que impide la propagación del impulso eléctrico.',
      en: 'Amide-type local anesthetic, with rapid onset and intermediate duration; like other local anesthetics, it works by blocking voltage-gated sodium channels in the nerve membrane, preventing propagation of the electrical impulse.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a anestèsia local i regional; també s\'empra com a antiarítmic en altres contextos.',
      es: 'Se usa para anestesia local y regional; también se emplea como antiarrítmico en otros contextos.',
      en: 'Used for local and regional anesthesia; also used as an antiarrhythmic in other contexts.',
    ),
    image: InstrumentImage(
      url: 'https://commons.wikimedia.org/wiki/Special:FilePath/Lidocaine_ampoule.png',
      license: 'CC BY-SA 4.0',
      attribution: 'Whispyhistory, Wikimedia Commons',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Lidocaine_ampoule.png',
    ),
  ),
  Drug(
    id: 'bupivacaina',
    name: LocalizedText(ca: 'Bupivacaïna', es: 'Bupivacaína', en: 'Bupivacaine'),
    aliases: ['Marcaine', 'Inibsacain'],
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
    image: InstrumentImage(
      url: 'https://commons.wikimedia.org/wiki/Special:FilePath/Bupivacaine_vial.jpg',
      license: 'CC0 1.0',
      attribution: 'Whispyhistory, Wikimedia Commons',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Bupivacaine_vial.jpg',
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
    tip: LocalizedText(
      ca: 'Es va desenvolupar com l\'enantiòmer S (levogir) pur de la molècula, cosa que contribueix a la seva menor toxicitat cardíaca i neurològica respecte a barreges racèmiques com la bupivacaïna.',
      es: 'Se desarrolló como el enantiómero S (levógiro) puro de la molécula, lo que contribuye a su menor toxicidad cardíaca y neurológica frente a mezclas racémicas como la bupivacaína.',
      en: 'It was developed as the pure S-(levorotatory) enantiomer of the molecule, which contributes to its lower cardiac and neurologic toxicity compared to racemic mixtures such as bupivacaine.',
    ),
    image: InstrumentImage(
      url: 'https://commons.wikimedia.org/wiki/Special:FilePath/Ropivacaine_poly.jpg',
      license: 'CC BY-SA 4.0',
      attribution: 'Anesth Earth, Wikimedia Commons',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Ropivacaine_poly.jpg',
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
    aliases: ['Prostigmine'],
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
    aliases: ['Narcan', 'Nyxoid'],
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
    image: InstrumentImage(
      url: 'https://upload.wikimedia.org/wikipedia/commons/0/0e/Naloxone_%281%29.JPG',
      license: 'CC BY 3.0',
      attribution: 'Intropin, Wikimedia Commons',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Naloxone_(1).JPG',
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
    routes: ['IV', 'Oral', 'nasal', 'ophthalmic'],
    description: LocalizedText(
      ca: 'Agonista alfa-1 d\'acció directa, vasopressor pur sense efecte inotròpic rellevant; per via oral i nasal, la vasoconstricció de la mucosa és la base del seu ús com a descongestionant.',
      es: 'Agonista alfa-1 de acción directa, vasopresor puro sin efecto inotrópico relevante; por vía oral y nasal, la vasoconstricción de la mucosa es la base de su uso como descongestionante.',
      en: 'Direct-acting alpha-1 agonist, a pure vasopressor without a relevant inotropic effect; given orally or nasally, mucosal vasoconstriction is the basis of its use as a decongestant.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per tractar la hipotensió, especialment quan interessa evitar un augment reflex de la freqüència cardíaca, o quan es tolera bé una freqüència cardíaca més baixa.',
      es: 'Se usa para tratar la hipotensión, especialmente cuando interesa evitar un aumento reflejo de la frecuencia cardíaca, o cuando se tolera bien una frecuencia cardíaca más baja.',
      en: 'Used to treat hypotension, particularly when avoiding a reflex increase in heart rate matters, or when a lower heart rate is well tolerated.',
    ),
    tip: LocalizedText(
      ca: 'També s\'utilitza per via tòpica com a descongestionant nasal i midriàtic oftalmològic, en presentacions diferents de la intravenosa.',
      es: 'También se emplea por vía tópica como descongestionante nasal y midriático oftalmológico, en presentaciones distintas de la intravenosa.',
      en: 'It is also used topically as a nasal decongestant and ophthalmic mydriatic, in presentations different from the intravenous one.',
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
    image: InstrumentImage(
      url: 'https://commons.wikimedia.org/wiki/Special:FilePath/Norepi.jpg',
      license: 'CC BY-SA 4.0',
      attribution: 'James Heilman, MD, Wikimedia Commons',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Norepi.jpg',
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
    tip: LocalizedText(
      ca: 'Pertany al grup d\'antiemètics coneguts com a "setrons".',
      es: 'Pertenece al grupo de antieméticos conocidos como "setrones".',
      en: 'It belongs to the group of antiemetics known as "setrons".',
    ),
    image: InstrumentImage(
      url: 'https://upload.wikimedia.org/wikipedia/commons/e/e6/Ampolla1213.jpg',
      license: 'CC BY 4.0',
      attribution: 'Daniel.GONZALEZ27, Wikimedia Commons',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Ampolla1213.jpg',
    ),
  ),
  Drug(
    id: 'droperidol',
    name: LocalizedText(ca: 'Droperidol', es: 'Droperidol', en: 'Droperidol'),
    aliases: ['Xomolix'],
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
    image: InstrumentImage(
      url: 'https://commons.wikimedia.org/wiki/Special:FilePath/Midazolam.JPG',
      license: 'CC BY 3.0',
      attribution: 'James Heilman, MD, Wikimedia Commons',
      sourceUrl: 'https://commons.wikimedia.org/wiki/File:Midazolam.JPG',
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
    tip: LocalizedText(
      ca: 'És l\'enantiòmer actiu (S) de la medetomidina, un fàrmac d\'ús veterinari.',
      es: 'Es el enantiómero activo (S) de la medetomidina, un fármaco de uso veterinario.',
      en: 'It is the active (S) enantiomer of medetomidine, a drug used in veterinary medicine.',
    ),
  ),

  // Analgésicos / antiinflamatorios
  Drug(
    id: 'paracetamol',
    name: LocalizedText(ca: 'Paracetamol', es: 'Paracetamol', en: 'Paracetamol (acetaminophen)'),
    aliases: ['Acetaminofén', 'Acetaminophen', 'Apiretal', 'Gelocatil'],
    drugClass: DrugClass.analgesicoAntiinflamatorio,
    routes: ['Oral', 'IV', 'rectal'],
    description: LocalizedText(
      ca: 'Analgèsic i antipirètic d\'ús molt estès, amb un mecanisme d\'acció central encara no del tot aclarit; a diferència dels AINE, pràcticament no té efecte antiinflamatori perifèric.',
      es: 'Analgésico y antipirético de uso muy extendido, con un mecanismo de acción central aún no del todo aclarado; a diferencia de los AINE, prácticamente no tiene efecto antiinflamatorio periférico.',
      en: 'Widely used analgesic and antipyretic with a central mechanism of action that is still not fully understood; unlike NSAIDs, it has virtually no peripheral anti-inflammatory effect.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per al dolor lleu-moderat i la febre, sovint com a base de l\'analgèsia multimodal postoperatòria.',
      es: 'Se usa para el dolor leve-moderado y la fiebre, a menudo como base de la analgesia multimodal postoperatoria.',
      en: 'Used for mild-to-moderate pain and fever, often as the backbone of multimodal postoperative analgesia.',
    ),
    tip: LocalizedText(
      ca: 'La seva toxicitat principal és hepàtica; N-acetilcisteïna n\'és l\'antídot en cas de sobredosi.',
      es: 'Su toxicidad principal es hepática; N-acetilcisteína es su antídoto en caso de sobredosis.',
      en: 'Its main toxicity is hepatic; N-acetylcysteine is the antidote in case of overdose.',
    ),
  ),
  Drug(
    id: 'ibuprofeno',
    name: LocalizedText(ca: 'Ibuprofèn', es: 'Ibuprofeno', en: 'Ibuprofen'),
    aliases: ['Dalsy', 'Espidifen', 'Neobrufen'],
    drugClass: DrugClass.analgesicoAntiinflamatorio,
    routes: ['Oral', 'IV'],
    description: LocalizedText(
      ca: 'Antiinflamatori no esteroïdal (AINE) derivat de l\'àcid propiònic, inhibidor no selectiu de la ciclooxigenasa (COX-1 i COX-2).',
      es: 'Antiinflamatorio no esteroideo (AINE) derivado del ácido propiónico, inhibidor no selectivo de la ciclooxigenasa (COX-1 y COX-2).',
      en: 'Non-steroidal anti-inflammatory drug (NSAID) derived from propionic acid, a non-selective cyclooxygenase (COX-1 and COX-2) inhibitor.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per al dolor lleu-moderat, la inflamació i la febre.',
      es: 'Se usa para el dolor leve-moderado, la inflamación y la fiebre.',
      en: 'Used for mild-to-moderate pain, inflammation, and fever.',
    ),
    tip: LocalizedText(
      ca: 'Com la resta d\'AINE, s\'associa a risc gastrointestinal i renal, i habitualment s\'evita en el tercer trimestre de l\'embaràs.',
      es: 'Como el resto de AINE, se asocia a riesgo gastrointestinal y renal, y habitualmente se evita en el tercer trimestre del embarazo.',
      en: 'Like other NSAIDs, it carries gastrointestinal and renal risk, and is usually avoided in the third trimester of pregnancy.',
    ),
  ),
  Drug(
    id: 'acido-mefenamico',
    name: LocalizedText(ca: 'Àcid mefenàmic', es: 'Ácido mefenámico', en: 'Mefenamic acid'),
    aliases: ['Ponstan'],
    drugClass: DrugClass.analgesicoAntiinflamatorio,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'AINE del grup dels fenamats, també inhibidor no selectiu de la COX.',
      es: 'AINE del grupo de los fenamatos, también inhibidor no selectivo de la COX.',
      en: 'NSAID from the fenamate group, also a non-selective COX inhibitor.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza sobretot per al dolor menstrual (dismenorrea) i altres dolors lleus-moderats.',
      es: 'Se usa sobre todo para el dolor menstrual (dismenorrea) y otros dolores leves-moderados.',
      en: 'Used mainly for menstrual pain (dysmenorrhea) and other mild-to-moderate pain.',
    ),
  ),
  Drug(
    id: 'nimesulida',
    name: LocalizedText(ca: 'Nimesulida', es: 'Nimesulida', en: 'Nimesulide'),
    drugClass: DrugClass.analgesicoAntiinflamatorio,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'AINE amb certa selectivitat preferent per la COX-2.',
      es: 'AINE con cierta selectividad preferente por la COX-2.',
      en: 'NSAID with some preferential COX-2 selectivity.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per al dolor i la inflamació; el seu ús està restringit o retirat en diversos països per risc d\'hepatotoxicitat.',
      es: 'Se usa para el dolor y la inflamación; su uso está restringido o retirado en varios países por riesgo de hepatotoxicidad.',
      en: 'Used for pain and inflammation; it is restricted or withdrawn in several countries due to hepatotoxicity risk.',
    ),
    tip: LocalizedText(
      ca: 'A la Unió Europea el seu ús està limitat a tractaments curts per aquest motiu.',
      es: 'En la Unión Europea su uso está limitado a tratamientos cortos por este motivo.',
      en: 'In the European Union its use is restricted to short-term treatment for this reason.',
    ),
  ),
  Drug(
    id: 'aceclofenaco',
    name: LocalizedText(ca: 'Aceclofenac', es: 'Aceclofenaco', en: 'Aceclofenac'),
    aliases: ['Airtal'],
    drugClass: DrugClass.analgesicoAntiinflamatorio,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'AINE derivat de l\'àcid fenilacètic, emparentat estructuralment amb el diclofenac.',
      es: 'AINE derivado del ácido fenilacético, emparentado estructuralmente con el diclofenaco.',
      en: 'NSAID derived from phenylacetic acid, structurally related to diclofenac.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per al dolor i la inflamació de processos musculoesquelètics.',
      es: 'Se usa para el dolor y la inflamación de procesos musculoesqueléticos.',
      en: 'Used for pain and inflammation in musculoskeletal conditions.',
    ),
  ),

  // Antihistamínicos
  Drug(
    id: 'cetirizina',
    name: LocalizedText(ca: 'Cetirizina', es: 'Cetirizina', en: 'Cetirizine'),
    aliases: ['Zyrtec', 'Levocetirizina', 'Levocetirizine'],
    drugClass: DrugClass.antihistaminico,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Antihistamínic H1 de segona generació, amb poca penetració al sistema nerviós central i per tant poc efecte sedant en comparació amb els de primera generació.',
      es: 'Antihistamínico H1 de segunda generación, con poca penetración en el sistema nervioso central y por tanto poco efecto sedante en comparación con los de primera generación.',
      en: 'Second-generation H1 antihistamine, with little central nervous system penetration and therefore little sedative effect compared with first-generation agents.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a la rinitis al·lèrgica i la urticària.',
      es: 'Se usa para la rinitis alérgica y la urticaria.',
      en: 'Used for allergic rhinitis and urticaria.',
    ),
    tip: LocalizedText(
      ca: 'La levocetirizina n\'és l\'enantiòmer actiu, amb el mateix efecte clínic a dosi menor.',
      es: 'La levocetirizina es su enantiómero activo, con el mismo efecto clínico a menor dosis.',
      en: 'Levocetirizine is its active enantiomer, with the same clinical effect at a lower dose.',
    ),
  ),
  Drug(
    id: 'clorfenamina',
    name: LocalizedText(ca: 'Clorfenamina', es: 'Clorfenamina', en: 'Chlorphenamine'),
    aliases: ['Clorfeniramina', 'Chlorpheniramine', 'Polaramine', 'Pheniramine', 'Feniramina'],
    drugClass: DrugClass.antihistaminico,
    routes: ['Oral', 'IV', 'IM'],
    description: LocalizedText(
      ca: 'Antihistamínic H1 de primera generació, amb efecte sedant notable per la seva penetració al sistema nerviós central.',
      es: 'Antihistamínico H1 de primera generación, con efecto sedante notable por su penetración en el sistema nervioso central.',
      en: 'First-generation H1 antihistamine, with notable sedative effect due to its central nervous system penetration.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a símptomes al·lèrgics i com a coadjuvant en reaccions anafilàctiques.',
      es: 'Se usa para síntomas alérgicos y como coadyuvante en reacciones anafilácticas.',
      en: 'Used for allergic symptoms and as an adjunct in anaphylactic reactions.',
    ),
  ),
  Drug(
    id: 'difenhidramina',
    name: LocalizedText(ca: 'Difenhidramina', es: 'Difenhidramina', en: 'Diphenhydramine'),
    aliases: ['Benadryl'],
    drugClass: DrugClass.antihistaminico,
    routes: ['Oral', 'IV', 'IM'],
    description: LocalizedText(
      ca: 'Antihistamínic H1 de primera generació amb efecte sedant i anticolinèrgic marcats.',
      es: 'Antihistamínico H1 de primera generación con efecto sedante y anticolinérgico marcados.',
      en: 'First-generation H1 antihistamine with marked sedative and anticholinergic effects.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a símptomes al·lèrgics, com a inductor lleu del son i com a antiemètic en algunes reaccions.',
      es: 'Se usa para síntomas alérgicos, como inductor leve del sueño y como antiemético en algunas reacciones.',
      en: 'Used for allergic symptoms, as a mild sleep aid, and as an antiemetic in some reactions.',
    ),
  ),
  Drug(
    id: 'ciproheptadina',
    name: LocalizedText(ca: 'Ciproheptadina', es: 'Ciproheptadina', en: 'Cyproheptadine'),
    aliases: ['Periactin'],
    drugClass: DrugClass.antihistaminico,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Antihistamínic H1 de primera generació amb efecte antiserotoninèrgic afegit.',
      es: 'Antihistamínico H1 de primera generación con efecto antiserotoninérgico añadido.',
      en: 'First-generation H1 antihistamine with an added antiserotonergic effect.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a símptomes al·lèrgics i, per l\'efecte antiserotoninèrgic, com a estimulant de la gana.',
      es: 'Se usa para síntomas alérgicos y, por su efecto antiserotoninérgico, como estimulante del apetito.',
      en: 'Used for allergic symptoms and, because of its antiserotonergic effect, as an appetite stimulant.',
    ),
  ),
  Drug(
    id: 'prometazina',
    name: LocalizedText(ca: 'Prometazina', es: 'Prometazina', en: 'Promethazine'),
    aliases: ['Fenergan'],
    drugClass: DrugClass.antihistaminico,
    routes: ['Oral', 'IM', 'IV'],
    description: LocalizedText(
      ca: 'Fenotiazina amb efecte antihistamínic H1, sedant i antiemètic.',
      es: 'Fenotiazina con efecto antihistamínico H1, sedante y antiemético.',
      en: 'Phenothiazine with H1 antihistamine, sedative, and antiemetic effects.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a símptomes al·lèrgics, nàusees i vòmits, i com a sedant lleu.',
      es: 'Se usa para síntomas alérgicos, náuseas y vómitos, y como sedante leve.',
      en: 'Used for allergic symptoms, nausea and vomiting, and as a mild sedative.',
    ),
    tip: LocalizedText(
      ca: 'La via IV s\'associa a risc de lesió tissular greu si s\'extravasa.',
      es: 'La vía IV se asocia a riesgo de lesión tisular grave si se extravasa.',
      en: 'The IV route carries a risk of severe tissue injury if it extravasates.',
    ),
  ),

  // Antibióticos
  Drug(
    id: 'amoxicilina',
    name: LocalizedText(ca: 'Amoxicil·lina', es: 'Amoxicilina', en: 'Amoxicillin'),
    aliases: ['Clamoxyl'],
    drugClass: DrugClass.antibiotico,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Antibiòtic betalactàmic de la família de les aminopenicil·lines, amb espectre ampliat respecte a la penicil·lina original.',
      es: 'Antibiótico betalactámico de la familia de las aminopenicilinas, con espectro ampliado respecto a la penicilina original.',
      en: 'Beta-lactam antibiotic of the aminopenicillin family, with an expanded spectrum compared with the original penicillin.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a infeccions bacterianes respiratòries, d\'oïda i urinàries, entre d\'altres.',
      es: 'Se usa para infecciones bacterianas respiratorias, de oído y urinarias, entre otras.',
      en: 'Used for respiratory, ear, and urinary bacterial infections, among others.',
    ),
  ),
  Drug(
    id: 'amoxicilina-clavulanico',
    name: LocalizedText(ca: 'Amoxicil·lina/àcid clavulànic', es: 'Amoxicilina/ácido clavulánico', en: 'Amoxicillin/clavulanic acid'),
    aliases: ['Augmentine', 'Co-amoxiclav'],
    drugClass: DrugClass.antibiotico,
    routes: ['Oral', 'IV'],
    description: LocalizedText(
      ca: 'Combinació d\'amoxicil·lina amb àcid clavulànic, un inhibidor de betalactamases que protegeix l\'amoxicil·lina de la degradació per bacteris productors d\'aquest enzim.',
      es: 'Combinación de amoxicilina con ácido clavulánico, un inhibidor de betalactamasas que protege a la amoxicilina de la degradación por bacterias productoras de esta enzima.',
      en: 'Combination of amoxicillin with clavulanic acid, a beta-lactamase inhibitor that protects amoxicillin from degradation by bacteria producing this enzyme.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a infeccions causades per bacteris resistents a l\'amoxicil·lina sola, com algunes infeccions respiratòries, de pell i intraabdominals.',
      es: 'Se usa para infecciones causadas por bacterias resistentes a la amoxicilina sola, como algunas infecciones respiratorias, de piel e intraabdominales.',
      en: 'Used for infections caused by bacteria resistant to amoxicillin alone, such as some respiratory, skin, and intra-abdominal infections.',
    ),
  ),
  Drug(
    id: 'azitromicina',
    name: LocalizedText(ca: 'Azitromicina', es: 'Azitromicina', en: 'Azithromycin'),
    aliases: ['Zitromax'],
    drugClass: DrugClass.antibiotico,
    routes: ['Oral', 'IV'],
    description: LocalizedText(
      ca: 'Antibiòtic macròlid d\'acció llarga, que inhibeix la síntesi proteica bacteriana unint-se a la subunitat ribosòmica 50S.',
      es: 'Antibiótico macrólido de acción prolongada, que inhibe la síntesis proteica bacteriana uniéndose a la subunidad ribosómica 50S.',
      en: 'Long-acting macrolide antibiotic that inhibits bacterial protein synthesis by binding to the 50S ribosomal subunit.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a infeccions respiratòries, algunes infeccions de transmissió sexual i certes infeccions cutànies.',
      es: 'Se usa para infecciones respiratorias, algunas infecciones de transmisión sexual y ciertas infecciones cutáneas.',
      en: 'Used for respiratory infections, some sexually transmitted infections, and certain skin infections.',
    ),
  ),
  Drug(
    id: 'cefixima',
    name: LocalizedText(ca: 'Cefixima', es: 'Cefixima', en: 'Cefixime'),
    drugClass: DrugClass.antibiotico,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Cefalosporina de tercera generació d\'administració oral.',
      es: 'Cefalosporina de tercera generación de administración oral.',
      en: 'Third-generation cephalosporin for oral administration.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a infeccions urinàries i respiratòries, entre d\'altres.',
      es: 'Se usa para infecciones urinarias y respiratorias, entre otras.',
      en: 'Used for urinary and respiratory infections, among others.',
    ),
  ),
  Drug(
    id: 'metronidazol',
    name: LocalizedText(ca: 'Metronidazol', es: 'Metronidazol', en: 'Metronidazole'),
    aliases: ['Flagyl'],
    drugClass: DrugClass.antibiotico,
    routes: ['Oral', 'IV', 'topical'],
    description: LocalizedText(
      ca: 'Antibiòtic i antiparasitari del grup dels nitroimidazols, actiu contra bacteris anaerobis i alguns protozous.',
      es: 'Antibiótico y antiparasitario del grupo de los nitroimidazoles, activo frente a bacterias anaerobias y algunos protozoos.',
      en: 'Antibiotic and antiparasitic agent from the nitroimidazole group, active against anaerobic bacteria and some protozoa.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a infeccions per anaerobis (incloent-hi profilaxi quirúrgica), infeccions intraabdominals i infeccions per protozous com la giàrdia o l\'amebiasi.',
      es: 'Se usa para infecciones por anaerobios (incluyendo profilaxis quirúrgica), infecciones intraabdominales e infecciones por protozoos como la giardia o la amebiasis.',
      en: 'Used for anaerobic infections (including surgical prophylaxis), intra-abdominal infections, and protozoal infections such as giardiasis or amebiasis.',
    ),
    tip: LocalizedText(
      ca: 'Interacciona amb l\'alcohol produint un efecte tipus disulfiram (ruboritzaciò, nàusees).',
      es: 'Interacciona con el alcohol produciendo un efecto tipo disulfiram (enrojecimiento, náuseas).',
      en: 'Interacts with alcohol, producing a disulfiram-like effect (flushing, nausea).',
    ),
  ),
  Drug(
    id: 'neomicina',
    name: LocalizedText(ca: 'Neomicina', es: 'Neomicina', en: 'Neomycin'),
    drugClass: DrugClass.antibiotico,
    routes: ['Oral', 'topical'],
    description: LocalizedText(
      ca: 'Antibiòtic aminoglucòsid que, per via oral, pràcticament no s\'absorbeix al tracte digestiu.',
      es: 'Antibiótico aminoglucósido que, por vía oral, prácticamente no se absorbe en el tracto digestivo.',
      en: 'Aminoglycoside antibiotic that, when given orally, is virtually not absorbed from the digestive tract.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per via oral per a la descontaminació intestinal preoperatòria i en l\'encefalopatia hepàtica, i per via tòpica per a infeccions cutànies.',
      es: 'Se usa por vía oral para la descontaminación intestinal preoperatoria y en la encefalopatía hepática, y por vía tópica para infecciones cutáneas.',
      en: 'Used orally for preoperative bowel decontamination and in hepatic encephalopathy, and topically for skin infections.',
    ),
  ),
  Drug(
    id: 'piperacilina-tazobactam',
    name: LocalizedText(ca: 'Piperacil·lina/tazobactam', es: 'Piperacilina/tazobactam', en: 'Piperacillin/tazobactam'),
    aliases: ['Tazocel'],
    drugClass: DrugClass.antibiotico,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Combinació d\'una penicil·lina d\'ampli espectre (piperacil·lina) amb un inhibidor de betalactamases (tazobactam) que amplia la seva cobertura.',
      es: 'Combinación de una penicilina de amplio espectro (piperacilina) con un inhibidor de betalactamasas (tazobactam) que amplía su cobertura.',
      en: 'Combination of a broad-spectrum penicillin (piperacillin) with a beta-lactamase inhibitor (tazobactam) that broadens its coverage.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en infeccions greus intrahospitalàries de ventall ampli, incloent-hi infeccions intraabdominals, respiratòries i sèptiques.',
      es: 'Se usa en infecciones graves intrahospitalarias de amplio espectro, incluyendo infecciones intraabdominales, respiratorias y sépticas.',
      en: 'Used for severe broad-spectrum hospital infections, including intra-abdominal, respiratory, and septic infections.',
    ),
  ),
  Drug(
    id: 'cefoperazona-sulbactam',
    name: LocalizedText(ca: 'Cefoperazona/sulbactam', es: 'Cefoperazona/sulbactam', en: 'Cefoperazone/sulbactam'),
    aliases: ['Sulperazon'],
    drugClass: DrugClass.antibiotico,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Combinació d\'una cefalosporina de tercera generació (cefoperazona) amb un inhibidor de betalactamases (sulbactam).',
      es: 'Combinación de una cefalosporina de tercera generación (cefoperazona) con un inhibidor de betalactamasas (sulbactam).',
      en: 'Combination of a third-generation cephalosporin (cefoperazone) with a beta-lactamase inhibitor (sulbactam).',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en infeccions intrahospitalàries greus; no està comercialitzada als EUA però s\'usa en altres regions.',
      es: 'Se usa en infecciones intrahospitalarias graves; no está comercializada en EE. UU. pero se usa en otras regiones.',
      en: 'Used for severe hospital infections; it is not marketed in the US but is used in other regions.',
    ),
  ),
  Drug(
    id: 'ceftazidima-avibactam',
    name: LocalizedText(ca: 'Ceftazidima/avibactam', es: 'Ceftazidima/avibactam', en: 'Ceftazidime/avibactam'),
    aliases: ['Avycaz'],
    drugClass: DrugClass.antibiotico,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Combinació d\'una cefalosporina de tercera generació (ceftazidima) amb avibactam, un inhibidor de betalactamases no betalactàmic.',
      es: 'Combinación de una cefalosporina de tercera generación (ceftazidima) con avibactam, un inhibidor de betalactamasas no betalactámico.',
      en: 'Combination of a third-generation cephalosporin (ceftazidime) with avibactam, a non-beta-lactam beta-lactamase inhibitor.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en infeccions greus (intraabdominals, urinàries, pneumònia) causades per bacteris gramnegatius multiresistents.',
      es: 'Se usa en infecciones graves (intraabdominales, urinarias, neumonía) causadas por bacterias gramnegativas multirresistentes.',
      en: 'Used for severe infections (intra-abdominal, urinary, pneumonia) caused by multidrug-resistant gram-negative bacteria.',
    ),
  ),
  Drug(
    id: 'meropenem-vaborbactam',
    name: LocalizedText(ca: 'Meropenem/vaborbactam', es: 'Meropenem/vaborbactam', en: 'Meropenem/vaborbactam'),
    aliases: ['Vabomere'],
    drugClass: DrugClass.antibiotico,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Combinació d\'un carbapenem (meropenem) amb vaborbactam, un inhibidor de betalactamases d\'estructura borònica cíclica.',
      es: 'Combinación de un carbapenem (meropenem) con vaborbactam, un inhibidor de betalactamasas de estructura borónica cíclica.',
      en: 'Combination of a carbapenem (meropenem) with vaborbactam, a cyclic boronate beta-lactamase inhibitor.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en infeccions urinàries complicades causades per bacteris gramnegatius multiresistents.',
      es: 'Se usa en infecciones urinarias complicadas causadas por bacterias gramnegativas multirresistentes.',
      en: 'Used for complicated urinary tract infections caused by multidrug-resistant gram-negative bacteria.',
    ),
  ),
  Drug(
    id: 'gentamicina',
    name: LocalizedText(ca: 'Gentamicina', es: 'Gentamicina', en: 'Gentamicin'),
    drugClass: DrugClass.antibiotico,
    routes: ['IV', 'IM', 'topical'],
    description: LocalizedText(
      ca: 'Antibiòtic aminoglucòsid, actiu principalment contra bacteris gramnegatius, que inhibeix la síntesi proteica bacteriana.',
      es: 'Antibiótico aminoglucósido, activo principalmente frente a bacterias gramnegativas, que inhibe la síntesis proteica bacteriana.',
      en: 'Aminoglycoside antibiotic, active mainly against gram-negative bacteria, which inhibits bacterial protein synthesis.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en infeccions greus per gramnegatius i, sovint, com a part de la profilaxi quirúrgica.',
      es: 'Se usa en infecciones graves por gramnegativos y, a menudo, como parte de la profilaxis quirúrgica.',
      en: 'Used for severe gram-negative infections and often as part of surgical prophylaxis.',
    ),
    tip: LocalizedText(
      ca: 'Té potencial de nefrotoxicitat i ototoxicitat, per la qual cosa sovint es monitoritzen els seus nivells plasmàtics.',
      es: 'Tiene potencial de nefrotoxicidad y ototoxicidad, por lo que a menudo se monitorizan sus niveles plasmáticos.',
      en: 'Has nephrotoxic and ototoxic potential, so its plasma levels are often monitored.',
    ),
  ),
  Drug(
    id: 'amikacina',
    name: LocalizedText(ca: 'Amikacina', es: 'Amikacina', en: 'Amikacin'),
    drugClass: DrugClass.antibiotico,
    routes: ['IV', 'IM'],
    description: LocalizedText(
      ca: 'Antibiòtic aminoglucòsid semisintètic, amb un espectre més ampli enfront de soques resistents a altres aminoglucòsids.',
      es: 'Antibiótico aminoglucósido semisintético, con un espectro más amplio frente a cepas resistentes a otros aminoglucósidos.',
      en: 'Semisynthetic aminoglycoside antibiotic, with a broader spectrum against strains resistant to other aminoglycosides.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en infeccions greus per gramnegatius, incloent-hi soques resistents a altres aminoglucòsids.',
      es: 'Se usa en infecciones graves por gramnegativos, incluyendo cepas resistentes a otros aminoglucósidos.',
      en: 'Used for severe gram-negative infections, including strains resistant to other aminoglycosides.',
    ),
  ),
  Drug(
    id: 'tobramicina',
    name: LocalizedText(ca: 'Tobramicina', es: 'Tobramicina', en: 'Tobramycin'),
    drugClass: DrugClass.antibiotico,
    routes: ['IV', 'IM', 'inhaled', 'ophthalmic'],
    description: LocalizedText(
      ca: 'Antibiòtic aminoglucòsid, amb activitat especialment destacada contra Pseudomonas aeruginosa.',
      es: 'Antibiótico aminoglucósido, con actividad especialmente destacada frente a Pseudomonas aeruginosa.',
      en: 'Aminoglycoside antibiotic, with particularly notable activity against Pseudomonas aeruginosa.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en infeccions greus per gramnegatius, en forma inhalada per a la colonització crònica per Pseudomonas en fibrosi quística, i en forma oftàlmica per a infeccions oculars.',
      es: 'Se usa en infecciones graves por gramnegativos, en forma inhalada para la colonización crónica por Pseudomonas en fibrosis quística, y en forma oftálmica para infecciones oculares.',
      en: 'Used for severe gram-negative infections, in inhaled form for chronic Pseudomonas colonization in cystic fibrosis, and in ophthalmic form for eye infections.',
    ),
  ),
  Drug(
    id: 'colistina',
    name: LocalizedText(ca: 'Colistina', es: 'Colistina', en: 'Colistin'),
    aliases: ['Polimixina E', 'Colistimethate'],
    drugClass: DrugClass.antibiotico,
    routes: ['IV', 'inhaled'],
    description: LocalizedText(
      ca: 'Antibiòtic polimixina, que altera la membrana cel·lular bacteriana; es considera un antibiòtic d\'últim recurs per la seva toxicitat.',
      es: 'Antibiótico polimixina, que altera la membrana celular bacteriana; se considera un antibiótico de último recurso por su toxicidad.',
      en: 'Polymyxin antibiotic that disrupts the bacterial cell membrane; considered a last-resort antibiotic due to its toxicity.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en infeccions greus per bacteris gramnegatius multiresistents, quan altres opcions no són viables.',
      es: 'Se usa en infecciones graves por bacterias gramnegativas multirresistentes, cuando otras opciones no son viables.',
      en: 'Used for severe infections caused by multidrug-resistant gram-negative bacteria, when other options are not viable.',
    ),
    tip: LocalizedText(
      ca: 'La seva nefrotoxicitat n\'ha limitat històricament l\'ús generalitzat.',
      es: 'Su nefrotoxicidad ha limitado históricamente su uso generalizado.',
      en: 'Its nephrotoxicity has historically limited its widespread use.',
    ),
  ),

  // Antiparasitarios
  Drug(
    id: 'albendazol',
    name: LocalizedText(ca: 'Albendazol', es: 'Albendazol', en: 'Albendazole'),
    aliases: ['Eskazole'],
    drugClass: DrugClass.antiparasitario,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Antihelmíntic de la família dels benzimidazols, que interfereix amb la formació de microtúbuls del paràsit.',
      es: 'Antihelmíntico de la familia de los benzimidazoles, que interfiere con la formación de microtúbulos del parásito.',
      en: 'Anthelmintic from the benzimidazole family, which interferes with the parasite\'s microtubule formation.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a diverses infeccions per cucs intestinals (nematodes) i, a dosis diferents, per a infeccions com l\'equinococosi.',
      es: 'Se usa para diversas infecciones por gusanos intestinales (nematodos) y, a dosis distintas, para infecciones como la equinococosis.',
      en: 'Used for various intestinal worm (nematode) infections and, at different doses, for infections such as echinococcosis.',
    ),
  ),
  Drug(
    id: 'ivermectina',
    name: LocalizedText(ca: 'Ivermectina', es: 'Ivermectina', en: 'Ivermectin'),
    aliases: ['Stromectol'],
    drugClass: DrugClass.antiparasitario,
    routes: ['Oral', 'topical'],
    description: LocalizedText(
      ca: 'Antiparasitari de la família de les avermectines, que paralitza la musculatura del paràsit actuant sobre canals de clor dependents de glutamat.',
      es: 'Antiparasitario de la familia de las avermectinas, que paraliza la musculatura del parásito actuando sobre canales de cloro dependientes de glutamato.',
      en: 'Antiparasitic from the avermectin family, which paralyzes the parasite\'s musculature by acting on glutamate-gated chloride channels.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a l\'escabiosi, l\'estrongiloidosi i altres parasitosis; per via tòpica també per a la rosàcia i la pediculosi.',
      es: 'Se usa para la escabiosis, la estrongiloidosis y otras parasitosis; por vía tópica también para la rosácea y la pediculosis.',
      en: 'Used for scabies, strongyloidiasis, and other parasitic infections; topically also for rosacea and head lice.',
    ),
  ),

  // Digestivo
  Drug(
    id: 'omeprazol',
    name: LocalizedText(ca: 'Omeprazol', es: 'Omeprazol', en: 'Omeprazole'),
    drugClass: DrugClass.digestivo,
    routes: ['Oral', 'IV'],
    description: LocalizedText(
      ca: 'Inhibidor de la bomba de protons (IBP), que redueix la secreció àcida gàstrica bloquejant la bomba H+/K+-ATPasa de les cèl·lules parietals.',
      es: 'Inhibidor de la bomba de protones (IBP), que reduce la secreción ácida gástrica bloqueando la bomba H+/K+-ATPasa de las células parietales.',
      en: 'Proton pump inhibitor (PPI) that reduces gastric acid secretion by blocking the H+/K+-ATPase pump of parietal cells.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a la malaltia per reflux gastroesofàgic, l\'úlcera pèptica i la protecció gàstrica durant tractaments que n\'augmenten el risc.',
      es: 'Se usa para la enfermedad por reflujo gastroesofágico, la úlcera péptica y la protección gástrica durante tratamientos que aumentan su riesgo.',
      en: 'Used for gastroesophageal reflux disease, peptic ulcer, and gastric protection during treatments that increase its risk.',
    ),
  ),
  Drug(
    id: 'ranitidina',
    name: LocalizedText(ca: 'Ranitidina', es: 'Ranitidina', en: 'Ranitidine'),
    aliases: ['Zantac'],
    drugClass: DrugClass.digestivo,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Antagonista dels receptors H2 de la histamina, que redueix la secreció àcida gàstrica.',
      es: 'Antagonista de los receptores H2 de la histamina, que reduce la secreción ácida gástrica.',
      en: 'Histamine H2-receptor antagonist that reduces gastric acid secretion.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per al reflux gastroesofàgic i l\'úlcera pèptica.',
      es: 'Se usa para el reflujo gastroesofágico y la úlcera péptica.',
      en: 'Used for gastroesophageal reflux and peptic ulcer.',
    ),
    tip: LocalizedText(
      ca: 'Es va retirar del mercat el 2020 per la troballa de nivells variables de N-nitrosodimetilamina (NDMA) en alguns lots; una formulació reformulada ha tornat a algun mercat anys després.',
      es: 'Se retiró del mercado en 2020 por el hallazgo de niveles variables de N-nitrosodimetilamina (NDMA) en algunos lotes; una formulación reformulada ha vuelto a algún mercado años después.',
      en: 'It was withdrawn from the market in 2020 after variable levels of N-nitrosodimethylamine (NDMA) were found in some batches; a reformulated version has since returned to some markets.',
    ),
  ),
  Drug(
    id: 'sucralfato',
    name: LocalizedText(ca: 'Sucralfat', es: 'Sucralfato', en: 'Sucralfate'),
    drugClass: DrugClass.digestivo,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Protector de la mucosa gàstrica que, en un medi àcid, forma una pasta viscosa que s\'adhereix a la superfície de les úlceres, sense efecte antiàcid sistèmic rellevant.',
      es: 'Protector de la mucosa gástrica que, en un medio ácido, forma una pasta viscosa que se adhiere a la superficie de las úlceras, sin efecto antiácido sistémico relevante.',
      en: 'Gastric mucosal protectant that, in an acidic environment, forms a viscous paste that adheres to the surface of ulcers, without a relevant systemic antacid effect.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a l\'úlcera pèptica i, de vegades, com a protecció de la mucosa en altres contextos.',
      es: 'Se usa para la úlcera péptica y, en ocasiones, como protección de la mucosa en otros contextos.',
      en: 'Used for peptic ulcer and, occasionally, for mucosal protection in other contexts.',
    ),
  ),
  Drug(
    id: 'hidroxido-aluminio-magnesio',
    name: LocalizedText(ca: 'Hidròxid d\'alumini/magnesi', es: 'Hidróxido de aluminio/magnesio', en: 'Aluminum/magnesium hydroxide'),
    aliases: ['Almax', 'Maalox', 'Milk of Magnesia'],
    drugClass: DrugClass.digestivo,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Antiàcid que neutralitza directament l\'àcid gàstric; combina hidròxid d\'alumini (constipant) i d\'magnesi (laxant) per contrarestar els seus efectes digestius oposats.',
      es: 'Antiácido que neutraliza directamente el ácido gástrico; combina hidróxido de aluminio (estreñiente) y de magnesio (laxante) para contrarrestar sus efectos digestivos opuestos.',
      en: 'Antacid that directly neutralizes gastric acid; it combines aluminum hydroxide (constipating) and magnesium hydroxide (laxative) to offset their opposite digestive effects.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a l\'alleujament simptomàtic ràpid de l\'acidesa i la dispèpsia; l\'hidròxid de magnesi sol s\'utilitza també com a laxant.',
      es: 'Se usa para el alivio sintomático rápido de la acidez y la dispepsia; el hidróxido de magnesio solo se usa también como laxante.',
      en: 'Used for quick symptomatic relief of heartburn and dyspepsia; magnesium hydroxide alone is also used as a laxative.',
    ),
  ),
  Drug(
    id: 'dicicloverina',
    name: LocalizedText(ca: 'Dicicloverina', es: 'Dicicloverina', en: 'Dicyclomine'),
    aliases: ['Dicyclomine', 'Bentyl'],
    drugClass: DrugClass.digestivo,
    routes: ['Oral', 'IM'],
    description: LocalizedText(
      ca: 'Antiespasmòdic anticolinèrgic que relaxa la musculatura llisa digestiva.',
      es: 'Antiespasmódico anticolinérgico que relaja la musculatura lisa digestiva.',
      en: 'Anticholinergic antispasmodic that relaxes digestive smooth muscle.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per als espasmes i el dolor abdominal còlic, com en la síndrome de l\'intestí irritable.',
      es: 'Se usa para los espasmos y el dolor abdominal cólico, como en el síndrome del intestino irritable.',
      en: 'Used for cramping abdominal spasms and pain, such as in irritable bowel syndrome.',
    ),
  ),
  Drug(
    id: 'simeticona',
    name: LocalizedText(ca: 'Simeticona', es: 'Simeticona', en: 'Simethicone'),
    aliases: ['Aero Red'],
    drugClass: DrugClass.digestivo,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Agent antiflatulent que redueix la tensió superficial de les bombolles de gas intestinal, afavorint-ne la coalescència i expulsió.',
      es: 'Agente antiflatulento que reduce la tensión superficial de las burbujas de gas intestinal, favoreciendo su coalescencia y expulsión.',
      en: 'Antiflatulent agent that reduces the surface tension of intestinal gas bubbles, promoting their coalescence and expulsion.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a la flatulència i la sensació de distensió abdominal.',
      es: 'Se usa para la flatulencia y la sensación de distensión abdominal.',
      en: 'Used for flatulence and bloating.',
    ),
  ),
  Drug(
    id: 'lactulosa',
    name: LocalizedText(ca: 'Lactulosa', es: 'Lactulosa', en: 'Lactulose'),
    aliases: ['Duphalac'],
    drugClass: DrugClass.digestivo,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Disacàrid sintètic que actua com a laxant osmòtic, atraient aigua cap a la llum intestinal; a l\'intestí gros, la seva fermentació bacteriana també redueix l\'absorció d\'amoníac.',
      es: 'Disacárido sintético que actúa como laxante osmótico, atrayendo agua hacia la luz intestinal; en el intestino grueso, su fermentación bacteriana también reduce la absorción de amoníaco.',
      en: 'Synthetic disaccharide that acts as an osmotic laxative, drawing water into the intestinal lumen; in the large intestine, its bacterial fermentation also reduces ammonia absorption.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per al restrenyiment i, a l\'encefalopatia hepàtica, per reduir els nivells d\'amoníac.',
      es: 'Se usa para el estreñimiento y, en la encefalopatía hepática, para reducir los niveles de amoníaco.',
      en: 'Used for constipation and, in hepatic encephalopathy, to reduce ammonia levels.',
    ),
  ),
  Drug(
    id: 'picosulfato-sodico',
    name: LocalizedText(ca: 'Picosulfat sòdic', es: 'Picosulfato sódico', en: 'Sodium picosulfate'),
    aliases: ['Dulcolaxo'],
    drugClass: DrugClass.digestivo,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Laxant estimulant que, un cop activat pel metabolisme de la flora intestinal, augmenta el peristaltisme del còlon.',
      es: 'Laxante estimulante que, una vez activado por el metabolismo de la flora intestinal, aumenta el peristaltismo del colon.',
      en: 'Stimulant laxative that, once activated by gut flora metabolism, increases colonic peristalsis.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per al restrenyiment ocasional i per a la preparació intestinal abans de procediments com la colonoscòpia.',
      es: 'Se usa para el estreñimiento ocasional y para la preparación intestinal antes de procedimientos como la colonoscopia.',
      en: 'Used for occasional constipation and for bowel preparation before procedures such as colonoscopy.',
    ),
  ),

  // Respiratorio
  Drug(
    id: 'salbutamol',
    name: LocalizedText(ca: 'Salbutamol', es: 'Salbutamol', en: 'Salbutamol (albuterol)'),
    aliases: ['Albuterol', 'Ventolin'],
    drugClass: DrugClass.broncodilatadorRespiratorio,
    routes: ['Inhaled', 'Oral', 'IV'],
    description: LocalizedText(
      ca: 'Agonista beta-2 adrenèrgic d\'acció curta, que relaxa la musculatura llisa bronquial.',
      es: 'Agonista beta-2 adrenérgico de acción corta, que relaja la musculatura lisa bronquial.',
      en: 'Short-acting beta-2 adrenergic agonist that relaxes bronchial smooth muscle.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza com a broncodilatador de rescat en l\'asma i la malaltia pulmonar obstructiva crònica.',
      es: 'Se usa como broncodilatador de rescate en el asma y la enfermedad pulmonar obstructiva crónica.',
      en: 'Used as a rescue bronchodilator in asthma and chronic obstructive pulmonary disease.',
    ),
  ),
  Drug(
    id: 'terbutalina',
    name: LocalizedText(ca: 'Terbutalina', es: 'Terbutalina', en: 'Terbutaline'),
    aliases: ['Brethine'],
    drugClass: DrugClass.broncodilatadorRespiratorio,
    routes: ['Inhaled', 'Oral', 'subcutaneous'],
    description: LocalizedText(
      ca: 'Agonista beta-2 adrenèrgic d\'acció curta, similar al salbutamol.',
      es: 'Agonista beta-2 adrenérgico de acción corta, similar al salbutamol.',
      en: 'Short-acting beta-2 adrenergic agonist, similar to salbutamol.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza com a broncodilatador en l\'asma; per via subcutània també s\'ha emprat com a tocolític per frenar el part prematur.',
      es: 'Se usa como broncodilatador en el asma; por vía subcutánea también se ha empleado como tocolítico para frenar el parto prematuro.',
      en: 'Used as a bronchodilator in asthma; subcutaneously it has also been used as a tocolytic to delay preterm labor.',
    ),
  ),
  Drug(
    id: 'montelukast',
    name: LocalizedText(ca: 'Montelukast', es: 'Montelukast', en: 'Montelukast'),
    aliases: ['Singulair'],
    drugClass: DrugClass.broncodilatadorRespiratorio,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Antagonista dels receptors dels leucotriens, que redueix la inflamació i la broncoconstricció associades a aquests mediadors.',
      es: 'Antagonista de los receptores de los leucotrienos, que reduce la inflamación y la broncoconstricción asociadas a estos mediadores.',
      en: 'Leukotriene receptor antagonist, which reduces the inflammation and bronchoconstriction associated with these mediators.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza com a tractament de manteniment de l\'asma i de la rinitis al·lèrgica.',
      es: 'Se usa como tratamiento de mantenimiento del asma y de la rinitis alérgica.',
      en: 'Used as maintenance treatment for asthma and allergic rhinitis.',
    ),
  ),
  Drug(
    id: 'cromoglicato-sodico',
    name: LocalizedText(ca: 'Cromoglicat sòdic', es: 'Cromoglicato sódico', en: 'Sodium cromoglycate'),
    aliases: ['Cromolyn'],
    drugClass: DrugClass.broncodilatadorRespiratorio,
    routes: ['Inhaled'],
    description: LocalizedText(
      ca: 'Estabilitzador dels mastòcits que n\'impedeix la degranulació i l\'alliberament de mediadors inflamatoris.',
      es: 'Estabilizador de los mastocitos que impide su degranulación y la liberación de mediadores inflamatorios.',
      en: 'Mast cell stabilizer that prevents their degranulation and the release of inflammatory mediators.',
    ),
    use: LocalizedText(
      ca: 'S\'ha utilitzat com a tractament preventiu de l\'asma, especialment en infants; actualment és menys utilitzat que altres opcions.',
      es: 'Se ha usado como tratamiento preventivo del asma, especialmente en niños; actualmente es menos utilizado que otras opciones.',
      en: 'Used as a preventive asthma treatment, especially in children; it is now less used than other options.',
    ),
  ),
  Drug(
    id: 'ambroxol',
    name: LocalizedText(ca: 'Ambroxol', es: 'Ambroxol', en: 'Ambroxol'),
    aliases: ['Mucosan'],
    drugClass: DrugClass.broncodilatadorRespiratorio,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Mucolític que facilita l\'eliminació de les secrecions bronquials, augmentant-ne la producció de surfactant i reduint-ne la viscositat.',
      es: 'Mucolítico que facilita la eliminación de las secreciones bronquiales, aumentando la producción de surfactante y reduciendo su viscosidad.',
      en: 'Mucolytic that facilitates clearance of bronchial secretions, increasing surfactant production and reducing their viscosity.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en afeccions respiratòries amb secrecions espesses, com la bronquitis.',
      es: 'Se usa en afecciones respiratorias con secreciones espesas, como la bronquitis.',
      en: 'Used in respiratory conditions with thick secretions, such as bronchitis.',
    ),
  ),
  Drug(
    id: 'guaifenesina',
    name: LocalizedText(ca: 'Guaifenesina', es: 'Guaifenesina', en: 'Guaifenesin'),
    aliases: ['Guaifenesín'],
    drugClass: DrugClass.broncodilatadorRespiratorio,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Expectorant que redueix la viscositat de les secrecions bronquials, facilitant-ne l\'expulsió amb la tos.',
      es: 'Expectorante que reduce la viscosidad de las secreciones bronquiales, facilitando su expulsión con la tos.',
      en: 'Expectorant that reduces the viscosity of bronchial secretions, making them easier to expel with coughing.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a la tos productiva associada a processos respiratoris.',
      es: 'Se usa para la tos productiva asociada a procesos respiratorios.',
      en: 'Used for productive cough associated with respiratory conditions.',
    ),
  ),
  Drug(
    id: 'dextrometorfano',
    name: LocalizedText(ca: 'Dextrometorfan', es: 'Dextrometorfano', en: 'Dextromethorphan'),
    drugClass: DrugClass.broncodilatadorRespiratorio,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Antitussigen d\'acció central, estructuralment emparentat amb els opioides però sense activitat analgèsica rellevant a les dosis habituals.',
      es: 'Antitusígeno de acción central, estructuralmente emparentado con los opioides pero sin actividad analgésica relevante a las dosis habituales.',
      en: 'Centrally acting antitussive, structurally related to opioids but without relevant analgesic activity at usual doses.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a la tos seca no productiva.',
      es: 'Se usa para la tos seca no productiva.',
      en: 'Used for dry, non-productive cough.',
    ),
  ),

  // Vitaminas / suplementos
  Drug(
    id: 'multivitaminico',
    name: LocalizedText(ca: 'Multivitamínic', es: 'Multivitamínico', en: 'Multivitamin'),
    drugClass: DrugClass.vitaminaSuplemento,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Combinació de diverses vitamines (i sovint minerals) en una única formulació.',
      es: 'Combinación de varias vitaminas (y a menudo minerales) en una única formulación.',
      en: 'Combination of several vitamins (and often minerals) in a single formulation.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per prevenir o tractar dèficits nutricionals generals.',
      es: 'Se usa para prevenir o tratar déficits nutricionales generales.',
      en: 'Used to prevent or treat general nutritional deficiencies.',
    ),
  ),
  Drug(
    id: 'complejo-vitaminico-b',
    name: LocalizedText(ca: 'Complex vitamínic B', es: 'Complejo vitamínico B', en: 'Vitamin B complex'),
    drugClass: DrugClass.vitaminaSuplemento,
    routes: ['Oral', 'IM', 'IV'],
    description: LocalizedText(
      ca: 'Combinació de diverses vitamines del grup B (B1, B6, B12, entre d\'altres), amb funcions metabòliques i neurològiques diverses.',
      es: 'Combinación de varias vitaminas del grupo B (B1, B6, B12, entre otras), con funciones metabólicas y neurológicas diversas.',
      en: 'Combination of several B-group vitamins (B1, B6, B12, among others), with diverse metabolic and neurological functions.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a dèficits vitamínics del grup B i, de vegades, en neuropaties perifèriques.',
      es: 'Se usa para déficits vitamínicos del grupo B y, en ocasiones, en neuropatías periféricas.',
      en: 'Used for B-group vitamin deficiencies and, occasionally, in peripheral neuropathies.',
    ),
  ),
  Drug(
    id: 'vitamina-c',
    name: LocalizedText(ca: 'Vitamina C', es: 'Vitamina C', en: 'Vitamin C'),
    aliases: ['Àcid ascòrbic', 'Ácido ascórbico', 'Ascorbic acid'],
    drugClass: DrugClass.vitaminaSuplemento,
    routes: ['Oral', 'IV'],
    description: LocalizedText(
      ca: 'Vitamina hidrosoluble amb funció antioxidant, necessària per a la síntesi de col·lagen.',
      es: 'Vitamina hidrosoluble con función antioxidante, necesaria para la síntesis de colágeno.',
      en: 'Water-soluble vitamin with antioxidant function, necessary for collagen synthesis.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per prevenir o tractar-ne el dèficit (escorbut) i com a suplement immunitari general.',
      es: 'Se usa para prevenir o tratar su déficit (escorbuto) y como suplemento inmunitario general.',
      en: 'Used to prevent or treat its deficiency (scurvy) and as a general immune supplement.',
    ),
  ),
  Drug(
    id: 'zinc-suplemento',
    name: LocalizedText(ca: 'Zinc', es: 'Zinc', en: 'Zinc'),
    drugClass: DrugClass.vitaminaSuplemento,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Oligoelement essencial, cofactor de nombrosos enzims i important per a la funció immunitària i la cicatrització.',
      es: 'Oligoelemento esencial, cofactor de numerosas enzimas e importante para la función inmunitaria y la cicatrización.',
      en: 'Essential trace element, a cofactor for numerous enzymes and important for immune function and wound healing.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per prevenir o tractar-ne el dèficit, i com a coadjuvant en episodis de diarrea en infants.',
      es: 'Se usa para prevenir o tratar su déficit, y como coadyuvante en episodios de diarrea en niños.',
      en: 'Used to prevent or treat its deficiency, and as an adjunct in episodes of diarrhea in children.',
    ),
  ),
  Drug(
    id: 'hierro-suplemento',
    name: LocalizedText(ca: 'Ferro', es: 'Hierro', en: 'Iron'),
    aliases: ['Sulfato ferroso', 'Ferrous sulfate', 'Fumarato ferroso'],
    drugClass: DrugClass.vitaminaSuplemento,
    routes: ['Oral', 'IV'],
    description: LocalizedText(
      ca: 'Suplement mineral essencial per a la síntesi d\'hemoglobina.',
      es: 'Suplemento mineral esencial para la síntesis de hemoglobina.',
      en: 'Mineral supplement essential for hemoglobin synthesis.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per prevenir i tractar l\'anèmia ferropènica.',
      es: 'Se usa para prevenir y tratar la anemia ferropénica.',
      en: 'Used to prevent and treat iron-deficiency anemia.',
    ),
    tip: LocalizedText(
      ca: 'La formulació oral sol causar molèsties digestives i tenyir les femtes de color fosc.',
      es: 'La formulación oral suele causar molestias digestivas y teñir las heces de color oscuro.',
      en: 'The oral formulation commonly causes digestive discomfort and darkens the stool.',
    ),
  ),
  Drug(
    id: 'calcio-suplemento',
    name: LocalizedText(ca: 'Calci', es: 'Calcio', en: 'Calcium'),
    aliases: ['Carbonato de calcio', 'Calcium carbonate'],
    drugClass: DrugClass.vitaminaSuplemento,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Suplement mineral essencial per a la mineralització òssia i la funció neuromuscular.',
      es: 'Suplemento mineral esencial para la mineralización ósea y la función neuromuscular.',
      en: 'Mineral supplement essential for bone mineralization and neuromuscular function.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per prevenir i tractar-ne el dèficit, i com a coadjuvant en l\'osteoporosi.',
      es: 'Se usa para prevenir y tratar su déficit, y como coadyuvante en la osteoporosis.',
      en: 'Used to prevent and treat its deficiency, and as an adjunct in osteoporosis.',
    ),
  ),
  Drug(
    id: 'vitamina-k1',
    name: LocalizedText(ca: 'Vitamina K1', es: 'Vitamina K1', en: 'Vitamin K1'),
    aliases: ['Fitomenadiona', 'Phytomenadione', 'Konakion'],
    drugClass: DrugClass.vitaminaSuplemento,
    routes: ['Oral', 'IM', 'IV'],
    description: LocalizedText(
      ca: 'Vitamina liposoluble necessària per a la síntesi hepàtica de diversos factors de coagulació (II, VII, IX, X).',
      es: 'Vitamina liposoluble necesaria para la síntesis hepática de varios factores de coagulación (II, VII, IX, X).',
      en: 'Fat-soluble vitamin necessary for hepatic synthesis of several clotting factors (II, VII, IX, X).',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per revertir l\'efecte dels antagonistes de la vitamina K (com la warfarina) i, de forma profilàctica, als nounats.',
      es: 'Se usa para revertir el efecto de los antagonistas de la vitamina K (como la warfarina) y, de forma profiláctica, en los recién nacidos.',
      en: 'Used to reverse the effect of vitamin K antagonists (such as warfarin) and, prophylactically, in newborns.',
    ),
  ),

  // Corticoides
  Drug(
    id: 'budesonida',
    name: LocalizedText(ca: 'Budesonida', es: 'Budesonida', en: 'Budesonide'),
    aliases: ['Pulmicort'],
    drugClass: DrugClass.corticoide,
    routes: ['Inhaled', 'Oral', 'nasal'],
    description: LocalizedText(
      ca: 'Corticoide amb activitat antiinflamatòria principalment local, i baixa biodisponibilitat sistèmica en forma inhalada o nasal.',
      es: 'Corticoide con actividad antiinflamatoria principalmente local, y baja biodisponibilidad sistémica en forma inhalada o nasal.',
      en: 'Corticosteroid with mainly local anti-inflammatory activity, and low systemic bioavailability in inhaled or nasal form.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza com a tractament de manteniment de l\'asma i, per via nasal, de la rinitis al·lèrgica.',
      es: 'Se usa como tratamiento de mantenimiento del asma y, por vía nasal, de la rinitis alérgica.',
      en: 'Used as maintenance treatment for asthma and, nasally, for allergic rhinitis.',
    ),
  ),
  Drug(
    id: 'dexametasona',
    name: LocalizedText(ca: 'Dexametasona', es: 'Dexametasona', en: 'Dexamethasone'),
    aliases: ['Fortecortin'],
    drugClass: DrugClass.corticoide,
    routes: ['IV', 'IM', 'Oral'],
    description: LocalizedText(
      ca: 'Corticoide sintètic d\'elevada potència antiinflamatòria i acció perllongada, amb efecte mineralocorticoide mínim.',
      es: 'Corticoide sintético de elevada potencia antiinflamatoria y acción prolongada, con efecto mineralocorticoide mínimo.',
      en: 'Synthetic corticosteroid with high anti-inflammatory potency and prolonged action, with minimal mineralocorticoid effect.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a la prevenció de nàusees postoperatòries, l\'edema cerebral, i múltiples processos inflamatoris i al·lèrgics.',
      es: 'Se usa para la prevención de náuseas postoperatorias, el edema cerebral, y múltiples procesos inflamatorios y alérgicos.',
      en: 'Used for prevention of postoperative nausea, cerebral edema, and multiple inflammatory and allergic conditions.',
    ),
  ),
  Drug(
    id: 'hidrocortisona',
    name: LocalizedText(ca: 'Hidrocortisona', es: 'Hidrocortisona', en: 'Hydrocortisone'),
    aliases: ['Hidrocortisona succinato sódico', 'Solu-Cortef'],
    drugClass: DrugClass.corticoide,
    routes: ['IV', 'IM', 'topical'],
    description: LocalizedText(
      ca: 'Corticoide amb activitat glucocorticoide i mineralocorticoide equilibrades, molt semblant al cortisol endogen.',
      es: 'Corticoide con actividad glucocorticoide y mineralocorticoide equilibradas, muy similar al cortisol endógeno.',
      en: 'Corticosteroid with balanced glucocorticoid and mineralocorticoid activity, very similar to endogenous cortisol.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en la insuficiència suprarenal, el xoc sèptic i reaccions al·lèrgiques greus.',
      es: 'Se usa en la insuficiencia suprarrenal, el shock séptico y reacciones alérgicas graves.',
      en: 'Used in adrenal insufficiency, septic shock, and severe allergic reactions.',
    ),
  ),
  Drug(
    id: 'metilprednisolona',
    name: LocalizedText(ca: 'Metilprednisolona', es: 'Metilprednisolona', en: 'Methylprednisolone'),
    aliases: ['Urbason', 'Solu-Medrol'],
    drugClass: DrugClass.corticoide,
    routes: ['IV', 'IM', 'Oral'],
    description: LocalizedText(
      ca: 'Corticoide sintètic d\'acció intermèdia, amb més potència antiinflamatòria que la hidrocortisona i menys efecte mineralocorticoide.',
      es: 'Corticoide sintético de acción intermedia, con mayor potencia antiinflamatoria que la hidrocortisona y menor efecto mineralocorticoide.',
      en: 'Synthetic intermediate-acting corticosteroid, with greater anti-inflammatory potency than hydrocortisone and less mineralocorticoid effect.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en processos inflamatoris i al·lèrgics greus, i en algunes exacerbacions de malalties autoimmunes.',
      es: 'Se usa en procesos inflamatorios y alérgicos graves, y en algunas exacerbaciones de enfermedades autoinmunes.',
      en: 'Used in severe inflammatory and allergic conditions, and in some flares of autoimmune diseases.',
    ),
  ),

  // Electrolitos / fluidos IV
  Drug(
    id: 'sulfato-magnesio',
    name: LocalizedText(ca: 'Sulfat de magnesi', es: 'Sulfato de magnesio', en: 'Magnesium sulfate'),
    drugClass: DrugClass.electrolitoFluido,
    routes: ['IV', 'IM'],
    description: LocalizedText(
      ca: 'Suplement d\'electròlit amb efectes a nivell neuromuscular i cardiovascular, actuant com a antagonista fisiològic del calci.',
      es: 'Suplemento de electrolito con efectos a nivel neuromuscular y cardiovascular, actuando como antagonista fisiológico del calcio.',
      en: 'Electrolyte supplement with neuromuscular and cardiovascular effects, acting as a physiological calcium antagonist.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a la prevenció i el tractament de les convulsions a la preeclàmpsia/eclàmpsia, com a tocolític, i en algunes arrítmies i la crisi asmàtica greu.',
      es: 'Se usa para la prevención y el tratamiento de las convulsiones en la preeclampsia/eclampsia, como tocolítico, y en algunas arritmias y la crisis asmática grave.',
      en: 'Used for prevention and treatment of seizures in preeclampsia/eclampsia, as a tocolytic, and in some arrhythmias and severe asthma exacerbations.',
    ),
  ),
  Drug(
    id: 'gluconato-calcio',
    name: LocalizedText(ca: 'Gluconat de calci', es: 'Gluconato de calcio', en: 'Calcium gluconate'),
    drugClass: DrugClass.electrolitoFluido,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Sal de calci que n\'aporta per via intravenosa de forma relativament suau per als teixits.',
      es: 'Sal de calcio que lo aporta por vía intravenosa de forma relativamente suave para los tejidos.',
      en: 'Calcium salt that provides it intravenously in a relatively tissue-gentle form.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en la hipocalcèmia i, de manera urgent, com a antídot cardioprotector en la hiperpotassèmia greu.',
      es: 'Se usa en la hipocalcemia y, de manera urgente, como antídoto cardioprotector en la hiperpotasemia grave.',
      en: 'Used in hypocalcemia and, urgently, as a cardioprotective antidote in severe hyperkalemia.',
    ),
  ),
  Drug(
    id: 'ringer-lactato',
    name: LocalizedText(ca: 'Ringer lactat', es: 'Ringer lactato', en: 'Lactated Ringer\'s solution'),
    aliases: ['Solución de Hartmann', 'Hartmann\'s solution'],
    drugClass: DrugClass.electrolitoFluido,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Solució cristal·loide isotònica amb una composició d\'electròlits similar a la del plasma, amb lactat com a precursor tamponador.',
      es: 'Solución cristaloide isotónica con una composición de electrolitos similar a la del plasma, con lactato como precursor tamponador.',
      en: 'Isotonic crystalloid solution with an electrolyte composition similar to plasma, with lactate as a buffering precursor.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza com a fluid de reposició estàndard en la reanimació amb líquids i el manteniment hidroelectrolític perioperatori.',
      es: 'Se usa como fluido de reposición estándar en la reanimación con líquidos y el mantenimiento hidroelectrolítico perioperatorio.',
      en: 'Used as a standard replacement fluid for fluid resuscitation and perioperative fluid/electrolyte maintenance.',
    ),
  ),
  Drug(
    id: 'dextrano-40',
    name: LocalizedText(ca: 'Dextrà 40', es: 'Dextrano 40', en: 'Dextran 40'),
    drugClass: DrugClass.electrolitoFluido,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Col·loide format per un polisacàrid de glucosa, utilitzat per expandir el volum plasmàtic.',
      es: 'Coloide formado por un polisacárido de glucosa, utilizado para expandir el volumen plasmático.',
      en: 'Colloid made of a glucose polysaccharide, used to expand plasma volume.',
    ),
    use: LocalizedText(
      ca: 'S\'ha utilitzat com a expansor de volum plasmàtic i amb finalitat antitrombòtica en cirurgia vascular; el seu ús ha disminuït per risc de reaccions al·lèrgiques i interferència amb la coagulació.',
      es: 'Se ha usado como expansor de volumen plasmático y con fin antitrombótico en cirugía vascular; su uso ha disminuido por riesgo de reacciones alérgicas e interferencia con la coagulación.',
      en: 'Used as a plasma volume expander and for antithrombotic purposes in vascular surgery; its use has declined due to the risk of allergic reactions and interference with coagulation.',
    ),
  ),
  Drug(
    id: 'hidroxietilalmidon',
    name: LocalizedText(ca: 'Hidroxietilamidó', es: 'Hidroxietilalmidón', en: 'Hydroxyethyl starch (HES)'),
    aliases: ['HES', 'Voluven'],
    drugClass: DrugClass.electrolitoFluido,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Col·loide sintètic derivat del midó, utilitzat per expandir el volum plasmàtic amb un efecte més perllongat que els cristal·loides.',
      es: 'Coloide sintético derivado del almidón, utilizado para expandir el volumen plasmático con un efecto más prolongado que los cristaloides.',
      en: 'Synthetic starch-derived colloid, used to expand plasma volume with a longer-lasting effect than crystalloids.',
    ),
    use: LocalizedText(
      ca: 'S\'ha utilitzat en la reanimació amb líquids durant la cirurgia.',
      es: 'Se ha usado en la reanimación con líquidos durante la cirugía.',
      en: 'Used in intraoperative fluid resuscitation.',
    ),
    tip: LocalizedText(
      ca: 'L\'Agència Europea del Medicament en restringeix l\'ús en pacients sèptics, cremats o crítics per risc de lesió renal.',
      es: 'La Agencia Europea del Medicamento restringe su uso en pacientes sépticos, quemados o críticos por riesgo de lesión renal.',
      en: 'The European Medicines Agency restricts its use in septic, burn, or critically ill patients due to the risk of kidney injury.',
    ),
  ),
  Drug(
    id: 'manitol',
    name: LocalizedText(ca: 'Manitol', es: 'Manitol', en: 'Mannitol'),
    drugClass: DrugClass.electrolitoFluido,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Diürètic osmòtic que augmenta l\'osmolaritat plasmàtica, atraient aigua des dels teixits (inclòs el cervell) cap al compartiment vascular.',
      es: 'Diurético osmótico que aumenta la osmolaridad plasmática, atrayendo agua desde los tejidos (incluido el cerebro) hacia el compartimento vascular.',
      en: 'Osmotic diuretic that increases plasma osmolarity, drawing water from tissues (including the brain) into the vascular compartment.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per reduir la pressió intracranial en l\'edema cerebral i, de vegades, en el glaucoma agut.',
      es: 'Se usa para reducir la presión intracraneal en el edema cerebral y, en ocasiones, en el glaucoma agudo.',
      en: 'Used to reduce intracranial pressure in cerebral edema and, occasionally, in acute glaucoma.',
    ),
  ),
  Drug(
    id: 'bicarbonato-sodico',
    name: LocalizedText(ca: 'Bicarbonat sòdic', es: 'Bicarbonato sódico', en: 'Sodium bicarbonate'),
    drugClass: DrugClass.electrolitoFluido,
    routes: ['IV', 'Oral'],
    description: LocalizedText(
      ca: 'Agent alcalinitzant que neutralitza l\'acidosi metabòlica.',
      es: 'Agente alcalinizante que neutraliza la acidosis metabólica.',
      en: 'Alkalinizing agent that neutralizes metabolic acidosis.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en l\'acidosi metabòlica greu i, en alguns protocols, en la hiperpotassèmia o la toxicitat per antidepressius tricíclics.',
      es: 'Se usa en la acidosis metabólica grave y, en algunos protocolos, en la hiperpotasemia o la toxicidad por antidepresivos tricíclicos.',
      en: 'Used in severe metabolic acidosis and, in some protocols, in hyperkalemia or tricyclic antidepressant toxicity.',
    ),
  ),
  Drug(
    id: 'cloruro-potasico',
    name: LocalizedText(ca: 'Clorur potàssic', es: 'Cloruro potásico', en: 'Potassium chloride'),
    drugClass: DrugClass.electrolitoFluido,
    routes: ['IV', 'Oral'],
    description: LocalizedText(
      ca: 'Suplement de potassi, un electròlit essencial per a l\'excitabilitat neuromuscular i cardíaca.',
      es: 'Suplemento de potasio, un electrolito esencial para la excitabilidad neuromuscular y cardíaca.',
      en: 'Potassium supplement, an electrolyte essential for neuromuscular and cardiac excitability.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per corregir la hipopotassèmia.',
      es: 'Se usa para corregir la hipopotasemia.',
      en: 'Used to correct hypokalemia.',
    ),
    tip: LocalizedText(
      ca: 'La via IV s\'ha d\'administrar sempre diluïda i amb monitorització, mai en bol directe, pel risc d\'arítmia greu.',
      es: 'La vía IV debe administrarse siempre diluida y con monitorización, nunca en bolo directo, por el riesgo de arritmia grave.',
      en: 'The IV route must always be given diluted and with monitoring, never as a direct bolus, due to the risk of severe arrhythmia.',
    ),
  ),

  // Vasopresores / inotrópicos (ampliación)
  Drug(
    id: 'adrenalina',
    name: LocalizedText(ca: 'Adrenalina', es: 'Adrenalina', en: 'Epinephrine (adrenaline)'),
    aliases: ['Epinefrina', 'Epinephrine'],
    drugClass: DrugClass.vasopresor,
    routes: ['IV', 'IM', 'nebulized'],
    description: LocalizedText(
      ca: 'Catecolamina endògena amb efecte agonista alfa i beta adrenèrgic combinat, amb efecte vasopressor, inotròpic i broncodilatador.',
      es: 'Catecolamina endógena con efecto agonista alfa y beta adrenérgico combinado, con efecto vasopresor, inotrópico y broncodilatador.',
      en: 'Endogenous catecholamine with combined alpha and beta adrenergic agonist effect, with vasopressor, inotropic, and bronchodilator actions.',
    ),
    use: LocalizedText(
      ca: 'És el fàrmac de primera línia a l\'anafilaxi i a la reanimació cardiopulmonar, i s\'utilitza també com a vasopressor en el xoc.',
      es: 'Es el fármaco de primera línea en la anafilaxia y en la reanimación cardiopulmonar, y se usa también como vasopresor en el shock.',
      en: 'It is the first-line drug in anaphylaxis and in cardiopulmonary resuscitation, and is also used as a vasopressor in shock.',
    ),
  ),
  Drug(
    id: 'isoprenalina',
    name: LocalizedText(ca: 'Isoprenalina', es: 'Isoprenalina', en: 'Isoprenaline (isoproterenol)'),
    aliases: ['Isoproterenol'],
    drugClass: DrugClass.vasopresor,
    routes: ['IV'],
    description: LocalizedText(
      ca: 'Agonista beta adrenèrgic pur, sense efecte alfa, amb un marcat efecte cronotròpic positiu.',
      es: 'Agonista beta adrenérgico puro, sin efecto alfa, con un marcado efecto cronotrópico positivo.',
      en: 'Pure beta-adrenergic agonist, without alpha effect, with a marked positive chronotropic effect.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en la bradicàrdia simptomàtica greu, mentre s\'organitza un marcapassos, quan l\'atropina no és suficient.',
      es: 'Se usa en la bradicardia sintomática grave, mientras se organiza un marcapasos, cuando la atropina no es suficiente.',
      en: 'Used in severe symptomatic bradycardia, while a pacemaker is arranged, when atropine is not sufficient.',
    ),
  ),
  Drug(
    id: 'dopamina',
    name: LocalizedText(ca: 'Dopamina', es: 'Dopamina', en: 'Dopamine'),
    drugClass: DrugClass.vasopresor,
    routes: ['IV', 'continuous infusion'],
    description: LocalizedText(
      ca: 'Catecolamina endògena precursora de la noradrenalina, amb un efecte dependent de la dosi sobre receptors dopaminèrgics, beta i alfa adrenèrgics.',
      es: 'Catecolamina endógena precursora de la noradrenalina, con un efecto dependiente de la dosis sobre receptores dopaminérgicos, beta y alfa adrenérgicos.',
      en: 'Endogenous catecholamine, a precursor of norepinephrine, with a dose-dependent effect on dopaminergic, beta, and alpha adrenergic receptors.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en el xoc i la hipotensió, encara que ha estat substituïda en bona part per la noradrenalina com a vasopressor de primera línia.',
      es: 'Se usa en el shock y la hipotensión, aunque ha sido sustituida en buena parte por la noradrenalina como vasopresor de primera línea.',
      en: 'Used in shock and hypotension, although it has largely been replaced by norepinephrine as the first-line vasopressor.',
    ),
  ),
  Drug(
    id: 'dobutamina',
    name: LocalizedText(ca: 'Dobutamina', es: 'Dobutamina', en: 'Dobutamine'),
    drugClass: DrugClass.vasopresor,
    routes: ['IV', 'continuous infusion'],
    description: LocalizedText(
      ca: 'Agonista beta-1 adrenèrgic predominant, amb un efecte inotròpic positiu marcat i un efecte vasopressor mínim o nul.',
      es: 'Agonista beta-1 adrenérgico predominante, con un efecto inotrópico positivo marcado y un efecto vasopresor mínimo o nulo.',
      en: 'Predominantly beta-1 adrenergic agonist, with a marked positive inotropic effect and minimal or no vasopressor effect.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en la insuficiència cardíaca aguda i el xoc cardiogènic per augmentar el gasto cardíac.',
      es: 'Se usa en la insuficiencia cardíaca aguda y el shock cardiogénico para aumentar el gasto cardíaco.',
      en: 'Used in acute heart failure and cardiogenic shock to increase cardiac output.',
    ),
  ),

  // Cardiovascular (antihipertensivo / antiarrítmico)
  Drug(
    id: 'nitroprusiato-sodico',
    name: LocalizedText(ca: 'Nitroprussiat sòdic', es: 'Nitroprusiato sódico', en: 'Sodium nitroprusside'),
    drugClass: DrugClass.antihipertensivoCardiovascular,
    routes: ['IV', 'continuous infusion'],
    description: LocalizedText(
      ca: 'Vasodilatador arterial i venós d\'acció molt ràpida, que allibera òxid nítric.',
      es: 'Vasodilatador arterial y venoso de acción muy rápida, que libera óxido nítrico.',
      en: 'Very fast-acting arterial and venous vasodilator that releases nitric oxide.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en les emergències hipertensives i la hipotensió controlada durant la cirurgia.',
      es: 'Se usa en las emergencias hipertensivas y la hipotensión controlada durante la cirugía.',
      en: 'Used in hypertensive emergencies and controlled hypotension during surgery.',
    ),
    tip: LocalizedText(
      ca: 'El seu metabolisme allibera cianur, per la qual cosa l\'ús perllongat o a dosis altes comporta risc de toxicitat per cianur.',
      es: 'Su metabolismo libera cianuro, por lo que su uso prolongado o a dosis altas conlleva riesgo de toxicidad por cianuro.',
      en: 'Its metabolism releases cyanide, so prolonged or high-dose use carries a risk of cyanide toxicity.',
    ),
  ),
  Drug(
    id: 'nitroglicerina',
    name: LocalizedText(ca: 'Nitroglicerina', es: 'Nitroglicerina', en: 'Nitroglycerin'),
    aliases: ['Trinitrato de glicerilo', 'Glyceryl trinitrate'],
    drugClass: DrugClass.antihipertensivoCardiovascular,
    routes: ['IV', 'sublingual', 'topical', 'continuous infusion'],
    description: LocalizedText(
      ca: 'Nitrat orgànic vasodilatador, predominantment venós a dosis baixes, que allibera òxid nítric.',
      es: 'Nitrato orgánico vasodilatador, predominantemente venoso a dosis bajas, que libera óxido nítrico.',
      en: 'Vasodilating organic nitrate, predominantly venous at low doses, which releases nitric oxide.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza a l\'angina de pit i la isquèmia miocàrdica, i a la insuficiència cardíaca aguda.',
      es: 'Se usa en la angina de pecho y la isquemia miocárdica, y en la insuficiencia cardíaca aguda.',
      en: 'Used in angina pectoris and myocardial ischemia, and in acute heart failure.',
    ),
  ),
  Drug(
    id: 'amiodarona',
    name: LocalizedText(ca: 'Amiodarona', es: 'Amiodarona', en: 'Amiodarone'),
    aliases: ['Trangorex'],
    drugClass: DrugClass.antihipertensivoCardiovascular,
    routes: ['IV', 'Oral'],
    description: LocalizedText(
      ca: 'Antiarítmic de classe III que allarga la durada del potencial d\'acció cardíac, tot i tenir també propietats d\'altres classes.',
      es: 'Antiarrítmico de clase III que alarga la duración del potencial de acción cardíaco, aunque también tiene propiedades de otras clases.',
      en: 'Class III antiarrhythmic that prolongs the duration of the cardiac action potential, although it also has properties of other classes.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en arítmies ventriculars i supraventriculars greus, incloent-hi la fibril·lació auricular i l\'aturada cardíaca per fibril·lació ventricular refractària.',
      es: 'Se usa en arritmias ventriculares y supraventriculares graves, incluyendo la fibrilación auricular y la parada cardíaca por fibrilación ventricular refractaria.',
      en: 'Used in severe ventricular and supraventricular arrhythmias, including atrial fibrillation and cardiac arrest due to refractory ventricular fibrillation.',
    ),
    tip: LocalizedText(
      ca: 'Conté iode a la seva estructura i pot alterar la funció tiroïdal amb l\'ús perllongat.',
      es: 'Contiene yodo en su estructura y puede alterar la función tiroidea con el uso prolongado.',
      en: 'It contains iodine in its structure and can alter thyroid function with prolonged use.',
    ),
  ),

  // Anticolinérgicos
  Drug(
    id: 'atropina',
    name: LocalizedText(ca: 'Atropina', es: 'Atropina', en: 'Atropine'),
    drugClass: DrugClass.anticolinergico,
    routes: ['IV', 'IM'],
    description: LocalizedText(
      ca: 'Antagonista dels receptors muscarínics de l\'acetilcolina, que bloqueja els efectes parasimpàtics.',
      es: 'Antagonista de los receptores muscarínicos de la acetilcolina, que bloquea los efectos parasimpáticos.',
      en: 'Muscarinic acetylcholine receptor antagonist that blocks parasympathetic effects.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en la bradicàrdia simptomàtica, com a antídot a la intoxicació per organofosforats, i per contrarestar els efectes colinèrgics de la neostigmina.',
      es: 'Se usa en la bradicardia sintomática, como antídoto en la intoxicación por organofosforados, y para contrarrestar los efectos colinérgicos de la neostigmina.',
      en: 'Used in symptomatic bradycardia, as an antidote in organophosphate poisoning, and to counteract the cholinergic effects of neostigmine.',
    ),
  ),
  Drug(
    id: 'glicopirronio',
    name: LocalizedText(ca: 'Glicopirroni', es: 'Glicopirronio', en: 'Glycopyrronium (glycopyrrolate)'),
    aliases: ['Glicopirrolato', 'Glycopyrrolate'],
    drugClass: DrugClass.anticolinergico,
    routes: ['IV', 'IM'],
    description: LocalizedText(
      ca: 'Antagonista muscarínic similar a l\'atropina, però que no travessa la barrera hematoencefàlica.',
      es: 'Antagonista muscarínico similar a la atropina, pero que no atraviesa la barrera hematoencefálica.',
      en: 'Muscarinic antagonist similar to atropine, but which does not cross the blood-brain barrier.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per reduir les secrecions abans de l\'anestèsia i per contrarestar els efectes colinèrgics de la neostigmina.',
      es: 'Se usa para reducir las secreciones antes de la anestesia y para contrarrestar los efectos colinérgicos de la neostigmina.',
      en: 'Used to reduce secretions before anesthesia and to counteract the cholinergic effects of neostigmine.',
    ),
  ),

  // Diuréticos
  Drug(
    id: 'furosemida',
    name: LocalizedText(ca: 'Furosemida', es: 'Furosemida', en: 'Furosemide'),
    aliases: ['Seguril'],
    drugClass: DrugClass.diuretico,
    routes: ['IV', 'Oral', 'IM'],
    description: LocalizedText(
      ca: 'Diürètic de nansa que inhibeix la reabsorció de sodi i clor a la porció ascendent de l\'ansa de Henle.',
      es: 'Diurético de asa que inhibe la reabsorción de sodio y cloro en la porción ascendente del asa de Henle.',
      en: 'Loop diuretic that inhibits sodium and chloride reabsorption in the ascending limb of the loop of Henle.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en la sobrecàrrega de líquids, la insuficiència cardíaca i l\'edema de diversos orígens.',
      es: 'Se usa en la sobrecarga de líquidos, la insuficiencia cardíaca y el edema de diversos orígenes.',
      en: 'Used in fluid overload, heart failure, and edema of various origins.',
    ),
  ),

  // Antipsicóticos
  Drug(
    id: 'clorpromazina',
    name: LocalizedText(ca: 'Clorpromazina', es: 'Clorpromazina', en: 'Chlorpromazine'),
    aliases: ['Largactil'],
    drugClass: DrugClass.antipsicotico,
    routes: ['Oral', 'IM', 'IV'],
    description: LocalizedText(
      ca: 'Antipsicòtic de primera generació (típic), antagonista dopaminèrgic, amb efecte sedant i antiemètic afegits.',
      es: 'Antipsicótico de primera generación (típico), antagonista dopaminérgico, con efecto sedante y antiemético añadidos.',
      en: 'First-generation (typical) antipsychotic, a dopamine antagonist, with added sedative and antiemetic effects.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en l\'agitació psicòtica greu i, històricament, en el singlot persistent i les nàusees refractàries.',
      es: 'Se usa en la agitación psicótica grave y, históricamente, en el hipo persistente y las náuseas refractarias.',
      en: 'Used in severe psychotic agitation and, historically, in persistent hiccups and refractory nausea.',
    ),
  ),
  Drug(
    id: 'haloperidol',
    name: LocalizedText(ca: 'Haloperidol', es: 'Haloperidol', en: 'Haloperidol'),
    aliases: ['Haloperidol Esteve'],
    drugClass: DrugClass.antipsicotico,
    routes: ['Oral', 'IM', 'IV'],
    description: LocalizedText(
      ca: 'Antipsicòtic de primera generació (típic) d\'alta potència, antagonista dopaminèrgic.',
      es: 'Antipsicótico de primera generación (típico) de alta potencia, antagonista dopaminérgico.',
      en: 'High-potency first-generation (typical) antipsychotic, a dopamine antagonist.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en l\'agitació aguda i el deliri, i com a antiemètic en nàusees refractàries.',
      es: 'Se usa en la agitación aguda y el delirio, y como antiemético en náuseas refractarias.',
      en: 'Used in acute agitation and delirium, and as an antiemetic in refractory nausea.',
    ),
    tip: LocalizedText(
      ca: 'S\'associa a risc de prolongació de l\'interval QT i, a dosis altes, a símptomes extrapiramidals.',
      es: 'Se asocia a riesgo de prolongación del intervalo QT y, a dosis altas, a síntomas extrapiramidales.',
      en: 'Associated with a risk of QT interval prolongation and, at high doses, extrapyramidal symptoms.',
    ),
  ),

  // Anticonvulsivantes
  Drug(
    id: 'fenitoina',
    name: LocalizedText(ca: 'Fenitoïna', es: 'Fenitoína', en: 'Phenytoin'),
    aliases: ['Epanutin', 'Sinergina'],
    drugClass: DrugClass.anticonvulsivo,
    routes: ['IV', 'Oral'],
    description: LocalizedText(
      ca: 'Anticonvulsivant que estabilitza les membranes neuronals bloquejant els canals de sodi dependents de voltatge.',
      es: 'Anticonvulsivante que estabiliza las membranas neuronales bloqueando los canales de sodio dependientes de voltaje.',
      en: 'Anticonvulsant that stabilizes neuronal membranes by blocking voltage-gated sodium channels.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza en el tractament i la prevenció de les convulsions, incloent-hi l\'estatus epilèptic.',
      es: 'Se usa en el tratamiento y la prevención de las convulsiones, incluyendo el estatus epiléptico.',
      en: 'Used in the treatment and prevention of seizures, including status epilepticus.',
    ),
    tip: LocalizedText(
      ca: 'Té un marge terapèutic estret i una farmacocinètica no lineal, per la qual cosa se sol monitoritzar-ne el nivell plasmàtic.',
      es: 'Tiene un margen terapéutico estrecho y una farmacocinética no lineal, por lo que suele monitorizarse su nivel plasmático.',
      en: 'It has a narrow therapeutic margin and non-linear pharmacokinetics, so its plasma level is usually monitored.',
    ),
  ),

  // Anticoagulantes / hemostáticos
  Drug(
    id: 'acido-tranexamico',
    name: LocalizedText(ca: 'Àcid tranexàmic', es: 'Ácido tranexámico', en: 'Tranexamic acid'),
    aliases: ['Amchafibrin'],
    drugClass: DrugClass.anticoagulanteHemostatico,
    routes: ['IV', 'Oral', 'topical'],
    description: LocalizedText(
      ca: 'Agent antifibrinolític que inhibeix l\'activació del plasminogen, reduint la degradació dels coàguls de fibrina.',
      es: 'Agente antifibrinolítico que inhibe la activación del plasminógeno, reduciendo la degradación de los coágulos de fibrina.',
      en: 'Antifibrinolytic agent that inhibits plasminogen activation, reducing the breakdown of fibrin clots.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per reduir l\'hemorràgia en traumatismes greus, hemorràgia postpart i cirurgies amb risc de sagnat important.',
      es: 'Se usa para reducir la hemorragia en traumatismos graves, hemorragia posparto y cirugías con riesgo de sangrado importante.',
      en: 'Used to reduce bleeding in major trauma, postpartum hemorrhage, and surgeries with significant bleeding risk.',
    ),
  ),
  Drug(
    id: 'heparina-sodica',
    name: LocalizedText(ca: 'Heparina sòdica', es: 'Heparina sódica', en: 'Heparin sodium'),
    drugClass: DrugClass.anticoagulanteHemostatico,
    routes: ['IV', 'subcutaneous'],
    description: LocalizedText(
      ca: 'Anticoagulant que potencia l\'acció de l\'antitrombina III, inhibint diversos factors de la coagulació.',
      es: 'Anticoagulante que potencia la acción de la antitrombina III, inhibiendo varios factores de la coagulación.',
      en: 'Anticoagulant that potentiates the action of antithrombin III, inhibiting several clotting factors.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a la prevenció i el tractament de la trombosi venosa, i per anticoagular durant procediments com la circulació extracorpòria.',
      es: 'Se usa para la prevención y el tratamiento de la trombosis venosa, y para anticoagular durante procedimientos como la circulación extracorpórea.',
      en: 'Used for prevention and treatment of venous thrombosis, and for anticoagulation during procedures such as extracorporeal circulation.',
    ),
    tip: LocalizedText(
      ca: 'El seu efecte es pot revertir amb protamina, i es pot monitoritzar amb el temps de tromboplastina parcial activat (TTPa).',
      es: 'Su efecto puede revertirse con protamina, y puede monitorizarse con el tiempo de tromboplastina parcial activado (TTPa).',
      en: 'Its effect can be reversed with protamine, and can be monitored with activated partial thromboplastin time (aPTT).',
    ),
  ),

  // Antidiabéticos
  Drug(
    id: 'insulina-regular',
    name: LocalizedText(ca: 'Insulina regular', es: 'Insulina regular', en: 'Regular insulin'),
    aliases: ['Insulina soluble', 'Soluble insulin', 'Actrapid'],
    drugClass: DrugClass.antidiabetico,
    routes: ['IV', 'subcutaneous'],
    description: LocalizedText(
      ca: 'Insulina humana d\'acció curta, d\'inici relativament ràpid i durada breu en comparació amb les formulacions d\'acció intermèdia o llarga.',
      es: 'Insulina humana de acción corta, de inicio relativamente rápido y duración breve en comparación con las formulaciones de acción intermedia o larga.',
      en: 'Short-acting human insulin, with a relatively fast onset and brief duration compared to intermediate- or long-acting formulations.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per al control de la glucèmia, incloent-hi les pautes d\'infusió intravenosa a l\'hospital i el tractament de la cetoacidosi diabètica.',
      es: 'Se usa para el control de la glucemia, incluyendo las pautas de infusión intravenosa en el hospital y el tratamiento de la cetoacidosis diabética.',
      en: 'Used for glycemic control, including intravenous infusion regimens in hospital and treatment of diabetic ketoacidosis.',
    ),
  ),
  Drug(
    id: 'insulina-nph',
    name: LocalizedText(ca: 'Insulina NPH', es: 'Insulina NPH', en: 'NPH insulin (isophane)'),
    aliases: ['Insulina isófana', 'Isophane insulin', 'Insulatard'],
    drugClass: DrugClass.antidiabetico,
    routes: ['subcutaneous'],
    description: LocalizedText(
      ca: 'Insulina humana d\'acció intermèdia, formulada amb protamina per alentir-ne l\'absorció i perllongar-ne l\'efecte.',
      es: 'Insulina humana de acción intermedia, formulada con protamina para enlentecer su absorción y prolongar su efecto.',
      en: 'Intermediate-acting human insulin, formulated with protamine to slow its absorption and prolong its effect.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza com a insulina basal en el tractament de manteniment de la diabetis.',
      es: 'Se usa como insulina basal en el tratamiento de mantenimiento de la diabetes.',
      en: 'Used as basal insulin in the maintenance treatment of diabetes.',
    ),
  ),

  // Antieméticos (ampliación)
  Drug(
    id: 'metoclopramida',
    name: LocalizedText(ca: 'Metoclopramida', es: 'Metoclopramida', en: 'Metoclopramide'),
    aliases: ['Primperan'],
    drugClass: DrugClass.antiemetico,
    routes: ['IV', 'Oral', 'IM'],
    description: LocalizedText(
      ca: 'Antagonista dopaminèrgic amb efecte procinètic (augmenta el buidament gàstric) i antiemètic.',
      es: 'Antagonista dopaminérgico con efecto procinético (aumenta el vaciado gástrico) y antiemético.',
      en: 'Dopamine antagonist with prokinetic (increases gastric emptying) and antiemetic effects.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a les nàusees i els vòmits, i en afeccions amb buidament gàstric alentit.',
      es: 'Se usa para las náuseas y los vómitos, y en afecciones con vaciado gástrico enlentecido.',
      en: 'Used for nausea and vomiting, and in conditions with delayed gastric emptying.',
    ),
    tip: LocalizedText(
      ca: 'El seu ús perllongat s\'associa a risc de símptomes extrapiramidals.',
      es: 'Su uso prolongado se asocia a riesgo de síntomas extrapiramidales.',
      en: 'Prolonged use is associated with a risk of extrapyramidal symptoms.',
    ),
  ),
  Drug(
    id: 'domperidona',
    name: LocalizedText(ca: 'Domperidona', es: 'Domperidona', en: 'Domperidone'),
    aliases: ['Motilium'],
    drugClass: DrugClass.antiemetico,
    routes: ['Oral'],
    description: LocalizedText(
      ca: 'Antagonista dopaminèrgic perifèric amb efecte procinètic i antiemètic, amb poca penetració al sistema nerviós central.',
      es: 'Antagonista dopaminérgico periférico con efecto procinético y antiemético, con poca penetración en el sistema nervioso central.',
      en: 'Peripheral dopamine antagonist with prokinetic and antiemetic effects, with little central nervous system penetration.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a les nàusees, els vòmits i la sensació de plenitud gàstrica.',
      es: 'Se usa para las náuseas, los vómitos y la sensación de plenitud gástrica.',
      en: 'Used for nausea, vomiting, and a sensation of gastric fullness.',
    ),
    tip: LocalizedText(
      ca: 'En comparació amb la metoclopramida, té menys risc d\'efectes extrapiramidals perquè travessa poc la barrera hematoencefàlica.',
      es: 'En comparación con la metoclopramida, tiene menor riesgo de efectos extrapiramidales porque atraviesa poco la barrera hematoencefálica.',
      en: 'Compared with metoclopramide, it carries a lower risk of extrapyramidal effects because it crosses the blood-brain barrier poorly.',
    ),
  ),

  // Sedantes (ampliación)
  Drug(
    id: 'diazepam',
    name: LocalizedText(ca: 'Diazepam', es: 'Diazepam', en: 'Diazepam'),
    aliases: ['Valium'],
    drugClass: DrugClass.sedante,
    routes: ['Oral', 'IV', 'IM', 'rectal'],
    description: LocalizedText(
      ca: 'Benzodiazepina d\'acció llarga, amb metabòlits actius que en perllonguen l\'efecte.',
      es: 'Benzodiacepina de acción larga, con metabolitos activos que prolongan su efecto.',
      en: 'Long-acting benzodiazepine, with active metabolites that prolong its effect.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a l\'ansietat, com a relaxant muscular, i en el tractament de les convulsions i l\'abstinència alcohòlica.',
      es: 'Se usa para la ansiedad, como relajante muscular, y en el tratamiento de las convulsiones y la abstinencia alcohólica.',
      en: 'Used for anxiety, as a muscle relaxant, and in the treatment of seizures and alcohol withdrawal.',
    ),
    tip: LocalizedText(
      ca: 'Com el midazolam, el seu efecte es pot revertir amb flumazenil.',
      es: 'Como el midazolam, su efecto puede revertirse con flumazenilo.',
      en: 'Like midazolam, its effect can be reversed with flumazenil.',
    ),
  ),
];
