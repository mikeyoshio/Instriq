import '../models/instrument.dart' show LocalizedText;
import '../models/surgical_position.dart';

/// Postures quirúrgiques. Text propi, redactat a partir del coneixement
/// clínic general d'infermeria quirúrgica; no copiat de cap font.
const List<SurgicalPosition> kSurgicalPositions = [
  SurgicalPosition(
    id: 'decubito-supino',
    relatedItems: ['soporte-brazo-mesa', 'rodete-cabeza', 'almohadilla-gel-posicionamiento', 'cinta-sujecion-paciente', 'arco-anestesia', 'mesa-quirofano-electrohidraulica'],
    name: LocalizedText(ca: 'Decúbit supí', es: 'Decúbito supino', en: 'Supine position'),
    aliases: ['Supine', 'Dorsal decubitus'],
    family: SurgicalPositionFamily.supino,
    description: LocalizedText(
      ca: 'Pacient estirat d\'esquena, amb el cap alineat amb el tronc sobre un coixí baix, les cames estirades i lleugerament separades i els braços al llarg del cos o sobre posabraços a menys de 90°.',
      es: 'Paciente tumbado boca arriba, con la cabeza alineada con el tronco sobre una almohada baja, las piernas estiradas y ligeramente separadas y los brazos a lo largo del cuerpo o sobre apoyabrazos a menos de 90°.',
      en: 'Patient lying on the back, head aligned with the trunk on a low pillow, legs straight and slightly apart, arms at the sides or on arm boards at less than 90°.',
    ),
    procedures: LocalizedText(
      ca: 'És la postura més habitual: cirurgia abdominal oberta i laparoscòpica, mama, extremitats, coll, cara i bona part de la cirurgia vascular.',
      es: 'Es la postura más habitual: cirugía abdominal abierta y laparoscópica, mama, extremidades, cuello, cara y buena parte de la cirugía vascular.',
      en: 'The most common position: open and laparoscopic abdominal surgery, breast, limbs, neck, face and much vascular surgery.',
    ),
    risks: LocalizedText(
      ca: 'Pressió a l\'occipuci, escàpules, colzes, sacre i talons. Lesió del plexe braquial si el braç s\'obre més de 90° o es gira cap enrere, i del nervi cubital si el colze queda recolzat sobre l\'epitròclea.',
      es: 'Presión en occipucio, escápulas, codos, sacro y talones. Lesión del plexo braquial si el brazo se abre más de 90° o se gira hacia atrás, y del nervio cubital si el codo queda apoyado sobre la epitróclea.',
      en: 'Pressure on the occiput, scapulae, elbows, sacrum and heels. Brachial plexus injury if the arm is abducted beyond 90° or rotated backwards, and ulnar nerve injury if the elbow rests on the medial epicondyle.',
    ),
    care: LocalizedText(
      ca: 'Coixinet sota els genolls perquè no quedin en hiperextensió i talons lliures de pressió. Palmell cap amunt al posabraços. Cap pell en contacte amb parts metàl·liques de la taula. La placa del bisturí elèctric en una zona muscular, neta i seca.',
      es: 'Almohadilla bajo las rodillas para que no queden en hiperextensión y talones libres de presión. Palma hacia arriba en el apoyabrazos. Ninguna zona de piel en contacto con partes metálicas de la mesa. La placa del bisturí eléctrico en una zona muscular, limpia y seca.',
      en: 'Pad under the knees so they are not hyperextended, heels off-loaded. Palm up on the arm board. No skin touching metal parts of the table. Electrosurgical return pad on a clean, dry, muscular area.',
    ),
  ),
  SurgicalPosition(
    id: 'trendelenburg',
    relatedItems: ['soporte-hombros', 'colchon-vacio-posicionamiento', 'cinta-sujecion-paciente', 'mesa-quirofano-electrohidraulica'],
    name: LocalizedText(ca: 'Trendelenburg', es: 'Trendelenburg', en: 'Trendelenburg position'),
    aliases: ['Trendelenburg', 'Head-down'],
    family: SurgicalPositionFamily.supino,
    description: LocalizedText(
      ca: 'Variant del supí amb la taula inclinada cap avall pel cap, de manera que la pelvis queda més alta que el cap. En el Trendelenburg forçat (cirurgia robòtica) la inclinació pot arribar als 30-45°.',
      es: 'Variante del supino con la mesa inclinada hacia abajo por la cabeza, de modo que la pelvis queda más alta que la cabeza. En el Trendelenburg forzado (cirugía robótica) la inclinación puede llegar a 30-45°.',
      en: 'Supine variant with the table tilted head-down so the pelvis is higher than the head. In steep Trendelenburg (robotic surgery) the tilt may reach 30-45°.',
    ),
    procedures: LocalizedText(
      ca: 'Cirurgia pelviana i del baix abdomen: ginecologia, urologia (prostatectomia robòtica), colon i recte per laparoscòpia. També per facilitar la canalització de la vena jugular o subclàvia.',
      es: 'Cirugía pélvica y del abdomen inferior: ginecología, urología (prostatectomía robótica), colon y recto por laparoscopia. También para facilitar la canalización de la vena yugular o subclavia.',
      en: 'Pelvic and lower abdominal surgery: gynaecology, urology (robotic prostatectomy), laparoscopic colorectal surgery. Also to help cannulate the jugular or subclavian vein.',
    ),
    risks: LocalizedText(
      ca: 'El pacient pot lliscar cap al cap. Augment de la pressió intracranial i intraocular, edema facial i de la via aèria, i menys expansió pulmonar perquè les vísceres empenyen el diafragma. Lesió del plexe braquial si s\'usen sostenidors d\'espatlles mal col·locats.',
      es: 'El paciente puede deslizarse hacia la cabeza. Aumento de la presión intracraneal e intraocular, edema facial y de la vía aérea, y menor expansión pulmonar porque las vísceras empujan el diafragma. Lesión del plexo braquial si se usan hombreras mal colocadas.',
      en: 'The patient may slide towards the head. Raised intracranial and intraocular pressure, facial and airway oedema, and reduced lung expansion as the viscera push on the diaphragm. Brachial plexus injury from badly placed shoulder supports.',
    ),
    care: LocalizedText(
      ca: 'Fixar el pacient abans d\'inclinar amb un matalàs antilliscant (gel o buit), mai amb sostenidors contra l\'acromi. Inclinar a poc a poc i avisant anestèsia. Comprovar la posició del pacient després d\'inclinar i protegir els ulls de l\'edema.',
      es: 'Fijar al paciente antes de inclinar con un colchón antideslizante (gel o vacío), nunca con hombreras contra el acromion. Inclinar poco a poco y avisando a anestesia. Comprobar la posición del paciente tras inclinar y proteger los ojos del edema.',
      en: 'Secure the patient before tilting with an anti-slip mattress (gel or vacuum), never with shoulder braces against the acromion. Tilt gradually and tell anaesthesia. Recheck the patient after tilting and protect the eyes from oedema.',
    ),
  ),
  SurgicalPosition(
    id: 'antitrendelenburg',
    relatedItems: ['reposapies-mesa', 'cinta-sujecion-paciente', 'mesa-quirofano-electrohidraulica'],
    name: LocalizedText(ca: 'Antitrendelenburg', es: 'Antitrendelenburg (Trendelenburg invertido)', en: 'Reverse Trendelenburg position'),
    aliases: ['Reverse Trendelenburg', 'Head-up', 'Trendelenburg inverso'],
    family: SurgicalPositionFamily.supino,
    description: LocalizedText(
      ca: 'Variant del supí amb la taula inclinada cap avall pels peus: el cap queda més alt que els peus, que es recolzen en un reposapeus.',
      es: 'Variante del supino con la mesa inclinada hacia abajo por los pies: la cabeza queda más alta que los pies, que se apoyan en un reposapiés.',
      en: 'Supine variant with the table tilted feet-down: the head is higher than the feet, which rest on a footboard.',
    ),
    procedures: LocalizedText(
      ca: 'Cirurgia de l\'abdomen superior per laparoscòpia (vesícula, estómac, hiat, cirurgia bariàtrica), tiroide i cap i coll.',
      es: 'Cirugía del abdomen superior por laparoscopia (vesícula, estómago, hiato, cirugía bariátrica), tiroides y cabeza y cuello.',
      en: 'Laparoscopic upper abdominal surgery (gallbladder, stomach, hiatus, bariatric surgery), thyroid, and head and neck surgery.',
    ),
    risks: LocalizedText(
      ca: 'Hipotensió per acumulació de sang a les cames i risc de trombosi venosa. El pacient pot lliscar cap als peus. Pressió a les plantes dels peus si el reposapeus no està ben encoixinat.',
      es: 'Hipotensión por acumulación de sangre en las piernas y riesgo de trombosis venosa. El paciente puede deslizarse hacia los pies. Presión en las plantas si el reposapiés no está bien acolchado.',
      en: 'Hypotension from blood pooling in the legs and risk of venous thrombosis. The patient may slide towards the feet. Pressure on the soles if the footboard is not well padded.',
    ),
    care: LocalizedText(
      ca: 'Reposapeus encoixinat amb els peus a 90°. Mitges o compressió pneumàtica intermitent segons protocol. Canvis d\'inclinació lents i coordinats amb anestèsia.',
      es: 'Reposapiés acolchado con los pies a 90°. Medias o compresión neumática intermitente según protocolo. Cambios de inclinación lentos y coordinados con anestesia.',
      en: 'Padded footboard with the feet at 90°. Stockings or intermittent pneumatic compression per protocol. Slow tilt changes coordinated with anaesthesia.',
    ),
  ),
  SurgicalPosition(
    id: 'rose',
    relatedItems: ['rodillo-posicionamiento', 'rodete-cabeza', 'soporte-brazo-mesa'],
    name: LocalizedText(ca: 'Posició de Rose (hiperextensió cervical)', es: 'Posición de Rose (hiperextensión cervical)', en: 'Rose position (neck hyperextension)'),
    aliases: ['Rose position', 'Neck extension'],
    family: SurgicalPositionFamily.supino,
    description: LocalizedText(
      ca: 'Supí amb el coll en extensió: un coixí o un rotlle sota les espatlles i el cap recolzat en un rodet, de manera que la barbeta queda amunt.',
      es: 'Supino con el cuello en extensión: una almohada o un rodillo bajo los hombros y la cabeza apoyada en un rodete, de modo que el mentón queda hacia arriba.',
      en: 'Supine with the neck extended: a roll under the shoulders and the head on a head ring, so the chin points upwards.',
    ),
    procedures: LocalizedText(
      ca: 'Cirurgia de tiroide i paratiroides, traqueotomia, amigdalectomia i cirurgia de la cara anterior del coll.',
      es: 'Cirugía de tiroides y paratiroides, traqueotomía, amigdalectomía y cirugía de la cara anterior del cuello.',
      en: 'Thyroid and parathyroid surgery, tracheostomy, tonsillectomy and anterior neck surgery.',
    ),
    risks: LocalizedText(
      ca: 'Dolor cervical postoperatori i, en pacients amb artrosi o patologia cervical, risc de lesió medul·lar per extensió excessiva. Pressió a l\'occipuci.',
      es: 'Dolor cervical postoperatorio y, en pacientes con artrosis o patología cervical, riesgo de lesión medular por extensión excesiva. Presión en el occipucio.',
      en: 'Postoperative neck pain and, in patients with cervical arthritis or disease, risk of spinal cord injury from excessive extension. Pressure on the occiput.',
    ),
    care: LocalizedText(
      ca: 'Comprovar abans la mobilitat cervical del pacient. Extensió suficient per exposar el camp, no la màxima. El cap ben subjectat perquè no rodi. Protegir els ulls.',
      es: 'Comprobar antes la movilidad cervical del paciente. Extensión suficiente para exponer el campo, no la máxima. La cabeza bien sujeta para que no ruede. Proteger los ojos.',
      en: 'Check the patient\'s neck mobility beforehand. Extend enough to expose the field, not to the maximum. Keep the head secure so it cannot roll. Protect the eyes.',
    ),
  ),
  SurgicalPosition(
    id: 'litotomia',
    relatedItems: ['pernera-litotomia', 'almohadilla-gel-posicionamiento', 'soporte-brazo-mesa'],
    name: LocalizedText(ca: 'Litotomia (ginecològica)', es: 'Litotomía (ginecológica)', en: 'Lithotomy position'),
    aliases: ['Lithotomy', 'Gynaecological position'],
    family: SurgicalPositionFamily.supino,
    description: LocalizedText(
      ca: 'Supí amb les natges a la vora de la taula i les cames aixecades i separades sobre perneres, amb malucs i genolls flexionats. Les dues cames es pugen i es baixen alhora.',
      es: 'Supino con las nalgas en el borde de la mesa y las piernas elevadas y separadas sobre perneras, con caderas y rodillas flexionadas. Las dos piernas se suben y se bajan a la vez.',
      en: 'Supine with the buttocks at the edge of the table and the legs raised and apart in stirrups, hips and knees flexed. Both legs are raised and lowered together.',
    ),
    procedures: LocalizedText(
      ca: 'Cirurgia perineal, vaginal, anal i urològica endoscòpica (RTU, ureteroscòpia), parts i alguns abordatges combinats de colon i recte.',
      es: 'Cirugía perineal, vaginal, anal y urológica endoscópica (RTU, ureteroscopia), partos y algunos abordajes combinados de colon y recto.',
      en: 'Perineal, vaginal, anal and endoscopic urological surgery (TURP, ureteroscopy), childbirth and some combined colorectal approaches.',
    ),
    risks: LocalizedText(
      ca: 'Lesió del nervi peroneal per pressió del cap del peroné contra la pernera, i del femoral i l\'obturador per flexió o abducció excessiva del maluc. Síndrome compartimental a les cames en cirurgies llargues. Hipotensió en baixar les cames. Lumbàlgia.',
      es: 'Lesión del nervio peroneo por presión de la cabeza del peroné contra la pernera, y del femoral y el obturador por flexión o abducción excesiva de la cadera. Síndrome compartimental en las piernas en cirugías largas. Hipotensión al bajar las piernas. Lumbalgia.',
      en: 'Peroneal nerve injury from the fibular head pressing on the stirrup, and femoral and obturator nerve injury from excessive hip flexion or abduction. Compartment syndrome of the legs in long cases. Hypotension when the legs are lowered. Low back pain.',
    ),
    care: LocalizedText(
      ca: 'Pujar i baixar les cames alhora i a poc a poc, amb dues persones. Encoixinar la cara externa del genoll. Vigilar els dits de les mans quan s\'aixeca o es baixa la part dels peus de la taula. Avisar anestèsia en baixar les cames.',
      es: 'Subir y bajar las piernas a la vez y despacio, entre dos personas. Acolchar la cara externa de la rodilla. Vigilar los dedos de las manos al subir o bajar la parte de los pies de la mesa. Avisar a anestesia al bajar las piernas.',
      en: 'Raise and lower the legs together and slowly, with two people. Pad the outside of the knee. Watch the patient\'s fingers when the foot section of the table is raised or lowered. Tell anaesthesia before lowering the legs.',
    ),
  ),
  SurgicalPosition(
    id: 'decubito-lateral',
    relatedItems: ['colchon-vacio-posicionamiento', 'soporte-lateral-mesa', 'rodillo-posicionamiento', 'apoyabrazos-doble-lateral', 'almohadilla-gel-posicionamiento', 'cinta-sujecion-paciente'],
    name: LocalizedText(ca: 'Decúbit lateral', es: 'Decúbito lateral', en: 'Lateral decubitus position'),
    aliases: ['Lateral decubitus', 'Lateral position'],
    family: SurgicalPositionFamily.lateral,
    description: LocalizedText(
      ca: 'Pacient sobre un costat (s\'anomena pel costat de baix: decúbit lateral dret si està sobre el costat dret), amb la cama de baix flexionada i la de dalt estirada i un coixí entre totes dues. El tronc es fixa amb suports o matalàs de buit.',
      es: 'Paciente sobre un costado (se nombra por el lado de abajo: decúbito lateral derecho si está sobre el lado derecho), con la pierna de abajo flexionada y la de arriba estirada y una almohada entre ambas. El tronco se fija con soportes o colchón de vacío.',
      en: 'Patient on one side (named after the side underneath: right lateral if lying on the right side), lower leg flexed, upper leg straight, with a pillow between them. The trunk is held with supports or a vacuum mattress.',
    ),
    procedures: LocalizedText(
      ca: 'Cirurgia toràcica (toracotomia, videotoracoscòpia), maluc, espatlla, ronyó i alguns abordatges de columna.',
      es: 'Cirugía torácica (toracotomía, videotoracoscopia), cadera, hombro, riñón y algunos abordajes de columna.',
      en: 'Thoracic surgery (thoracotomy, VATS), hip, shoulder, kidney and some spinal approaches.',
    ),
    risks: LocalizedText(
      ca: 'Pressió a l\'orella, l\'espatlla, la cresta ilíaca, el genoll i el turmell del costat de baix. Lesió del plexe braquial i compressió axil·lar del costat de baix. Alteració ventilació-perfusió: el pulmó de baix rep més sang però ventila pitjor.',
      es: 'Presión en la oreja, el hombro, la cresta ilíaca, la rodilla y el tobillo del lado de abajo. Lesión del plexo braquial y compresión axilar del lado de abajo. Alteración ventilación-perfusión: el pulmón de abajo recibe más sangre pero ventila peor.',
      en: 'Pressure on the ear, shoulder, iliac crest, knee and ankle on the lower side. Brachial plexus injury and axillary compression on the lower side. Ventilation-perfusion mismatch: the lower lung gets more blood but ventilates less.',
    ),
    care: LocalizedText(
      ca: 'Coixí o rotlle sota el tòrax, just per sota de l\'aixella (no dins), per alliberar el plexe braquial. Cap alineat amb la columna i l\'orella sense doblegar. Braç de dalt sobre un suport sense estirar. Girar en bloc, coordinats amb anestèsia que controla el cap i el tub.',
      es: 'Almohadilla o rodillo bajo el tórax, justo por debajo de la axila (no dentro), para liberar el plexo braquial. Cabeza alineada con la columna y la oreja sin doblar. Brazo de arriba sobre un soporte sin estirar. Girar en bloque, coordinados con anestesia que controla la cabeza y el tubo.',
      en: 'Pad or roll under the chest, just below the armpit (not in it), to off-load the brachial plexus. Head aligned with the spine and the ear not folded. Upper arm on a support without stretching. Log-roll in coordination with anaesthesia, who controls the head and tube.',
    ),
  ),
  SurgicalPosition(
    id: 'lumbotomia',
    relatedItems: ['soporte-lateral-mesa', 'rodillo-posicionamiento', 'apoyabrazos-doble-lateral', 'cinta-sujecion-paciente', 'mesa-quirofano-electrohidraulica'],
    name: LocalizedText(ca: 'Posició de lumbotomia (renal)', es: 'Posición de lumbotomía (renal)', en: 'Kidney (flank) position'),
    aliases: ['Kidney position', 'Flank position', 'Lateral renal'],
    family: SurgicalPositionFamily.lateral,
    description: LocalizedText(
      ca: 'Decúbit lateral amb el flanc a operar amunt i situat sobre el pont de la taula o un coixí, i la taula flexionada perquè s\'obri l\'espai entre l\'última costella i la cresta ilíaca.',
      es: 'Decúbito lateral con el flanco a operar hacia arriba y situado sobre el puente de la mesa o una almohada, y la mesa flexionada para que se abra el espacio entre la última costilla y la cresta ilíaca.',
      en: 'Lateral position with the operative flank uppermost over the table bridge or a roll, and the table flexed to open the space between the lowest rib and the iliac crest.',
    ),
    procedures: LocalizedText(
      ca: 'Cirurgia oberta o laparoscòpica de ronyó, urèter proximal i glàndula suprarenal.',
      es: 'Cirugía abierta o laparoscópica de riñón, uréter proximal y glándula suprarrenal.',
      en: 'Open or laparoscopic surgery of the kidney, proximal ureter and adrenal gland.',
    ),
    risks: LocalizedText(
      ca: 'Els mateixos que el decúbit lateral i, a més, hipotensió per compressió de la vena cava quan es flexiona la taula, i dolor lumbar postoperatori.',
      es: 'Los mismos que el decúbito lateral y, además, hipotensión por compresión de la vena cava al flexionar la mesa, y dolor lumbar postoperatorio.',
      en: 'As for lateral decubitus, plus hypotension from vena cava compression when the table is flexed, and postoperative back pain.',
    ),
    care: LocalizedText(
      ca: 'Flexionar la taula només el necessari i avisant anestèsia. Tornar la taula a pla abans de tancar la paret perquè la sutura no quedi a tensió. Fixar bé el pacient abans de flexionar.',
      es: 'Flexionar la mesa solo lo necesario y avisando a anestesia. Devolver la mesa a plano antes de cerrar la pared para que la sutura no quede a tensión. Fijar bien al paciente antes de flexionar.',
      en: 'Flex the table only as much as needed and tell anaesthesia. Return the table to flat before closing the wall so the suture is not under tension. Secure the patient well before flexing.',
    ),
  ),
  SurgicalPosition(
    id: 'decubito-prono',
    relatedItems: ['almohada-facial-prono', 'rodillo-posicionamiento', 'marco-wilson', 'cabezal-herradura', 'almohadilla-gel-posicionamiento', 'soporte-brazo-mesa'],
    name: LocalizedText(ca: 'Decúbit pron', es: 'Decúbito prono', en: 'Prone position'),
    aliases: ['Prone', 'Ventral decubitus'],
    family: SurgicalPositionFamily.prono,
    description: LocalizedText(
      ca: 'Pacient bocaterrosa, amb el cap girat de costat o recolzat de cara en un suport amb forat (tipus coixí de prono o capçal de Mayfield), el tòrax i la pelvis sobre suports o un marc que deixen l\'abdomen lliure, i els braços al llarg del cos o endavant a menys de 90°.',
      es: 'Paciente boca abajo, con la cabeza girada de lado o apoyada de cara en un soporte con hueco (tipo almohada de prono o cabezal de Mayfield), el tórax y la pelvis sobre soportes o un marco que dejan el abdomen libre, y los brazos a lo largo del cuerpo o hacia delante a menos de 90°.',
      en: 'Patient face down, head turned to the side or face-down in a cut-out support (prone pillow or Mayfield head holder), chest and pelvis on supports or a frame that leaves the abdomen free, and the arms at the sides or forward at less than 90°.',
    ),
    procedures: LocalizedText(
      ca: 'Cirurgia de columna, fossa posterior, part posterior de les extremitats, regió sacra i glútia, i algunes cirurgies renals percutànies.',
      es: 'Cirugía de columna, fosa posterior, parte posterior de las extremidades, región sacra y glútea, y algunas cirugías renales percutáneas.',
      en: 'Spinal surgery, posterior fossa, back of the limbs, sacral and gluteal region, and some percutaneous kidney surgery.',
    ),
    risks: LocalizedText(
      ca: 'Pressió als ulls (pèrdua visual per isquèmia), front, barbeta, pits, genitals, crestes ilíaques, genolls i dits dels peus. Si l\'abdomen queda comprimit, menys retorn venós i més sagnat. Desconnexió o desplaçament del tub en girar.',
      es: 'Presión en los ojos (pérdida visual por isquemia), frente, mentón, mamas, genitales, crestas ilíacas, rodillas y dedos de los pies. Si el abdomen queda comprimido, menor retorno venoso y más sangrado. Desconexión o desplazamiento del tubo al girar.',
      en: 'Pressure on the eyes (ischaemic vision loss), forehead, chin, breasts, genitals, iliac crests, knees and toes. A compressed abdomen reduces venous return and increases bleeding. Tube disconnection or displacement when turning.',
    ),
    care: LocalizedText(
      ca: 'Girar en bloc amb prou persones i anestèsia al cap. Comprovar ulls i cara sense pressió després de girar i periòdicament. Abdomen lliure, pits i genitals sense compressió, peus amb els dits penjant o sobre un coixí. Tenir la llitera a punt per tornar-lo a supí d\'urgència.',
      es: 'Girar en bloque con suficientes personas y anestesia en la cabeza. Comprobar ojos y cara sin presión tras girar y periódicamente. Abdomen libre, mamas y genitales sin compresión, pies con los dedos colgando o sobre una almohada. Tener la camilla preparada para volver a supino de urgencia.',
      en: 'Log-roll with enough staff and anaesthesia at the head. Check the eyes and face are free of pressure after turning and periodically. Abdomen free, breasts and genitals uncompressed, toes hanging free or on a pillow. Keep the trolley ready to return the patient to supine in an emergency.',
    ),
  ),
  SurgicalPosition(
    id: 'navaja-kraske',
    relatedItems: ['almohada-facial-prono', 'rodillo-posicionamiento', 'almohadilla-gel-posicionamiento', 'cinta-sujecion-paciente'],
    name: LocalizedText(ca: 'Posició de navalla (Kraske)', es: 'Posición de navaja (Kraske)', en: 'Jackknife (Kraske) position'),
    aliases: ['Jackknife', 'Kraske position'],
    family: SurgicalPositionFamily.prono,
    description: LocalizedText(
      ca: 'Variant del pron amb la taula flexionada al nivell dels malucs, de manera que la pelvis queda al punt més alt i el cap i les cames més baixos. Les natges se separen amb cinta adhesiva.',
      es: 'Variante del prono con la mesa flexionada a la altura de las caderas, de modo que la pelvis queda en el punto más alto y la cabeza y las piernas más bajas. Las nalgas se separan con cinta adhesiva.',
      en: 'Prone variant with the table flexed at the hips so the pelvis is the highest point and the head and legs are lower. The buttocks are separated with adhesive tape.',
    ),
    procedures: LocalizedText(
      ca: 'Cirurgia proctològica: hemorroides, fístules i fissures anals, sinus pilonidal i algunes cirurgies rectals per via transanal.',
      es: 'Cirugía proctológica: hemorroides, fístulas y fisuras anales, sinus pilonidal y algunas cirugías rectales por vía transanal.',
      en: 'Proctological surgery: haemorrhoids, anal fistulas and fissures, pilonidal sinus and some transanal rectal surgery.',
    ),
    risks: LocalizedText(
      ca: 'Els mateixos que el pron, i més pressió a les crestes ilíaques i els genolls. Disminució del retorn venós i hipotensió en flexionar.',
      es: 'Los mismos que el prono, y más presión en crestas ilíacas y rodillas. Disminución del retorno venoso e hipotensión al flexionar.',
      en: 'As for prone, with more pressure on the iliac crests and knees. Reduced venous return and hypotension when the table is flexed.',
    ),
    care: LocalizedText(
      ca: 'Coixí sota la pelvis a l\'altura del pont de la taula. Retirar la cinta de les natges amb cura en acabar, sense arrencar la pell. Mateixes comprovacions de cara, ulls i tòrax que en el pron.',
      es: 'Almohada bajo la pelvis a la altura del puente de la mesa. Retirar la cinta de las nalgas con cuidado al terminar, sin arrancar la piel. Mismas comprobaciones de cara, ojos y tórax que en el prono.',
      en: 'Pad under the pelvis at the table break. Remove the buttock tape carefully at the end without stripping skin. Same face, eye and chest checks as for prone.',
    ),
  ),
  SurgicalPosition(
    id: 'genupectoral',
    relatedItems: ['marco-wilson', 'almohada-facial-prono', 'almohadilla-gel-posicionamiento'],
    name: LocalizedText(ca: 'Genupectoral (genolls-pit)', es: 'Genupectoral (rodillas-pecho)', en: 'Knee-chest position'),
    aliases: ['Knee-chest position', 'Andrews frame position', 'Mohammedan position'],
    family: SurgicalPositionFamily.prono,
    description: LocalizedText(
      ca: 'Variant del pron amb el pacient agenollat, els malucs flexionats i el pit recolzat a la taula; per a cirurgia es fa sobre un marc específic (tipus Andrews) amb un seient per a les natges.',
      es: 'Variante del prono con el paciente arrodillado, las caderas flexionadas y el pecho apoyado en la mesa; para cirugía se hace sobre un marco específico (tipo Andrews) con un asiento para las nalgas.',
      en: 'Prone variant with the patient kneeling, hips flexed and the chest on the table; for surgery a dedicated frame (Andrews type) with a seat for the buttocks is used.',
    ),
    procedures: LocalizedText(
      ca: 'Cirurgia de columna lumbar (discectomia, laminectomia): la flexió obre l\'espai interlaminar i l\'abdomen penja lliure, cosa que redueix el sagnat epidural.',
      es: 'Cirugía de columna lumbar (discectomía, laminectomía): la flexión abre el espacio interlaminar y el abdomen cuelga libre, lo que reduce el sangrado epidural.',
      en: 'Lumbar spine surgery (discectomy, laminectomy): flexion opens the interlaminar space and the abdomen hangs free, reducing epidural bleeding.',
    ),
    risks: LocalizedText(
      ca: 'Pressió als genolls i a la part anterior de les cames, risc de síndrome compartimental i trombosi per flexió prolongada, i hipotensió per acumulació de sang a les extremitats inferiors.',
      es: 'Presión en las rodillas y la parte anterior de las piernas, riesgo de síndrome compartimental y trombosis por flexión prolongada, e hipotensión por acumulación de sangre en las extremidades inferiores.',
      en: 'Pressure on the knees and front of the legs, risk of compartment syndrome and thrombosis from prolonged flexion, and hypotension from blood pooling in the legs.',
    ),
    care: LocalizedText(
      ca: 'Genolls molt ben encoixinats i turmells sense pressió. Comprovar els polsos distals després de col·locar-lo. Cada canvi, coordinat amb anestèsia.',
      es: 'Rodillas muy bien acolchadas y tobillos sin presión. Comprobar los pulsos distales tras colocarlo. Cada cambio, coordinado con anestesia.',
      en: 'Knees very well padded and ankles free of pressure. Check distal pulses after positioning. Coordinate every change with anaesthesia.',
    ),
  ),
  SurgicalPosition(
    id: 'fowler',
    relatedItems: ['reposapies-mesa', 'almohadilla-gel-posicionamiento', 'cinta-sujecion-paciente'],
    name: LocalizedText(ca: 'Fowler (semiassegut)', es: 'Fowler (semisentado)', en: 'Fowler (semi-sitting) position'),
    aliases: ['Fowler', 'Semi-Fowler', 'Semi-sitting'],
    family: SurgicalPositionFamily.sentado,
    description: LocalizedText(
      ca: 'Supí amb el respatller de la taula aixecat entre 30 i 90° (semi-Fowler a 30-45°, Fowler alt a 60-90°), els genolls lleugerament flexionats i els peus sobre un reposapeus.',
      es: 'Supino con el respaldo de la mesa elevado entre 30 y 90° (semi-Fowler a 30-45°, Fowler alto a 60-90°), las rodillas ligeramente flexionadas y los pies sobre un reposapiés.',
      en: 'Supine with the table back raised between 30 and 90° (semi-Fowler 30-45°, high Fowler 60-90°), knees slightly flexed and feet on a footboard.',
    ),
    procedures: LocalizedText(
      ca: 'Cirurgia de cap i coll, nas i sins, mama (reconstrucció), algunes cirurgies d\'espatlla i pacients amb dificultat respiratòria en decúbit.',
      es: 'Cirugía de cabeza y cuello, nariz y senos, mama (reconstrucción), algunas cirugías de hombro y pacientes con dificultad respiratoria en decúbito.',
      en: 'Head and neck, nose and sinus surgery, breast reconstruction, some shoulder surgery, and patients who cannot breathe lying flat.',
    ),
    risks: LocalizedText(
      ca: 'Hipotensió ortostàtica, pressió al sacre i les natges, lliscament cap als peus i, com més incorporat, més risc d\'embòlia gasosa si el camp quirúrgic és per sobre del cor.',
      es: 'Hipotensión ortostática, presión en sacro y nalgas, deslizamiento hacia los pies y, cuanto más incorporado, más riesgo de embolia gaseosa si el campo quirúrgico está por encima del corazón.',
      en: 'Orthostatic hypotension, pressure on the sacrum and buttocks, sliding towards the feet and, the more upright, a higher risk of air embolism if the surgical field is above the heart.',
    ),
    care: LocalizedText(
      ca: 'Incorporar-lo per etapes i avisant anestèsia. Coixí sota els genolls, reposapeus encoixinat i braços recolzats perquè no pengin. Cap ben subjectat.',
      es: 'Incorporarlo por etapas y avisando a anestesia. Almohada bajo las rodillas, reposapiés acolchado y brazos apoyados para que no cuelguen. Cabeza bien sujeta.',
      en: 'Sit the patient up in stages and tell anaesthesia. Pillow under the knees, padded footboard and arms supported so they do not hang. Head well secured.',
    ),
  ),
  SurgicalPosition(
    id: 'silla-playa',
    relatedItems: ['respaldo-silla-playa', 'almohadilla-gel-posicionamiento', 'cinta-sujecion-paciente'],
    name: LocalizedText(ca: 'Cadira de platja', es: 'Silla de playa', en: 'Beach chair position'),
    aliases: ['Beach chair', 'Barber chair'],
    family: SurgicalPositionFamily.sentado,
    description: LocalizedText(
      ca: 'Pacient assegut amb el tronc a uns 60-80°, el cap fixat en un capçal específic, els malucs i genolls flexionats i l\'espatlla a operar fora de la vora de la taula, amb el braç lliure o en un posabraços articulat.',
      es: 'Paciente sentado con el tronco a unos 60-80°, la cabeza fijada en un cabezal específico, caderas y rodillas flexionadas y el hombro a operar fuera del borde de la mesa, con el brazo libre o en un apoyabrazos articulado.',
      en: 'Patient sitting with the trunk at about 60-80°, head fixed in a dedicated head rest, hips and knees flexed and the operative shoulder clear of the table edge, arm free or in an articulated arm holder.',
    ),
    procedures: LocalizedText(
      ca: 'Cirurgia d\'espatlla oberta i artroscòpica: manegot dels rotadors, inestabilitat, pròtesi d\'espatlla.',
      es: 'Cirugía de hombro abierta y artroscópica: manguito de los rotadores, inestabilidad, prótesis de hombro.',
      en: 'Open and arthroscopic shoulder surgery: rotator cuff repair, instability, shoulder replacement.',
    ),
    risks: LocalizedText(
      ca: 'Hipotensió i menys perfusió cerebral (el cervell queda per sobre del punt on es mesura la pressió), embòlia gasosa, lesió del nervi auricular major o del plexe cervical si el cap queda girat o en flexió lateral, i pressió al sacre.',
      es: 'Hipotensión y menor perfusión cerebral (el cerebro queda por encima del punto donde se mide la presión), embolia gaseosa, lesión del nervio auricular mayor o del plexo cervical si la cabeza queda girada o en flexión lateral, y presión en el sacro.',
      en: 'Hypotension and reduced cerebral perfusion (the brain sits above the level where pressure is measured), air embolism, injury to the great auricular nerve or cervical plexus if the head is turned or tilted, and sacral pressure.',
    ),
    care: LocalizedText(
      ca: 'Cap neutre i ben fixat, sense pressió als ulls ni a les orelles. Pujar el respatller per etapes. Coixí sota els genolls i talons lliures. Braç contrari recolzat. Mitges o compressió pneumàtica segons protocol.',
      es: 'Cabeza neutra y bien fijada, sin presión en ojos ni orejas. Subir el respaldo por etapas. Almohada bajo las rodillas y talones libres. Brazo contrario apoyado. Medias o compresión neumática según protocolo.',
      en: 'Head neutral and well fixed, no pressure on the eyes or ears. Raise the back in stages. Pillow under the knees and heels free. Opposite arm supported. Stockings or pneumatic compression per protocol.',
    ),
  ),
  SurgicalPosition(
    id: 'sedestacion-neuroquirurgica',
    relatedItems: ['cabezal-fijacion-mayfield', 'reposapies-mesa', 'almohadilla-gel-posicionamiento'],
    name: LocalizedText(ca: 'Posició asseguda (neurocirurgia)', es: 'Posición sentada (neurocirugía)', en: 'Neurosurgical sitting position'),
    aliases: ['Sitting position', 'Neurosurgical sitting position'],
    family: SurgicalPositionFamily.sentado,
    description: LocalizedText(
      ca: 'Pacient assegut amb el tronc gairebé vertical, el cap flexionat endavant i fixat amb un capçal de punxes (tipus Mayfield) a la taula, les cames elevades a l\'altura del cor i els braços recolzats sobre la falda o sobre un coixí.',
      es: 'Paciente sentado con el tronco casi vertical, la cabeza flexionada hacia delante y fijada con un cabezal de púas (tipo Mayfield) a la mesa, las piernas elevadas a la altura del corazón y los brazos apoyados sobre el regazo o sobre una almohada.',
      en: 'Patient sitting with the trunk almost upright, head flexed forward and fixed to the table in a pin head holder (Mayfield type), legs raised to heart level and arms resting on the lap or a pillow.',
    ),
    procedures: LocalizedText(
      ca: 'Cirurgia de la fossa posterior i de la columna cervical posterior, quan el cirurgià necessita un camp sec i un bon drenatge venós.',
      es: 'Cirugía de la fosa posterior y de la columna cervical posterior, cuando el cirujano necesita un campo seco y un buen drenaje venoso.',
      en: 'Posterior fossa and posterior cervical spine surgery, when the surgeon needs a dry field and good venous drainage.',
    ),
    risks: LocalizedText(
      ca: 'Embòlia gasosa venosa (el risc principal), hipotensió, pneumocèfal, compressió de la via aèria o de la medul·la per flexió excessiva del coll, i lesió del nervi ciàtic si les cames queden estirades.',
      es: 'Embolia gaseosa venosa (el riesgo principal), hipotensión, neumoencéfalo, compresión de la vía aérea o de la médula por flexión excesiva del cuello, y lesión del nervio ciático si las piernas quedan estiradas.',
      en: 'Venous air embolism (the main risk), hypotension, pneumocephalus, airway or spinal cord compression from excessive neck flexion, and sciatic nerve injury if the legs are kept straight.',
    ),
    care: LocalizedText(
      ca: 'Deixar almenys dos dits entre la barbeta i l\'estèrnum. Genolls flexionats. Monitoratge per detectar l\'embòlia gasosa segons protocol d\'anestèsia. Sèrum a punt per inundar el camp si entra aire. Comprovar el capçal abans de moure la taula.',
      es: 'Dejar al menos dos dedos entre el mentón y el esternón. Rodillas flexionadas. Monitorización para detectar la embolia gaseosa según protocolo de anestesia. Suero preparado para inundar el campo si entra aire. Comprobar el cabezal antes de mover la mesa.',
      en: 'Leave at least two finger-breadths between chin and sternum. Knees flexed. Monitoring for air embolism per the anaesthesia protocol. Saline ready to flood the field if air is entrained. Check the head holder before moving the table.',
    ),
  ),
];
