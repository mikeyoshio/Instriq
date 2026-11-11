# Inventari d'infografies d'Instagram vs. catàleg Instriq

Font: sèrie d'infografies "50 X Instruments/Drugs" d'un compte d'infermeria genèric
("quaderns" il·lustrats amb numeració 1-50 per bloc, cobrint tot un hospital:
obstetrícia, neurocirurgia, sala de parts, UCI, esterilització/CSSD, farmàcia oral
i injectables). Document de seguiment creat el 2026-11-11 a partir de les imatges
compartides en xat, cotejant cada ítem contra `lib/data/instruments_data.dart`.

Metodologia: per cada ítem es busca el nom en anglès i sinònims habituals en
castellà/català al catàleg (camps `name` i `aliases`). **Sí** = coincidència clara
(es dona l'`id`). **Posible** = hi ha un instrument del catàleg relacionat però no
idèntic (marca diferent, especialitat diferent, o el catàleg només té la versió
genèrica). **No** = no trobat amb una cerca raonablement àmplia.

## Scoreboard

| Bloc | Ítems vistos | Ja al catàleg (Sí) | Relacionats (Posible) | No al catàleg |
|---|---|---|---|---|
| **Instrumental** | 254 | 141 | 18 | 95 |
| **Equipamiento** | 247 | 2 | 1 | 244 |
| **Fàrmacs** | 100 | 90 | — | 10 (descartats deliberadament) |
| **Total** | 601 | 233 | 19 | 349 |

*(Instrumental actualitzat el 2026-11-11 després d'ampliar el catàleg amb 20 instruments nous d'Obstetrícia/Neurocirurgia i 8 alias a fitxes existents. Equipament actualitzat el mateix dia amb 33 fitxes del lot 2 i 27 fitxes més del lot 3 (CSSD/esterilització + mobiliari de sala de parts, incloent-hi les 3 fitxes de monitorització obstètrica que tancaven l'abast previst per a un lot 4 separat -- ja no cal). Les xifres de la fila "Equipamiento" de dalt encara no estan recomptades amb precisió agregada; la taula de cada imatge (3, 4, 5, 7, 10) ja reflecteix l'estat real ítem a ítem. Fàrmacs tancat el mateix dia (lot 5): 80 fitxes noves a `drugs_data.dart` (22->102) + uns 10 ítems ja coberts per fàrmacs d'anestèsia existents un cop fusionats els duplicats xarop/injectable del mateix fàrmac (ondansetron, midazolam, lidocaïna, bupivacaïna, neostigmina, noradrenalina), i 4 descartats deliberadament (Ofloxacin/Codeine Syrup per lectura dubtosa de la infografia, Serratiopeptidase per evidència clínica feble, Netilmicina per estar discontinuada a la majoria de mercats). El catàleg de farmacologia ja no és només "d'anestèsia" -- s'ha ampliat a formulari general de planta, sempre sense dosis enlloc.)*

(Els comptadors "Instrumental" inclouen el subconjunt d'instrumental de mà de les
imatges d'UCI/Labour Room/Esterilització; la resta d'aquestes imatges són
equipament de planta i compten a la fila "Equipamiento".)

---

## Imatge 1 — "50 Obstetrics Instruments" (Part-1, 1-50)

| # | Ítem | Classificació | Al catàleg? |
|---|---|---|---|
| 1 | Forceps | Instrumental | Sí (`forceps-obstetrico`) |
| 2 | Vacuum Extractor | Instrumental | Sí (`ventosa-obstetrica` / "Vacuum extractor (ventouse)") |
| 3 | Fetal Scalp Electrode | Equipamiento | No |
| 4 | Fetal Scalp Clip | Equipamiento | No |
| 5 | Amniotomy Hook | Instrumental | Sí ("Amniotomy hook") |
| 6 | Allis Forceps | Instrumental | Sí |
| 7 | Sponge Holding Forceps | Instrumental | Sí ("Ring forceps (Foerster)", conegut com a "sponge forceps") |
| 8 | Bozeman Forceps | Instrumental | Sí (`pinza-bozeman`, afegit) |
| 9 | Vulsellum Forceps | Instrumental | Sí (pinça de tracció cervical d'una sola dent, catalogada separada de Green-Armytage) |
| 10 | Placenta Forceps | Instrumental | Sí (`pinza-restos-ovulares`, afegit; fusionat amb #11/#34) |
| 11 | Ovum Forceps | Instrumental | Sí (`pinza-restos-ovulares`, afegit; fusionat amb #10/#34) |
| 12 | Sims Speculum | Instrumental | Sí ("Sims vaginal speculum") |
| 13 | Cusco's Speculum | Instrumental | Sí (esmentat com "bivalve Cusco speculum already catalogued") |
| 14 | Bivalve Speculum | Instrumental | Sí (mateix que Cusco) |
| 15 | Auvard Weighted Speculum | Instrumental | Sí (`especulo-auvard`, afegit) |
| 16 | Vaginal Retractor | Instrumental | Sí (alias "Vaginal retractor" afegit a `separador-breisky-navratil`) |
| 17 | Cervical Dilator (Hegar) | Instrumental | Sí ("Hegar cervical dilators") |
| 18 | Uterine Sound | Instrumental | Sí (`histerometro` -- fals negatiu del report original, ja existia) |
| 19 | Hysterometer | Instrumental | Sí (= #18, `histerometro`) |
| 20 | Foleys Catheter | Instrumental | Sí (`sonda-foley`) |
| 21 | Foleys Catheter (2 Way) | Instrumental | Sí (mateixa entrada genèrica) |
| 22 | Ryles Tube | Instrumental | No |
| 23 | Infant Feeding Tube | Instrumental | No |
| 24 | Episiotomy Scissors | Instrumental | Sí ("Episiotomy scissors (Braun-Stadler)") |
| 25 | Mayo Scissors | Instrumental | Sí |
| 26 | Metzenbaum Scissors | Instrumental | Sí |
| 27 | Stitch Scissors | Instrumental | Sí ("Littauer scissors" — tisores de treure punts) |
| 28 | Sponge Forceps | Instrumental | Sí (mateixa Ring/Foerster forceps) |
| 29 | Dressing Forceps | Instrumental | Sí (alias afegit a `pinza-diseccion-sin-dientes`) |
| 30 | Toothed Forceps | Instrumental | Sí ("Toothed dissecting forceps") |
| 31 | Volsellum Forceps | Instrumental | Sí (= #9) |
| 32 | Tenaculum Forceps | Instrumental | Sí (mateixa entrada que Vulsellum) |
| 33 | Bullet Forceps | Instrumental | No (saltat -- cap font de fabricant el documenta com a instrument diferenciat) |
| 34 | Ovum Seizing Forceps | Instrumental | Sí (`pinza-restos-ovulares`, = #10/#11) |
| 35 | Placenta Extracting Forceps | Instrumental | Sí (`pinza-restos-ovulares`, = #10/#11/#34) |
| 36 | Cord Clamps | Instrumental | Sí ("umbilical cord clamp", esmentat com ja catalogat) |
| 37 | Umbilical Cord Scissors | Instrumental | Sí ("Busch umbilical cord scissors") |
| 38 | Perineal Retractor | Instrumental | Sí (`separador-perineal`, afegit) |
| 39 | Galli Duct Forceps | Instrumental | No (saltat -- no verificable com a instrument real amb aquest nom) |
| 40 | Uterine Retractor | Instrumental | No (saltat -- massa genèric, sense disseny propi diferenciat confirmat) |
| 41 | Volsellum Forceps (dup.) | Instrumental | Sí (= #9) |
| 42 | Doyen's Retractor | Instrumental | Sí ("Valva de Doyen" / "Doyen retractor") |
| 43 | Green Armytage Forceps | Instrumental | Sí |
| 44 | Veit-Smellie Retractor | Instrumental | No (saltat -- quasi segur confusió amb la maniobra de Mauriceau-Smellie-Veit, una tècnica manual, no un instrument) |
| 45 | Anal Sphincter Retractor | Instrumental | Sí (alias afegit a `separador-anal-autoestatic-de-lone-star`) |
| 46 | Breisky Retractor | Instrumental | Sí ("Breisky-Navratil vaginal retractor") |
| 47 | Post Partum Hemorrhage Clamp | Instrumental | No (saltat -- no verificable com a instrument real amb aquest nom) |
| 48 | PPH Suture Needle | Consumible | No (saltat -- no és un nom d'instrument reconegut) |
| 49 | Uterine Packing Forceps | Instrumental | Sí (`pinza-bozeman` -- mateix instrument, afegit com a alias) |
| 50 | Cervical Punch Forceps | Instrumental | Sí (`pinza-biopsia-cervical` -- fals negatiu del report original, l'alias "Cervical punch forceps" ja hi era) |

## Imatge 2 — "50 Neurological Instruments" (Part-1, 1-50)

| # | Ítem | Classificació | Al catàleg? |
|---|---|---|---|
| 1 | Scalpel Handle | Instrumental | Sí ("Scalpel (handle + blade)") |
| 2 | Scalpel Blade | Instrumental | Sí ("Scalpel blade (loose)") |
| 3 | Adson Tissue Forceps | Instrumental | Sí (amb/sense dents) |
| 4 | Cushing Tissue Forceps | Instrumental | Sí ("Cushing forceps") |
| 5 | DeBakey Tissue Forceps | Instrumental | Sí ("DeBakey atraumatic vascular forceps") |
| 6 | Frazier Suction Tube | Instrumental | Sí (`canula-frazier`) |
| 7 | Yankauer Suction Tube | Instrumental | Sí ("Yankauer cannula") |
| 8 | Dandy Brain Retractor | Instrumental | No (saltat -- cap font trobada més enllà de la biografia històrica de Walter Dandy) |
| 9 | Cushing Retractor | Instrumental | Sí (`separador-cushing`, afegit) |
| 10 | Leyla Retractor | Instrumental | Sí (sistema combinat "Leyla/Greenberg") |
| 11 | Weitlaner Retractor | Instrumental | Sí |
| 12 | Greenberg Retractor | Instrumental | Sí (mateix sistema combinat que #10) |
| 13 | Langenbeck Retractor | Instrumental | Sí |
| 14 | Gelpi Retractor | Instrumental | Sí |
| 15 | Fukuda Brain Retractor | Instrumental | No (saltat -- cap font trobada) |
| 16 | Cerebellar Retractor | Instrumental | Sí (`separador-cerebelar`, afegit) |
| 17 | Love Nerve Root Retractor | Instrumental | Sí (`separador-nervio-love`, afegit; fusionat amb #98 de la imatge 6) |
| 18 | Kerrison Rongeur | Instrumental | Sí |
| 19 | Leksell Rongeur | Instrumental | Sí ("Leksell-type double-action bone rongeur") |
| 20 | Hudson Brace | Instrumental | Sí (`taladro-hudson`, afegit) |
| 21 | Pituitary Rongeur | Instrumental | Sí |
| 22 | Bone Cutting Rongeur | Instrumental | Sí (gúbia òssia genèrica) |
| 23 | Microsurgical Scissors (Straight) | Instrumental | Posible: Vannas/Iris microtisores existeixen, no amb aquest nom |
| 24 | Microsurgical Scissors (Curved) | Instrumental | Posible (idem) |
| 25 | Potts Scissors | Instrumental | Sí ("Potts-Smith scissors") |
| 26 | Steven's Scissors | Instrumental | Sí (`tisora-stevens`, afegit) |
| 27 | Metzenbaum Scissors | Instrumental | Sí |
| 28 | Micro Needle Holder | Instrumental | Sí (coberts per Castroviejo/Barraquer) |
| 29 | Castroviejo Needle Holder | Instrumental | Sí |
| 30 | Mayo-Hegar Needle Holder | Instrumental | Sí |
| 31 | Micro Forceps | Instrumental | No |
| 32 | Jeweler's Forceps | Instrumental | No (només esmentada de passada en un altre instrument) |
| 33 | Bayonet Forceps | Instrumental | Sí (fals negatiu del report original -- l'alias "Cushing bayonet forceps" ja hi era) |
| 34 | Dumont Forceps | Instrumental | No (saltat -- sembla nom de marca de pinça de joier, se solapa amb "Jeweler's Forceps" #32 ja descartat) |
| 35 | Cushing Spatula | Instrumental | Sí (`espatula-cushing`, afegit) |
| 36 | Penfield Dissector (No.1) | Instrumental | Sí ("Penfield dissector", entrada genèrica) |
| 37 | Penfield Dissector (No.2) | Instrumental | Sí (= #36) |
| 38 | Penfield Dissector (No.3) | Instrumental | Sí (= #36) |
| 39 | Penfield Elevator (Flat) | Instrumental | Sí (= #36, mateix instrument de doble punta) |
| 40 | Penfield Elevator (Curved) | Instrumental | Sí (= #36) |
| 41 | Nerve Hook | Instrumental | Sí (`gancho-nervio`, afegit) |
| 42 | Jacobson Nerve Hook | Instrumental | Sí (alias de `gancho-nervio`) |
| 43 | Senn Nerve Hook | Instrumental | Sí (alias de `gancho-nervio`) |
| 44 | Graham Dissector | Instrumental | No (saltat -- cap font trobada) |
| 45 | Arachnoid Dissector | Instrumental | Sí (alias afegit a `disectores-rhoton`) |
| 46 | Dural Elevator | Instrumental | Sí (`elevador-dural-horsley`, afegit) |
| 47 | Malleable Retractor | Instrumental | Sí |
| 48 | Sugita Clip Applier | Instrumental | Sí (fals negatiu del report original -- ja és alias de `aplicador-clip-aneurisma`) |
| 49 | Yasargil Clip Applier | Instrumental | Sí (ídem, ja és alias de `aplicador-clip-aneurisma`) |
| 50 | Aneurysm Clip Applier | Instrumental | Sí |

## Imatge 6 — "100 Neurological Instruments" (Part-2, 51-100)

| # | Ítem | Classificació | Al catàleg? |
|---|---|---|---|
| 51 | Weitlaner Self-Retaining Retractor | Instrumental | Sí (= Weitlaner retractor) |
| 52 | Rhoton Retractor | Instrumental | No (saltat -- el catàleg té "Rhoton Dissector Set", producte diferent, cap font d'un "retractor" propi) |
| 53 | Cohen Retractor | Instrumental | No (saltat -- cap font trobada) |
| 54 | Brain Spatula (Farabeuf) | Instrumental | Posible: "Farabeuf retractor" existeix, epònim compartit, producte diferent |
| 55 | Malleable Brain Retractor | Instrumental | Sí (via separador maleable genèric) |
| 56 | Scoville Retractor | Instrumental | Sí (`separador-scoville`, afegit) |
| 57 | Davis Retractor | Instrumental | Sí (`separador-davis`, afegit) |
| 58 | Grooved Director | Instrumental | Sí ("Sonda acanalada" / "Grooved director") |
| 59 | Brain Retractor System | Instrumental | Sí (sistema Leyla/Greenberg) |
| 60 | Reynolds Retractor | Instrumental | No (saltat -- cap font trobada) |
| 61 | Leksell Retractor System | Instrumental | No (saltat -- no confirmat com a sistema diferenciat del rongeur/clip Leksell ja catalogats) |
| 62 | Sugita Retractor System | Instrumental | No (saltat -- no confirmat com a sistema diferenciat de l'aplicador de clip Sugita ja catalogat) |
| 63 | Greenberg Retractor System | Instrumental | Sí (= #59) |
| 64 | Jarit Retractor | Instrumental | No (saltat -- "Jarit" sembla nom de fabricant, no disseny propi diferenciat) |
| 65 | Meyerding Retractor | Instrumental | Sí (`separador-meyerding`, afegit) |
| 66 | Horsley Bone Punch | Instrumental | Sí (`gubia-horsley`, afegit) |
| 67 | Luer Bone Punch | Instrumental | Sí (`gubia-luer`, afegit) |
| 68 | Kerrison Punch | Instrumental | Sí (= Kerrison rongeur) |
| 69 | Rongeur Punch | Instrumental | Posible (gúbia òssia genèrica) |
| 70 | Leksell Rongeur Punch | Instrumental | Sí (= Leksell rongeur) |
| 71 | Dandy Scalpel | Instrumental | No (saltat -- cap font trobada, probable variant de nom del mànec Handle No.3 ja catalogat) |
| 72 | Gillies Scalpel | Instrumental | No (saltat -- cap font trobada, probable confusió amb el mànec "Barron"/No.3 ja catalogat) |
| 73 | Baron Scalpel | Instrumental | No (saltat -- probable variant ortogràfica de "Barron" (mànec No.3 ja catalogat), cap font pròpia trobada) |
| 74 | Handle No.3 Scalpel | Instrumental | Sí (mencionat explícitament al catàleg) |
| 75 | Penfield #1 Dissector | Instrumental | Sí |
| 76 | Penfield #2 Dissector | Instrumental | Sí |
| 77 | Penfield #3 Dissector | Instrumental | Sí |
| 78 | Penfield #4 Dissector | Instrumental | Sí |
| 79 | Penfield #7 Dissector | Instrumental | Sí |
| 80 | Morgan Dissector | Instrumental | No (saltat -- cap font trobada) |
| 81 | Cushing Aspirating Cannula | Instrumental | No (saltat -- cap font d'un disseny propi diferenciat de Frazier/Yankauer ja catalogats) |
| 82 | Frazier Aspirating Cannula | Instrumental | Sí |
| 83 | Yankauer Frazier Cannula | Instrumental | Sí (combinació dels dos ja catalogats) |
| 84 | Poole Suction Cannula | Instrumental | Sí |
| 85 | Luer-Lok Suction Cannula | Instrumental | No (saltat -- Luer-lock és un tipus de connexió genèric, no un producte propi) |
| 86 | Spetzler Suction Cannula | Instrumental | No (saltat -- cap font trobada) |
| 87 | Slotted Suction Cannula | Instrumental | No (saltat -- cap font trobada) |
| 88 | Ventricular Cannula | Instrumental | Posible: "External ventricular drain catheter" és semblant, producte diferent (sense canvis, ambigüitat no resolta) |
| 89 | Cushing Cannula | Instrumental | No (saltat -- cap font trobada) |
| 90 | Dandy Cannula | Instrumental | No (saltat -- cap font trobada) |
| 91 | Woodson Elevator | Instrumental | Sí (`elevador-woodson`, afegit) |
| 92 | Freer Elevator | Instrumental | Sí ("Freer elevator (ENT)") |
| 93 | Love Elevator | Instrumental | No (saltat -- cap font trobada, diferent de "Love nerve root retractor" ja afegit) |
| 94 | Rhoton Elevator | Instrumental | Sí (alias afegit a `disectores-rhoton`) |
| 95 | Penfield Elevator | Instrumental | Sí |
| 96 | Zabrams Elevator | Instrumental | No (saltat -- cap font trobada) |
| 97 | Discectomy Rongeur | Instrumental | Posible (gúbia òssia genèrica, sense canvis -- no prou diferenciat per justificar alias o fitxa pròpia) |
| 98 | Nerve Root Retractor | Instrumental | Sí (`separador-nervio-love`, = #17 de la imatge 2) |
| 99 | Micro Nerve Hook | Instrumental | Sí (alias de `gancho-nervio`) |
| 100 | Arachnoid Knife | Instrumental | Sí (`bisturi-aracnoideo`, afegit) |

## Imatge 3 — "50 Labour Room Instruments" (Part-1, 1-50)

| # | Ítem | Classificació | Al catàleg? |
|---|---|---|---|
| 1 | Sims Speculum | Instrumental | Sí |
| 2 | Cusco's Speculum | Instrumental | Sí |
| 3 | Vaginal Wall Retractor | Instrumental | Sí (alias "Vaginal wall retractor" afegit a `separador-breisky-navratil`, = #16 de la imatge 1) |
| 4 | Auvard Weighted Speculum | Instrumental | No |
| 5 | Volsellum Forceps | Instrumental | Sí |
| 6 | Sponge Holding Forceps | Instrumental | Sí |
| 7 | Allis Forceps | Instrumental | Sí |
| 8 | Foetal Scalp Electrode | Equipamiento | No |
| 9 | Fetal Scalp Clip | Equipamiento | No |
| 10 | Amniotomy Hook | Instrumental | Sí |
| 11 | Artery Forceps | Instrumental | Sí (alias afegit a `pinza-kelly`) |
| 12 | Dressing Forceps | Instrumental | Sí (= #29 de la imatge 1, alias a `pinza-diseccion-sin-dientes`) |
| 13 | Tissue Forceps | Instrumental | Sí (alias afegit a `pinza-diseccion-dientes`) |
| 14 | Kocher Forceps | Instrumental | Sí |
| 15 | Babcock Forceps | Instrumental | Sí |
| 16 | Green Armytage Forceps | Instrumental | Sí |
| 17 | Desjardin's Forceps | Instrumental | Sí ("Desjardins gallstone forceps", altra especialitat, mateix nom) |
| 18 | Placenta Forceps | Instrumental | Sí (= #10 de la imatge 1, `pinza-restos-ovulares`) |
| 19 | Cord Clamps | Instrumental | Sí |
| 20 | Umbilical Cord Scissors | Instrumental | Sí |
| 21 | Episiotomy Scissors | Instrumental | Sí |
| 22 | Mayo Scissors (Straight) | Instrumental | Sí |
| 23 | Mayo Scissors (Curved) | Instrumental | Sí |
| 24 | Metzenbaum Scissors | Instrumental | Sí |
| 25 | Stitch Scissors | Instrumental | Sí |
| 26 | Uterine Scissors | Instrumental | No (saltat -- massa genèric, sense disseny propi diferenciat de Mayo/Metzenbaum ja catalogades) |
| 27 | Curved Umbilical Scissors | Instrumental | Sí |
| 28 | Toomey Syringe | Consumible | Posible (xeringa d'un sol ús genèrica) |
| 29 | Bulb Suction (Catheter) | Instrumental | Sí (`pera-aspiracion-neonatal`, afegit) |
| 30 | Fetal Doppler | Equipamiento | Sí (`doppler-fetal-manual`, nou -- el Doppler vascular/intraoperatori ja catalogat és un producte diferent) |
| 31 | Labour Bed | Equipamiento | Sí (`llit-dilatacio-part`, fusionat amb #32) |
| 32 | Delivery Table | Equipamiento | Sí (= #31) |
| 33 | Instrument Trolley | Equipamiento | Sí (= `carro-transport-cssd` de la imatge 5, sense fitxa duplicada) |
| 34 | Mayo Instrument Tray | Equipamiento | Sí (`suport-taula-mayo`) |
| 35 | Kidney Tray | Equipamiento | Sí (`safata-ronyo`) |
| 36 | Gallipot (250 ml) | Equipamiento | Sí (`got-antiseptic-gallipot`, fusionat amb #37) |
| 37 | Gallipot (500 ml) | Equipamiento | Sí (= #36) |
| 38 | Sponge Bowl | Equipamiento | Sí (`bol-quirurgic-acer`, fusionat amb #39/#40) |
| 39 | Instrument Bowl | Equipamiento | Sí (= #38) |
| 40 | Perineal Tray | Equipamiento | Sí (= #38) |
| 41 | Hot Water Bag | Equipamiento | Sí (`bossa-aigua-calenta`) |
| 42 | Urine Pot | Equipamiento | No (deixat fora -- valor diferencial molt baix) |
| 43 | Enema Can | Equipamiento | No (deixat fora -- pràctica en desús, valor diferencial baix) |
| 44 | Measuring Tape | Equipamiento | No (deixat fora -- trivial) |
| 45 | Partograph Chart | Equipamiento (documental) | No (és un document clínic, no un objecte físic) |
| 46 | CTG Machine | Equipamiento | Sí (`monitor-ctg-cardiotocograf`) |
| 47 | BP Apparatus | Equipamiento | No (cobert conceptualment pel monitor CTG/multiparamètric, mateix criteri que el lot 2) |
| 48 | Stethoscope (Fetal) | Equipamiento | Sí (`estetoscop-pinard`) |
| 49 | Examination Gloves | Equipamiento/Consumible | No (massa genèric) |
| 50 | Waste Bin | Equipamiento | No (massa genèric, mateix criteri que el lot 2) |

*(Fetal Doppler, #30, resolt dins d'aquest mateix lot: `doppler-fetal-manual`.)*

## Imatge 4 — "50 ICU Instruments" (Part-1, 1-50)

**Actualitzat després del lot 2** (equipament crític/via aèria/monitorització,
`docs/CHANGELOG.md`). Molts "No" originals ja eren falsos negatius: el catàleg
ja tenia laringoscopi, desfibril·lador-monitor, tub endotraqueal, cànula de
traqueostomia, catèter venós central, catèter arterial, pulsioxímetre,
capnògraf, bossa autoinflable i 3 ecògrafs portàtils abans de començar aquest
lot.

| # | Ítem | Classificació | Al catàleg? |
|---|---|---|---|
| 1 | Multipara Monitor | Equipamiento | Sí (`monitor-constantes-vitales`) |
| 2 | Ventilator | Equipamiento | Sí (`ventilador-mecanico-uci`) |
| 3 | Syringe Pump | Equipamiento | Sí (`bomba-infusion-volumetrica`, fusionat) |
| 4 | Infusion Pump | Equipamiento | Sí (`bomba-infusion-volumetrica`) |
| 5 | Defibrillator | Equipamiento | Sí (ja existia: `desfibrilador-monitor`) |
| 6 | Suction Apparatus | Equipamiento | Sí (ja existia: `sistema-aspiracion-pared`) |
| 7 | Oxygen Cylinder | Equipamiento | Sí (`bombona-oxigen`) |
| 8 | Ambu Bag (Manual Resuscitator) | Equipamiento | Sí (ja existia: bossa autoinflable de reanimació) |
| 9 | Oxygen Mask | Equipamiento | Sí (`sistema-oxigenoterapia-baix-flux`) |
| 10 | Nasal Cannula | Instrumental/Consumible | Sí (= #9, fusionat) |
| 11 | Pulse Oximeter | Equipamiento | Sí (ja existia: `pulsioximetro`) |
| 12 | Capnography Monitor | Equipamiento | Sí (ja existia: `capnografo`) |
| 13 | Arterial Line Set | Instrumental/Consumible | Sí (ja existia: catèter arterial) |
| 14 | Central Line Catheter | Instrumental/Consumible | Sí (ja existia: catèter venós central) |
| 15 | Triple Lumen Catheter | Instrumental/Consumible | Sí (= #14) |
| 16 | Foley's Catheter | Instrumental | Sí |
| 17 | Ryle's Tube | Instrumental | Sí (`sonda-nasogastrica`) |
| 18 | Endotracheal Tube | Instrumental/Consumible | Sí (ja existia) |
| 19 | Tracheostomy Tube | Instrumental/Consumible | Sí (ja existia) |
| 20 | Laryngoscope Set | Equipamiento | Sí (ja existia: laringoscopi) |
| 21 | Suction Catheter | Instrumental/Consumible | Sí (`sonda-aspiracion-traqueal`) |
| 22 | Yankauer Suction Tip | Instrumental | Sí |
| 23 | ECG Electrodes | Equipamiento/Consumible | No (cobert conceptualment pel monitor multiparamètric, sense fitxa pròpia) |
| 24 | ECG Machine | Equipamiento | No (= #23) |
| 25 | BP Apparatus | Equipamiento | No (cobert pel monitor multiparamètric -- PA no invasiva) |
| 26 | Temperature Probe | Equipamiento | No (deixat fora, baix valor diferencial) |
| 27 | Glucometer | Equipamiento | Sí (`glucometro`) |
| 28 | Nebulizer | Equipamiento | No (deixat fora aquest lot) |
| 29 | Spirometer | Equipamiento | Sí (`espirometre-diagnostic`) |
| 30 | Incentive Spirometer | Equipamiento | Sí (`espirometre-incentivador`) |
| 31 | Chest Drain Set | Instrumental/Consumible | Sí (ja existia: sistema de drenatge toràcic) |
| 32 | Underwater Seal Drain | Equipamiento | Sí (= #31) |
| 33 | Pressure Transducer | Equipamiento | No (cobert conceptualment via Arterial Line Set) |
| 34 | ABG Analyzer | Equipamiento | Sí (`analitzador-gasometria-pocd`) |
| 35 | Portable X-Ray Machine | Equipamiento | Sí (`radiografia-portatil`) |
| 36 | Ultrasound Machine | Equipamiento | Sí (ja existia, 3 ecògrafs diferents) |
| 37 | ET Suction Catheter | Instrumental/Consumible | Sí (= #21) |
| 38 | I.V. Cannula (Set) | Instrumental/Consumible | Sí (`cateter-venoso-periferico`) |
| 39 | HME Filter | Equipamiento/Consumible | No (deixat fora) |
| 40 | Humidifier Bottle | Equipamiento | No (deixat fora) |
| 41 | ABG Syringe | Consumible | Posible (xeringa genèrica) |
| 42 | Tourniquet | Equipamiento | Sí ("Pneumatic surgical tourniquet") |
| 43 | Vein Finder | Equipamiento | Sí (`localitzador-venes-infraroig`) |
| 44 | Drug Trolley | Equipamiento | No (mobiliari de muntatge, deixat fora) |
| 45 | Crash Cart | Equipamiento | No (deixat fora) |
| 46 | Bedside Table | Equipamiento | No (deixat fora, trivial) |
| 47 | ICU Bed | Equipamiento | No (mobiliari genèric de planta, pendent del lot 3) |
| 48 | Air Mattress | Equipamiento | No (deixat fora) |
| 49 | Cardiac Monitor | Equipamiento | Sí (= #1, fusionat) |
| 50 | Sterilization Container | Equipamiento | No (pertany al lot 3 CSSD) |

## Imatge 7 — "50 ICU Instruments" (Part-8, 351-400)

Equipament avançat d'UCI (monitors, analitzadors, bombes especialitzades).
**Actualitzat després del lot 2**: la majoria segueix fora de l'abast
d'aquest lot (massa nínxol o de baix valor diferencial per al temps
disponible — vegeu `docs/CHANGELOG.md`), però alguns conceptes ja queden
coberts, fusionats amb una fitxa general:

- Resolts: High Flow Oxygen Therapy Device → `canula-nasal-alt-flux`; Neonatal
  Ventilator → `ventilador-mecanico-uci` (mencionat al `tip`); Portable ECG
  Printer → cobert pel monitor multiparamètric; Capnography (Mainstream)
  Monitor → ja existia (`capnografo`); Blood Gas Analyzer (Portable) /
  Co-Oximeter / Portable Hemoglobin Analyzer → `analitzador-gasometria-pocd`;
  Fiberoptic Bronchoscope → ja existia (`fibrobroncoscopi-intubacio`);
  Patient Warming System → `manta-aire-calent`; Targeted Temperature
  Management System → `sistema-control-temperatura-dirigit`; Rapid Infuser
  (Blood & Fluid Warmer) → `infusor-rapid-alt-flux`; IV Fluid Warmer with
  Infusion Set / Fluid Warmer Cabinet → `escalfador-fluids-sang`; Pneumatic
  Anti-Embolism Device → `dispositiu-compressio-pneumatica-intermitent`;
  Vein Finder (Infrared) → `localitzador-venes-infraroig`; Portable Oral
  Suction Device → ja existia (`sistema-aspiracion-pared`); CPR Feedback
  Device → cobert conceptualment pel desfibril·lador-monitor existent.
- També resolts (ja existien al catàleg abans d'aquest lot, el report
  original s'havia equivocat): BIS Monitor (`monitor-bis`), ETCO2 Monitor (=
  capnògraf, `capnografo`), Neuromuscular Transmission Monitor
  (`neuroestimulador-periferico`), Video Laryngoscope (`videolaringoscopio`).
- Electrolyte Analyzer / Digital Urine Analyzer POC → Sí, plegats a
  `analitzador-gasometria-pocd`; Blood Ketone Meter → Sí, plegat a
  `glucometro`; Pediatric Resuscitator Bag → Sí, plegat a la bossa
  autoinflable existent.
- Encara "No", deixats fora deliberadament per nínxol/baix valor diferencial:
  Serosanguineous Drainage System, Infrared Thermometer, Lactate Monitoring
  Device, Tissue Oxygen Monitor, Transesophageal Echocardiography Probe,
  Urine Output Monitoring System, Medical Gas Blender, Pulse Wave Analysis
  Monitor, Microdialysis Monitoring System, Central Line Dressing Change
  Kit, Portable Anesthesia Gas Analyzer, Sterile Multiparameter
  Monitor/Procedure Cart (variants de muntatge).

## Imatge 10 — ICU / Anestèsia (51-140)

Barreja d'equipament de planta i instrumental/consumible de via aèria.
**Actualitzat després del lot 2**:

| # | Ítem | Classificació | Al catàleg? |
|---|---|---|---|
| 51-53 | Laryngoscope Handle/Blade (Macintosh/Miller) | Instrumental | Sí (ja existia: laringoscopi, mànec + fulla) |
| 54 | Video Laryngoscope | Equipamiento | Sí (ja existia: videolaringoscopi) |
| 55 | Fiberoptic Bronchoscope | Equipamiento | Sí (ja existia) |
| 61 | Transport Ventilator | Equipamiento | Sí (`ventilador-mecanico-uci`, mencionat al tip) |
| 62 | High Flow Nasal Cannula | Equipamiento | Sí (`canula-nasal-alt-flux`) |
| 63 | Non-Rebreather Mask | Equipamiento | Sí (`sistema-oxigenoterapia-baix-flux`) |
| 64-65 | BiPAP Machine / Bubble CPAP System | Equipamiento | Sí (`dispositiu-vmni-bipap-cpap`) |
| 66-67 | Nitrous Oxide Cylinder / Anesthesia Machine | Equipamiento | Sí (`bombona-oxigen` / ja existia la màquina d'anestèsia) |
| 68 | Scalpel Handle | Instrumental | Sí (= Imatge 2 #1) |
| 69 | Surgical Blade | Instrumental | Sí (= Imatge 2 #2) |
| 70 | Electrocautery Unit | Equipamiento | No (el catàleg té accessoris d'electrocirurgia — ganxo monopolar, elèctrodes — però no la unitat generadora en si; deixat fora aquest lot) |
| 73 | Intra Aortic Balloon Pump | Equipamiento | Sí (ja existia) |
| 74-75 | CRRT Machine / Dialysis Machine | Equipamiento | Sí (`maquina-hemodialisi-crrt`, fusionat) |
| 76 | Bladder Scanner | Equipamiento | Sí (`escaner-vesical`) |
| 80 | Sputum Suction Catheter | Instrumental/Consumible | Sí (`sonda-aspiracion-traqueal`) |
| 82-84 | Resuscitation Trolley / Warming Blanket / Blood Warmer Device | Equipamiento | Sí (manta i escalfador resolts; el carro de muntatge, no) |
| 85-86 | Infant Incubator / Phototherapy Unit | Equipamiento | Sí (`incubadora-neonatal`, `unitat-fototerapia-neonatal`) |
| 90 | Central Venous Catheter (CVC) Set | Instrumental/Consumible | Sí (ja existia) |
| 92-93 | Tracheostomy Tube (Cuffed/Uncuffed) | Instrumental/Consumible | Sí (ja existia, dup. Imatge 4 #19) |
| 101-103 | IV Infusion Set / IV Cannula (Peripheral/Safety) | Instrumental/Consumible | Sí (`cateter-venoso-periferico`) |
| 107-108 | Arterial Line Monitoring Line / Pressure Transducer | Instrumental/Consumible | Sí (ja existia el catèter arterial; el transductor en si, no) |
| 110 | Foley Catheter | Instrumental | Sí (dup.) |
| 114-115 | NG Tube / Ryle's Tube | Instrumental/Consumible | Sí (`sonda-nasogastrica`) |
| 116-117 | ET Tube (Cuffed/Uncuffed) | Instrumental/Consumible | Sí (ja existia) |
| 118-119 | Stylet / Tube Introducer | Instrumental/Consumible | Sí (`fiador-tub-endotraqueal`) |
| 121 | Ambu Mask | Equipamiento | Sí (= bossa autoinflable existent) |
| 122 | Oropharyngeal Airway | Instrumental | Sí ("Guedel cannula") |
| 123 | Nasopharyngeal Airway | Instrumental | Sí (`canula-nasofaringia`) |
| 129 | Acapella Device | Equipamiento | Sí (`dispositiu-pep-oscillatori`, fusionat amb Flutter) |
| 133-136 | Syringe (1/5/10ml, Insulin) | Consumible | Posible (xeringa d'un sol ús genèrica, no diferenciada per mida/tipus — sense canvis) |
| 139 | Sharps Container | Equipamiento | Sí (`contenidor-objectes-punxants`) |
| 138 | Safety Needle | Consumible | Sí (`agulla-seguretat`) |
| *(resta no esmentada: 56-60, 71-72, 77-79, 81, 87-89, 91, 94-100, 104-106, 109, 111-113, 120, 124-128, 130-132, 137, 140)* | Equipamiento/Consumible | No — torre d'endoscòpia, regulador/flowmeter/PEEP valve d'ús genèric ja cobert via `valvula-peep`, bàscula, martell de percussió, vibració toràcica, entrenador inspiratori, connectors/allargaderes genèrics, sondatge/col·lecció d'orina i femta (`sonda-vesical-intermitent`/`sistema-gestio-fecal` ja els cobreixen conceptualment), biohazard waste bin genèric. |

## Imatge 5 — "50 Sterilization / CSSD Instruments" (Part-1, 1-50)

**Actualitzat després del lot 3.** Molts conceptes queden fusionats en una sola
fitxa quan el post els llistava com a variants de mida/format del mateix
objecte real (vegeu `docs/CHANGELOG.md` per al detall complet de fusions).

| # | Ítem | Al catàleg? |
|---|---|---|
| 1 | Instrument Cleaning Tray | Sí (`cistella-perforada-instrumental`) |
| 2 | Perforated Basket | Sí (= #1) |
| 3 | Wire Mesh Basket | Sí (= #1) |
| 4 | Instrument Trolley | Sí (`carro-transport-cssd`) |
| 5 | Loading Trolley | Sí (= #4) |
| 6 | Unloading Trolley | Sí (= #4) |
| 7 | SS Kidney Tray | Sí (`safata-ronyo`, imatge 3 #35) |
| 8 | SS Gallipot (250 ml) | Sí (`got-antiseptic-gallipot`, imatge 3 #36) |
| 9 | SS Gallipot (500 ml) | Sí (= #8) |
| 10 | SS Bowl | Sí (`bol-quirurgic-acer`, imatge 3 #38) |
| 11 | Instrument Set Container | Sí (`contenidor-rigid-esterilitzacio`) |
| 12 | Hinged Container | Sí (= #11) |
| 13 | Wire Mesh Tray | Sí (= #1) |
| 14 | Silicone Mat | No (deixat fora -- valor diferencial baix) |
| 15 | Instrument Stand | Sí (`prestatgeria-emmagatzematge-esteril`) |
| 16 | Rinsing Sink | No (deixat fora -- infraestructura de planta, no equipament mòbil) |
| 17 | Ultrasonic Cleaner | Sí (`netejador-ultrasons`) |
| 18 | Washer Disinfector | Sí (`rentadora-desinfectora`) |
| 19 | Hot Air Oven (Dry Heat) | Sí (`forn-aire-calent-sec`) |
| 20 | Autoclave (Vertical) | Sí (`autoclau-vapor`) |
| 21 | Autoclave (Horizontal) | Sí (= #20) |
| 22 | Steam Sterilizer | Sí (= #20) |
| 23 | ETO Gas Sterilizer | Sí (`esterilitzador-oxid-etile`) |
| 24 | Plasma Sterilizer | Sí (`esterilitzador-plasma-peroxid`) |
| 25 | Sterilization Pouch | Sí (`bossa-esterilitzacio`) |
| 26 | Sterilization Roll | Sí (= #25) |
| 27 | Sterilization Wrap | Sí (= #25) |
| 28 | Sterilization Tape | Sí (`indicador-quimic-esterilitzacio`) |
| 29 | Chemical Indicator Tape | Sí (= #28) |
| 30 | Biological Indicator | Sí (`indicador-biologic-esterilitzacio`) |
| 31 | Test Pack | Sí (`paquet-prova-bowie-dick`, fusionat -- el Bowie-Dick és, a la pràctica, el test pack estàndard) |
| 32 | Bowie Dick Test Pack | Sí (= #31) |
| 33 | pH Indicator Strip | No (deixat fora -- valor diferencial baix) |
| 34 | Cleaning Brush (Big) | Sí (`raspall-neteja-instrumental`) |
| 35 | Cleaning Brush (Small) | Sí (= #34) |
| 36 | Lumen Cleaning Brush | Sí (= #34, variant de llum com a `tip`) |
| 37 | Pipette (Plastic) | No (deixat fora -- material de laboratori genèric) |
| 38 | Measuring Cylinder | No (deixat fora -- material de laboratori genèric) |
| 39 | Detergent Solution Can | No (deixat fora -- consumible químic massa genèric) |
| 40 | Enzymatic Detergent | No (= #39) |
| 41 | Lubricant Spray | No (deixat fora -- consumible de manteniment, valor diferencial baix) |
| 42 | Rust Remover Solution | No (= #41) |
| 43 | Corrosion Inhibitor | No (= #41) |
| 44 | Distilled Water Can | No (= #39) |
| 45 | Drying Cabinet | No (fase ja integrada a la rentadora desinfectora) |
| 46 | Sealing Machine | Sí (`selladora-bosses-esterilitzacio`) |
| 47 | Heat Sealer (Continuous) | Sí (= #46) |
| 48 | Vacuum Packing Machine | Sí (= #46) |
| 49 | Sterile Storage Rack | Sí (= #15) |
| 50 | Laminar Air Flow Cabinet | Sí (`cabina-flux-laminar`) |

## Imatge 8 — "50 Medicine & Syrup" (Part-1, 1-50)

Resolt el 2026-11-11 (lot 5): el catàleg de farmacologia (`lib/data/drugs_data.dart`,
abans només "d'anestèsia") s'ha ampliat a formulari general. **Sí** = fitxa nova
o entrada existent ampliada; **No (descartat)** = no verificable com a fàrmac
real amb aquest nom exacte, no afegit deliberadament.

| Ítem (post) | Al catàleg? |
|---|---|
| Paracetamol Syrup | Sí (`paracetamol`) |
| Ibuprofen Syrup (×2, fusionades) | Sí (`ibuprofeno`) |
| Cetirizine Syrup | Sí (`cetirizina`, alias) |
| Levocetirizine Syrup | Sí (alias de `cetirizina`) |
| Chlorpheniramine Syrup | Sí (`clorfenamina`) |
| Diphenhydramine Syrup | Sí (`difenhidramina`) |
| Amoxicillin Syrup | Sí (`amoxicilina`) |
| Azithromycin Syrup | Sí (`azitromicina`) |
| Cefixime Syrup | Sí (`cefixima`) |
| Ofloxacin Syrup(?) | No (descartat: lectura dubtosa de la infografia) |
| Metronidazole Syrup | Sí (`metronidazol`) |
| Albendazole Syrup | Sí (`albendazol`) |
| Ivermectin Syrup | Sí (`ivermectina`) |
| Domperidone Syrup | Sí (`domperidona`) |
| Ondansetron Syrup | Sí (ja existia, `ondansetron`) |
| Ranitidine Syrup | Sí (`ranitidina`) |
| Omeprazole Syrup | Sí (`omeprazol`) |
| Sucralfate Syrup | Sí (`sucralfato`) |
| Magnesium Hydroxide Syrup | Sí (`hidroxido-aluminio-magnesio`, fusionat) |
| Aluminium Hydroxide Syrup(?) | Sí (fusionat a `hidroxido-aluminio-magnesio`) |
| Dicyclomine Syrup | Sí (`dicicloverina`) |
| Simethicone Syrup | Sí (`simeticona`) |
| Lactulose Syrup | Sí (`lactulosa`) |
| Sodium Picosulfate Syrup | Sí (`picosulfato-sodico`) |
| Mefenamic Acid Syrup | Sí (`acido-mefenamico`) |
| Nimesulide Syrup | Sí (`nimesulida`) |
| Aceclofenac Syrup | Sí (`aceclofenaco`) |
| Serratiopeptidase Syrup | No (descartat: evidència clínica feble, producte d'ús regional) |
| Ambroxol Syrup(?) | Sí (`ambroxol`) |
| Guaifenesin Syrup | Sí (`guaifenesina`) |
| Terbutaline Syrup | Sí (`terbutalina`) |
| Salbutamol Syrup | Sí (`salbutamol`) |
| Budesonide Syrup | Sí (`budesonida`) |
| Montelukast Syrup | Sí (`montelukast`) |
| Sodium Cromoglycate Syrup | Sí (`cromoglicato-sodico`) |
| Pheniramine Syrup | Sí (fusionat a `clorfenamina`) |
| Phenylephrine Syrup | Sí (entrada existent `fenilefrina` ampliada amb vies oral/nasal) |
| Dextromethorphan Syrup | Sí (`dextrometorfano`) |
| Codeine Syrup(?) | No (descartat: lectura dubtosa + ús pediàtric restringit) |
| Multivitamin Syrup | Sí (`multivitaminico`) |
| Vitamin B-Complex Syrup | Sí (`complejo-vitaminico-b`) |
| Vitamin C Syrup | Sí (`vitamina-c`) |
| Zinc Syrup | Sí (`zinc-suplemento`) |
| Iron Syrup | Sí (`hierro-suplemento`) |
| Calcium Syrup | Sí (`calcio-suplemento`) |
| Cyproheptadine Syrup | Sí (`ciproheptadina`) |
| Disodium Hydrogen Citrate Syrup | No (descartat: ús molt de nínxol, sense classe pròpia clara) |
| Neomycin Syrup | Sí (`neomicina`) |
| Promethazine Syrup(?) | Sí (`prometazina`, fusionat amb la versió injectable) |

## Imatge 9 — "50 Injection Drugs" (Part-8, 351-400)

Resolt el 2026-11-11 (lot 5), mateix criteri que la imatge 8.

| Ítem (post) | Al catàleg? |
|---|---|
| Piperacillin + Tazobactam | Sí (`piperacilina-tazobactam`) |
| Amoxicillin + Clavulanic Acid | Sí (`amoxicilina-clavulanico`) |
| Cefoperazone + Sulbactam | Sí (`cefoperazona-sulbactam`) |
| Ceftazidime + Avibactam | Sí (`ceftazidima-avibactam`) |
| Meropenem + Vaborbactam | Sí (`meropenem-vaborbactam`) |
| Gentamicin Sulfate | Sí (`gentamicina`) |
| Amikacin Sulfate | Sí (`amikacina`) |
| Tobramycin Sulfate | Sí (`tobramicina`) |
| Netilmicin Sulfate | No (descartat: discontinuada a la majoria de mercats) |
| Colistin Sulfate | Sí (`colistina`) |
| Adrenaline | Sí (`adrenalina`) |
| Noradrenaline | Sí (ja existia, `noradrenalina`) |
| Isoprenaline | Sí (`isoprenalina`) |
| Dopamine | Sí (`dopamina`) |
| Dobutamine | Sí (`dobutamina`) |
| Atropine Sulfate | Sí (`atropina`) |
| Glycopyrrolate | Sí (`glicopirronio`) |
| Neostigmine | Sí (ja existia, `neostigmina`) |
| Magnesium Sulfate | Sí (`sulfato-magnesio`) |
| Calcium Gluconate | Sí (`gluconato-calcio`) |
| Sodium Nitroprusside | Sí (`nitroprusiato-sodico`) |
| Nitroglycerin | Sí (`nitroglicerina`) |
| Amiodarone | Sí (`amiodarona`) |
| Lidocaine 2% (×2 variants) | Sí (ja existia, `lidocaina`) |
| Bupivacaine 0.5% | Sí (ja existia, `bupivacaina`) |
| Ringer Lactate | Sí (`ringer-lactato`) |
| Dextran 40 | Sí (`dextrano-40`) |
| HES (Hydroxyethyl Starch 6%) | Sí (`hidroxietilalmidon`) |
| Mannitol 20% | Sí (`manitol`) |
| Furosemide | Sí (`furosemida`) |
| Dexamethasone | Sí (`dexametasona`) |
| Hydrocortisone Sodium Succinate | Sí (`hidrocortisona`) |
| Methylprednisolone | Sí (`metilprednisolona`) |
| Ondansetron | Sí (ja existia, `ondansetron`) |
| Metoclopramide | Sí (`metoclopramida`) |
| Promethazine | Sí (fusionat amb la versió xarop, `prometazina`) |
| Chlorpromazine | Sí (`clorpromazina`) |
| Haloperidol | Sí (`haloperidol`) |
| Midazolam | Sí (ja existia, `midazolam`) |
| Diazepam | Sí (`diazepam`) |
| Phenytoin Sodium | Sí (`fenitoina`) |
| Sodium Bicarbonate 7.5% | Sí (`bicarbonato-sodico`) |
| Potassium Chloride | Sí (`cloruro-potasico`) |
| Vitamin B Complex | Sí (fusionat amb la versió xarop, `complejo-vitaminico-b`) |
| Vitamin K1 | Sí (`vitamina-k1`) |
| Tranexamic Acid | Sí (`acido-tranexamico`) |
| Heparin Sodium | Sí (`heparina-sodica`) |
| Insulin Soluble | Sí (`insulina-regular`) |
| Insulin Isophane (NPH) | Sí (`insulina-nph`) |

## Imatge 11 — "Types of Syringes" (taula de referència, no numerada)

| Ítem | Classificació | Al catàleg? |
|---|---|---|
| Disposable Syringe | Consumible | Sí ("Disposable syringe") |
| Insulin Syringe | Consumible | Posible (no diferenciada) |
| Tuberculin Syringe | Consumible | Posible |
| Luer Lock Syringe | Consumible | Posible |
| Luer Slip Syringe | Consumible | Posible |
| Oral/Enteral Syringe | Consumible | Posible |
| Spinal Syringe | Consumible | Posible |
| Auto Disable (AD) Syringe | Consumible | Posible |
| Pre-filled Syringe | Consumible | Posible |
| Heparin Syringe | Consumible | Posible |
| Safety Syringe | Consumible | Posible |

---

## Notes finals: abast actual d'Instriq

**Encaixen de ple** amb el catàleg actual (instrumental quirúrgic de mà,
organitzat per especialitat):
- **Obstetrícia/Ginecologia** (Imatge 1): bona cobertura ja existent (forceps,
  espècules, tisores, pinces hemostàtiques). Gaps reals: Vacuum Extractor ja hi
  és, però manquen peces de nom propi força específiques (Bozeman, Placenta
  Forceps, Ovum Forceps, Auvard Weighted Speculum, Veit-Smellie).
- **Neurocirurgia** (Imatges 2 i 6, 100 ítems): cobertura mitjana-alta en
  separadors/gúbies/dissectors Penfield, però manquen bastants retractors de
  marca específica (Rhoton, Scoville, Davis, Jarit, Meyerding, Reynolds, Cohen)
  i elevadors (Woodson, Love, Rhoton, Zabrams) que avui no estan catalogats.
- **Labour Room** (Imatge 3): el subconjunt d'instrumental de mà és
  essencialment el mateix que Obstetrícia (mateixes respostes); el subconjunt
  d'equipament de sala (llit, taula de part, safates, etc.) queda fora d'abast.

**Fora de l'abast actual** (cap entrada equivalent, i l'enum `Specialty` ni tan
sols té una categoria per a aquests àmbits):
- **UCI** (Imatges 4, 7 i 10, ~190 ítems): monitors, respiradors, bombes,
  analitzadors de planta — no instrumental de camp quirúrgic.
- **Esterilització/CSSD** (Imatge 5, 50 ítems): maquinària i consumibles de
  processament de material, no instrumental quirúrgic en si.
- **Fàrmacs** (Imatges 8 i 9, 100 ítems): domini completament diferent
  (formulari/farmàcia), sense cap camp al model `Instrument` per a dosi,
  principi actiu o via d'administració. Si es vol un comptador "X fàrmacs" a la
  web caldria un model de dades nou, no reutilitzar `InstrumentCategory`.
