import '../models/clinical_scale.dart';
import '../models/instrument.dart' show LocalizedText;

/// Escales de valoració amb càlcul guiat. Ítems i punts segons la
/// referència original de cada escala; text propi. Mai dosis.
const List<ClinicalScale> kClinicalScales = [
  ClinicalScale(
    id: 'asa',
    name: LocalizedText(ca: 'Classificació ASA', es: 'Clasificación ASA', en: 'ASA physical status'),
    area: ScaleArea.preanestesia,
    description: LocalizedText(ca: 'Estat físic del pacient abans de l\'anestèsia. No mesura el risc de la cirurgia en si. S\'hi afegeix una «E» si la intervenció és urgent.', es: 'Estado físico del paciente antes de la anestesia. No mide el riesgo de la cirugía en sí. Se añade una «E» si la intervención es urgente.', en: 'The patient\'s physical status before anaesthesia. It does not measure the risk of the operation itself. An "E" is added for emergency surgery.'),
    classification: true,
    reference: 'American Society of Anesthesiologists. ASA Physical Status Classification System (última actualització 2020).',
    items: [
      ScaleItem(LocalizedText(ca: 'Estat físic', es: 'Estado físico', en: 'Physical status'), [
        ScaleOption(1, LocalizedText(ca: 'ASA I — Pacient sa', es: 'ASA I — Paciente sano', en: 'ASA I — Healthy patient')),
        ScaleOption(2, LocalizedText(ca: 'ASA II — Malaltia sistèmica lleu, sense limitació funcional', es: 'ASA II — Enfermedad sistémica leve, sin limitación funcional', en: 'ASA II — Mild systemic disease, no functional limitation')),
        ScaleOption(3, LocalizedText(ca: 'ASA III — Malaltia sistèmica greu, amb limitació funcional', es: 'ASA III — Enfermedad sistémica grave, con limitación funcional', en: 'ASA III — Severe systemic disease with functional limitation')),
        ScaleOption(4, LocalizedText(ca: 'ASA IV — Malaltia sistèmica greu que és una amenaça constant per a la vida', es: 'ASA IV — Enfermedad sistémica grave que es una amenaza constante para la vida', en: 'ASA IV — Severe systemic disease that is a constant threat to life')),
        ScaleOption(5, LocalizedText(ca: 'ASA V — Pacient moribund que no sobreviurà sense la intervenció', es: 'ASA V — Paciente moribundo que no sobrevivirá sin la intervención', en: 'ASA V — Moribund patient not expected to survive without the operation')),
        ScaleOption(6, LocalizedText(ca: 'ASA VI — Mort encefàlica, donant d\'òrgans', es: 'ASA VI — Muerte encefálica, donante de órganos', en: 'ASA VI — Brain-dead organ donor')),
      ]),
    ],
    bands: [
    ],
  ),
  ClinicalScale(
    id: 'mallampati',
    name: LocalizedText(ca: 'Mallampati', es: 'Mallampati', en: 'Mallampati'),
    area: ScaleArea.preanestesia,
    description: LocalizedText(ca: 'Prediu la dificultat d\'intubació segons el que es veu de la faringe amb el pacient assegut, la boca ben oberta i la llengua fora, sense fonar.', es: 'Predice la dificultad de intubación según lo que se ve de la faringe con el paciente sentado, la boca bien abierta y la lengua fuera, sin fonar.', en: 'Predicts difficult intubation from what is visible of the pharynx with the patient sitting, mouth wide open and tongue out, without phonation.'),
    classification: true,
    reference: 'Mallampati SR et al. Can Anaesth Soc J 1985; modificada per Samsoon GL, Young JR. Anaesthesia 1987.',
    items: [
      ScaleItem(LocalizedText(ca: 'Què es veu', es: 'Qué se ve', en: 'What is visible'), [
        ScaleOption(1, LocalizedText(ca: 'Classe I — Paladar tou, istme de les faus, úvula i pilars', es: 'Clase I — Paladar blando, istmo de las fauces, úvula y pilares', en: 'Class I — Soft palate, fauces, uvula and pillars')),
        ScaleOption(2, LocalizedText(ca: 'Classe II — Paladar tou, istme de les faus i úvula', es: 'Clase II — Paladar blando, istmo de las fauces y úvula', en: 'Class II — Soft palate, fauces and uvula')),
        ScaleOption(3, LocalizedText(ca: 'Classe III — Paladar tou i base de l\'úvula', es: 'Clase III — Paladar blando y base de la úvula', en: 'Class III — Soft palate and base of the uvula')),
        ScaleOption(4, LocalizedText(ca: 'Classe IV — Només el paladar dur', es: 'Clase IV — Solo el paladar duro', en: 'Class IV — Hard palate only')),
      ]),
    ],
    bands: [
      ScaleBand(1, 2, LocalizedText(ca: 'Intubació previsiblement fàcil', es: 'Intubación previsiblemente fácil', en: 'Intubation expected to be easy')),
      ScaleBand(3, 4, LocalizedText(ca: 'Possible via aèria difícil: avisar i tenir a punt el carro', es: 'Posible vía aérea difícil: avisar y tener preparado el carro', en: 'Possible difficult airway: warn the team and have the trolley ready')),
    ],
  ),
  ClinicalScale(
    id: 'stop-bang',
    name: LocalizedText(ca: 'STOP-Bang', es: 'STOP-Bang', en: 'STOP-Bang'),
    area: ScaleArea.preanestesia,
    description: LocalizedText(ca: 'Cribratge d\'apnea obstructiva de la son abans de la cirurgia. Un risc alt fa preveure via aèria difícil i més complicacions respiratòries a la URPA.', es: 'Cribado de apnea obstructiva del sueño antes de la cirugía. Un riesgo alto hace prever vía aérea difícil y más complicaciones respiratorias en la URPA.', en: 'Pre-operative screening for obstructive sleep apnoea. High risk predicts difficult airway and more respiratory complications in recovery.'),
    reference: 'Chung F et al. Anesthesiology 2008;108:812-21.',
    items: [
      ScaleItem(LocalizedText(ca: 'Ronca fort (se sent amb la porta tancada)', es: 'Ronca fuerte (se oye con la puerta cerrada)', en: 'Snores loudly (heard through a closed door)'), [
        ScaleOption(0, LocalizedText(ca: 'No', es: 'No', en: 'No')),
        ScaleOption(1, LocalizedText(ca: 'Sí', es: 'Sí', en: 'Yes')),
      ]),
      ScaleItem(LocalizedText(ca: 'Cansament o somnolència durant el dia', es: 'Cansancio o somnolencia durante el día', en: 'Daytime tiredness or sleepiness'), [
        ScaleOption(0, LocalizedText(ca: 'No', es: 'No', en: 'No')),
        ScaleOption(1, LocalizedText(ca: 'Sí', es: 'Sí', en: 'Yes')),
      ]),
      ScaleItem(LocalizedText(ca: 'Algú l\'ha vist deixar de respirar dormint', es: 'Alguien le ha visto dejar de respirar dormido', en: 'Observed to stop breathing during sleep'), [
        ScaleOption(0, LocalizedText(ca: 'No', es: 'No', en: 'No')),
        ScaleOption(1, LocalizedText(ca: 'Sí', es: 'Sí', en: 'Yes')),
      ]),
      ScaleItem(LocalizedText(ca: 'Pressió arterial alta o en tractament', es: 'Presión arterial alta o en tratamiento', en: 'High blood pressure or treated for it'), [
        ScaleOption(0, LocalizedText(ca: 'No', es: 'No', en: 'No')),
        ScaleOption(1, LocalizedText(ca: 'Sí', es: 'Sí', en: 'Yes')),
      ]),
      ScaleItem(LocalizedText(ca: 'IMC superior a 35', es: 'IMC superior a 35', en: 'BMI over 35'), [
        ScaleOption(0, LocalizedText(ca: 'No', es: 'No', en: 'No')),
        ScaleOption(1, LocalizedText(ca: 'Sí', es: 'Sí', en: 'Yes')),
      ]),
      ScaleItem(LocalizedText(ca: 'Edat superior a 50 anys', es: 'Edad superior a 50 años', en: 'Age over 50'), [
        ScaleOption(0, LocalizedText(ca: 'No', es: 'No', en: 'No')),
        ScaleOption(1, LocalizedText(ca: 'Sí', es: 'Sí', en: 'Yes')),
      ]),
      ScaleItem(LocalizedText(ca: 'Perímetre del coll superior a 40 cm', es: 'Perímetro del cuello superior a 40 cm', en: 'Neck circumference over 40 cm'), [
        ScaleOption(0, LocalizedText(ca: 'No', es: 'No', en: 'No')),
        ScaleOption(1, LocalizedText(ca: 'Sí', es: 'Sí', en: 'Yes')),
      ]),
      ScaleItem(LocalizedText(ca: 'Sexe masculí', es: 'Sexo masculino', en: 'Male sex'), [
        ScaleOption(0, LocalizedText(ca: 'No', es: 'No', en: 'No')),
        ScaleOption(1, LocalizedText(ca: 'Sí', es: 'Sí', en: 'Yes')),
      ]),
    ],
    bands: [
      ScaleBand(0, 2, LocalizedText(ca: 'Risc baix', es: 'Riesgo bajo', en: 'Low risk')),
      ScaleBand(3, 4, LocalizedText(ca: 'Risc intermedi', es: 'Riesgo intermedio', en: 'Intermediate risk')),
      ScaleBand(5, 8, LocalizedText(ca: 'Risc alt', es: 'Riesgo alto', en: 'High risk')),
    ],
  ),
  ClinicalScale(
    id: 'apfel',
    name: LocalizedText(ca: 'Apfel (nàusees i vòmits postoperatoris)', es: 'Apfel (náuseas y vómitos postoperatorios)', en: 'Apfel score (PONV)'),
    area: ScaleArea.preanestesia,
    description: LocalizedText(ca: 'Risc de nàusees i vòmits postoperatoris en anestèsia general, amb quatre factors. Orienta la profilaxi que decideix l\'anestesiòleg.', es: 'Riesgo de náuseas y vómitos postoperatorios en anestesia general, con cuatro factores. Orienta la profilaxis que decide el anestesiólogo.', en: 'Risk of postoperative nausea and vomiting after general anaesthesia from four factors. It guides the prophylaxis the anaesthetist chooses.'),
    reference: 'Apfel CC et al. Anesthesiology 1999;91:693-700.',
    items: [
      ScaleItem(LocalizedText(ca: 'Sexe femení', es: 'Sexo femenino', en: 'Female sex'), [
        ScaleOption(0, LocalizedText(ca: 'No', es: 'No', en: 'No')),
        ScaleOption(1, LocalizedText(ca: 'Sí', es: 'Sí', en: 'Yes')),
      ]),
      ScaleItem(LocalizedText(ca: 'No fumador', es: 'No fumador', en: 'Non-smoker'), [
        ScaleOption(0, LocalizedText(ca: 'No', es: 'No', en: 'No')),
        ScaleOption(1, LocalizedText(ca: 'Sí', es: 'Sí', en: 'Yes')),
      ]),
      ScaleItem(LocalizedText(ca: 'Antecedents de NVPO o de mareig en viatjar', es: 'Antecedentes de NVPO o de mareo en los viajes', en: 'History of PONV or motion sickness'), [
        ScaleOption(0, LocalizedText(ca: 'No', es: 'No', en: 'No')),
        ScaleOption(1, LocalizedText(ca: 'Sí', es: 'Sí', en: 'Yes')),
      ]),
      ScaleItem(LocalizedText(ca: 'Opioides previstos després de la intervenció', es: 'Opioides previstos tras la intervención', en: 'Postoperative opioids expected'), [
        ScaleOption(0, LocalizedText(ca: 'No', es: 'No', en: 'No')),
        ScaleOption(1, LocalizedText(ca: 'Sí', es: 'Sí', en: 'Yes')),
      ]),
    ],
    bands: [
      ScaleBand(0, 0, LocalizedText(ca: 'Risc aproximat del 10 %', es: 'Riesgo aproximado del 10 %', en: 'Approximate risk 10%')),
      ScaleBand(1, 1, LocalizedText(ca: 'Risc aproximat del 20 %', es: 'Riesgo aproximado del 20 %', en: 'Approximate risk 20%')),
      ScaleBand(2, 2, LocalizedText(ca: 'Risc aproximat del 40 %', es: 'Riesgo aproximado del 40 %', en: 'Approximate risk 40%')),
      ScaleBand(3, 3, LocalizedText(ca: 'Risc aproximat del 60 %', es: 'Riesgo aproximado del 60 %', en: 'Approximate risk 60%')),
      ScaleBand(4, 4, LocalizedText(ca: 'Risc aproximat del 80 %', es: 'Riesgo aproximado del 80 %', en: 'Approximate risk 80%')),
    ],
  ),
  ClinicalScale(
    id: 'aldrete',
    name: LocalizedText(ca: 'Aldrete modificada', es: 'Aldrete modificada', en: 'Modified Aldrete score'),
    area: ScaleArea.recuperacion,
    description: LocalizedText(ca: 'Valora la recuperació a la URPA. Es puntua a l\'arribada i periòdicament fins a l\'alta.', es: 'Valora la recuperación en la URPA. Se puntúa al llegar y periódicamente hasta el alta.', en: 'Assesses recovery in the post-anaesthesia care unit, scored on arrival and regularly until discharge.'),
    reference: 'Aldrete JA. J Clin Anesth 1995;7:89-91.',
    items: [
      ScaleItem(LocalizedText(ca: 'Activitat', es: 'Actividad', en: 'Activity'), [
        ScaleOption(2, LocalizedText(ca: 'Mou les quatre extremitats', es: 'Mueve las cuatro extremidades', en: 'Moves all four limbs')),
        ScaleOption(1, LocalizedText(ca: 'Mou dues extremitats', es: 'Mueve dos extremidades', en: 'Moves two limbs')),
        ScaleOption(0, LocalizedText(ca: 'No mou cap extremitat', es: 'No mueve ninguna extremidad', en: 'Moves no limbs')),
      ]),
      ScaleItem(LocalizedText(ca: 'Respiració', es: 'Respiración', en: 'Breathing'), [
        ScaleOption(2, LocalizedText(ca: 'Respira profundament i tus', es: 'Respira profundamente y tose', en: 'Breathes deeply and coughs')),
        ScaleOption(1, LocalizedText(ca: 'Dispnea o respiració limitada', es: 'Disnea o respiración limitada', en: 'Dyspnoea or limited breathing')),
        ScaleOption(0, LocalizedText(ca: 'Apnea', es: 'Apnea', en: 'Apnoeic')),
      ]),
      ScaleItem(LocalizedText(ca: 'Circulació (TA respecte a la preanestèsica)', es: 'Circulación (TA respecto a la preanestésica)', en: 'Circulation (BP vs pre-anaesthetic)'), [
        ScaleOption(2, LocalizedText(ca: 'Variació de ±20 % o menys', es: 'Variación de ±20 % o menos', en: 'Within ±20%')),
        ScaleOption(1, LocalizedText(ca: 'Variació entre el 20 i el 49 %', es: 'Variación entre el 20 y el 49 %', en: 'Between 20% and 49%')),
        ScaleOption(0, LocalizedText(ca: 'Variació del 50 % o més', es: 'Variación del 50 % o más', en: '50% or more')),
      ]),
      ScaleItem(LocalizedText(ca: 'Consciència', es: 'Consciencia', en: 'Consciousness'), [
        ScaleOption(2, LocalizedText(ca: 'Completament despert', es: 'Completamente despierto', en: 'Fully awake')),
        ScaleOption(1, LocalizedText(ca: 'Es desperta quan se\'l crida', es: 'Se despierta al llamarle', en: 'Rousable on calling')),
        ScaleOption(0, LocalizedText(ca: 'No respon', es: 'No responde', en: 'Not responding')),
      ]),
      ScaleItem(LocalizedText(ca: 'Saturació d\'oxigen', es: 'Saturación de oxígeno', en: 'Oxygen saturation'), [
        ScaleOption(2, LocalizedText(ca: 'Més del 92 % respirant aire ambient', es: 'Más del 92 % respirando aire ambiente', en: 'Over 92% on room air')),
        ScaleOption(1, LocalizedText(ca: 'Necessita oxigen per mantenir més del 90 %', es: 'Necesita oxígeno para mantener más del 90 %', en: 'Needs oxygen to keep above 90%')),
        ScaleOption(0, LocalizedText(ca: 'Menys del 90 % fins i tot amb oxigen', es: 'Menos del 90 % incluso con oxígeno', en: 'Below 90% even with oxygen')),
      ]),
    ],
    bands: [
      ScaleBand(9, 10, LocalizedText(ca: 'Puntuació habitual per a l\'alta de la URPA, si el protocol ho permet', es: 'Puntuación habitual para el alta de la URPA, si el protocolo lo permite', en: 'Usual discharge score from recovery, if protocol allows')),
      ScaleBand(0, 8, LocalizedText(ca: 'Continua a la URPA i es torna a valorar', es: 'Sigue en la URPA y se vuelve a valorar', en: 'Stays in recovery and is reassessed')),
    ],
  ),
  ClinicalScale(
    id: 'bromage',
    name: LocalizedText(ca: 'Bromage (bloqueig motor)', es: 'Bromage (bloqueo motor)', en: 'Bromage scale (motor block)'),
    area: ScaleArea.recuperacion,
    description: LocalizedText(ca: 'Grau de bloqueig motor de les extremitats inferiors després d\'una anestèsia raquídia o epidural. Es valora fins que el bloqueig desapareix.', es: 'Grado de bloqueo motor de las extremidades inferiores tras una anestesia raquídea o epidural. Se valora hasta que el bloqueo desaparece.', en: 'Degree of lower-limb motor block after spinal or epidural anaesthesia, assessed until the block wears off.'),
    classification: true,
    reference: 'Bromage PR. Acta Anaesthesiol Scand 1965;9(Suppl 16):55-69.',
    items: [
      ScaleItem(LocalizedText(ca: 'Què pot moure', es: 'Qué puede mover', en: 'What the patient can move'), [
        ScaleOption(0, LocalizedText(ca: '0 — Sense bloqueig: flexiona genolls i peus', es: '0 — Sin bloqueo: flexiona rodillas y pies', en: '0 — No block: flexes knees and feet')),
        ScaleOption(1, LocalizedText(ca: '1 — No aixeca la cama estirada; mou genolls i peus', es: '1 — No levanta la pierna estirada; mueve rodillas y pies', en: '1 — Cannot raise the straight leg; moves knees and feet')),
        ScaleOption(2, LocalizedText(ca: '2 — No flexiona els genolls; només mou els peus', es: '2 — No flexiona las rodillas; solo mueve los pies', en: '2 — Cannot flex the knees; moves feet only')),
        ScaleOption(3, LocalizedText(ca: '3 — Bloqueig complet: no mou ni genolls ni peus', es: '3 — Bloqueo completo: no mueve ni rodillas ni pies', en: '3 — Complete block: cannot move knees or feet')),
      ]),
    ],
    bands: [
    ],
  ),
  ClinicalScale(
    id: 'rass',
    name: LocalizedText(ca: 'RASS (agitació i sedació)', es: 'RASS (agitación y sedación)', en: 'RASS (agitation and sedation)'),
    area: ScaleArea.recuperacion,
    description: LocalizedText(ca: 'Escala de Richmond. Primer s\'observa el pacient; si no està alerta, se\'l crida pel nom i, si no respon, s\'estimula físicament.', es: 'Escala de Richmond. Primero se observa al paciente; si no está alerta, se le llama por su nombre y, si no responde, se le estimula físicamente.', en: 'Richmond scale. Observe first; if not alert, call the patient by name and, if there is no response, use physical stimulation.'),
    classification: true,
    reference: 'Sessler CN et al. Am J Respir Crit Care Med 2002;166:1338-44.',
    items: [
      ScaleItem(LocalizedText(ca: 'Nivell', es: 'Nivel', en: 'Level'), [
        ScaleOption(4, LocalizedText(ca: '+4 Combatiu: violent, perill per a l\'equip', es: '+4 Combativo: violento, peligro para el equipo', en: '+4 Combative: violent, danger to staff')),
        ScaleOption(3, LocalizedText(ca: '+3 Molt agitat: s\'arrenca tubs o catèters, agressiu', es: '+3 Muy agitado: se arranca tubos o catéteres, agresivo', en: '+3 Very agitated: pulls at tubes or catheters, aggressive')),
        ScaleOption(2, LocalizedText(ca: '+2 Agitat: moviments sense propòsit, lluita amb el ventilador', es: '+2 Agitado: movimientos sin propósito, lucha con el ventilador', en: '+2 Agitated: purposeless movement, fights the ventilator')),
        ScaleOption(1, LocalizedText(ca: '+1 Inquiet: ansiós, però sense moviments agressius', es: '+1 Inquieto: ansioso, pero sin movimientos agresivos', en: '+1 Restless: anxious but not aggressive')),
        ScaleOption(0, LocalizedText(ca: '0 Alerta i tranquil', es: '0 Alerta y tranquilo', en: '0 Alert and calm')),
        ScaleOption(-1, LocalizedText(ca: '−1 Somnolent: es desperta a la veu i manté els ulls oberts més de 10 s', es: '−1 Somnoliento: se despierta a la voz y mantiene los ojos abiertos más de 10 s', en: '−1 Drowsy: wakes to voice, eye contact over 10 s')),
        ScaleOption(-2, LocalizedText(ca: '−2 Sedació lleu: es desperta a la veu, menys de 10 s', es: '−2 Sedación leve: se despierta a la voz, menos de 10 s', en: '−2 Light sedation: wakes to voice, under 10 s')),
        ScaleOption(-3, LocalizedText(ca: '−3 Sedació moderada: es mou o obre els ulls a la veu, sense contacte visual', es: '−3 Sedación moderada: se mueve o abre los ojos a la voz, sin contacto visual', en: '−3 Moderate sedation: movement or eye opening to voice, no eye contact')),
        ScaleOption(-4, LocalizedText(ca: '−4 Sedació profunda: no respon a la veu, es mou amb estímul físic', es: '−4 Sedación profunda: no responde a la voz, se mueve con estímulo físico', en: '−4 Deep sedation: no response to voice, moves to physical stimulus')),
        ScaleOption(-5, LocalizedText(ca: '−5 No despertable: cap resposta a la veu ni a l\'estímul físic', es: '−5 No despertable: ninguna respuesta a la voz ni al estímulo físico', en: '−5 Unrousable: no response to voice or physical stimulus')),
      ]),
    ],
    bands: [
    ],
  ),
  ClinicalScale(
    id: 'ramsay',
    name: LocalizedText(ca: 'Ramsay (sedació)', es: 'Ramsay (sedación)', en: 'Ramsay sedation scale'),
    area: ScaleArea.recuperacion,
    description: LocalizedText(ca: 'Nivell de sedació en sis graus, molt usada en sedacions de procediments i a la URPA.', es: 'Nivel de sedación en seis grados, muy usada en sedaciones de procedimientos y en la URPA.', en: 'Six-level sedation scale, widely used for procedural sedation and in recovery.'),
    classification: true,
    reference: 'Ramsay MA et al. Br Med J 1974;2:656-9.',
    items: [
      ScaleItem(LocalizedText(ca: 'Nivell', es: 'Nivel', en: 'Level'), [
        ScaleOption(1, LocalizedText(ca: '1 — Ansiós, agitat o inquiet', es: '1 — Ansioso, agitado o inquieto', en: '1 — Anxious, agitated or restless')),
        ScaleOption(2, LocalizedText(ca: '2 — Col·laborador, orientat i tranquil', es: '2 — Colaborador, orientado y tranquilo', en: '2 — Cooperative, oriented and calm')),
        ScaleOption(3, LocalizedText(ca: '3 — Respon només a ordres verbals', es: '3 — Responde solo a órdenes verbales', en: '3 — Responds to commands only')),
        ScaleOption(4, LocalizedText(ca: '4 — Adormit, resposta ràpida a un toc al front o a un soroll fort', es: '4 — Dormido, respuesta rápida a un toque en la frente o a un ruido fuerte', en: '4 — Asleep, brisk response to a glabellar tap or loud noise')),
        ScaleOption(5, LocalizedText(ca: '5 — Adormit, resposta lenta a aquests estímuls', es: '5 — Dormido, respuesta lenta a esos estímulos', en: '5 — Asleep, sluggish response to those stimuli')),
        ScaleOption(6, LocalizedText(ca: '6 — No respon', es: '6 — No responde', en: '6 — No response')),
      ]),
    ],
    bands: [
    ],
  ),
  ClinicalScale(
    id: 'glasgow',
    name: LocalizedText(ca: 'Escala de coma de Glasgow', es: 'Escala de coma de Glasgow', en: 'Glasgow Coma Scale'),
    area: ScaleArea.valoracion,
    description: LocalizedText(ca: 'Nivell de consciència a partir de la millor resposta ocular, verbal i motora. Es registra també per components (p. ex. O3 V4 M6).', es: 'Nivel de consciencia a partir de la mejor respuesta ocular, verbal y motora. Se registra también por componentes (p. ej. O3 V4 M6).', en: 'Level of consciousness from the best eye, verbal and motor response. Also record the components (e.g. E3 V4 M6).'),
    reference: 'Teasdale G, Jennett B. Lancet 1974;2:81-4.',
    items: [
      ScaleItem(LocalizedText(ca: 'Obertura d\'ulls', es: 'Apertura ocular', en: 'Eye opening'), [
        ScaleOption(4, LocalizedText(ca: 'Espontània', es: 'Espontánea', en: 'Spontaneous')),
        ScaleOption(3, LocalizedText(ca: 'A la veu', es: 'A la voz', en: 'To sound')),
        ScaleOption(2, LocalizedText(ca: 'A la pressió (dolor)', es: 'A la presión (dolor)', en: 'To pressure')),
        ScaleOption(1, LocalizedText(ca: 'Cap', es: 'Ninguna', en: 'None')),
      ]),
      ScaleItem(LocalizedText(ca: 'Resposta verbal', es: 'Respuesta verbal', en: 'Verbal response'), [
        ScaleOption(5, LocalizedText(ca: 'Orientada', es: 'Orientada', en: 'Oriented')),
        ScaleOption(4, LocalizedText(ca: 'Confusa', es: 'Confusa', en: 'Confused')),
        ScaleOption(3, LocalizedText(ca: 'Paraules inadequades', es: 'Palabras inadecuadas', en: 'Words')),
        ScaleOption(2, LocalizedText(ca: 'Sons incomprensibles', es: 'Sonidos incomprensibles', en: 'Sounds')),
        ScaleOption(1, LocalizedText(ca: 'Cap', es: 'Ninguna', en: 'None')),
      ]),
      ScaleItem(LocalizedText(ca: 'Resposta motora', es: 'Respuesta motora', en: 'Motor response'), [
        ScaleOption(6, LocalizedText(ca: 'Obeeix ordres', es: 'Obedece órdenes', en: 'Obeys commands')),
        ScaleOption(5, LocalizedText(ca: 'Localitza el dolor', es: 'Localiza el dolor', en: 'Localising')),
        ScaleOption(4, LocalizedText(ca: 'Retirada (flexió normal)', es: 'Retirada (flexión normal)', en: 'Normal flexion (withdrawal)')),
        ScaleOption(3, LocalizedText(ca: 'Flexió anormal', es: 'Flexión anormal', en: 'Abnormal flexion')),
        ScaleOption(2, LocalizedText(ca: 'Extensió', es: 'Extensión', en: 'Extension')),
        ScaleOption(1, LocalizedText(ca: 'Cap', es: 'Ninguna', en: 'None')),
      ]),
    ],
    bands: [
      ScaleBand(13, 15, LocalizedText(ca: 'Lleu', es: 'Leve', en: 'Mild')),
      ScaleBand(9, 12, LocalizedText(ca: 'Moderat', es: 'Moderado', en: 'Moderate')),
      ScaleBand(3, 8, LocalizedText(ca: 'Greu: protegir la via aèria', es: 'Grave: proteger la vía aérea', en: 'Severe: protect the airway')),
    ],
  ),
  ClinicalScale(
    id: 'eva',
    name: LocalizedText(ca: 'EVA / EVN (intensitat del dolor)', es: 'EVA / EVN (intensidad del dolor)', en: 'Pain intensity (VAS / NRS)'),
    area: ScaleArea.valoracion,
    description: LocalizedText(ca: 'El pacient puntua el dolor de 0 (gens) a 10 (el pitjor imaginable). Es torna a valorar després de cada analgèsia.', es: 'El paciente puntúa el dolor de 0 (nada) a 10 (el peor imaginable). Se vuelve a valorar tras cada analgesia.', en: 'The patient rates pain from 0 (none) to 10 (worst imaginable). Reassess after each analgesic.'),
    reference: 'Escala visual analògica i escala verbal numèrica; Hawker GA et al. Arthritis Care Res 2011;63(S11):S240-52.',
    items: [
      ScaleItem(LocalizedText(ca: 'Dolor', es: 'Dolor', en: 'Pain'), [
        ScaleOption(0, LocalizedText(ca: '0', es: '0', en: '0')),
        ScaleOption(1, LocalizedText(ca: '1', es: '1', en: '1')),
        ScaleOption(2, LocalizedText(ca: '2', es: '2', en: '2')),
        ScaleOption(3, LocalizedText(ca: '3', es: '3', en: '3')),
        ScaleOption(4, LocalizedText(ca: '4', es: '4', en: '4')),
        ScaleOption(5, LocalizedText(ca: '5', es: '5', en: '5')),
        ScaleOption(6, LocalizedText(ca: '6', es: '6', en: '6')),
        ScaleOption(7, LocalizedText(ca: '7', es: '7', en: '7')),
        ScaleOption(8, LocalizedText(ca: '8', es: '8', en: '8')),
        ScaleOption(9, LocalizedText(ca: '9', es: '9', en: '9')),
        ScaleOption(10, LocalizedText(ca: '10', es: '10', en: '10')),
      ]),
    ],
    bands: [
      ScaleBand(0, 0, LocalizedText(ca: 'Sense dolor', es: 'Sin dolor', en: 'No pain')),
      ScaleBand(1, 3, LocalizedText(ca: 'Dolor lleu', es: 'Dolor leve', en: 'Mild pain')),
      ScaleBand(4, 6, LocalizedText(ca: 'Dolor moderat', es: 'Dolor moderado', en: 'Moderate pain')),
      ScaleBand(7, 10, LocalizedText(ca: 'Dolor intens', es: 'Dolor intenso', en: 'Severe pain')),
    ],
  ),
  ClinicalScale(
    id: 'braden',
    name: LocalizedText(ca: 'Braden (risc d\'úlceres per pressió)', es: 'Braden (riesgo de úlceras por presión)', en: 'Braden scale (pressure injury risk)'),
    area: ScaleArea.valoracion,
    description: LocalizedText(ca: 'Risc de lesions per pressió. Com més baixa la puntuació, més risc. A quiròfan, les hores sobre la taula s\'hi sumen encara que la puntuació sigui bona.', es: 'Riesgo de lesiones por presión. Cuanto más baja la puntuación, más riesgo. En quirófano, las horas sobre la mesa se suman aunque la puntuación sea buena.', en: 'Pressure injury risk: the lower the score, the higher the risk. In theatre, hours on the table add to the risk even with a good score.'),
    reference: 'Bergstrom N et al. Nurs Res 1987;36:205-10.',
    items: [
      ScaleItem(LocalizedText(ca: 'Percepció sensorial', es: 'Percepción sensorial', en: 'Sensory perception'), [
        ScaleOption(1, LocalizedText(ca: 'Completament limitada', es: 'Completamente limitada', en: 'Completely limited')),
        ScaleOption(2, LocalizedText(ca: 'Molt limitada', es: 'Muy limitada', en: 'Very limited')),
        ScaleOption(3, LocalizedText(ca: 'Lleugerament limitada', es: 'Ligeramente limitada', en: 'Slightly limited')),
        ScaleOption(4, LocalizedText(ca: 'Sense alteració', es: 'Sin alteración', en: 'No impairment')),
      ]),
      ScaleItem(LocalizedText(ca: 'Humitat', es: 'Humedad', en: 'Moisture'), [
        ScaleOption(1, LocalizedText(ca: 'Constantment humida', es: 'Constantemente húmeda', en: 'Constantly moist')),
        ScaleOption(2, LocalizedText(ca: 'Sovint humida', es: 'A menudo húmeda', en: 'Often moist')),
        ScaleOption(3, LocalizedText(ca: 'Ocasionalment humida', es: 'Ocasionalmente húmeda', en: 'Occasionally moist')),
        ScaleOption(4, LocalizedText(ca: 'Rarament humida', es: 'Raramente húmeda', en: 'Rarely moist')),
      ]),
      ScaleItem(LocalizedText(ca: 'Activitat', es: 'Actividad', en: 'Activity'), [
        ScaleOption(1, LocalizedText(ca: 'Enllitat', es: 'Encamado', en: 'Bedfast')),
        ScaleOption(2, LocalizedText(ca: 'En cadira', es: 'En silla', en: 'Chairfast')),
        ScaleOption(3, LocalizedText(ca: 'Camina ocasionalment', es: 'Camina ocasionalmente', en: 'Walks occasionally')),
        ScaleOption(4, LocalizedText(ca: 'Camina sovint', es: 'Camina con frecuencia', en: 'Walks frequently')),
      ]),
      ScaleItem(LocalizedText(ca: 'Mobilitat', es: 'Movilidad', en: 'Mobility'), [
        ScaleOption(1, LocalizedText(ca: 'Completament immòbil', es: 'Completamente inmóvil', en: 'Completely immobile')),
        ScaleOption(2, LocalizedText(ca: 'Molt limitada', es: 'Muy limitada', en: 'Very limited')),
        ScaleOption(3, LocalizedText(ca: 'Lleugerament limitada', es: 'Ligeramente limitada', en: 'Slightly limited')),
        ScaleOption(4, LocalizedText(ca: 'Sense limitacions', es: 'Sin limitaciones', en: 'No limitation')),
      ]),
      ScaleItem(LocalizedText(ca: 'Nutrició', es: 'Nutrición', en: 'Nutrition'), [
        ScaleOption(1, LocalizedText(ca: 'Molt pobra', es: 'Muy pobre', en: 'Very poor')),
        ScaleOption(2, LocalizedText(ca: 'Probablement inadequada', es: 'Probablemente inadecuada', en: 'Probably inadequate')),
        ScaleOption(3, LocalizedText(ca: 'Adequada', es: 'Adecuada', en: 'Adequate')),
        ScaleOption(4, LocalizedText(ca: 'Excel·lent', es: 'Excelente', en: 'Excellent')),
      ]),
      ScaleItem(LocalizedText(ca: 'Fregament i lliscament', es: 'Roce y cizallamiento', en: 'Friction and shear'), [
        ScaleOption(1, LocalizedText(ca: 'És un problema', es: 'Es un problema', en: 'Problem')),
        ScaleOption(2, LocalizedText(ca: 'És un problema potencial', es: 'Es un problema potencial', en: 'Potential problem')),
        ScaleOption(3, LocalizedText(ca: 'Sense problema aparent', es: 'Sin problema aparente', en: 'No apparent problem')),
      ]),
    ],
    bands: [
      ScaleBand(6, 9, LocalizedText(ca: 'Risc molt alt', es: 'Riesgo muy alto', en: 'Very high risk')),
      ScaleBand(10, 12, LocalizedText(ca: 'Risc alt', es: 'Riesgo alto', en: 'High risk')),
      ScaleBand(13, 14, LocalizedText(ca: 'Risc moderat', es: 'Riesgo moderado', en: 'Moderate risk')),
      ScaleBand(15, 18, LocalizedText(ca: 'Risc baix', es: 'Riesgo bajo', en: 'Low risk')),
      ScaleBand(19, 23, LocalizedText(ca: 'Sense risc segons l\'escala', es: 'Sin riesgo según la escala', en: 'No risk on this scale')),
    ],
  ),
  ClinicalScale(
    id: '4at',
    name: LocalizedText(ca: '4AT (cribratge de deliri)', es: '4AT (cribado de delirio)', en: '4AT (delirium screening)'),
    area: ScaleArea.valoracion,
    description: LocalizedText(ca: 'Cribratge ràpid de deliri, útil en gent gran abans i després de la cirurgia. No necessita formació especial.', es: 'Cribado rápido de delirio, útil en personas mayores antes y después de la cirugía. No necesita formación especial.', en: 'Rapid delirium screen, useful in older patients before and after surgery. No special training needed.'),
    reference: 'Bellelli G et al. Age Ageing 2014;43:496-502. www.the4AT.com',
    items: [
      ScaleItem(LocalizedText(ca: 'Alerta', es: 'Alerta', en: 'Alertness'), [
        ScaleOption(0, LocalizedText(ca: 'Normal (plenament alerta, sense agitació)', es: 'Normal (plenamente alerta, sin agitación)', en: 'Normal (fully alert, not agitated)')),
        ScaleOption(4, LocalizedText(ca: 'Clarament anormal (somnolent o agitat)', es: 'Claramente anormal (somnoliento o agitado)', en: 'Clearly abnormal (drowsy or agitated)')),
      ]),
      ScaleItem(LocalizedText(ca: 'AMT4: edat, data de naixement, lloc i any', es: 'AMT4: edad, fecha de nacimiento, lugar y año', en: 'AMT4: age, date of birth, place and year'), [
        ScaleOption(0, LocalizedText(ca: 'Cap error', es: 'Ningún error', en: 'No mistakes')),
        ScaleOption(1, LocalizedText(ca: '1 error', es: '1 error', en: '1 mistake')),
        ScaleOption(2, LocalizedText(ca: '2 o més errors, o no es pot fer', es: '2 o más errores, o no se puede hacer', en: '2 or more mistakes, or untestable')),
      ]),
      ScaleItem(LocalizedText(ca: 'Atenció: mesos de l\'any al revés', es: 'Atención: meses del año al revés', en: 'Attention: months of the year backwards'), [
        ScaleOption(0, LocalizedText(ca: '7 mesos o més correctes', es: '7 meses o más correctos', en: '7 or more months correct')),
        ScaleOption(1, LocalizedText(ca: 'Comença però en diu menys de 7, o s\'hi nega', es: 'Empieza pero dice menos de 7, o se niega', en: 'Starts but under 7, or refuses')),
        ScaleOption(2, LocalizedText(ca: 'No es pot fer (no pot començar per malestar o somnolència)', es: 'No se puede hacer (no puede empezar por malestar o somnolencia)', en: 'Untestable (cannot start because unwell or drowsy)')),
      ]),
      ScaleItem(LocalizedText(ca: 'Canvi agut o curs fluctuant', es: 'Cambio agudo o curso fluctuante', en: 'Acute change or fluctuating course'), [
        ScaleOption(0, LocalizedText(ca: 'No', es: 'No', en: 'No')),
        ScaleOption(4, LocalizedText(ca: 'Sí', es: 'Sí', en: 'Yes')),
      ]),
    ],
    bands: [
      ScaleBand(0, 0, LocalizedText(ca: 'Deliri poc probable', es: 'Delirio poco probable', en: 'Delirium unlikely')),
      ScaleBand(1, 3, LocalizedText(ca: 'Possible deteriorament cognitiu', es: 'Posible deterioro cognitivo', en: 'Possible cognitive impairment')),
      ScaleBand(4, 12, LocalizedText(ca: 'Possible deliri: avisar el metge', es: 'Posible delirio: avisar al médico', en: 'Possible delirium: inform the doctor')),
    ],
  ),
];
