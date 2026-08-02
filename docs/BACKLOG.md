# Instriq Product Backlog

## Estat actual

### Tasques pendents (requereixen intervenció manual)

Aquestes tasques no poden ser automatitzades per Claude Code.

* Publicar manualment el fitxer AAB a Google Play Console.
* Verificar en un entorn real, amb usuaris autenticats, els fluxos D i E:

  * Equip amb permisos heretats.
  * Flux complet de creació d'una targeta:

    * Esborrany.
    * Revisió.
    * Publicació.

Actualment aquests fluxos únicament s'han validat en mode convidat.

---

## Bugs coneguts (pendents d'investigar)

* ~~Filtre de Mode de Treball no sembla tenir efecte~~ — **arreglat (2026-08)**. Causa real: `PopupMenuButton<T>` de Flutter confon "menú tancat sense triar" amb "s'ha triat `value: null`" (`showMenu` retorna `null` en tots dos casos), així que `onSelected` mai s'executava en tocar "Sense preferència" a `lib/navigation/work_mode_header.dart` — el mode mai es reiniciava i el botó tornava a mostrar l'anterior. El selector de xips de "El meu compte" (`work_mode_picker.dart`) ja funcionava bé, no tenia aquest problema. Verificat amb `flutter analyze`/`flutter test`; **pendent de provar en viu amb usuari autenticat** (el header només es mostra amb hospital connectat, no reproduïble en mode convidat).

---

# Millores pendents

## Arquitectura funcional

* Dissenyar el sistema de versionat per a l'instrumental personalitzat.
* Dissenyar el versionat de la informació d'esterilització i de les fitxes tècniques.
* Completar el model de Grafo de Coneixement.
* Convertir Vídeo i Nota en entitats independents relacionades amb la resta del sistema.

---

## Aprenentatge

* Sincronitzar el progrés d'aprenentatge amb Supabase.
* Actualment el progrés és exclusivament local.

---

## Offline

* Implementar suport complet per treballar sense connexió.
* Sincronització automàtica.
* Resolució de conflictes.
* Cache intel·ligent.

---

## Qualitat de dades

* Unificar les dues taxonomies actuals d'especialitats (14 i 16 categories).
* Internacionalitzar les observacions d'esterilització.
* Eliminar textos fixos únicament disponibles en castellà.

---

## Plataforma

* Migrar Flutter al nou sistema "Built-in Kotlin".
* Aquesta migració no és urgent però s'ha de planificar.

---

## Sostenibilitat

* Desenvolupar un sistema de donacions completament transparent.
* Diferenciar clarament:

  * Manteniment del projecte.
  * Donacions destinades a investigació mèdica.

---

# Product Roadmap

## EPIC 1 · Knowledge Graph

### Objectiu

Transformar Instriq en una plataforma basada en coneixement relacionat.

No volem una wiki.

No volem una col·lecció de fitxes.

Volem un Grafo de Coneixement.

Exemple:

Colecistectomia

↓

utilitza

↓

Kelly

↓

fabricada per

↓

Aesculap

↓

compatible amb

↓

Autoclau de vapor

↓

inclosa a

↓

Safata General

↓

preferida pel

↓

Dr. Garcia

Cada element ha de convertir-se en una entitat independent relacionada amb la resta.

---

## EPIC 2 · Clinical Workspace

### Objectiu

Eliminar el concepte de "fitxa".

Crear un espai de treball clínic centrat en cada procediment.

Exemple:

Colecistectomia laparoscòpica

En una única pantalla:

* Resum.
* Passos.
* Vídeos.
* Instrumental.
* Safata.
* Material fungible.
* Sutures.
* Implants.
* Posicionament.
* Esterilització.
* IFU.
* Notes.
* Preferències de l'equip.
* Historial de versions.

L'usuari no ha de navegar entre múltiples pantalles per completar una tasca.

---

## EPIC 3 · CSSD Workspace

### Objectiu

Construir un mòdul específic per a esterilització.

No serà un conjunt de camps.

Serà un model de dades propi.

Cada instrument podrà relacionar-se amb:

* Mètodes d'esterilització.
* Paràmetres.
* Compatibilitats.
* Incidències.
* Lubricació.
* Manteniment.
* IFU.
* Fabricant.
* Historial.

---

## EPIC 4 · Trays 2.0

### Objectiu

Evolucionar les safates cap a un model complet.

Cada safata haurà de permetre:

* Checklist.
* Posició física de cada instrument.
* Fotografies.
* Versions.
* Preparació.
* Control de qualitat.
* Validació.
* Duplicació.
* Notes.
* Historial.

---

## EPIC 5 · Smart Search

### Objectiu

La cerca serà el centre de tota la plataforma.

No únicament buscarà noms.

També relacions.

Exemples:

Kelly

Cole

Autoclau

Trauma

Dr. Garcia

Tisores

ETHICON

Plasma

Bisturí

Els resultats hauran d'agrupar-se per tipus d'entitat.

La cerca haurà d'evolucionar posteriorment cap a cerca semàntica.

---

## EPIC 6 · Clinical AI Assistant

### Objectiu

Incorporar IA únicament quan el Knowledge Graph estigui consolidat.

La IA haurà de poder:

* Respondre preguntes.
* Comparar instruments.
* Explicar procediments.
* Generar resums.
* Detectar documentació incompleta.
* Relacionar contingut.
* Recomanar coneixement.

Mai generarà informació sense suport documental.

Tota resposta haurà d'indicar la font utilitzada.

---

## EPIC 7 · Offline First

### Objectiu

Permetre treballar sense connexió.

Especialment en hospitals amb cobertura limitada.

Inclou:

* Cache intel·ligent.
* Sincronització automàtica.
* Resolució de conflictes.
* Gestió de versions.
* Descàrrega selectiva de contingut.
* Recuperació automàtica quan torni la connexió.

---

## EPIC 8 · Contextual Learning

### Objectiu

Transformar Instriq en una plataforma d'aprenentatge contextual.

No és un LMS tradicional.

L'aprenentatge neix durant el treball diari.

Exemple:

L'usuari consulta un instrument.

↓

Pot iniciar una sessió d'aprenentatge.

↓

Respondre preguntes.

↓

Repetició espaiada.

↓

Recordatoris.

↓

Seguiment del progrés.

↓

Estadístiques personals.

L'objectiu és accelerar l'aprenentatge sense separar-lo del context clínic.

---

# Proper pas

Abans d'implementar qualsevol d'aquestes EPICS, cal completar la revisió arquitectònica del projecte.

Cada EPIC haurà de revisar-se segons cinc criteris:

* Impacte sobre el model de domini.
* Compatibilitat amb el Knowledge Graph.
* Impacte sobre l'experiència d'usuari.
* Compatibilitat amb l'arquitectura actual.
* Dependències amb altres EPICS.

Cap EPIC s'hauria de desenvolupar sense haver superat aquesta revisió prèvia.

---

# Revisió arquitectònica (feta contra l'estat real del codi, 2026-07)

Cada EPIC avaluat segons els 5 criteris anteriors. Base de referència: el model de dades tipat construït a Fase C (`Manufacturer`, `Surgeon`, `SpecialtyEntity`, `Tag`, `ReferenceDocument`, FK reals — no text lliure), el patró polimòrfic `ref_type`/`ref_id` (ja usat a 8 taules), i el patró de capçalera+versions (`group_documents`/`trays`/`preference_cards`, sense abstracció genèrica compartida).

## EPIC 1 · Knowledge Graph

* **Model de domini**: impacte mitjà-alt. Moltes relacions per parell ja existeixen (Instrument↔Manufacturer, Instrument↔SterilizationMethod, Tray↔Instrument via `tray_items`, PreferenceCard↔Surgeon). El buit real és **tècnica/protocol ↔ instrumental** i **tècnica ↔ safata**: `group_documents` avui no té cap FK cap a `instruments` ni `trays`. Cal una taula d'unió nova (o reutilitzar el patró `ref_type`/`ref_id` ja provat), no un graf genèric.
* **Compatibilitat amb el Knowledge Graph**: és la pròpia fundació — EPIC 2, 5 i 6 en depenen directament.
* **Impacte UX**: nou — cap pantalla actual mostra "elements relacionats"; caldrà un component de navegació per relacions reutilitzable entre fitxes.
* **Compatibilitat amb arquitectura actual**: alta. Estén el patró ja aprovat (taules tipades + FK) enlloc del model genèric `entities`/`entity_relations` que ja es va descartar explícitament aquesta sessió (complexitat RLS, pèrdua d'integritat referencial, cost de self-joins).
* **Dependències**: cap bloqueig entrant; bloqueja EPIC 2, 5 (agrupació per relació) i 6 (obligatori).
* **Veredicte**: primer EPIC a fer. Baix risc arquitectònic, alt valor habilitador.

**Estat: primer tram fet (2026-08).** Implementat `knowledge_links` (`supabase/schema_v24_knowledge_links.sql`): taula-índex derivada, sincronitzada al publicar una tècnica/protocol o safata, amb la relació que faltava (`related_tray_ids` a `group_document_versions`) i la relació inversa nova (secció "Usat a" a la fitxa d'instrumental de catàleg, personalitzat i de safata). Verificat amb `flutter analyze`/`flutter test` i en emulador (mode convidat). Pendent, no fet en aquest tram: EPIC 2 (Clinical Workspace) i la resta d'EPICS 3-8, tal com estava previst a la seqüenciació recomanada.

## EPIC 2 · Clinical Workspace

* **Model de domini**: cal una entitat lleugera "procediment" que referenciï tècnica+safata+targeta+esterilització, no fusionar-les en una de sola.
* **Compatibilitat amb el Knowledge Graph**: dependència dura — sense EPIC 1 això és només una altra pantalla d'enllaços manuals, no coneixement relacionat de veritat.
* **Impacte UX**: alt — la pantalla més gran des de Fase A/B, però compatible amb el shell responsive ja construït (pensat per allotjar qualsevol pantalla de detall).
* **Compatibilitat amb arquitectura actual**: mitjana. Necessitarà una RPC d'agregació (mateix patró que `hospital_content_stats`/`organization_usage_stats`), no un paradigma nou.
* **Dependències**: bloquejat per EPIC 1; es beneficia d'EPIC 3 i 4 ja fets.
* **Veredicte**: segon EPIC, immediatament després d'EPIC 1.

## EPIC 3 · CSSD Workspace

* **Model de domini**: additiu sobre `instrument_sterilization_methods`/`instrument_technical_info` (ja existents). "Incidències" és taula nova, candidata natural al patró `ref_type`/`ref_id`.
* **Compatibilitat amb el Knowledge Graph**: bon encaix, ja FK'd a Instrument/Manufacturer.
* **Impacte UX**: mitjà — pantalles noves seguint convencions ja usades a la fitxa d'esterilització actual.
* **Compatibilitat amb arquitectura actual**: alta — coincideix exactament amb el "versionat d'esterilització" ja marcat com a pendent des de Fase E.
* **Dependències**: bloquejat per una decisió de producte encara oberta: **qui aprova un canvi a un dato GLOBAL del catàleg** (no és una decisió tècnica, cal resposta abans de dissenyar RLS/aprovació).
* **Veredicte**: no planificar fins resoldre la pregunta de producte; en paral·lel a EPIC 1/2 si es resol.

## EPIC 4 · Trays 2.0

* **Model de domini**: additiu — `TrayVersion` ja existeix; Posicions/Duplicació/Control de qualitat són camps i una RPC de clonat, no un redisseny.
* **Compatibilitat amb el Knowledge Graph**: neutre, ja relacionat amb instrumental.
* **Impacte UX**: mitjà — checklist, selector de posició, botó duplicar; incremental sobre pantalles existents.
* **Compatibilitat amb arquitectura actual**: alta — reutilitza el patró de versionat ja provat 3 vegades.
* **Dependències**: cap bloqueig.
* **Veredicte**: EPIC de risc més baix; es pot fer en paral·lel a EPIC 1, sense esperar res.

**Estat: fet (2026-08).** Implementat sobre `tray_versions`/`trays` existents: posició opcional per ítem, duplicar bandeja (`duplicate_tray`, sense copiar fotos — limitació de Storage documentada), i **sessions reals de preparació** (`tray_preparation_sessions`) amb control de qualitat/validació — es va preguntar explícitament l'abast d'aquest últim punt (flag lleuger vs. sessió real amb historial) i es va triar la sessió real. Verificat amb `flutter analyze`/`flutter test` i en emulador (mode convidat, sense regressions). Pendent, com sempre amb aquests fluxos: provar amb compte autenticat real preparar una safata i fer-ne el control de qualitat.

## EPIC 5 · Smart Search

* **Model de domini**: cap entitat nova; cal una cerca creuada (full-text Postgres, `tsvector`/GIN) sobre Instrument/GroupDocument/Tray/PreferenceCard/Manufacturer/Surgeon/Tag.
* **Compatibilitat amb el Knowledge Graph**: la cerca bàsica per nom pot anar sense EPIC 1; agrupar per relació ("tot el que toca Dr. Garcia") sí que en depèn.
* **Impacte UX**: alt però de baix risc — ja hi ha un cercador global des de Fase B; això és una millora de backend + agrupació de resultats, no una pantalla nova.
* **Compatibilitat amb arquitectura actual**: mitjana — necessita `pg_trgm`/`tsvector`, infraestructura Postgres estàndard, sense dependència externa nova.
* **Dependències**: independent per començar; la cerca semàntica (fase posterior explícita al propi document) comparteix infraestructura d'embeddings amb EPIC 6 — dissenyar-les juntes evita construir-ho dues vegades.
* **Veredicte**: es pot començar ja (cerca per nom/entitat); ajornar la part semàntica fins decidir EPIC 6.

**Estat: fet (2026-08), la part per nom/entitat.** No es va introduir `pg_trgm`/`tsvector`: totes les llistes rellevants ja es cachegen senceres en memòria a l'escala real de l'app (catàleg de 110 instruments, fabricants/cirurgians/etiquetes d'un hospital), així que el filtratge en client segueix sent l'opció correcta — la infraestructura Postgres queda per quan hi hagi cerca semàntica de veritat (EPIC 6). Ampliat el cercador d'Inici: instrumental ara també per especialitat, categoria i mètode d'esterilització; noves seccions de resultats per fabricants, cirurgians i etiquetes (reutilitzant `ManufacturerDetailScreen`/`SurgeonDetailScreen`/`TagDetailScreen` ja existents — `SurgeonDetailScreen` ja mostra les targetes de preferència del cirurgià, així que no calia afegir-les com a resultat propi). De pas, unificats els dos jocs de predicats duplicats (`_hasAnySearchResults`/`_buildSearchResults`) en un sol càlcul.

Dos bugs reals trobats i arreglats durant la verificació: (1) les etiquetes de mètode d'esterilització eren un text fix en castellà (`SterilizationMethod.label`), així que cercar "Autoclau" en català no trobava res — ara localitzades (`sterilizationMethodValueLabel`, mateix patró que `WorkModePicker.labelFor`) i ja s'usen també a la fitxa d'instrument i al formulari d'admin; (2) el metadata de cerca (fabricants, etiquetes, especialitats, mètodes d'esterilització) es carregava dins del mateix bloc que exigia tenir hospital connectat, així que no funcionava en mode convidat tot i ser catàleg global — separat de la resta de `_loadGroupContent`.

## EPIC 6 · Clinical AI Assistant

* **Model de domini**: sense impacte fins introduir `pgvector`/embeddings.
* **Compatibilitat amb el Knowledge Graph**: dependència dura explícita al propi document — no començar sense EPIC 1 consolidat.
* **Impacte UX**: alt i nou paradigma (xat/preguntes); ha de citar sempre la font i **no ha de poder citar esborranys**, només contingut publicat/aprovat — coherent amb el model de confiança draft→revisió→publicat ja establert a tota la resta de l'app.
* **Compatibilitat amb arquitectura actual**: la de més superfície nova de tots els EPICS — requereix integració amb un LLM extern (probablement via Edge Function) i `pgvector`, cap dels dos existeix avui.
* **Dependències**: bloquejat per EPIC 1; comparteix infraestructura amb la cerca semàntica d'EPIC 5.
* **Veredicte**: últim EPIC a planificar; requereix decisió de producte pròpia (quin proveïdor d'IA, cost, privacitat de dades clíniques enviades a un tercer) abans de dissenyar-lo.

## EPIC 7 · Offline First

* **Model de domini**: cap entitat nova; estén el mode sense connexió ja existent (tècniques/protocols/targetes) a Bandejes i afegeix resolució de conflictes real.
* **Compatibilitat amb el Knowledge Graph**: neutre, és una qüestió de client, no d'esquema.
* **Impacte UX**: mitjà — calen indicadors d'estat de sincronització i una UI de conflicte ("la teva versió vs. la del servidor") que avui no existeix enlloc de l'app.
* **Compatibilitat amb arquitectura actual**: **risc mitjà-alt**. L'stack actual (`connectivity_plus` + `shared_preferences`, sense base de dades local) serveix per a cua-i-repetició simple; resolució de conflictes real amb un graf d'entitats creixent normalment demana un magatzem local de veritat (p. ex. sqlite/drift) — és una decisió d'stack no presa encara, no una simple ampliació.
* **Dependències**: l'abast creix amb cada entitat nova (Bandejes, després Clinical Workspace/CSSD).
* **Veredicte**: limitar-lo a Bandejes primer (ja marcat com "a continuar"); no generalitzar-lo fins decidir l'stack local.

## EPIC 8 · Contextual Learning

* **Model de domini**: sessió d'aprenentatge/pregunta/repetició espaiada, candidat natural al patró `ref_type`/`ref_id` (reutilitzable, no cal dissenyar-lo de zero).
* **Compatibilitat amb el Knowledge Graph**: es beneficia de les relacions per generar preguntes creuades, però pot llançar-se per instrument sol sense el graf complet.
* **Impacte UX**: mitjà — nous punts d'entrada "inicia sessió" des de la fitxa d'instrument/tècnica; la notificació de recordatoris reutilitza la infraestructura push ja existent.
* **Compatibilitat amb arquitectura actual**: compatible, estén el mòdul Aprendre existent.
* **Dependències**: **dependència dura** amb "Sincronitzar el progrés d'aprenentatge amb Supabase" (ja llistat per separat al backlog) — la repetició espaiada necessita estat de programació al servidor, no només local.
* **Veredicte**: seqüenciar just després de la sincronització de progrés, no abans.

## Seqüenciació recomanada

1. **EPIC 1 · Knowledge Graph** — fundació, desbloqueja la resta.
2. **EPIC 4 · Trays 2.0** en paral·lel — cap dependència, risc baix.
3. **EPIC 5 · Smart Search** (part per nom/entitat) en paral·lel — cap dependència dura.
4. **EPIC 2 · Clinical Workspace** — un cop EPIC 1 tingui les relacions clau (tècnica↔instrumental↔safata).
5. **Sincronitzar progrés d'aprenentatge a Supabase** (millora, no EPIC) → **EPIC 8 · Contextual Learning**.
6. **EPIC 3 · CSSD Workspace** — només després de resoldre qui aprova canvis a dades globals del catàleg.
7. **EPIC 7 · Offline First** — limitat a Bandejes fins decidir stack de base de dades local.
8. **EPIC 6 · Clinical AI Assistant** — últim, requereix EPIC 1 consolidat + decisió de producte sobre proveïdor d'IA i privacitat.
