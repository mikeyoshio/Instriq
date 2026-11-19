import '../models/instrument.dart' show LocalizedText;
import '../models/perioperative_guide.dart';

/// Guies perioperatòries. Text propi a partir de recomanacions generals
/// (OMS, guies d'infermeria quirúrgica); mai dosis de fàrmacs.
const List<PerioperativeGuide> kPerioperativeGuides = [
  PerioperativeGuide(
    id: 'lavado-quirurgico',
    name: LocalizedText(ca: 'Rentat quirúrgic de mans', es: 'Lavado quirúrgico de manos', en: 'Surgical hand antisepsis'),
    aliases: ['Surgical hand antisepsis', 'Surgical scrub', 'Lavado de manos quirúrgico'],
    area: GuideArea.asepsia,
    summary: LocalizedText(
      ca: 'Elimina la brutícia i redueix al màxim la flora de mans i avantbraços abans de posar-se la bata i els guants estèrils. Es pot fer amb solució alcohòlica o amb sabó antisèptic i aigua.',
      es: 'Elimina la suciedad y reduce al máximo la flora de manos y antebrazos antes de ponerse la bata y los guantes estériles. Puede hacerse con solución alcohólica o con jabón antiséptico y agua.',
      en: 'Removes dirt and reduces hand and forearm flora as far as possible before putting on a sterile gown and gloves. It can be done with an alcohol-based rub or with antiseptic soap and water.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Abans de començar', es: 'Antes de empezar', en: 'Before you start'),
        LocalizedText(
          ca: '• Ungles curtes i sense esmalt ni ungles artificials.\n• Sense anells, rellotge ni polseres.\n• Gorro que cobreixi tot el cabell i mascareta ben ajustada abans del rentat.\n• Primer rentat del dia: netejar sota les ungles amb el netejador d\'ungles.',
          es: '• Uñas cortas y sin esmalte ni uñas artificiales.\n• Sin anillos, reloj ni pulseras.\n• Gorro que cubra todo el pelo y mascarilla bien ajustada antes del lavado.\n• Primer lavado del día: limpiar bajo las uñas con el limpiaúñas.',
          en: '• Short nails, no polish or artificial nails.\n• No rings, watch or bracelets.\n• Cap covering all hair and a well-fitted mask before scrubbing.\n• First scrub of the day: clean under the nails with a nail cleaner.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Amb solució alcohòlica', es: 'Con solución alcohólica', en: 'Alcohol-based rub'),
        LocalizedText(
          ca: 'Mans netes i seques. Aplicar el producte a mans i avantbraços fins als colzes, en diverses dosis, seguint el temps i la tècnica que indica el fabricant (habitualment entre 2 i 5 minuts en total). Deixar assecar del tot abans de posar-se els guants.',
          es: 'Manos limpias y secas. Aplicar el producto en manos y antebrazos hasta los codos, en varias tomas, siguiendo el tiempo y la técnica que indica el fabricante (habitualmente entre 2 y 5 minutos en total). Dejar secar del todo antes de ponerse los guantes.',
          en: 'Clean, dry hands. Apply the product to hands and forearms up to the elbows in several applications, following the manufacturer\'s time and technique (usually 2 to 5 minutes in total). Let it dry completely before gloving.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Amb sabó antisèptic', es: 'Con jabón antiséptico', en: 'Antiseptic soap'),
        LocalizedText(
          ca: 'Mullar mans i avantbraços, aplicar el sabó i fregar per zones (dits, palmells, dors, canells, avantbraços) el temps que indica el fabricant. Esbandir des de la punta dels dits cap al colze, amb les mans sempre per sobre dels colzes perquè l\'aigua no torni cap a les mans. Assecar amb tovallola estèril.',
          es: 'Mojar manos y antebrazos, aplicar el jabón y frotar por zonas (dedos, palmas, dorso, muñecas, antebrazos) el tiempo que indica el fabricante. Aclarar desde la punta de los dedos hacia el codo, con las manos siempre por encima de los codos para que el agua no vuelva hacia las manos. Secar con toalla estéril.',
          en: 'Wet hands and forearms, apply the soap and scrub area by area (fingers, palms, backs, wrists, forearms) for the manufacturer\'s time. Rinse from fingertips to elbow, keeping the hands above the elbows so water does not run back. Dry with a sterile towel.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Errors habituals', es: 'Errores habituales', en: 'Common mistakes'),
        LocalizedText(
          ca: '• Tocar l\'aixeta, la mascareta o la roba després del rentat: cal tornar a començar.\n• Posar-se els guants amb l\'alcohol encara humit.\n• Fer servir raspall sobre la pell: irrita i no millora el resultat.',
          es: '• Tocar el grifo, la mascarilla o la ropa tras el lavado: hay que volver a empezar.\n• Ponerse los guantes con el alcohol todavía húmedo.\n• Usar cepillo sobre la piel: irrita y no mejora el resultado.',
          en: '• Touching the tap, mask or clothing after scrubbing: start again.\n• Gloving while the alcohol is still wet.\n• Using a brush on the skin: it irritates and does not improve the result.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'vestido-enguantado',
    name: LocalizedText(ca: 'Posar-se bata i guants estèrils', es: 'Vestido con bata y guantes estériles', en: 'Sterile gowning and gloving'),
    aliases: ['Gowning and gloving', 'Closed gloving', 'Doble guante'],
    area: GuideArea.asepsia,
    summary: LocalizedText(
      ca: 'Després del rentat quirúrgic, la bata i els guants estèrils fan de barrera entre l\'equip i el camp. La tècnica tancada evita que la mà nua toqui la part externa dels guants.',
      es: 'Tras el lavado quirúrgico, la bata y los guantes estériles hacen de barrera entre el equipo y el campo. La técnica cerrada evita que la mano desnuda toque la parte externa de los guantes.',
      en: 'After surgical hand antisepsis, the sterile gown and gloves form the barrier between the team and the field. The closed technique keeps the bare hand from touching the outside of the gloves.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Bata', es: 'Bata', en: 'Gown'),
        LocalizedText(
          ca: 'Agafar la bata per l\'interior del coll, deixar que es desplegui sense tocar res i ficar els braços a les mànigues sense treure les mans pels punys (tècnica tancada). La infermera circulant lliga l\'interior per darrere. El cinturó es lliga un cop posats els guants, girant amb l\'ajuda d\'un company estèril o la targeta de la bata.',
          es: 'Coger la bata por el interior del cuello, dejar que se despliegue sin tocar nada y meter los brazos en las mangas sin sacar las manos por los puños (técnica cerrada). La enfermera circulante ata el interior por detrás. El cinturón se ata una vez puestos los guantes, girando con ayuda de un compañero estéril o la tarjeta de la bata.',
          en: 'Hold the gown by the inside of the neck, let it unfold without touching anything and slide the arms into the sleeves without pushing the hands through the cuffs (closed technique). The circulating nurse ties the inside at the back. The belt is tied after gloving, turning with a sterile colleague or the gown\'s card.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Guants', es: 'Guantes', en: 'Gloves'),
        LocalizedText(
          ca: 'Amb tècnica tancada, el guant es col·loca sobre el puny de la bata amb la mà encara dins de la màniga i s\'estira cap amunt. Es recomana el doble guant en cirurgia: la parella interior, sovint de color, fa veure les perforacions del guant exterior.',
          es: 'Con técnica cerrada, el guante se coloca sobre el puño de la bata con la mano aún dentro de la manga y se estira hacia arriba. Se recomienda el doble guante en cirugía: el par interior, a menudo de color, permite ver las perforaciones del guante exterior.',
          en: 'With the closed technique, the glove is placed over the gown cuff with the hand still inside the sleeve and pulled up. Double gloving is recommended: the inner pair, often coloured, shows perforations in the outer glove.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Què és estèril', es: 'Qué es estéril', en: 'What counts as sterile'),
        LocalizedText(
          ca: 'De la bata, només la part davantera des del pit fins a la cintura (o l\'alçada de la taula) i les mànigues fins a uns centímetres per sobre del colze. L\'esquena, les aixelles i per sota de la cintura no es consideren estèrils. Les mans sempre a la vista, entre la cintura i les espatlles.',
          es: 'De la bata, solo la parte delantera desde el pecho hasta la cintura (o la altura de la mesa) y las mangas hasta unos centímetros por encima del codo. La espalda, las axilas y por debajo de la cintura no se consideran estériles. Las manos siempre a la vista, entre la cintura y los hombros.',
          en: 'Only the front of the gown from chest to waist (or table height) and the sleeves to a few centimetres above the elbow. The back, armpits and below the waist are not considered sterile. Keep the hands in view, between waist and shoulders.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Canviar-se', es: 'Cambiarse', en: 'Changing'),
        LocalizedText(
          ca: 'Canviar el guant exterior si es perfora, es contamina o segons el protocol del centre (per exemple, abans de manipular una pròtesi). Si la bata es contamina, cal canviar bata i guants.',
          es: 'Cambiar el guante exterior si se perfora, se contamina o según el protocolo del centro (por ejemplo, antes de manipular una prótesis). Si la bata se contamina, hay que cambiar bata y guantes.',
          en: 'Change the outer glove if it is perforated or contaminated, or per local protocol (for example, before handling an implant). If the gown is contaminated, change both gown and gloves.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'campo-esteril',
    name: LocalizedText(ca: 'Camp estèril i muntatge de la taula', es: 'Campo estéril y montaje de la mesa', en: 'Sterile field and back table setup'),
    aliases: ['Sterile field', 'Back table setup', 'Aseptic technique', 'Mesa de instrumental'],
    area: GuideArea.asepsia,
    summary: LocalizedText(
      ca: 'El camp estèril és l\'àrea al voltant del pacient i les taules on només hi entra material i personal estèril. Muntar-lo bé i mantenir-lo és feina de tot l\'equip.',
      es: 'El campo estéril es el área alrededor del paciente y las mesas donde solo entra material y personal estéril. Montarlo bien y mantenerlo es trabajo de todo el equipo.',
      en: 'The sterile field is the area around the patient and tables where only sterile items and scrubbed staff belong. Setting it up and keeping it sterile is the whole team\'s job.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Abans d\'obrir', es: 'Antes de abrir', en: 'Before opening'),
        LocalizedText(
          ca: '• Comprovar l\'envàs: íntegre, sec, dins de data i amb l\'indicador químic virat.\n• Obrir el material el més a prop possible de l\'inici de la intervenció.\n• Taules netes i a l\'alçada de treball; cap corrent d\'aire dirigit al camp.',
          es: '• Comprobar el envase: íntegro, seco, en fecha y con el indicador químico virado.\n• Abrir el material lo más cerca posible del inicio de la intervención.\n• Mesas limpias y a la altura de trabajo; ninguna corriente de aire dirigida al campo.',
          en: '• Check the pack: intact, dry, in date and with the chemical indicator changed.\n• Open as close as possible to the start of surgery.\n• Clean tables at working height; no draughts directed at the field.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Muntatge', es: 'Montaje', en: 'Setting up'),
        LocalizedText(
          ca: 'La infermera instrumentista ordena l\'instrumental segons l\'ordre d\'ús i la seva manera habitual de treballar, perquè qualsevol company pugui trobar-ho. Comprova la integritat i el funcionament de cada instrument i l\'indicador intern de cada contenidor. La taula de Mayo porta només el que s\'usarà de seguida.',
          es: 'La enfermera instrumentista ordena el instrumental según el orden de uso y su forma habitual de trabajar, para que cualquier compañero pueda encontrarlo. Comprueba la integridad y el funcionamiento de cada instrumento y el indicador interno de cada contenedor. La mesa de Mayo lleva solo lo que se usará enseguida.',
          en: 'The scrub nurse arranges instruments in order of use, in a consistent layout any colleague can follow. Check each instrument\'s integrity and function and the internal indicator in each container. The Mayo stand holds only what will be used next.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Principis d\'asèpsia', es: 'Principios de asepsia', en: 'Aseptic principles'),
        LocalizedText(
          ca: '• Si hi ha dubte sobre l\'esterilitat, es considera contaminat.\n• Estèril només toca estèril; el personal estèril es creua esquena amb esquena.\n• Les vores de l\'envàs i dels talls de camp no són estèrils.\n• Un camp mullat ja no fa de barrera: cal cobrir-lo amb un camp sec.\n• El camp no es deixa mai sol un cop obert.',
          es: '• Si hay duda sobre la esterilidad, se considera contaminado.\n• Estéril solo toca estéril; el personal estéril se cruza espalda con espalda.\n• Los bordes del envase y de los paños no son estériles.\n• Un campo mojado ya no hace de barrera: hay que cubrirlo con un paño seco.\n• El campo no se deja nunca solo una vez abierto.',
          en: '• If in doubt about sterility, consider it contaminated.\n• Sterile touches only sterile; scrubbed staff pass back to back.\n• Pack edges and drape edges are not sterile.\n• A wet drape is no longer a barrier: cover it with a dry one.\n• Never leave an opened field unattended.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'electrocirugia',
    name: LocalizedText(ca: 'Seguretat amb el bisturí elèctric', es: 'Seguridad con el bisturí eléctrico', en: 'Electrosurgery safety'),
    aliases: ['Electrosurgery safety', 'Bisturí eléctrico', 'Placa neutra', 'Return electrode'],
    area: GuideArea.seguridad,
    summary: LocalizedText(
      ca: 'El bisturí elèctric talla i coagula fent passar corrent pel teixit. Els riscos principals són les cremades a la placa o en punts de contacte, el foc al camp i les interferències amb dispositius implantats.',
      es: 'El bisturí eléctrico corta y coagula haciendo pasar corriente por el tejido. Los riesgos principales son las quemaduras en la placa o en puntos de contacto, el fuego en el campo y las interferencias con dispositivos implantados.',
      en: 'The electrosurgical unit cuts and coagulates by passing current through tissue. The main risks are burns at the pad or contact points, surgical fires and interference with implanted devices.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Placa de retorn (monopolar)', es: 'Placa de retorno (monopolar)', en: 'Return electrode (monopolar)'),
        LocalizedText(
          ca: '• Sobre múscul ben irrigat, a prop del camp: cuixa, natja, braç.\n• Pell neta, seca i sense pèl; mai sobre prominències òssies, cicatrius, tatuatges ni pròtesis metàl·liques.\n• Adherida del tot, sense plecs; no tallar-la ni recol·locar-la si ja s\'ha enganxat.\n• Revisar-la de nou després de qualsevol canvi de postura.',
          es: '• Sobre músculo bien irrigado, cerca del campo: muslo, nalga, brazo.\n• Piel limpia, seca y sin vello; nunca sobre prominencias óseas, cicatrices, tatuajes ni prótesis metálicas.\n• Adherida del todo, sin pliegues; no cortarla ni recolocarla si ya se ha pegado.\n• Revisarla de nuevo tras cualquier cambio de postura.',
          en: '• On well-perfused muscle close to the site: thigh, buttock, arm.\n• Clean, dry, hair-free skin; never over bony prominences, scars, tattoos or metal implants.\n• Fully adhered with no folds; do not cut it or reposition it once applied.\n• Recheck it after any change of position.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Al camp', es: 'En el campo', en: 'In the field'),
        LocalizedText(
          ca: '• Guardar el llapis a la funda quan no s\'usa: es pot activar sense voler.\n• Netejar l\'escara de la punta per mantenir l\'eficàcia.\n• Potència més baixa que funcioni.\n• Cap part del pacient en contacte amb metall de la taula.\n• Aspirador de fums quan se\'n produeixen molts.',
          es: '• Guardar el lápiz en la funda cuando no se usa: puede activarse sin querer.\n• Limpiar la escara de la punta para mantener la eficacia.\n• La potencia más baja que funcione.\n• Ninguna parte del paciente en contacto con metal de la mesa.\n• Aspirador de humos cuando se producen muchos.',
          en: '• Holster the pencil when not in use: it can be activated by accident.\n• Clean char off the tip to keep it effective.\n• Use the lowest effective power.\n• No part of the patient touching metal on the table.\n• Smoke evacuation when a lot of plume is produced.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Foc al camp', es: 'Fuego en el campo', en: 'Surgical fire'),
        LocalizedText(
          ca: 'Cal combustible (antisèptic alcohòlic, camps), oxigen i una font d\'ignició (bisturí, làser). Deixar assecar del tot l\'antisèptic alcohòlic i que no faci bassal sota el pacient abans de posar camps. Avisar anestèsia quan s\'usa el bisturí a prop de la via aèria amb oxigen alt.',
          es: 'Hace falta combustible (antiséptico alcohólico, paños), oxígeno y una fuente de ignición (bisturí, láser). Dejar secar del todo el antiséptico alcohólico y que no haga charco bajo el paciente antes de poner paños. Avisar a anestesia cuando se usa el bisturí cerca de la vía aérea con oxígeno alto.',
          en: 'It takes fuel (alcohol-based prep, drapes), oxygen and an ignition source (diathermy, laser). Let alcohol-based prep dry completely and make sure it does not pool under the patient before draping. Warn anaesthesia when using diathermy near the airway with high oxygen.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Marcapassos i DAI', es: 'Marcapasos y DAI', en: 'Pacemakers and ICDs'),
        LocalizedText(
          ca: 'Informar-ne l\'equip abans de començar: es prefereix el bipolar; si cal monopolar, la placa s\'ha de col·locar de manera que el corrent no passi pel dispositiu, i se segueix el protocol de cardiologia o anestèsia per programar-lo.',
          es: 'Informar al equipo antes de empezar: se prefiere el bipolar; si hace falta monopolar, la placa debe colocarse de modo que la corriente no pase por el dispositivo, y se sigue el protocolo de cardiología o anestesia para programarlo.',
          en: 'Tell the team before starting: bipolar is preferred; if monopolar is needed, place the pad so current does not cross the device, and follow the cardiology or anaesthesia protocol for reprogramming.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'recuento-quirurgico',
    name: LocalizedText(ca: 'Recompte quirúrgic', es: 'Recuento quirúrgico', en: 'Surgical count'),
    aliases: ['Surgical count', 'Recuento de gasas', 'Retained surgical item'],
    area: GuideArea.seguridad,
    summary: LocalizedText(
      ca: 'El recompte de gases, compreses, agulles i instrumental evita deixar material dins del pacient. Es fa en veu alta entre la infermera instrumentista i la circulant, i es registra.',
      es: 'El recuento de gasas, compresas, agujas e instrumental evita dejar material dentro del paciente. Se hace en voz alta entre la enfermera instrumentista y la circulante, y se registra.',
      en: 'Counting swabs, sponges, needles and instruments prevents items being left inside the patient. It is done aloud by the scrub and circulating nurses and recorded.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Quan es compta', es: 'Cuándo se cuenta', en: 'When to count'),
        LocalizedText(
          ca: '• Abans de començar (recompte inicial).\n• Quan s\'afegeix material.\n• Abans de tancar una cavitat dins d\'una altra (per exemple, l\'úter abans de l\'abdomen).\n• Abans de tancar la paret i abans de tancar la pell.\n• Quan canvia la infermera instrumentista o la circulant.',
          es: '• Antes de empezar (recuento inicial).\n• Cuando se añade material.\n• Antes de cerrar una cavidad dentro de otra (por ejemplo, el útero antes del abdomen).\n• Antes de cerrar la pared y antes de cerrar la piel.\n• Cuando cambia la enfermera instrumentista o la circulante.',
          en: '• Before starting (baseline count).\n• When items are added.\n• Before closing a cavity within a cavity (e.g. the uterus before the abdomen).\n• Before closing the fascia and before closing the skin.\n• When the scrub or circulating nurse changes.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Com es compta', es: 'Cómo se cuenta', en: 'How to count'),
        LocalizedText(
          ca: 'Les dues infermeres miren i compten alhora en veu alta, separant cada unitat. Només gases i compreses radiopaques al camp. No tallar mai gases ni compreses. Les agulles usades, al comptador d\'agulles. El material que es retira del camp no surt del quiròfan fins al final.',
          es: 'Las dos enfermeras miran y cuentan a la vez en voz alta, separando cada unidad. Solo gasas y compresas radiopacas en el campo. No cortar nunca gasas ni compresas. Las agujas usadas, al contador de agujas. El material que se retira del campo no sale del quirófano hasta el final.',
          en: 'Both nurses look and count aloud together, separating each item. Only radiopaque swabs and sponges in the field. Never cut swabs or sponges. Used needles go in the needle counter. Nothing counted leaves the theatre until the end.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Si no quadra', es: 'Si no cuadra', en: 'If the count is wrong'),
        LocalizedText(
          ca: 'Avisar el cirurgià de seguida i abans de tancar. Buscar al camp, a la ferida, al terra i a les bosses. Si no apareix, radiografia segons el protocol. Registrar-ho i notificar-ho com a incident encara que aparegui.',
          es: 'Avisar al cirujano enseguida y antes de cerrar. Buscar en el campo, la herida, el suelo y las bolsas. Si no aparece, radiografía según protocolo. Registrarlo y notificarlo como incidente aunque aparezca.',
          en: 'Tell the surgeon immediately and before closing. Search the field, wound, floor and bins. If it is not found, X-ray per protocol. Record it and report it as an incident even if it turns up.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'checklist-oms',
    name: LocalizedText(ca: 'Llistat de verificació quirúrgica de l\'OMS', es: 'Listado de verificación quirúrgica de la OMS', en: 'WHO surgical safety checklist'),
    aliases: ['WHO surgical safety checklist', 'Listado de verificación quirúrgica', 'Time out', 'Pausa quirúrgica'],
    area: GuideArea.seguridad,
    summary: LocalizedText(
      ca: 'Llista de comprovacions en tres moments de la intervenció que redueix errors de pacient, lloc i procediment, i complicacions evitables. Funciona si tot l\'equip s\'atura i hi participa en veu alta.',
      es: 'Lista de comprobaciones en tres momentos de la intervención que reduce errores de paciente, lugar y procedimiento, y complicaciones evitables. Funciona si todo el equipo se detiene y participa en voz alta.',
      en: 'A list of checks at three points in the operation that reduces wrong patient, site and procedure errors and avoidable complications. It works when the whole team stops and takes part aloud.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: '1. Abans de la inducció anestèsica', es: '1. Antes de la inducción anestésica', en: '1. Before induction of anaesthesia'),
        LocalizedText(
          ca: '• Identitat del pacient, lloc, procediment i consentiment confirmats.\n• Lloc quirúrgic marcat, si cal.\n• Comprovació de l\'equip d\'anestèsia i pulsioxímetre funcionant.\n• Al·lèrgies conegudes.\n• Via aèria difícil o risc d\'aspiració.\n• Risc de sagnat important i reserva de sang preparada.',
          es: '• Identidad del paciente, lugar, procedimiento y consentimiento confirmados.\n• Lugar quirúrgico marcado, si procede.\n• Comprobación del equipo de anestesia y pulsioxímetro funcionando.\n• Alergias conocidas.\n• Vía aérea difícil o riesgo de aspiración.\n• Riesgo de sangrado importante y reserva de sangre preparada.',
          en: '• Patient identity, site, procedure and consent confirmed.\n• Site marked, if applicable.\n• Anaesthesia equipment check done and pulse oximeter working.\n• Known allergies.\n• Difficult airway or aspiration risk.\n• Risk of major blood loss and blood available.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: '2. Abans de la incisió (pausa quirúrgica)', es: '2. Antes de la incisión (pausa quirúrgica)', en: '2. Before skin incision (time out)'),
        LocalizedText(
          ca: '• Tots els membres de l\'equip es presenten pel nom i la funció.\n• Es confirma en veu alta pacient, lloc i procediment.\n• Cirurgià: passos crítics, durada i sagnat previst.\n• Anestèsia: aspectes específics del pacient.\n• Infermeria: esterilitat confirmada (indicadors) i problemes d\'equipament.\n• Profilaxi antibiòtica administrada en el temps indicat.\n• Imatges essencials a la vista.',
          es: '• Todos los miembros del equipo se presentan por nombre y función.\n• Se confirma en voz alta paciente, lugar y procedimiento.\n• Cirujano: pasos críticos, duración y sangrado previsto.\n• Anestesia: aspectos específicos del paciente.\n• Enfermería: esterilidad confirmada (indicadores) y problemas de equipamiento.\n• Profilaxis antibiótica administrada en el tiempo indicado.\n• Imágenes esenciales a la vista.',
          en: '• Everyone introduces themselves by name and role.\n• Patient, site and procedure confirmed aloud.\n• Surgeon: critical steps, duration and expected blood loss.\n• Anaesthesia: patient-specific concerns.\n• Nursing: sterility confirmed (indicators) and equipment issues.\n• Antibiotic prophylaxis given within the right time.\n• Essential imaging displayed.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: '3. Abans que el pacient surti del quiròfan', es: '3. Antes de que el paciente salga del quirófano', en: '3. Before the patient leaves theatre'),
        LocalizedText(
          ca: '• Nom del procediment realitzat.\n• Recompte de gases, agulles i instrumental correcte.\n• Mostres etiquetades, llegint l\'etiqueta en veu alta amb el nom del pacient.\n• Problemes amb l\'equipament que s\'han de resoldre.\n• Aspectes clau per a la recuperació del pacient.',
          es: '• Nombre del procedimiento realizado.\n• Recuento de gasas, agujas e instrumental correcto.\n• Muestras etiquetadas, leyendo la etiqueta en voz alta con el nombre del paciente.\n• Problemas con el equipamiento que hay que resolver.\n• Aspectos clave para la recuperación del paciente.',
          en: '• Name of the procedure performed.\n• Swab, needle and instrument counts correct.\n• Specimens labelled, reading the label aloud including the patient\'s name.\n• Equipment problems to be addressed.\n• Key concerns for the patient\'s recovery.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'isquemia-manguito',
    name: LocalizedText(ca: 'Isquèmia amb maniguet pneumàtic', es: 'Isquemia con manguito neumático', en: 'Pneumatic tourniquet'),
    aliases: ['Pneumatic tourniquet', 'Torniquete', 'Manguito de isquemia', 'Esmarch'],
    area: GuideArea.paciente,
    summary: LocalizedText(
      ca: 'El maniguet d\'isquèmia deixa l\'extremitat sense flux de sang per operar en un camp sec. Ben usat és segur, però la pressió i el temps excessius lesionen nervis, múscul i pell.',
      es: 'El manguito de isquemia deja la extremidad sin flujo de sangre para operar en un campo seco. Bien usado es seguro, pero la presión y el tiempo excesivos lesionan nervios, músculo y piel.',
      en: 'The tourniquet stops blood flow to the limb so surgery can be done in a bloodless field. Used well it is safe, but excessive pressure or time injures nerves, muscle and skin.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Col·locació', es: 'Colocación', en: 'Application'),
        LocalizedText(
          ca: '• Maniguet de l\'amplada adequada a l\'extremitat, a la part més proximal i gruixuda.\n• Protecció de cotó sota el maniguet, sense plecs.\n• Que l\'antisèptic no regalimi sota el maniguet: provoca cremades químiques.\n• Comprovar abans el funcionament i que no hi hagi fuites.',
          es: '• Manguito de la anchura adecuada a la extremidad, en la parte más proximal y gruesa.\n• Protección de algodón bajo el manguito, sin pliegues.\n• Que el antiséptico no se escurra bajo el manguito: provoca quemaduras químicas.\n• Comprobar antes el funcionamiento y que no haya fugas.',
          en: '• Cuff of the right width for the limb, on the most proximal, thickest part.\n• Cotton padding under the cuff, with no wrinkles.\n• Do not let prep solution run under the cuff: it causes chemical burns.\n• Check function and leaks beforehand.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Inflat i temps', es: 'Inflado y tiempo', en: 'Inflation and time'),
        LocalizedText(
          ca: 'La pressió la fixa el cirurgià segons el protocol, sovint a partir de la pressió d\'oclusió de l\'extremitat. Abans d\'inflar es pot fer l\'exsanguinació amb una bena d\'Esmarch, excepte si hi ha infecció, tumor o sospita de trombosi. Anotar l\'hora d\'inflat i avisar el cirurgià a intervals regulars; el temps màxim recomanat el marca el protocol (sovint unes dues hores seguides).',
          es: 'La presión la fija el cirujano según el protocolo, a menudo a partir de la presión de oclusión de la extremidad. Antes de inflar se puede hacer la exanguinación con una venda de Esmarch, salvo si hay infección, tumor o sospecha de trombosis. Anotar la hora de inflado y avisar al cirujano a intervalos regulares; el tiempo máximo recomendado lo marca el protocolo (a menudo unas dos horas seguidas).',
          en: 'The surgeon sets the pressure per protocol, often based on limb occlusion pressure. Before inflating, the limb can be exsanguinated with an Esmarch bandage, except with infection, tumour or suspected thrombosis. Record the inflation time and remind the surgeon at regular intervals; the protocol sets the maximum time (often about two hours continuously).',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Desinflat', es: 'Desinflado', en: 'Deflation'),
        LocalizedText(
          ca: 'Avisar anestèsia abans de desinflar: el retorn de la sang pot fer baixar la pressió arterial. Anotar l\'hora de desinflat i el temps total, i revisar la pell sota el maniguet.',
          es: 'Avisar a anestesia antes de desinflar: el retorno de la sangre puede bajar la presión arterial. Anotar la hora de desinflado y el tiempo total, y revisar la piel bajo el manguito.',
          en: 'Tell anaesthesia before deflating: reperfusion can drop the blood pressure. Record deflation time and total time, and check the skin under the cuff.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'drenajes-quirurgicos',
    name: LocalizedText(ca: 'Drenatges quirúrgics', es: 'Drenajes quirúrgicos', en: 'Surgical drains'),
    aliases: ['Surgical drains', 'Redon', 'Blake', 'Jackson-Pratt', 'Penrose', 'Drenaje torácico'],
    area: GuideArea.material,
    summary: LocalizedText(
      ca: 'Els drenatges treuen sang, sèrum, bilis o aire d\'una ferida o cavitat perquè no s\'acumulin. Poden ser passius (per gravetat o capil·laritat) o actius (amb buit), i oberts o tancats.',
      es: 'Los drenajes sacan sangre, suero, bilis o aire de una herida o cavidad para que no se acumulen. Pueden ser pasivos (por gravedad o capilaridad) o activos (con vacío), y abiertos o cerrados.',
      en: 'Drains remove blood, serum, bile or air from a wound or cavity so they do not collect. They may be passive (gravity or capillary action) or active (suction), open or closed.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Tipus habituals', es: 'Tipos habituales', en: 'Common types'),
        LocalizedText(
          ca: '• Penrose: làmina de goma tova, passiu i obert.\n• Redon: tub multiperforat amb flascó de buit, actiu i tancat.\n• Blake o Jackson-Pratt: tub acanalat o pla amb pera de silicona, actiu i tancat.\n• Drenatge toràcic: tub connectat a un sistema amb segell d\'aigua, per a aire o líquid de la pleura.\n• Tub en T (Kehr): a la via biliar.',
          es: '• Penrose: lámina de goma blanda, pasivo y abierto.\n• Redon: tubo multiperforado con frasco de vacío, activo y cerrado.\n• Blake o Jackson-Pratt: tubo acanalado o plano con pera de silicona, activo y cerrado.\n• Drenaje torácico: tubo conectado a un sistema con sello de agua, para aire o líquido de la pleura.\n• Tubo en T (Kehr): en la vía biliar.',
          en: '• Penrose: soft rubber sheet, passive and open.\n• Redon: multi-perforated tube with a vacuum bottle, active and closed.\n• Blake or Jackson-Pratt: fluted or flat tube with a silicone bulb, active and closed.\n• Chest drain: tube connected to an underwater-seal system, for air or fluid in the pleura.\n• T-tube (Kehr): in the bile duct.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Al quiròfan', es: 'En el quirófano', en: 'In theatre'),
        LocalizedText(
          ca: 'Fixar el drenatge a la pell, connectar-lo abans de treure els camps i activar el buit. Etiquetar cada drenatge si n\'hi ha més d\'un i anotar-ne la localització al registre.',
          es: 'Fijar el drenaje a la piel, conectarlo antes de retirar los paños y activar el vacío. Etiquetar cada drenaje si hay más de uno y anotar su localización en el registro.',
          en: 'Secure the drain to the skin, connect it before removing the drapes and activate suction. Label each drain if there is more than one and record its site.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Cures', es: 'Cuidados', en: 'Care'),
        LocalizedText(
          ca: '• Recipient per sota del punt d\'inserció i sense colzes al tub.\n• Comprovar que el buit es manté (pera o flascó comprimits).\n• Registrar quantitat i aspecte del contingut; avisar si és sang abundant o canvia de cop.\n• No pinçar un drenatge toràcic de manera rutinària; seguir el protocol.',
          es: '• Recipiente por debajo del punto de inserción y sin acodaduras en el tubo.\n• Comprobar que el vacío se mantiene (pera o frasco comprimidos).\n• Registrar cantidad y aspecto del contenido; avisar si es sangre abundante o cambia de golpe.\n• No pinzar un drenaje torácico de forma rutinaria; seguir el protocolo.',
          en: '• Collector below the insertion site and no kinks in the tube.\n• Check suction is maintained (bulb or bottle compressed).\n• Record volume and appearance; report heavy bleeding or sudden changes.\n• Do not routinely clamp a chest drain; follow protocol.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'sondas',
    name: LocalizedText(ca: 'Sondatge vesical i nasogàstric', es: 'Sondaje vesical y nasogástrico', en: 'Urinary and nasogastric catheters'),
    aliases: ['Urinary catheter', 'Sonda vesical', 'Nasogastric tube', 'Sonda nasogástrica'],
    area: GuideArea.material,
    summary: LocalizedText(
      ca: 'Al quiròfan les sondes més habituals són la vesical, per buidar la bufeta i controlar la diüresi, i la nasogàstrica, per descomprimir l\'estómac.',
      es: 'En el quirófano las sondas más habituales son la vesical, para vaciar la vejiga y controlar la diuresis, y la nasogástrica, para descomprimir el estómago.',
      en: 'In theatre the most common tubes are the urinary catheter, to drain the bladder and monitor urine output, and the nasogastric tube, to decompress the stomach.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Sonda vesical', es: 'Sonda vesical', en: 'Urinary catheter'),
        LocalizedText(
          ca: '• Indicació clara: cirurgia llarga, pelviana, control de diüresi o retenció.\n• Tècnica estèril i sistema tancat des del principi.\n• Inflar el baló amb aigua estèril només quan surt orina.\n• Bossa per sota de la bufeta i sense colzes; fixar la sonda a la cuixa.\n• Retirar-la tan aviat com no calgui: cada dia de sonda augmenta el risc d\'infecció.',
          es: '• Indicación clara: cirugía larga, pélvica, control de diuresis o retención.\n• Técnica estéril y sistema cerrado desde el principio.\n• Inflar el balón con agua estéril solo cuando sale orina.\n• Bolsa por debajo de la vejiga y sin acodaduras; fijar la sonda al muslo.\n• Retirarla en cuanto no haga falta: cada día de sonda aumenta el riesgo de infección.',
          en: '• Clear indication: long or pelvic surgery, urine output monitoring or retention.\n• Sterile technique and a closed system from the start.\n• Inflate the balloon with sterile water only once urine flows.\n• Bag below the bladder and unkinked; secure the catheter to the thigh.\n• Remove it as soon as it is no longer needed: each day raises the infection risk.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Sonda nasogàstrica', es: 'Sonda nasogástrica', en: 'Nasogastric tube'),
        LocalizedText(
          ca: '• Mesurar la llargada del nas al lòbul de l\'orella i fins a l\'apòfisi xifoide.\n• Amb el pacient intubat la col·loca anestèsia; si costa, ajuda la laringoscòpia.\n• Comprovar la posició (aspirat gàstric, radiografia segons protocol) abans de fer-la servir.\n• Fixar-la al nas sense pressionar l\'ala nasal.',
          es: '• Medir la longitud de la nariz al lóbulo de la oreja y hasta el apéndice xifoides.\n• Con el paciente intubado la coloca anestesia; si cuesta, ayuda la laringoscopia.\n• Comprobar la posición (aspirado gástrico, radiografía según protocolo) antes de usarla.\n• Fijarla a la nariz sin presionar el ala nasal.',
          en: '• Measure from the nose to the earlobe and down to the xiphoid.\n• In an intubated patient anaesthesia places it; laryngoscopy helps if it is difficult.\n• Confirm position (gastric aspirate, X-ray per protocol) before use.\n• Secure it to the nose without pressing on the nostril.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'apositos-quirurgicos',
    name: LocalizedText(ca: 'Apòsits de la ferida quirúrgica', es: 'Apósitos de la herida quirúrgica', en: 'Surgical wound dressings'),
    aliases: ['Surgical dressings', 'Wound dressing', 'Apósito', 'NPWT', 'Terapia de presión negativa'],
    area: GuideArea.material,
    summary: LocalizedText(
      ca: 'L\'apòsit protegeix la incisió de la contaminació i absorbeix l\'exsudat les primeres hores, mentre la ferida es tanca. Es posa al quiròfan amb tècnica estèril.',
      es: 'El apósito protege la incisión de la contaminación y absorbe el exudado las primeras horas, mientras la herida se cierra. Se coloca en el quirófano con técnica estéril.',
      en: 'The dressing protects the incision from contamination and absorbs exudate in the first hours while the wound seals. It is applied in theatre with sterile technique.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Tipus', es: 'Tipos', en: 'Types'),
        LocalizedText(
          ca: '• Apòsit adhesiu amb coixinet absorbent: el més habitual.\n• Pel·lícula transparent: deixa veure la ferida; per a ferides amb poc exsudat.\n• Hidrocol·loide o d\'escuma: més absorbents, ferides amb més exsudat.\n• Amb plata o antimicrobià: segons protocol en risc d\'infecció.\n• Teràpia de pressió negativa incisional: en pacients d\'alt risc segons indicació del cirurgià.',
          es: '• Apósito adhesivo con almohadilla absorbente: el más habitual.\n• Película transparente: deja ver la herida; para heridas con poco exudado.\n• Hidrocoloide o de espuma: más absorbentes, heridas con más exudado.\n• Con plata o antimicrobiano: según protocolo en riesgo de infección.\n• Terapia de presión negativa incisional: en pacientes de alto riesgo según indicación del cirujano.',
          en: '• Adhesive dressing with an absorbent pad: the most common.\n• Transparent film: lets you see the wound; for low-exudate wounds.\n• Hydrocolloid or foam: more absorbent, for heavier exudate.\n• Silver or antimicrobial: per protocol when infection risk is high.\n• Incisional negative pressure therapy: in high-risk patients as the surgeon decides.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Al quiròfan', es: 'En el quirófano', en: 'In theatre'),
        LocalizedText(
          ca: 'Netejar i assecar la pell al voltant de la incisió, posar l\'apòsit abans de retirar els camps i sense tensió perquè no faci butllofes. Els guants i el material han de ser encara estèrils.',
          es: 'Limpiar y secar la piel alrededor de la incisión, colocar el apósito antes de retirar los paños y sin tensión para que no haga ampollas. Los guantes y el material deben seguir siendo estériles.',
          en: 'Clean and dry the skin around the incision, apply the dressing before removing the drapes and without tension so it does not blister. Gloves and materials must still be sterile.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Després', es: 'Después', en: 'Afterwards'),
        LocalizedText(
          ca: 'En general no es canvia abans de 48 hores si està sec i ben enganxat; si es xopa o es desenganxa, es canvia amb tècnica asèptica. Registrar-ne l\'aspecte i qualsevol signe d\'infecció.',
          es: 'En general no se cambia antes de 48 horas si está seco y bien pegado; si se empapa o se despega, se cambia con técnica aséptica. Registrar su aspecto y cualquier signo de infección.',
          en: 'As a rule, do not change it within 48 hours if it is dry and intact; if it becomes soaked or detached, change it aseptically. Record its appearance and any sign of infection.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'muestras-quirurgicas',
    name: LocalizedText(ca: 'Maneig de mostres quirúrgiques', es: 'Manejo de muestras quirúrgicas', en: 'Handling surgical specimens'),
    aliases: ['Surgical specimens', 'Anatomía patológica', 'Biopsia intraoperatoria', 'Frozen section'],
    area: GuideArea.seguridad,
    summary: LocalizedText(
      ca: 'Una mostra perduda, mal identificada o mal conservada pot obligar a repetir una intervenció o donar un diagnòstic equivocat. Cada mostra s\'identifica, es conserva i es registra al moment.',
      es: 'Una muestra perdida, mal identificada o mal conservada puede obligar a repetir una intervención o dar un diagnóstico equivocado. Cada muestra se identifica, se conserva y se registra en el momento.',
      en: 'A lost, mislabelled or badly preserved specimen can mean repeat surgery or a wrong diagnosis. Each specimen is identified, preserved and recorded at the time.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Identificació', es: 'Identificación', en: 'Identification'),
        LocalizedText(
          ca: '• El cirurgià diu en veu alta què és la mostra, el costat i la localització.\n• Etiqueta al recipient (no a la tapa) amb dos identificadors del pacient, tipus de mostra, costat i data.\n• Marques d\'orientació (fils, clips) que indiqui el cirurgià, anotades a la petició.\n• Llegir l\'etiqueta en veu alta a la sortida del llistat de verificació.',
          es: '• El cirujano dice en voz alta qué es la muestra, el lado y la localización.\n• Etiqueta en el recipiente (no en la tapa) con dos identificadores del paciente, tipo de muestra, lado y fecha.\n• Marcas de orientación (hilos, clips) que indique el cirujano, anotadas en la petición.\n• Leer la etiqueta en voz alta en la salida del listado de verificación.',
          en: '• The surgeon states aloud what the specimen is, the side and site.\n• Label on the container (not the lid) with two patient identifiers, specimen type, side and date.\n• Orientation markers (stitches, clips) as the surgeon indicates, noted on the request.\n• Read the label aloud at sign out.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Conservació', es: 'Conservación', en: 'Preservation'),
        LocalizedText(
          ca: '• Anatomia patològica diferida: formol, amb un volum molt superior al de la mostra perquè la cobreixi del tot.\n• Biòpsia intraoperatòria: en fresc, sense formol ni sèrum, i enviada de seguida.\n• Microbiologia: recipient estèril, mai amb formol.\n• Cada mostra en el seu recipient; no barrejar ganglis de llocs diferents.',
          es: '• Anatomía patológica diferida: formol, con un volumen muy superior al de la muestra para que la cubra del todo.\n• Biopsia intraoperatoria: en fresco, sin formol ni suero, y enviada enseguida.\n• Microbiología: recipiente estéril, nunca con formol.\n• Cada muestra en su recipiente; no mezclar ganglios de lugares distintos.',
          en: '• Routine histology: formalin, in a much larger volume than the specimen so it is fully covered.\n• Frozen section: fresh, with no formalin or saline, and sent immediately.\n• Microbiology: sterile container, never formalin.\n• One container per specimen; do not mix lymph nodes from different sites.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Registre', es: 'Registro', en: 'Recording'),
        LocalizedText(
          ca: 'Anotar cada mostra al registre del quiròfan i comprovar que el nombre de recipients coincideix amb el de peticions. No llençar res del camp fins que s\'hagi confirmat que no és una mostra.',
          es: 'Anotar cada muestra en el registro del quirófano y comprobar que el número de recipientes coincide con el de peticiones. No desechar nada del campo hasta confirmar que no es una muestra.',
          en: 'Record each specimen in the theatre log and check the number of containers matches the number of requests. Do not discard anything from the field until it is confirmed not to be a specimen.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'hipotermia-perioperatoria',
    name: LocalizedText(ca: 'Prevenció de la hipotèrmia', es: 'Prevención de la hipotermia', en: 'Preventing perioperative hypothermia'),
    aliases: ['Perioperative hypothermia', 'Calentamiento del paciente', 'Forced-air warming'],
    area: GuideArea.paciente,
    summary: LocalizedText(
      ca: 'Per sota de 36 °C el pacient té més risc d\'infecció de ferida, sagnat, problemes cardíacs, tremolor i una recuperació més lenta. L\'anestèsia i el quiròfan fred hi contribueixen, i és més fàcil prevenir-la que corregir-la.',
      es: 'Por debajo de 36 °C el paciente tiene más riesgo de infección de herida, sangrado, problemas cardíacos, temblor y una recuperación más lenta. La anestesia y el quirófano frío contribuyen, y es más fácil prevenirla que corregirla.',
      en: 'Below 36 °C the patient is at higher risk of wound infection, bleeding, cardiac events, shivering and slower recovery. Anaesthesia and a cold theatre both contribute, and it is easier to prevent than to correct.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Abans de la intervenció', es: 'Antes de la intervención', en: 'Before surgery'),
        LocalizedText(
          ca: 'Prendre la temperatura abans d\'entrar al quiròfan. Si és baixa, escalfar el pacient abans d\'iniciar l\'anestèsia. L\'escalfament previ amb manta d\'aire calent redueix la caiguda de temperatura de la primera hora.',
          es: 'Tomar la temperatura antes de entrar en el quirófano. Si es baja, calentar al paciente antes de iniciar la anestesia. El calentamiento previo con manta de aire caliente reduce la caída de temperatura de la primera hora.',
          en: 'Take the temperature before entering theatre. If it is low, warm the patient before starting anaesthesia. Prewarming with a forced-air blanket reduces the temperature drop in the first hour.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Durant la intervenció', es: 'Durante la intervención', en: 'During surgery'),
        LocalizedText(
          ca: '• Quiròfan càlid mentre el pacient està destapat.\n• Tapar tot el que no sigui el camp quirúrgic.\n• Manta d\'aire calent o matalàs tèrmic.\n• Sèrums i hemoderivats escalfats amb escalfador; líquids d\'irrigació calents.\n• Temperatura del pacient al principi i periòdicament (segons protocol, sovint cada 30 minuts).',
          es: '• Quirófano cálido mientras el paciente está destapado.\n• Tapar todo lo que no sea el campo quirúrgico.\n• Manta de aire caliente o colchón térmico.\n• Sueros y hemoderivados calentados con calentador; líquidos de irrigación calientes.\n• Temperatura del paciente al principio y periódicamente (según protocolo, a menudo cada 30 minutos).',
          en: '• Warm theatre while the patient is exposed.\n• Cover everything except the surgical field.\n• Forced-air blanket or warming mattress.\n• IV fluids and blood products through a warmer; warm irrigation fluids.\n• Patient temperature at the start and regularly (per protocol, often every 30 minutes).',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Al final', es: 'Al final', en: 'At the end'),
        LocalizedText(
          ca: 'Comprovar la temperatura abans de traslladar-lo a reanimació; si està per sota de 36 °C, continuar escalfant-lo. Tapar-lo bé durant el trasllat.',
          es: 'Comprobar la temperatura antes de trasladarlo a reanimación; si está por debajo de 36 °C, seguir calentándolo. Taparlo bien durante el traslado.',
          en: 'Check the temperature before transfer to recovery; if below 36 °C, keep warming. Keep the patient well covered during transfer.',
        ),
      ),
    ],
  ),
];
