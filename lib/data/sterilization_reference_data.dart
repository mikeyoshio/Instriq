import '../models/instrument.dart' show LocalizedText;
import '../models/instrument_sterilization.dart' show SterilizationMethod;
import '../models/sterilization_reference.dart';

/// Exactament 6 entrades, una per cada valor de [SterilizationMethod], en el
/// mateix ordre que l'enum. A diferència de [Drug], aquí sí es poden
/// esmentar paràmetres tècnics d'equip (temperatura, temps, pressió) si el
/// text ho inclogués -- no és informació de dosi a pacient, és dada de
/// procés/equip. Cap xifra concreta perquè varien molt per fabricant
/// d'autoclau/esterilitzador.
const List<SterilizationMethodReference> kSterilizationMethodReferences = [
  SterilizationMethodReference(
    method: SterilizationMethod.vapor,
    description: LocalizedText(
      ca: 'Esterilització per calor humit a alta pressió (autoclau), el mètode més utilitzat per la seva eficàcia, rapidesa i baix cost quan el material ho tolera.',
      es: 'Esterilización por calor húmedo a alta presión (autoclave), el método más usado por su eficacia, rapidez y bajo coste cuando el material lo tolera.',
      en: 'Sterilization by moist heat at high pressure (autoclave), the most widely used method for its effectiveness, speed and low cost when the material tolerates it.',
    ),
    use: LocalizedText(
      ca: 'Mètode d\'elecció per a instrumental metàl·lic i tèxtil reutilitzable que suporta temperatura i humitat.',
      es: 'Método de elección para instrumental metálico y textil reutilizable que soporta temperatura y humedad.',
      en: 'Method of choice for reusable metal and textile instruments that tolerate temperature and humidity.',
    ),
    tip: LocalizedText(
      ca: 'No és compatible amb material termosensible (òptica delicada, plàstic, electrònica) ni amb instrumental que atrapi humitat en cavitats internes sense un cicle de buit adequat.',
      es: 'No es compatible con material termosensible (óptica delicada, plástico, electrónica) ni con instrumental que atrape humedad en cavidades internas sin un ciclo de vacío adecuado.',
      en: 'It is not compatible with heat-sensitive material (delicate optics, plastic, electronics) or with instruments that trap moisture in internal cavities without an adequate vacuum cycle.',
    ),
  ),
  SterilizationMethodReference(
    method: SterilizationMethod.plasma,
    aliases: ['STERRAD'],
    description: LocalizedText(
      ca: 'Esterilització a baixa temperatura mitjançant vapor de peròxid d\'hidrogen activat en estat de plasma, sense calor ni humitat residual significativa.',
      es: 'Esterilización a baja temperatura mediante vapor de peróxido de hidrógeno activado en estado de plasma, sin calor ni humedad residual significativa.',
      en: 'Low-temperature sterilization using hydrogen peroxide vapor activated into a plasma state, without heat or significant residual moisture.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per a instrumental termosensible que no tolera el vapor, com òptiques rígides, cables de llum o dispositius electrònics reutilitzables.',
      es: 'Se usa para instrumental termosensible que no tolera vapor, como ópticas rígidas, cables de luz o dispositivos electrónicos reutilizables.',
      en: 'Used for heat-sensitive instruments that cannot tolerate steam, such as rigid optics, light cables or reusable electronic devices.',
    ),
    tip: LocalizedText(
      ca: 'No penetra bé en llums llargs i estrets ni és compatible amb materials cel·lulòsics (paper, cotó), que absorbeixen el peròxid d\'hidrogen.',
      es: 'No penetra bien en lúmenes largos y estrechos ni es compatible con materiales celulósicos (papel, algodón), que absorben el peróxido de hidrógeno.',
      en: 'It does not penetrate long, narrow lumens well and is not compatible with cellulosic materials (paper, cotton), which absorb the hydrogen peroxide.',
    ),
  ),
  SterilizationMethodReference(
    method: SterilizationMethod.oxidoEtileno,
    description: LocalizedText(
      ca: 'Esterilització química a baixa temperatura mitjançant gas d\'òxid d\'etilè, amb un cicle molt més llarg que el vapor o el plasma.',
      es: 'Esterilización química a baja temperatura mediante gas de óxido de etileno, con un ciclo mucho más largo que el vapor o el plasma.',
      en: 'Low-temperature chemical sterilization using ethylene oxide gas, with a much longer cycle than steam or plasma.',
    ),
    use: LocalizedText(
      ca: 'Reservat per a material termosensible que tampoc tolera el plasma de peròxid d\'hidrogen, o amb geometries complexes (llums llargs, articulacions).',
      es: 'Reservado para material termosensible que el plasma de peróxido de hidrógeno tampoco tolera, o con geometrías complejas (lúmenes largos, articulaciones).',
      en: 'Reserved for heat-sensitive material that hydrogen peroxide plasma also cannot tolerate, or with complex geometries (long lumens, joints).',
    ),
    tip: LocalizedText(
      ca: 'Exigeix un període d\'aireació posterior, de vegades de diverses hores, per eliminar les restes tòxiques del gas abans que el material es pugui utilitzar.',
      es: 'Exige un periodo de aireación posterior, a veces de varias horas, para eliminar los residuos tóxicos del gas antes de que el material pueda usarse.',
      en: 'It requires a subsequent aeration period, sometimes of several hours, to remove the gas\'s toxic residues before the material can be used.',
    ),
  ),
  SterilizationMethodReference(
    method: SterilizationMethod.bajaTemperatura,
    description: LocalizedText(
      ca: 'Categoria general per a mètodes de baixa temperatura diferents del plasma de peròxid d\'hidrogen i l\'òxid d\'etilè (per exemple àcid peracètic líquid o ozó), utilitzats segons la disponibilitat de cada central d\'esterilització.',
      es: 'Categoría general para métodos de baja temperatura distintos del plasma de peróxido de hidrógeno y el óxido de etileno (por ejemplo ácido peracético líquido u ozono), usados según la disponibilidad de cada central de esterilización.',
      en: 'General category for low-temperature methods other than hydrogen peroxide plasma and ethylene oxide (for example liquid peracetic acid or ozone), used depending on the availability of each sterilization unit.',
    ),
    use: LocalizedText(
      ca: 'Alternativa quan el material és termosensible i els mètodes anteriors no estan disponibles o no són compatibles amb el seu disseny.',
      es: 'Alternativa cuando el material es termosensible y los métodos anteriores no están disponibles o no son compatibles con su diseño.',
      en: 'Alternative when the material is heat-sensitive and the previous methods are not available or not compatible with its design.',
    ),
    tip: LocalizedText(
      ca: 'En ser una categoria heterogènia, els paràmetres de cicle i la compatibilitat de materials varien molt segons el mètode concret -- consulta sempre la IFU específica del fabricant de l\'equip.',
      es: 'Al ser una categoría heterogénea, los parámetros de ciclo y la compatibilidad de materiales varían mucho según el método concreto -- consulta siempre la IFU específica del fabricante del equipo.',
      en: 'Since this is a heterogeneous category, cycle parameters and material compatibility vary widely depending on the specific method -- always check the equipment manufacturer\'s specific IFU.',
    ),
  ),
  SterilizationMethodReference(
    method: SterilizationMethod.desechable,
    description: LocalizedText(
      ca: 'Material dissenyat per a un únic ús i eliminació posterior, sense cap cicle de reprocessat.',
      es: 'Material diseñado para un único uso y eliminación posterior, sin ningún ciclo de reprocesado.',
      en: 'Material designed for a single use and subsequent disposal, without any reprocessing cycle.',
    ),
    use: LocalizedText(
      ca: 'S\'escull quan el reprocessat no és segur, no és cost-efectiu, o el fabricant no valida cap mètode d\'esterilització per a aquest disseny.',
      es: 'Se elige cuando el reprocesado no es seguro, no es coste-efectivo, o el fabricante no valida ningún método de esterilización para ese diseño.',
      en: 'Chosen when reprocessing is not safe, not cost-effective, or the manufacturer does not validate any sterilization method for that design.',
    ),
    tip: LocalizedText(
      ca: 'Reprocessar material d\'un sol ús fora de les vies de reprocessat validades pel fabricant (quan existeixen programes de reprocessat per part de tercers) compromet la traçabilitat i la garantia.',
      es: 'Reprocesar material de un solo uso fuera de las vías de reprocesado validadas por el fabricante (cuando existen programas de reprocesado por terceros) compromete la trazabilidad y la garantía.',
      en: 'Reprocessing single-use material outside the reprocessing pathways validated by the manufacturer (where third-party reprocessing programs exist) compromises traceability and the warranty.',
    ),
  ),
  SterilizationMethodReference(
    method: SterilizationMethod.noEsterilizable,
    description: LocalizedText(
      ca: 'Material o equip que no tolera cap mètode d\'esterilització disponible, ni està dissenyat per ser-ho.',
      es: 'Material o equipo que no tolera ningún método de esterilización disponible, ni está diseñado para serlo.',
      en: 'Material or equipment that does not tolerate any available sterilization method, nor is it designed to be sterilized.',
    ),
    use: LocalizedText(
      ca: 'Típicament equip auxiliar (monitors, consoles, carcasses externes) que es neteja i desinfecta però mai s\'esterilitza, perquè no entra en contacte directe amb teixit estèril.',
      es: 'Típicamente equipo auxiliar (monitores, consolas, carcasas externas) que se limpia y desinfecta pero nunca se esteriliza, porque no entra en contacto directo con tejido estéril.',
      en: 'Typically auxiliary equipment (monitors, consoles, external casings) that is cleaned and disinfected but never sterilized, because it does not come into direct contact with sterile tissue.',
    ),
    tip: LocalizedText(
      ca: 'Requereix un protocol de neteja/desinfecció propi i una barrera física (funda estèril d\'un sol ús) si ha d\'entrar al camp quirúrgic.',
      es: 'Requiere un protocolo de limpieza/desinfección propio y una barrera física (funda estéril de un solo uso) si debe entrar en el campo quirúrgico.',
      en: 'It requires its own cleaning/disinfection protocol and a physical barrier (single-use sterile sleeve) if it needs to enter the surgical field.',
    ),
  ),
];
