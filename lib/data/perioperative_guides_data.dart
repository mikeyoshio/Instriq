import '../models/instrument.dart' show LocalizedText;
import '../models/perioperative_guide.dart';

/// Guies perioperatòries. Text propi a partir de recomanacions generals
/// (OMS, guies d'infermeria quirúrgica); mai dosis de fàrmacs.
const List<PerioperativeGuide> kPerioperativeGuides = [
  PerioperativeGuide(
    id: 'lavado-quirurgico',
    relatedItems: ['cepillo-lavado-quirurgico', 'bata-quirurgica'],
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
    relatedItems: ['bata-quirurgica', 'guante-indicador-perforacion-doble'],
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
    relatedItems: ['campo-quirurgico-generico', 'campo-quirurgico-fenestrado', 'campo-adhesivo-incisional-iodado', 'funda-mesa-mayo', 'suport-taula-mayo'],
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
    relatedItems: ['generador-electrocirugia', 'electrobisturi', 'electrodo-dispersivo-adhesivo', 'sistema-evacuacion-humo-quirurgico'],
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
    relatedItems: ['gasa-quirurgica-radiopaca', 'compresa-laparotomia', 'torunda-gasa', 'contador-agujas'],
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
    relatedItems: ['torniquete-neumatico', 'venda-esmarch'],
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
    relatedItems: ['drenaje-redon', 'drenaje-jackson-pratt', 'drenaje-penrose', 'drenaje-kehr', 'drenaje-toracico-sello-agua'],
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
    relatedItems: ['sonda-foley', 'sonda-vesical-intermitent', 'bolsa-colectora-orina', 'sonda-nasogastrica'],
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
    relatedItems: ['aposito-adhesivo-herida', 'aposito-pelicula-transparente', 'aposito-tie-over'],
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
    relatedItems: ['bolsa-extraccion-especimenes'],
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
    relatedItems: ['manta-calentamiento-aire-forzado', 'calentador-fluidos-iv', 'armario-calentador-mantas-sueros'],
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
  PerioperativeGuide(
    id: 'humo-quirurgico',
    relatedItems: ['sistema-evacuacion-humo-quirurgico', 'respirador-ffp2-ffp3', 'generador-electrocirugia'],
    name: LocalizedText(ca: 'Fum quirúrgic', es: 'Humo quirúrgico', en: 'Surgical smoke'),
    aliases: ['Surgical smoke', 'Surgical plume', 'Humo de electrocirugía'],
    area: GuideArea.seguridad,
    summary: LocalizedText(
      ca: 'El bisturí elèctric, el làser i els dispositius d\'ultrasons vaporitzen teixit i generen un fum amb partícules fines, gasos irritants i, de vegades, material biològic. L\'exposició és diària per a tot l\'equip.',
      es: 'El bisturí eléctrico, el láser y los dispositivos de ultrasonidos vaporizan tejido y generan un humo con partículas finas, gases irritantes y, a veces, material biológico. La exposición es diaria para todo el equipo.',
      en: 'Electrosurgery, lasers and ultrasonic devices vaporise tissue and produce smoke containing fine particles, irritant gases and sometimes biological material. The whole team is exposed every day.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Com es controla', es: 'Cómo se controla', en: 'How it is controlled'),
        LocalizedText(
          ca: '• Evacuador de fum amb la boca d\'aspiració a pocs centímetres d\'on es genera.\n• Llapis de bisturí amb aspiració integrada quan n\'hi ha.\n• En laparoscòpia, filtre a la sortida del gas en lloc d\'obrir la vàlvula al quiròfan.',
          es: '• Evacuador de humo con la boca de aspiración a pocos centímetros de donde se genera.\n• Lápiz de bisturí con aspiración integrada cuando lo hay.\n• En laparoscopia, filtro en la salida del gas en vez de abrir la válvula al quirófano.',
          en: '• Smoke evacuator with the nozzle a few centimetres from the source.\n• Electrosurgical pencil with built-in suction where available.\n• In laparoscopy, filter the outflow gas instead of venting it into the room.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Protecció personal', es: 'Protección personal', en: 'Personal protection'),
        LocalizedText(
          ca: 'La mascareta quirúrgica no filtra bé les partícules fines. En procediments amb molt de fum o amb risc de virus al fum (làser sobre berrugues, per exemple), el protocol pot indicar un respirador FFP2 o FFP3.',
          es: 'La mascarilla quirúrgica no filtra bien las partículas finas. En procedimientos con mucho humo o con riesgo de virus en el humo (láser sobre verrugas, por ejemplo), el protocolo puede indicar un respirador FFP2 o FFP3.',
          en: 'A surgical mask does not filter fine particles well. For smoky procedures or where the plume may carry virus (laser on warts, for example), protocol may call for an FFP2 or FFP3 respirator.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Manteniment', es: 'Mantenimiento', en: 'Maintenance'),
        LocalizedText(
          ca: 'Els filtres de l\'evacuador tenen una vida útil limitada: canviar-los segons l\'indicador o el fabricant, amb guants, i llençar-los com a residu biològic.',
          es: 'Los filtros del evacuador tienen una vida útil limitada: cambiarlos según el indicador o el fabricante, con guantes, y desecharlos como residuo biológico.',
          en: 'Evacuator filters have a limited life: change them per the indicator or manufacturer, wearing gloves, and discard as biological waste.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'radioproteccion',
    relatedItems: ['arco-c', 'delantal-plomado', 'collar-tiroideo-plomado'],
    name: LocalizedText(ca: 'Radioprotecció amb arc en C', es: 'Radioprotección con arco en C', en: 'Radiation protection with the C-arm'),
    aliases: ['Radiation protection', 'C-arm safety', 'ALARA'],
    area: GuideArea.seguridad,
    summary: LocalizedText(
      ca: 'La fluoroscòpia exposa el pacient i l\'equip a radiació ionitzant. La major part de la dosi de l\'equip ve de la radiació dispersa que surt del pacient, i es redueix amb temps, distància i blindatge.',
      es: 'La fluoroscopia expone al paciente y al equipo a radiación ionizante. La mayor parte de la dosis del equipo procede de la radiación dispersa que sale del paciente, y se reduce con tiempo, distancia y blindaje.',
      en: 'Fluoroscopy exposes patient and team to ionising radiation. Most of the staff dose is scatter from the patient, reduced by time, distance and shielding.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Temps, distància i blindatge', es: 'Tiempo, distancia y blindaje', en: 'Time, distance and shielding'),
        LocalizedText(
          ca: '• Polsos curts i imatge guardada en lloc de fluoroscòpia contínua.\n• Allunyar-se del pacient quan es dispara: la dosi baixa molt amb cada pas enrere.\n• Davantal plomat ben cordat, protector de tiroide i, si n\'hi ha, mampares i ulleres plomades.',
          es: '• Pulsos cortos e imagen guardada en lugar de fluoroscopia continua.\n• Alejarse del paciente cuando se dispara: la dosis baja mucho con cada paso atrás.\n• Delantal plomado bien cerrado, protector de tiroides y, si los hay, mamparas y gafas plomadas.',
          en: '• Short pulses and last-image hold instead of continuous screening.\n• Step away from the patient when screening: dose drops sharply with each step back.\n• Lead apron fastened, thyroid collar and, where available, shields and lead glasses.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Posició de l\'arc', es: 'Posición del arco', en: 'C-arm position'),
        LocalizedText(
          ca: 'El tub de raigs, a sota de la taula i l\'intensificador o detector, a sobre i a prop del pacient. La radiació dispersa és més alta al costat del tub: l\'equip es col·loca preferentment al costat del detector.',
          es: 'El tubo de rayos, debajo de la mesa y el intensificador o detector, arriba y cerca del paciente. La radiación dispersa es mayor en el lado del tubo: el equipo se coloca preferentemente del lado del detector.',
          en: 'X-ray tube under the table and the image intensifier or detector above and close to the patient. Scatter is highest on the tube side, so staff stand on the detector side where possible.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Persones i registre', es: 'Personas y registro', en: 'People and records'),
        LocalizedText(
          ca: '• Dosímetre personal on indiqui el servei de radioprotecció.\n• Avís abans de cada disparament; qui no cal, surt o s\'allunya.\n• Preguntar per l\'embaràs a les pacients en edat fèrtil segons el protocol.\n• Davantals penjats, mai doblegats: les esquerdes del plom no es veuen.',
          es: '• Dosímetro personal donde indique el servicio de radioprotección.\n• Aviso antes de cada disparo; quien no hace falta, sale o se aleja.\n• Preguntar por embarazo a las pacientes en edad fértil según el protocolo.\n• Delantales colgados, nunca doblados: las grietas del plomo no se ven.',
          en: '• Personal dosimeter worn where the radiation protection service says.\n• Warn before each exposure; anyone not needed leaves or steps back.\n• Ask about pregnancy in patients of childbearing age per protocol.\n• Hang aprons, never fold them: cracks in the lead are invisible.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'seguridad-laser',
    relatedItems: ['gafas-proteccion-laser', 'tubo-laser-flex', 'laser-co2-laringeo'],
    name: LocalizedText(ca: 'Seguretat làser', es: 'Seguridad láser', en: 'Laser safety'),
    aliases: ['Laser safety', 'Seguridad láser'],
    area: GuideArea.seguridad,
    summary: LocalizedText(
      ca: 'Els làsers quirúrgics poden cremar la retina, la pell i el material del camp, i encendre gasos rics en oxigen. Cada làser té la seva longitud d\'ona i necessita la seva protecció.',
      es: 'Los láseres quirúrgicos pueden quemar la retina, la piel y el material del campo, y encender gases ricos en oxígeno. Cada láser tiene su longitud de onda y necesita su protección.',
      en: 'Surgical lasers can burn the retina, skin and drapes and ignite oxygen-rich gases. Each laser has its own wavelength and needs matching protection.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Abans d\'activar-lo', es: 'Antes de activarlo', en: 'Before activation'),
        LocalizedText(
          ca: '• Rètol d\'avís a les portes i finestres tapades si el protocol ho demana.\n• Ulleres amb la longitud d\'ona del làser que s\'usa per a tothom a la sala, i protecció ocular per al pacient.\n• Làser en espera (standby) fins que el cirurgià l\'apunta al teixit.',
          es: '• Cartel de aviso en las puertas y ventanas tapadas si el protocolo lo pide.\n• Gafas con la longitud de onda del láser en uso para todos en la sala, y protección ocular para el paciente.\n• Láser en espera (standby) hasta que el cirujano lo apunta al tejido.',
          en: '• Warning sign on the doors and windows covered if protocol requires.\n• Glasses rated for that laser\'s wavelength for everyone in the room, and eye protection for the patient.\n• Laser on standby until the surgeon is aimed at tissue.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Foc', es: 'Fuego', en: 'Fire'),
        LocalizedText(
          ca: 'En cirurgia de via aèria, tub endotraqueal resistent al làser amb el globus ple de sèrum, la fracció d\'oxigen tan baixa com permeti l\'anestesiòleg i compreses humides al voltant del camp. Tenir sèrum a mà.',
          es: 'En cirugía de vía aérea, tubo endotraqueal resistente al láser con el balón lleno de suero, la fracción de oxígeno tan baja como permita el anestesiólogo y compresas húmedas alrededor del campo. Tener suero a mano.',
          en: 'In airway surgery, use a laser-resistant tracheal tube with the cuff filled with saline, oxygen as low as the anaesthetist allows and moist swabs around the field. Keep saline at hand.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Instrumental', es: 'Instrumental', en: 'Instruments'),
        LocalizedText(
          ca: 'Instruments mats o ennegrits perquè el feix no rebot. El fum del làser s\'aspira com qualsevol fum quirúrgic.',
          es: 'Instrumental mate o ennegrecido para que el haz no rebote. El humo del láser se aspira como cualquier humo quirúrgico.',
          en: 'Use matt or blackened instruments so the beam does not reflect. Laser plume is evacuated like any surgical smoke.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'alergia-latex',
    name: LocalizedText(ca: 'Pacient al·lèrgic al làtex', es: 'Paciente alérgico al látex', en: 'Latex-allergic patient'),
    aliases: ['Latex allergy', 'Latex-free theatre', 'Quirófano libre de látex'],
    area: GuideArea.seguridad,
    summary: LocalizedText(
      ca: 'Una al·lèrgia al làtex pot provocar anafilaxi durant la intervenció. El risc és més alt en persones operades moltes vegades (espina bífida, malformacions urològiques), personal sanitari i al·lèrgics a fruites com el plàtan, l\'alvocat o el kiwi.',
      es: 'Una alergia al látex puede provocar anafilaxia durante la intervención. El riesgo es mayor en personas operadas muchas veces (espina bífida, malformaciones urológicas), personal sanitario y alérgicos a frutas como el plátano, el aguacate o el kiwi.',
      en: 'Latex allergy can cause anaphylaxis during surgery. Risk is higher in people with many previous operations (spina bifida, urological malformations), healthcare workers and those allergic to banana, avocado or kiwi.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Preparació del quiròfan', es: 'Preparación del quirófano', en: 'Preparing the theatre'),
        LocalizedText(
          ca: '• Primer de la llista del dia si el centre ho fa així, amb el quiròfan net.\n• Rètol de "lliure de làtex" a la porta i al llit.\n• Retirar o tapar tot el que en contingui: guants, sondes, drenatges, torniquets, manegots de pressió, tubs de goma, taps de vials.',
          es: '• Primero de la lista del día si el centro lo hace así, con el quirófano limpio.\n• Cartel de "libre de látex" en la puerta y en la cama.\n• Retirar o tapar todo lo que lo contenga: guantes, sondas, drenajes, torniquetes, manguitos de presión, tubos de goma, tapones de viales.',
          en: '• First on the list if that is local practice, in a clean theatre.\n• "Latex-free" sign on the door and bed.\n• Remove or cover anything containing latex: gloves, catheters, drains, tourniquets, BP cuffs, rubber tubing, vial stoppers.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Durant la intervenció', es: 'Durante la intervención', en: 'During surgery'),
        LocalizedText(
          ca: 'Tot l\'equip amb guants sense làtex. Si apareixen hipotensió, broncoespasme o vermellor sobtada sense una altra causa, avisar l\'anestesiòleg: pot ser anafilaxi.',
          es: 'Todo el equipo con guantes sin látex. Si aparecen hipotensión, broncoespasmo o enrojecimiento súbito sin otra causa, avisar al anestesiólogo: puede ser anafilaxia.',
          en: 'Whole team in latex-free gloves. Unexplained hypotension, bronchospasm or sudden flushing must be reported to the anaesthetist: it may be anaphylaxis.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Comprovació', es: 'Comprobación', en: 'Checking'),
        LocalizedText(
          ca: 'Mirar l\'etiqueta de cada producte (símbol de làtex) i, en cas de dubte, consultar la llista de material lliure de làtex del centre.',
          es: 'Mirar la etiqueta de cada producto (símbolo de látex) y, en caso de duda, consultar el listado de material libre de látex del centro.',
          en: 'Check each label for the latex symbol and, if in doubt, the hospital\'s latex-free product list.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'marcado-lateralidad',
    name: LocalizedText(ca: 'Marcatge del lloc quirúrgic i lateralitat', es: 'Marcado del sitio quirúrgico y lateralidad', en: 'Surgical site marking and laterality'),
    aliases: ['Site marking', 'Wrong-site surgery', 'Universal Protocol', 'Lateralidad'],
    area: GuideArea.seguridad,
    summary: LocalizedText(
      ca: 'La cirurgia en lloc, costat o pacient equivocat és rara però greu i evitable. Es prevé amb tres passos: verificar, marcar i fer una pausa abans de la incisió.',
      es: 'La cirugía en sitio, lado o paciente equivocado es rara pero grave y evitable. Se previene con tres pasos: verificar, marcar y hacer una pausa antes de la incisión.',
      en: 'Wrong-site, wrong-side or wrong-patient surgery is rare but serious and preventable. Three steps prevent it: verify, mark and pause before incision.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Verificar', es: 'Verificar', en: 'Verify'),
        LocalizedText(
          ca: 'Contrastar el nom, el procediment i el costat amb el pacient (si pot parlar), el consentiment, la història i les proves d\'imatge, en cada traspàs: planta, recepció i quiròfan.',
          es: 'Contrastar el nombre, el procedimiento y el lado con el paciente (si puede hablar), el consentimiento, la historia y las pruebas de imagen, en cada traspaso: planta, recepción y quirófano.',
          en: 'Check name, procedure and side against the patient (if able to speak), consent, notes and imaging at every handover: ward, reception and theatre.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Marcar', es: 'Marcar', en: 'Mark'),
        LocalizedText(
          ca: '• Ho fa el cirurgià que opera o algú del seu equip, abans de la sedació i amb el pacient despert si és possible.\n• Amb retolador permanent que no s\'esborri en pintar, a la zona o a prop de la incisió, i que quedi visible després de vestir.\n• Si no es pot marcar (mucoses, dents, nadons), el centre ha de tenir un sistema alternatiu.',
          es: '• Lo hace el cirujano que opera o alguien de su equipo, antes de la sedación y con el paciente despierto si es posible.\n• Con rotulador permanente que no se borre al pintar, en la zona o cerca de la incisión, y que quede visible tras vestir.\n• Si no se puede marcar (mucosas, dientes, neonatos), el centro debe tener un sistema alternativo.',
          en: '• Done by the operating surgeon or their team, before sedation and with the patient awake if possible.\n• With a permanent marker that survives prepping, at or near the incision, visible after draping.\n• Where marking is impossible (mucosa, teeth, neonates), the hospital needs an alternative system.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Pausa', es: 'Pausa', en: 'Pause'),
        LocalizedText(
          ca: 'Just abans de la incisió, tot l\'equip s\'atura i confirma en veu alta pacient, procediment i costat, i que la marca es veu al camp. És el segon temps del checklist de l\'OMS.',
          es: 'Justo antes de la incisión, todo el equipo se detiene y confirma en voz alta paciente, procedimiento y lado, y que la marca se ve en el campo. Es el segundo tiempo del checklist de la OMS.',
          en: 'Right before incision the whole team stops and confirms aloud the patient, procedure and side, and that the mark is visible in the field. This is the second phase of the WHO checklist.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'via-aerea-dificil',
    relatedItems: ['videolaringoscopio', 'fiador-intubacion', 'mascarilla-laringea-igel', 'fibrobroncoscopio-intubacion', 'capnografo'],
    name: LocalizedText(ca: 'Carro de via aèria difícil', es: 'Carro de vía aérea difícil', en: 'Difficult airway trolley'),
    aliases: ['Difficult airway trolley', 'Carro de vía aérea difícil', 'Difficult airway'],
    area: GuideArea.seguridad,
    summary: LocalizedText(
      ca: 'Quan no es pot ventilar o intubar, cada segon compta. El carro de via aèria difícil reuneix el material en un ordre conegut per tot l\'equip, i la infermera ha de saber on és cada cosa sense buscar-la.',
      es: 'Cuando no se puede ventilar o intubar, cada segundo cuenta. El carro de vía aérea difícil reúne el material en un orden conocido por todo el equipo, y la enfermera debe saber dónde está cada cosa sin buscarla.',
      en: 'When ventilation or intubation fails, every second counts. The difficult airway trolley holds the kit in an order the whole team knows, and the nurse should find each item without searching.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Què hi ha', es: 'Qué hay', en: 'What is in it'),
        LocalizedText(
          ca: '• Videolaringoscopi i fulles de diverses mides; laringoscopi amb fulles alternatives.\n• Tubs endotraqueals de diverses mides, fiadors i bougie.\n• Dispositius supraglòtics (mascaretes laríngies de segona generació) de diverses mides.\n• Fibrobroncoscopi o endoscopi d\'intubació.\n• Material per a l\'accés frontal del coll (cricotirotomia): bisturí, bougie i tub petit amb globus.',
          es: '• Videolaringoscopio y palas de varios tamaños; laringoscopio con palas alternativas.\n• Tubos endotraqueales de varios tamaños, fiadores y bougie.\n• Dispositivos supraglóticos (mascarillas laríngeas de segunda generación) de varios tamaños.\n• Fibrobroncoscopio o endoscopio de intubación.\n• Material para el acceso frontal del cuello (cricotiroidotomía): bisturí, bougie y tubo pequeño con balón.',
          en: '• Videolaryngoscope with blades in several sizes; laryngoscope with alternative blades.\n• Tracheal tubes in several sizes, stylets and bougie.\n• Supraglottic devices (second-generation laryngeal masks) in several sizes.\n• Flexible intubation scope.\n• Front-of-neck access kit (cricothyroidotomy): scalpel, bougie and small cuffed tube.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Durant la crisi', es: 'Durante la crisis', en: 'During the crisis'),
        LocalizedText(
          ca: 'Demanar ajuda en veu alta, tenir l\'aspiració a punt i el capnògraf connectat: la corba de CO2 és la confirmació de la intubació. L\'anestesiòleg segueix l\'algoritme del centre; la infermera dona el material que demana i anota els temps.',
          es: 'Pedir ayuda en voz alta, tener la aspiración preparada y el capnógrafo conectado: la curva de CO2 es la confirmación de la intubación. El anestesiólogo sigue el algoritmo del centro; la enfermera da el material que pide y anota los tiempos.',
          en: 'Call for help aloud, have suction ready and the capnograph connected: the CO2 trace confirms intubation. The anaesthetist follows the local algorithm; the nurse passes what is asked for and records times.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Revisió', es: 'Revisión', en: 'Checking'),
        LocalizedText(
          ca: 'Revisar el carro cada dia o segons el protocol, precintar-lo i reposar-lo just després d\'usar-lo.',
          es: 'Revisar el carro cada día o según el protocolo, precintarlo y reponerlo justo después de usarlo.',
          en: 'Check the trolley daily or per protocol, seal it and restock it straight after use.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'hipertermia-maligna',
    relatedItems: ['capnografo', 'calentador-fluidos-iv'],
    name: LocalizedText(ca: 'Hipertèrmia maligna', es: 'Hipertermia maligna', en: 'Malignant hyperthermia'),
    aliases: ['Malignant hyperthermia', 'MH', 'Hipertermia maligna'],
    area: GuideArea.seguridad,
    summary: LocalizedText(
      ca: 'Reacció genètica rara als anestèsics inhalats i a la succinilcolina: el múscul entra en hipermetabolisme. És una emergència que es tracta amb dantrolè, el fàrmac específic, que ha d\'estar al bloc quirúrgic.',
      es: 'Reacción genética rara a los anestésicos inhalados y a la succinilcolina: el músculo entra en hipermetabolismo. Es una emergencia que se trata con dantroleno, el fármaco específico, que debe estar en el bloque quirúrgico.',
      en: 'A rare inherited reaction to volatile anaesthetics and suxamethonium that sends muscle into a hypermetabolic state. It is an emergency treated with dantrolene, the specific drug, which must be available in theatre.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Signes', es: 'Signos', en: 'Signs'),
        LocalizedText(
          ca: 'El primer acostuma a ser un augment del CO2 espirat que no baixa en ventilar més. Després: taquicàrdia, rigidesa muscular (sobretot del masseter), sudoració, i la temperatura puja més tard.',
          es: 'El primero suele ser un aumento del CO2 espirado que no baja al ventilar más. Después: taquicardia, rigidez muscular (sobre todo del masetero), sudoración, y la temperatura sube más tarde.',
          en: 'Usually the first sign is rising end-tidal CO2 that does not fall with more ventilation. Then tachycardia, muscle rigidity (especially masseter), sweating; temperature rises late.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Què fa la infermera', es: 'Qué hace la enfermera', en: 'What the nurse does'),
        LocalizedText(
          ca: '• Avisar i portar el carro d\'hipertèrmia maligna; demanar mans: preparar el dantrolè requereix diverses persones.\n• L\'anestesiòleg atura els halogenats i ventila amb oxigen a flux alt.\n• Refredar: sèrums freds, gel a aixelles i engonals, mantes fora.\n• Sonda vesical per controlar la diüresi i extreure analítiques que es demanin.',
          es: '• Avisar y traer el carro de hipertermia maligna; pedir manos: preparar el dantroleno requiere varias personas.\n• El anestesiólogo suspende los halogenados y ventila con oxígeno a flujo alto.\n• Enfriar: sueros fríos, hielo en axilas e ingles, mantas fuera.\n• Sonda vesical para controlar la diuresis y extraer las analíticas que se pidan.',
          en: '• Raise the alarm and bring the MH trolley; call for help: preparing dantrolene takes several people.\n• The anaesthetist stops volatile agents and ventilates with high-flow oxygen.\n• Cool the patient: cold fluids, ice to axillae and groins, warming off.\n• Urinary catheter for urine output and draw the blood tests requested.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Carro', es: 'Carro', en: 'Trolley'),
        LocalizedText(
          ca: 'Conté el dantrolè, aigua per a injecció per dissoldre\'l, xeringues i agulles grans, sèrums freds i material per a analítiques. La quantitat i la dosi les marca el protocol del centre; es revisa com qualsevol carro d\'emergència.',
          es: 'Contiene el dantroleno, agua para inyección para disolverlo, jeringas y agujas grandes, sueros fríos y material para analíticas. La cantidad y la dosis las marca el protocolo del centro; se revisa como cualquier carro de emergencia.',
          en: 'It holds dantrolene, water for injection to dissolve it, large syringes and needles, cold fluids and blood-test kit. Quantities and dosing follow the hospital protocol; check it like any emergency trolley.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'torre-laparoscopia',
    relatedItems: ['unidad-camara-fuente-luz-endoscopia', 'insuflador-co2', 'laparoscopio', 'aguja-veress', 'trocar', 'sistema-evacuacion-humo-quirurgico'],
    name: LocalizedText(ca: 'Muntatge de la torre de laparoscòpia', es: 'Montaje de la torre de laparoscopia', en: 'Setting up the laparoscopy tower'),
    aliases: ['Laparoscopy tower setup', 'Montaje de torre de laparoscopia'],
    area: GuideArea.material,
    summary: LocalizedText(
      ca: 'La torre reuneix la càmera, la font de llum, l\'insuflador i el monitor. Muntar-la i comprovar-la abans que el pacient entri evita esperes amb l\'abdomen obert i errors d\'insuflació.',
      es: 'La torre reúne la cámara, la fuente de luz, el insuflador y el monitor. Montarla y comprobarla antes de que entre el paciente evita esperas con el abdomen abierto y errores de insuflación.',
      en: 'The tower holds the camera, light source, insufflator and monitor. Setting it up and checking it before the patient arrives avoids delays and insufflation errors.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Abans d\'entrar el pacient', es: 'Antes de entrar al paciente', en: 'Before the patient arrives'),
        LocalizedText(
          ca: '• Torre al costat oposat al cirurgià, amb el monitor davant seu; un segon monitor per a l\'ajudant si cal.\n• Encendre els equips i comprovar que hi ha imatge.\n• Bombona de CO2 oberta i amb gas suficient, i una de recanvi a prop.\n• Pressió màxima d\'insuflació la que indiqui el cirurgià o el protocol.',
          es: '• Torre en el lado opuesto al cirujano, con el monitor enfrente; un segundo monitor para el ayudante si hace falta.\n• Encender los equipos y comprobar que hay imagen.\n• Bombona de CO2 abierta y con gas suficiente, y una de recambio cerca.\n• Presión máxima de insuflación la que indique el cirujano o el protocolo.',
          en: '• Tower opposite the surgeon with the monitor facing them; a second monitor for the assistant if needed.\n• Switch everything on and check there is a picture.\n• CO2 cylinder open with enough gas and a spare nearby.\n• Maximum insufflation pressure as set by the surgeon or protocol.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Al camp', es: 'En el campo', en: 'In the field'),
        LocalizedText(
          ca: 'Passar del camp a la torre el cable de càmera, el de llum i el tub d\'insuflació, amb un filtre si n\'hi ha. Fer el balanç de blancs amb una gasa blanca i enfocar abans d\'entrar a l\'abdomen. Escalfar l\'òptica o fer servir antiboira.',
          es: 'Pasar del campo a la torre el cable de cámara, el de luz y el tubo de insuflación, con un filtro si lo hay. Hacer el balance de blancos con una gasa blanca y enfocar antes de entrar en el abdomen. Calentar la óptica o usar antivaho.',
          en: 'Pass the camera cable, light cable and insufflation tubing from field to tower, with a filter if supplied. White-balance on a white swab and focus before entering the abdomen. Warm the scope or use anti-fog.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Seguretat', es: 'Seguridad', en: 'Safety'),
        LocalizedText(
          ca: '• La punta del cable de llum crema: mai sobre els camps sense òptica connectada, i la font en espera quan no s\'usa.\n• Vigilar la pressió i el flux a l\'insuflador i avisar si salta l\'alarma.\n• Tenir a punt el material de conversió a cirurgia oberta.',
          es: '• La punta del cable de luz quema: nunca sobre los campos sin óptica conectada, y la fuente en espera cuando no se usa.\n• Vigilar la presión y el flujo en el insuflador y avisar si salta la alarma.\n• Tener preparado el material de conversión a cirugía abierta.',
          en: '• The light cable tip burns: never leave it on the drapes without a scope attached; keep the source on standby when not in use.\n• Watch pressure and flow on the insufflator and report alarms.\n• Have the open conversion set ready.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'torre-artroscopia',
    relatedItems: ['artroscopio', 'shaver-artroscopico', 'sistema-manejo-fluidos-distension', 'unidad-camara-fuente-luz-endoscopia', 'torniquete-neumatico'],
    name: LocalizedText(ca: 'Muntatge d\'artroscòpia', es: 'Montaje de artroscopia', en: 'Setting up arthroscopy'),
    aliases: ['Arthroscopy setup', 'Montaje de artroscopia'],
    area: GuideArea.material,
    summary: LocalizedText(
      ca: 'L\'artroscòpia treballa dins d\'una articulació plena de líquid: a més de càmera i llum, cal una bomba o un sistema de gravetat per distendre-la, el shaver i, sovint, radiofreqüència.',
      es: 'La artroscopia trabaja dentro de una articulación llena de líquido: además de cámara y luz, hace falta una bomba o un sistema de gravedad para distenderla, el shaver y, a menudo, radiofrecuencia.',
      en: 'Arthroscopy works inside a fluid-filled joint: besides camera and light it needs a pump or gravity system to distend it, the shaver and often radiofrequency.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Abans de començar', es: 'Antes de empezar', en: 'Before starting'),
        LocalizedText(
          ca: '• Torre al costat oposat a l\'articulació, amb el monitor a la vista del cirurgià.\n• Bosses de sèrum suficients i ben a prop: s\'acaben de pressa.\n• Pressió de la bomba la que indiqui el cirurgià; pedal del shaver i de la radiofreqüència al seu peu.',
          es: '• Torre en el lado opuesto a la articulación, con el monitor a la vista del cirujano.\n• Bolsas de suero suficientes y bien a mano: se acaban rápido.\n• Presión de la bomba la que indique el cirujano; pedal del shaver y de la radiofrecuencia a su pie.',
          en: '• Tower opposite the joint with the monitor in the surgeon\'s line of sight.\n• Plenty of irrigation bags close by: they run out fast.\n• Pump pressure as the surgeon sets; shaver and radiofrequency pedals at their foot.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Durant la intervenció', es: 'Durante la intervención', en: 'During surgery'),
        LocalizedText(
          ca: 'Canviar les bosses abans que es buidin perquè no entri aire. Vigilar el volum de sortida i l\'extremitat: si el líquid s\'extravasa als teixits, l\'extremitat s\'infla i s\'ha d\'avisar.',
          es: 'Cambiar las bolsas antes de que se vacíen para que no entre aire. Vigilar el volumen de salida y la extremidad: si el líquido se extravasa a los tejidos, la extremidad se hincha y hay que avisar.',
          en: 'Change bags before they run dry so no air enters. Watch the outflow volume and the limb: fluid leaking into tissues makes it swell and must be reported.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'El terra', es: 'El suelo', en: 'The floor'),
        LocalizedText(
          ca: 'Es fa servir molt líquid: bossa recol·lectora als camps, aspiració del terra o estores absorbents per evitar relliscades.',
          es: 'Se usa mucho líquido: bolsa colectora en los campos, aspiración de suelo o alfombras absorbentes para evitar resbalones.',
          en: 'A lot of fluid is used: fluid-collection drapes, floor suction or absorbent mats prevent slips.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'microscopio-quirurgico',
    relatedItems: ['microscopio-quirurgico'],
    name: LocalizedText(ca: 'Preparació del microscopi quirúrgic', es: 'Preparación del microscopio quirúrgico', en: 'Preparing the operating microscope'),
    aliases: ['Operating microscope setup', 'Preparación del microscopio'],
    area: GuideArea.material,
    summary: LocalizedText(
      ca: 'El microscopi s\'usa en neurocirurgia, ORL, oftalmologia, cirurgia plàstica i microcirurgia. Ha d\'estar equilibrat, enfocat i enfundat abans que el cirurgià el necessiti.',
      es: 'El microscopio se usa en neurocirugía, ORL, oftalmología, cirugía plástica y microcirugía. Debe estar equilibrado, enfocado y enfundado antes de que el cirujano lo necesite.',
      en: 'The microscope is used in neurosurgery, ENT, ophthalmology, plastic surgery and microsurgery. It must be balanced, focused and draped before the surgeon needs it.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Abans de vestir-lo', es: 'Antes de vestirlo', en: 'Before draping'),
        LocalizedText(
          ca: '• Situar-lo al costat del cirurgià, amb els frens posats i fora del pas.\n• Encendre la llum i comprovar la intensitat; ajustar els oculars (dioptries i distància entre ulls) amb el cirurgià.\n• Equilibrar el braç per a la configuració que s\'usarà, amb l\'ocular de l\'ajudant si cal.',
          es: '• Situarlo en el lado del cirujano, con los frenos puestos y fuera del paso.\n• Encender la luz y comprobar la intensidad; ajustar los oculares (dioptrías y distancia entre ojos) con el cirujano.\n• Equilibrar el brazo para la configuración que se usará, con el ocular del ayudante si hace falta.',
          en: '• Position it on the surgeon\'s side, brakes on and out of the way.\n• Turn on the light and check intensity; set eyepieces (dioptres and interpupillary distance) with the surgeon.\n• Balance the arm for the configuration to be used, with the assistant\'s eyepiece if needed.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Funda', es: 'Funda', en: 'Drape'),
        LocalizedText(
          ca: 'La posen dues persones: la instrumentista estèril desplega la funda sobre el capçal i els braços sense tocar res no estèril, i la circulant ajuda des de fora. Posar la tapa de la lent sense bombolles.',
          es: 'La ponen dos personas: la instrumentista estéril despliega la funda sobre el cabezal y los brazos sin tocar nada no estéril, y la circulante ayuda desde fuera. Colocar la tapa de la lente sin burbujas.',
          en: 'Two people drape it: the scrub nurse unrolls the drape over the head and arms without touching anything unsterile, and the circulating nurse helps from outside. Fit the lens cover without bubbles.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Seguretat', es: 'Seguridad', en: 'Safety'),
        LocalizedText(
          ca: 'La llum és molt intensa: abaixar-la si el microscopi no apunta al camp perquè no cremi el teixit ni els camps. Bloquejar els frens en acabar i tornar-lo a la posició de transport.',
          es: 'La luz es muy intensa: bajarla si el microscopio no apunta al campo para que no queme el tejido ni los campos. Bloquear los frenos al acabar y devolverlo a la posición de transporte.',
          en: 'The light is very intense: turn it down when not aimed at the field so it does not burn tissue or drapes. Lock the brakes afterwards and return it to the transport position.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'paciente-pediatrico',
    relatedItems: ['cuna-termica-radiante', 'manta-calentamiento-aire-forzado', 'trocar-laparoscopico-pediatrico'],
    name: LocalizedText(ca: 'Pacient pediàtric al quiròfan', es: 'Paciente pediátrico en quirófano', en: 'Paediatric patient in theatre'),
    aliases: ['Paediatric patient', 'Niño en quirófano'],
    area: GuideArea.paciente,
    summary: LocalizedText(
      ca: 'Els nens no són adults petits: perden calor de pressa, toleren poc el dejuni i l\'error en una dosi o en un volum pesa molt més. Tot el material es tria segons el pes i l\'edat.',
      es: 'Los niños no son adultos pequeños: pierden calor rápido, toleran poco el ayuno y un error en una dosis o en un volumen pesa mucho más. Todo el material se elige según el peso y la edad.',
      en: 'Children are not small adults: they lose heat quickly, tolerate fasting poorly and any dose or volume error matters far more. All equipment is chosen by weight and age.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Temperatura', es: 'Temperatura', en: 'Temperature'),
        LocalizedText(
          ca: 'Quiròfan calent abans que arribi, bressol tèrmic o manta d\'aire, cap tapat en els més petits i líquids escalfats. Destapar només el que calgui.',
          es: 'Quirófano caliente antes de que llegue, cuna térmica o manta de aire, cabeza cubierta en los más pequeños y líquidos calentados. Destapar solo lo necesario.',
          en: 'Warm theatre before arrival, radiant warmer or forced-air blanket, head covered in the youngest and warmed fluids. Expose only what is needed.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Material', es: 'Material', en: 'Equipment'),
        LocalizedText(
          ca: '• Pes al dia, anotat i visible per a tot l\'equip.\n• Material de via aèria de la mida que toca i de les mides de sobre i de sota.\n• Placa de retorn pediàtrica o neonatal i instrumental de mida reduïda.\n• Sèrums en sistemes amb control de volum per evitar sobrecàrregues.',
          es: '• Peso del día, anotado y visible para todo el equipo.\n• Material de vía aérea del tamaño que corresponde y de los tamaños de arriba y abajo.\n• Placa de retorno pediátrica o neonatal e instrumental de tamaño reducido.\n• Sueros en sistemas con control de volumen para evitar sobrecargas.',
          en: '• Today\'s weight recorded and visible to everyone.\n• Airway equipment in the right size plus one size up and down.\n• Paediatric or neonatal return electrode and reduced-size instruments.\n• IV fluids through volume-controlled sets to avoid overload.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'La família', es: 'La familia', en: 'Family'),
        LocalizedText(
          ca: 'Si el centre ho permet, un dels pares pot acompanyar-lo fins a la inducció. Explicar al nen el que passarà amb paraules senzilles i deixar-li el seu objecte de confort.',
          es: 'Si el centro lo permite, uno de los padres puede acompañarlo hasta la inducción. Explicar al niño lo que va a pasar con palabras sencillas y dejarle su objeto de apego.',
          en: 'Where allowed, a parent may stay until induction. Explain what will happen in simple words and let the child keep a comfort object.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'paciente-obeso',
    relatedItems: ['mesa-quirofano-electrohidraulica', 'colchon-vacio-posicionamiento', 'soporte-lateral-mesa', 'almohadilla-gel-posicionamiento', 'videolaringoscopio'],
    name: LocalizedText(ca: 'Pacient amb obesitat', es: 'Paciente con obesidad', en: 'Patient with obesity'),
    aliases: ['Bariatric patient', 'Obesity', 'Paciente bariátrico'],
    area: GuideArea.paciente,
    summary: LocalizedText(
      ca: 'L\'obesitat greu canvia el trasllat, el posicionament, la via aèria i el risc de lesions per pressió. El material ha d\'estar homologat per al pes del pacient.',
      es: 'La obesidad grave cambia el traslado, el posicionamiento, la vía aérea y el riesgo de lesiones por presión. El material debe estar homologado para el peso del paciente.',
      en: 'Severe obesity changes transfer, positioning, airway management and pressure-injury risk. All equipment must be rated for the patient\'s weight.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Abans d\'entrar', es: 'Antes de entrar', en: 'Before arrival'),
        LocalizedText(
          ca: '• Comprovar el pes màxim de la taula, de les extensions laterals i de la llitera.\n• Matalàs de transferència o grua, i prou persones per al trasllat.\n• Manegot de pressió de la mida adequada, instrumental llarg i trocars llargs si és laparoscòpia.',
          es: '• Comprobar el peso máximo de la mesa, de las extensiones laterales y de la camilla.\n• Colchón de transferencia o grúa, y suficientes personas para el traslado.\n• Manguito de presión del tamaño adecuado, instrumental largo y trocares largos si es laparoscopia.',
          en: '• Check the weight limit of the table, side extensions and trolley.\n• Transfer mattress or hoist and enough staff for the transfer.\n• Correctly sized BP cuff, long instruments and long trocars for laparoscopy.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Via aèria', es: 'Vía aérea', en: 'Airway'),
        LocalizedText(
          ca: 'La intubació pot ser difícil i la desaturació, ràpida. Coixins o falca per elevar el tronc i el cap (posició en rampa) i carro de via aèria difícil a prop.',
          es: 'La intubación puede ser difícil y la desaturación, rápida. Almohadas o cuña para elevar el tronco y la cabeza (posición en rampa) y carro de vía aérea difícil cerca.',
          en: 'Intubation may be difficult and desaturation rapid. Pillows or a wedge to raise the trunk and head (ramped position) and the difficult airway trolley nearby.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Posicionament', es: 'Posicionamiento', en: 'Positioning'),
        LocalizedText(
          ca: 'Cinta de subjecció i suports laterals ben fixats abans d\'inclinar la taula. Coixinets a tots els punts de pressió i revisió dels plecs de la pell, on es poden fer lesions per humitat o per pressió.',
          es: 'Cinta de sujeción y soportes laterales bien fijados antes de inclinar la mesa. Almohadillas en todos los puntos de presión y revisión de los pliegues de la piel, donde se pueden producir lesiones por humedad o por presión.',
          en: 'Strap and side supports secured before tilting the table. Pad all pressure points and check skin folds for moisture and pressure injury.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'paciente-gestante',
    relatedItems: ['rodillo-posicionamiento', 'doppler-fetal-manual'],
    name: LocalizedText(ca: 'Gestant en cirurgia no obstètrica', es: 'Gestante en cirugía no obstétrica', en: 'Pregnant patient in non-obstetric surgery'),
    aliases: ['Pregnant patient', 'Non-obstetric surgery in pregnancy', 'Embarazada'],
    area: GuideArea.paciente,
    summary: LocalizedText(
      ca: 'De vegades una gestant s\'ha d\'operar d\'una urgència no obstètrica (apendicitis, colecistitis, traumatisme). Es tracten dos pacients: la mare i el fetus, que depèn del flux uterí.',
      es: 'A veces una gestante debe operarse de una urgencia no obstétrica (apendicitis, colecistitis, traumatismo). Se tratan dos pacientes: la madre y el feto, que depende del flujo uterino.',
      en: 'Sometimes a pregnant woman needs emergency non-obstetric surgery (appendicitis, cholecystitis, trauma). There are two patients: the mother and the fetus, who depends on uterine blood flow.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Posició', es: 'Posición', en: 'Position'),
        LocalizedText(
          ca: 'A partir de la segona meitat de l\'embaràs, l\'úter comprimeix la vena cava en decúbit supí. Desplaçar l\'úter cap a l\'esquerra amb una falca sota el maluc dret o inclinant la taula.',
          es: 'A partir de la segunda mitad del embarazo, el útero comprime la vena cava en decúbito supino. Desplazar el útero hacia la izquierda con una cuña bajo la cadera derecha o inclinando la mesa.',
          en: 'From mid-pregnancy the uterus compresses the vena cava when supine. Displace it to the left with a wedge under the right hip or by tilting the table.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Coordinació', es: 'Coordinación', en: 'Coordination'),
        LocalizedText(
          ca: '• Avisar obstetrícia i, segons les setmanes, neonatologia.\n• Control del fetus abans i després, i durant la intervenció si ho decideix l\'obstetra.\n• Risc d\'aspiració més alt: aspiració preparada per a la inducció.',
          es: '• Avisar a obstetricia y, según las semanas, a neonatología.\n• Control del feto antes y después, y durante la intervención si lo decide el obstetra.\n• Riesgo de aspiración más alto: aspiración preparada para la inducción.',
          en: '• Inform obstetrics and, depending on gestation, neonatology.\n• Fetal monitoring before and after, and during surgery if the obstetrician decides.\n• Higher aspiration risk: suction ready for induction.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Radiació i fàrmacs', es: 'Radiación y fármacos', en: 'Radiation and drugs'),
        LocalizedText(
          ca: 'Si cal escòpia, protegir l\'abdomen quan sigui possible i limitar el temps. La medicació la decideix l\'anestesiòleg tenint en compte l\'embaràs.',
          es: 'Si hace falta escopia, proteger el abdomen cuando sea posible y limitar el tiempo. La medicación la decide el anestesiólogo teniendo en cuenta el embarazo.',
          en: 'If fluoroscopy is needed, shield the abdomen where possible and keep screening short. Drugs are chosen by the anaesthetist with the pregnancy in mind.',
        ),
      ),
    ],
  ),
  PerioperativeGuide(
    id: 'residuos-quirurgicos',
    relatedItems: ['contenidor-objectes-punxants', 'contador-agujas'],
    name: LocalizedText(ca: 'Residus i material després de la intervenció', es: 'Residuos y material tras la intervención', en: 'Waste and instruments after surgery'),
    aliases: ['Theatre waste', 'Waste segregation', 'Gestión de residuos'],
    area: GuideArea.material,
    summary: LocalizedText(
      ca: 'El quiròfan genera molts residus. Separar-los bé protegeix qui els manipula, compleix la normativa i redueix el cost i l\'impacte ambiental.',
      es: 'El quirófano genera muchos residuos. Separarlos bien protege a quien los manipula, cumple la normativa y reduce el coste y el impacto ambiental.',
      en: 'Theatres produce a lot of waste. Sorting it properly protects those who handle it, meets regulations and cuts cost and environmental impact.',
    ),
    sections: [
      GuideSection(
        LocalizedText(ca: 'Separació', es: 'Separación', en: 'Sorting'),
        LocalizedText(
          ca: '• Punxants i tallants, al contenidor rígid, mai a la bossa.\n• Material amb sang o fluids en quantitat, a residu sanitari de risc segons la normativa local.\n• Envasos i plàstics nets (embolcalls, caixes), a residu assimilable o reciclatge.\n• Citostàtics, químics i peces anatòmiques tenen el seu circuit propi.',
          es: '• Punzantes y cortantes, al contenedor rígido, nunca a la bolsa.\n• Material con sangre o fluidos en cantidad, a residuo sanitario de riesgo según la normativa local.\n• Envases y plásticos limpios (envoltorios, cajas), a residuo asimilable o reciclaje.\n• Citostáticos, químicos y piezas anatómicas tienen su propio circuito.',
          en: '• Sharps into the rigid container, never into a bag.\n• Items heavily soiled with blood or fluids into clinical waste per local rules.\n• Clean packaging and plastics into general waste or recycling.\n• Cytotoxics, chemicals and anatomical parts have their own pathway.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Instrumental', es: 'Instrumental', en: 'Instruments'),
        LocalizedText(
          ca: 'En acabar, la instrumentista retira les fulles i agulles, obre les pinces, separa les peces delicades i manté l\'instrumental humit (escuma o drap humit) perquè la sang no s\'assequi abans d\'arribar a esterilització. Comprovar que no hi falta cap peça de la caixa.',
          es: 'Al terminar, la instrumentista retira hojas y agujas, abre las pinzas, separa las piezas delicadas y mantiene el instrumental húmedo (espuma o paño húmedo) para que la sangre no se seque antes de llegar a esterilización. Comprobar que no falta ninguna pieza de la caja.',
          en: 'At the end the scrub nurse removes blades and needles, opens hinged instruments, separates delicate items and keeps instruments moist (foam or damp towel) so blood does not dry before reaching sterile services. Check no piece of the set is missing.',
        ),
      ),
      GuideSection(
        LocalizedText(ca: 'Al quiròfan', es: 'En el quirófano', en: 'In the theatre'),
        LocalizedText(
          ca: 'Llençar els líquids aspirats segons el protocol (sovint amb gelificant), no buidar-los a la pica. Netejar les superfícies abans del pacient següent.',
          es: 'Desechar los líquidos aspirados según el protocolo (a menudo con gelificante), no vaciarlos en el fregadero. Limpiar las superficies antes del siguiente paciente.',
          en: 'Dispose of suctioned fluid per protocol (often with a gelling agent), not down the sink. Clean surfaces before the next patient.',
        ),
      ),
    ],
  ),
];
