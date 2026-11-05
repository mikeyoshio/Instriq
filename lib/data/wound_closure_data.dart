import '../models/instrument.dart' show LocalizedText;
import '../models/wound_closure_material.dart';

const List<WoundClosureMaterial> kWoundClosureMaterials = [
  // Hemostáticos absorbibles
  WoundClosureMaterial(
    id: 'celulosa-oxidada',
    name: LocalizedText(
      ca: 'Cel·lulosa oxidada regenerada',
      es: 'Celulosa oxidada regenerada',
      en: 'Regenerated oxidized cellulose',
    ),
    aliases: ['Surgicel'],
    category: WoundClosureCategory.hemostaticoAbsorbible,
    description: LocalizedText(
      ca: 'Agent hemostàtic absorbible de cel·lulosa oxidada regenerada, que actua formant un coàgul artificial en contacte amb la sang i creant un entorn àcid bacteriostàtic.',
      es: 'Agente hemostático absorbible de celulosa oxidada regenerada, que actúa formando un coágulo artificial al contacto con la sangre y creando un entorno ácido bacteriostático.',
      en: 'Absorbable hemostatic agent made of regenerated oxidized cellulose, which works by forming an artificial clot on contact with blood and creating a bacteriostatic acidic environment.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per controlar l\'hemorràgia en làmina (oozing) de petits vasos quan l\'hemostàsia mecànica no és suficient o practicable.',
      es: 'Se utiliza para controlar hemorragia en capa (oozing) de pequeños vasos cuando la hemostasia mecánica no es suficiente o practicable.',
      en: 'Used to control diffuse oozing bleeding from small vessels when mechanical hemostasis is not sufficient or practicable.',
    ),
    tip: LocalizedText(
      ca: 'Es reabsorbeix completament en poques setmanes; deixar-lo al llit quirúrgic després de tancar no requereix retirar-lo posteriorment.',
      es: 'Se reabsorbe por completo en pocas semanas; dejarlo en el lecho quirúrgico tras cerrar no requiere su retirada posterior.',
      en: 'It is fully reabsorbed within a few weeks; leaving it in the surgical bed after closing does not require later removal.',
    ),
  ),
  WoundClosureMaterial(
    id: 'esponja-gelatina',
    name: LocalizedText(
      ca: 'Esponja de gelatina absorbible',
      es: 'Esponja de gelatina absorbible',
      en: 'Absorbable gelatin sponge',
    ),
    aliases: ['Gelfoam', 'Spongostan'],
    category: WoundClosureCategory.hemostaticoAbsorbible,
    description: LocalizedText(
      ca: 'Esponja absorbible de gelatina porcina que actua com a matriu mecànica per a la formació d\'un coàgul, sense activitat hemostàtica pròpia.',
      es: 'Esponja absorbible de gelatina porcina que actúa como matriz mecánica para la formación de un coágulo, sin actividad hemostática propia.',
      en: 'Absorbable porcine gelatin sponge that acts as a mechanical matrix for clot formation, without hemostatic activity of its own.',
    ),
    use: LocalizedText(
      ca: 'Útil per a hemorràgia capil·lar o venosa difusa en superfícies irregulars.',
      es: 'Útil para hemorragia capilar o venosa difusa en superficies irregulares.',
      en: 'Useful for diffuse capillary or venous bleeding on irregular surfaces.',
    ),
    tip: LocalizedText(
      ca: 'S\'expandeix en absorbir líquid; cal evitar sobredimensionar-la en espais tancats o confinats pel risc de compressió.',
      es: 'Se expande al absorber líquido; hay que evitar sobredimensionarla en espacios cerrados o confinados por el riesgo de compresión.',
      en: 'It expands as it absorbs fluid; oversizing it in closed or confined spaces should be avoided due to the risk of compression.',
    ),
  ),
  WoundClosureMaterial(
    id: 'colageno-microfibrilar',
    name: LocalizedText(
      ca: 'Col·lagen microfibril·lar',
      es: 'Colágeno microfibrilar',
      en: 'Microfibrillar collagen',
    ),
    aliases: ['Avitene'],
    category: WoundClosureCategory.hemostaticoAbsorbible,
    description: LocalizedText(
      ca: 'Col·lagen boví microfibril·lar que activa l\'agregació plaquetària en contacte directe amb una superfície sagnant.',
      es: 'Colágeno bovino microfibrilar que activa la agregación plaquetaria al contacto directo con una superficie sangrante.',
      en: 'Microfibrillar bovine collagen that activates platelet aggregation on direct contact with a bleeding surface.',
    ),
    use: LocalizedText(
      ca: 'Eficaç en hemorràgia de superfície difusa, especialment quan la cel·lulosa oxidada no controla bé el sagnat.',
      es: 'Eficaz en hemorragia de superficie difusa, especialmente cuando la celulosa oxidada no controla bien el sangrado.',
      en: 'Effective for diffuse surface bleeding, particularly when oxidized cellulose does not control the bleeding well.',
    ),
    tip: LocalizedText(
      ca: 'Cal aplicar-lo directament sobre teixit sec perquè s\'activi correctament; el contacte amb sang ja acumulada en redueix l\'eficàcia.',
      es: 'Requiere aplicarse directamente sobre tejido seco para activarse correctamente; el contacto con sangre ya acumulada reduce su eficacia.',
      en: 'It must be applied directly onto dry tissue to activate correctly; contact with already-pooled blood reduces its effectiveness.',
    ),
  ),
  WoundClosureMaterial(
    id: 'microesferas-polisacarido',
    name: LocalizedText(
      ca: 'Microesferes de polisacàrid porós',
      es: 'Microesferas de polisacárido poroso',
      en: 'Porous polysaccharide microspheres',
    ),
    aliases: ['Arista AH'],
    category: WoundClosureCategory.hemostaticoAbsorbible,
    description: LocalizedText(
      ca: 'Microesferes de midó vegetal purificat que absorbeixen ràpidament el component líquid de la sang, concentrant elements cel·lulars i factors de coagulació en el punt de sagnat.',
      es: 'Microesferas de almidón vegetal purificado que absorben rápidamente el componente líquido de la sangre, concentrando elementos celulares y factores de coagulación en el punto de sangrado.',
      en: 'Microspheres of purified plant starch that rapidly absorb the liquid component of blood, concentrating cellular elements and clotting factors at the bleeding site.',
    ),
    use: LocalizedText(
      ca: 'Hemostàsia de superfície en sagnat difús d\'intensitat baixa a moderada.',
      es: 'Hemostasia de superficie en sangrado difuso de baja a moderada intensidad.',
      en: 'Surface hemostasis for diffuse bleeding of low to moderate intensity.',
    ),
    tip: LocalizedText(
      ca: 'Es reabsorbeix completament en 24-48 hores, més ràpid que els hemostàtics de cel·lulosa o col·lagen.',
      es: 'Se reabsorbe completamente en 24-48 horas, más rápido que los hemostáticos de celulosa o colágeno.',
      en: 'It is fully reabsorbed within 24-48 hours, faster than cellulose- or collagen-based hemostatic agents.',
    ),
  ),

  // Hemostáticos activos
  WoundClosureMaterial(
    id: 'trombina-topica',
    name: LocalizedText(ca: 'Trombina tòpica', es: 'Trombina tópica', en: 'Topical thrombin'),
    category: WoundClosureCategory.hemostaticoActivo,
    description: LocalizedText(
      ca: 'Enzim que converteix el fibrinogen en fibrina directament en el punt d\'aplicació, sense dependre de tota la cascada de coagulació.',
      es: 'Enzima que convierte el fibrinógeno en fibrina directamente en el punto de aplicación, sin depender de toda la cascada de coagulación.',
      en: 'Enzyme that converts fibrinogen into fibrin directly at the application site, without relying on the full coagulation cascade.',
    ),
    use: LocalizedText(
      ca: 'Se sol combinar amb una matriu (esponja de gelatina o col·lagen) per potenciar l\'hemostàsia local.',
      es: 'Se combina habitualmente con una matriz (esponja de gelatina o colágeno) para potenciar la hemostasia local.',
      en: 'It is usually combined with a matrix (gelatin sponge or collagen) to enhance local hemostasis.',
    ),
    tip: LocalizedText(
      ca: 'Existeix d\'origen humà, boví o recombinant segons el producte; la variant bovina es va associar històricament a un risc rar d\'anticossos anti-factor V.',
      es: 'Existe de origen humano, bovino o recombinante según el producto; la variante bovina se asoció históricamente a un riesgo raro de anticuerpos anti-factor V.',
      en: 'It is available in human, bovine or recombinant form depending on the product; the bovine variant was historically associated with a rare risk of anti-factor V antibodies.',
    ),
  ),
  WoundClosureMaterial(
    id: 'matriz-gelatina-trombina',
    name: LocalizedText(
      ca: 'Matriu de gelatina i trombina',
      es: 'Matriz de gelatina y trombina',
      en: 'Gelatin-thrombin matrix',
    ),
    aliases: ['Floseal', 'Surgiflo'],
    category: WoundClosureCategory.hemostaticoActivo,
    description: LocalizedText(
      ca: 'Matriu flowable que combina grànuls de gelatina amb trombina, aplicable amb xeringa directament sobre superfícies irregulars o cavitats.',
      es: 'Matriz flowable que combina gránulos de gelatina con trombina, aplicable con jeringa directamente sobre superficies irregulares o cavidades.',
      en: 'Flowable matrix combining gelatin granules with thrombin, applicable with a syringe directly onto irregular surfaces or cavities.',
    ),
    use: LocalizedText(
      ca: 'Útil en sagnat moderat sobre superfícies difícils d\'abordar amb hemostàtics laminars, com llits de resecció hepàtica o esplènica.',
      es: 'Útil en sangrado moderado sobre superficies difíciles de abordar con hemostáticos laminares, como lechos de resección hepática o esplénica.',
      en: 'Useful for moderate bleeding on surfaces that are difficult to address with sheet-form hemostatic agents, such as hepatic or splenic resection beds.',
    ),
    tip: LocalizedText(
      ca: 'En ser injectable, s\'adapta a cavitats irregulars millor que les làmines de cel·lulosa o col·lagen.',
      es: 'Al ser inyectable, se adapta a cavidades irregulares mejor que las láminas de celulosa o colágeno.',
      en: 'Being injectable, it conforms to irregular cavities better than cellulose or collagen sheets.',
    ),
  ),

  // Sellantes tisulares
  WoundClosureMaterial(
    id: 'sellante-fibrina',
    name: LocalizedText(ca: 'Segellant de fibrina', es: 'Sellante de fibrina', en: 'Fibrin sealant'),
    aliases: ['Tisseel', 'Evicel'],
    category: WoundClosureCategory.sellanteTisular,
    description: LocalizedText(
      ca: 'Combinació de dos components (fibrinogen i trombina) que, en barrejar-se en el punt d\'aplicació, repliquen el pas final de la cascada de coagulació formant un coàgul de fibrina.',
      es: 'Combinación de dos componentes (fibrinógeno y trombina) que, al mezclarse en el punto de aplicación, replican el paso final de la cascada de coagulación formando un coágulo de fibrina.',
      en: 'Combination of two components (fibrinogen and thrombin) that, when mixed at the application site, replicate the final step of the coagulation cascade by forming a fibrin clot.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza com a segellant hemostàtic i, en algunes presentacions, com a adhesiu tissular per fixar colgalls o malles.',
      es: 'Se utiliza como sellante hemostático y, en algunas presentaciones, como adhesivo tisular para fijar colgajos o mallas.',
      en: 'Used as a hemostatic sealant and, in some presentations, as a tissue adhesive to fix flaps or meshes.',
    ),
    tip: LocalizedText(
      ca: 'A diferència dels hemostàtics de matriu (cel·lulosa, gelatina, col·lagen), actua també com a adhesiu, no només com a hemostàtic.',
      es: 'A diferencia de los hemostáticos de matriz (celulosa, gelatina, colágeno), actúa también como adhesivo, no solo como hemostático.',
      en: 'Unlike matrix-based hemostatic agents (cellulose, gelatin, collagen), it also acts as an adhesive, not only as a hemostatic agent.',
    ),
  ),
  WoundClosureMaterial(
    id: 'hidrogel-peg',
    name: LocalizedText(
      ca: 'Hidrogel segellant de polietilenglicol',
      es: 'Hidrogel sellante de polietilenglicol',
      en: 'Polyethylene glycol sealant hydrogel',
    ),
    aliases: ['DuraSeal'],
    category: WoundClosureCategory.sellanteTisular,
    description: LocalizedText(
      ca: 'Segellant sintètic de polietilenglicol (PEG) que polimeritza in situ formant una barrera flexible i impermeable.',
      es: 'Sellante sintético de polietilenglicol (PEG) que polimeriza in situ formando una barrera flexible e impermeable.',
      en: 'Synthetic polyethylene glycol (PEG) sealant that polymerizes in situ, forming a flexible, impermeable barrier.',
    ),
    use: LocalizedText(
      ca: 'S\'usa sobretot com a segellant dural adjuvant al tancament primari, per prevenir fugues de líquid cefaloraquidi.',
      es: 'Se usa sobre todo como sellante dural adyuvante al cierre primario, para prevenir fugas de líquido cefalorraquídeo.',
      en: 'Used mainly as a dural sealant adjunct to primary closure, to prevent cerebrospinal fluid leaks.',
    ),
    tip: LocalizedText(
      ca: 'S\'expandeix lleugerament en polimeritzar; cal tenir-ho en compte en espais amb poc marge, com el canal espinal.',
      es: 'Se expande ligeramente al polimerizar; hay que tenerlo en cuenta en espacios con poco margen, como el canal espinal.',
      en: 'It expands slightly as it polymerizes; this must be taken into account in spaces with little margin, such as the spinal canal.',
    ),
  ),

  // Adhesivo y cierre mecánico de piel
  WoundClosureMaterial(
    id: 'adhesivo-cianoacrilato',
    name: LocalizedText(
      ca: 'Adhesiu tissular de cianoacrilat',
      es: 'Adhesivo tisular de cianoacrilato',
      en: 'Cyanoacrylate tissue adhesive',
    ),
    aliases: ['Dermabond', 'Indermil'],
    category: WoundClosureCategory.adhesivoCutaneo,
    description: LocalizedText(
      ca: 'Adhesiu líquid de cianoacrilat que polimeritza en contacte amb la humitat de la pell, formant una pel·lícula flexible que manté aproximades les vores de la ferida.',
      es: 'Adhesivo líquido de cianoacrilato que polimeriza al contacto con la humedad de la piel, formando una película flexible que mantiene aproximados los bordes de la herida.',
      en: 'Liquid cyanoacrylate adhesive that polymerizes on contact with skin moisture, forming a flexible film that keeps the wound edges approximated.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitza per al tancament de ferides cutànies superficials amb vores afrontables, sovint com a complement d\'una sutura subcuticular.',
      es: 'Se utiliza para el cierre de heridas cutáneas superficiales de bordes afrontables, a menudo como complemento de una sutura subcuticular.',
      en: 'Used to close superficial skin wounds with approximable edges, often as a complement to a subcuticular suture.',
    ),
    tip: LocalizedText(
      ca: 'No ha d\'entrar en contacte amb mucoses ni usar-se sota tensió, i es desprèn tot sol per descamació en 5-10 dies.',
      es: 'No debe entrar en contacto con mucosas ni usarse bajo tensión, y se desprende solo por descamación en 5-10 días.',
      en: 'It must not come into contact with mucous membranes or be used under tension, and it sheds on its own through desquamation within 5-10 days.',
    ),
  ),
  WoundClosureMaterial(
    id: 'grapas-cutaneas',
    name: LocalizedText(
      ca: 'Grapes cutànies quirúrgiques',
      es: 'Grapas cutáneas quirúrgicas',
      en: 'Surgical skin staples',
    ),
    category: WoundClosureCategory.grapaCutanea,
    description: LocalizedText(
      ca: 'Grapes metàl·liques d\'acer inoxidable o titani per al tancament ràpid de la pell, aplicades amb una grapadora dedicada d\'un sol ús.',
      es: 'Grapas metálicas de acero inoxidable o titanio para el cierre rápido de la piel, aplicadas con un grapador dedicado de un solo uso.',
      en: 'Metal staples made of stainless steel or titanium for rapid skin closure, applied with a dedicated single-use stapler.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitzen sobretot en incisions llargues o lineals on la velocitat de tancament importa, com laparotomies o cesàries.',
      es: 'Se usan sobre todo en incisiones largas o lineales donde la velocidad de cierre importa, como laparotomías o cesáreas.',
      en: 'Used mainly for long or linear incisions where closure speed matters, such as laparotomies or cesarean sections.',
    ),
    tip: LocalizedText(
      ca: 'Requereixen un extractor de grapes específic per retirar-les; mai s\'han de treure amb un instrument genèric de tall.',
      es: 'Requieren un extractor de grapas específico para retirarlas; nunca se deben quitar con un instrumento genérico de corte.',
      en: 'They require a specific staple remover to take them out; they must never be removed with a generic cutting instrument.',
    ),
  ),
  WoundClosureMaterial(
    id: 'tiras-adhesivas-cutaneas',
    name: LocalizedText(
      ca: 'Tires adhesives d\'aproximació cutània',
      es: 'Tiras adhesivas de aproximación cutánea',
      en: 'Adhesive skin closure strips',
    ),
    aliases: ['Steri-Strip'],
    category: WoundClosureCategory.tiraAdhesivaCutanea,
    description: LocalizedText(
      ca: 'Tires adhesives reforçades de polièster no teixit per aproximar les vores d\'una ferida cutània sense penetrar la pell.',
      es: 'Tiras adhesivas reforzadas de poliéster no tejido para aproximar los bordes de una herida cutánea sin penetrar la piel.',
      en: 'Reinforced adhesive strips made of non-woven polyester used to approximate the edges of a skin wound without penetrating the skin.',
    ),
    use: LocalizedText(
      ca: 'S\'utilitzen en ferides superficials de baix risc de dehiscència, o com a reforç després de retirar punts o grapes.',
      es: 'Se usan en heridas superficiales de bajo riesgo de dehiscencia, o como refuerzo tras retirar puntos o grapas.',
      en: 'Used for superficial wounds with low risk of dehiscence, or as reinforcement after removing stitches or staples.',
    ),
    tip: LocalizedText(
      ca: 'La seva adherència millora amb un adhesiu de benzoïna aplicat a la pell circumdant, però aquest mai ha d\'entrar en contacte amb la ferida mateixa.',
      es: 'Su adherencia mejora con un adhesivo de benzoína aplicado en la piel circundante, pero este nunca debe entrar en contacto con la herida misma.',
      en: 'Their adhesion improves with a benzoin adhesive applied to the surrounding skin, but this must never come into contact with the wound itself.',
    ),
  ),

  // Hemostasia ósea
  WoundClosureMaterial(
    id: 'cera-osea',
    name: LocalizedText(ca: 'Cera d\'os', es: 'Cera de hueso', en: 'Bone wax'),
    category: WoundClosureCategory.ceraOsea,
    description: LocalizedText(
      ca: 'Barreja estèril de cera d\'abella i un agent estovador, utilitzada com a barrera mecànica (no química ni biològica) per al sagnat ossi.',
      es: 'Mezcla estéril de cera de abejas y un agente ablandador, usada como barrera mecánica (no química ni biológica) para el sangrado óseo.',
      en: 'Sterile blend of beeswax and a softening agent, used as a mechanical (not chemical or biological) barrier for bone bleeding.',
    ),
    use: LocalizedText(
      ca: 'S\'aplica directament sobre la superfície òssia sagnant, típicament en esternotomies o craniotomies.',
      es: 'Se aplica directamente sobre la superficie ósea sangrante, típicamente en esternotomías o craneotomías.',
      en: 'Applied directly onto the bleeding bone surface, typically in sternotomies or craniotomies.',
    ),
    tip: LocalizedText(
      ca: 'No és reabsorbible ni biodegradable per si mateixa; la seva presència prolongada al llit ossi pot interferir amb la consolidació òssia, per la qual cosa s\'utilitza en la quantitat mínima necessària.',
      es: 'No es reabsorbible ni biodegradable por sí misma; su presencia prolongada en el lecho óseo puede interferir con la consolidación ósea, por lo que se usa en la mínima cantidad necesaria.',
      en: 'It is not resorbable or biodegradable on its own; its prolonged presence in the bone bed can interfere with bone consolidation, so it is used in the minimum amount necessary.',
    ),
  ),
];
