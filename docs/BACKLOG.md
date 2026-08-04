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

## 🟢 Technical Debt

No són EPICs — són deute tècnic, sense decisió d'arquitectura pendent.

* Migrar Flutter al nou sistema "Built-in Kotlin" — no urgent, però el build d'EPIC 8 (2026-08) ja va mostrar el warning real: `package_info_plus`/`shared_preferences_android` encara apliquen el Kotlin Gradle Plugin antic.
* Unificar les dues taxonomies actuals d'especialitats (14 i 16 categories).
* Internacionalitzar les observacions d'esterilització.
* Eliminar textos fixos únicament disponibles en castellà.

---

## 🟡 Product Evolution

Evolució funcional. Els dos primers punts es relacionen amb **ADR-004** (veure secció d'ADRs): abans de construir-los caldria decidir si es duplica per quarta vegada el patró capçalera+versions o s'extreu un component compartit.

* Dissenyar el sistema de versionat per a l'instrumental personalitzat.
* Dissenyar el versionat de la informació d'esterilització i de les fitxes tècniques.
* Completar el model de Grafo de Coneixement.
* Convertir Vídeo i Nota en entitats independents relacionades amb la resta del sistema.

---

## Aprenentatge

* ~~Sincronitzar el progrés d'aprenentatge amb Supabase~~ — **fet (2026-08)**, com a prerequisit d'EPIC 8. Veure detall a la secció d'EPIC 8 més avall.

---

## Sostenibilitat

* Desenvolupar un sistema de donacions completament transparent.
* Diferenciar clarament:

  * Manteniment del projecte.
  * Donacions destinades a investigació mèdica.

---

# ADR pendents (Architecture Decision Records)

Revisió de l'usuari (2026-08): EPIC 3, 6 i 7 no estaven "bloquejats" per una pregunta puntual ("qui aprova", "quin proveïdor d'IA", "sqlite o drift"), sinó per decisions d'arquitectura més profundes que condicionen diversos EPICs alhora. A partir d'ara es documenten com a ADR pendents, no com a bloquejos ad-hoc: permet veure d'un cop d'ull quina decisió afecta quins EPICs, i si un EPIC pot avançar parcialment sense comprometre l'arquitectura futura.

**Pregunta de producte pendent, no tècnica** — es va plantejar en paral·lel: és Instriq una plataforma SaaS amb la comunitat com a extra (Visió A), o una comunitat Open Source amb els hospitals com a funcionalitat (Visió B)? `docs/ADR_001_KNOWLEDGE_GOVERNANCE.md` conclou que aquesta decisió **no bloqueja** l'arquitectura d'herència (funciona igual sota les dues visions), però queda pendent com a decisió de negoci separada.

## ADR-001 · Governança del coneixement

Què és global (catàleg), què és privat (organització), què és una adaptació local, qui n'és el propietari, qui pot publicar-hi canvis. Un cop existeixi aquest model, decidir "qui aprova" un canvi concret és trivial.

**Document d'arquitectura complet, sense codi ni migracions**: [`docs/ADR_001_KNOWLEDGE_GOVERNANCE.md`](ADR_001_KNOWLEDGE_GOVERNANCE.md) — comparativa Git (branques/forks/merges) vs. Wikipedia (veritat única) vs. còpia sense procedència vs. **referència upstream amb sincronització conscient de la divergència (recomanada)**; resposta a les 5 preguntes de governança, traducció a UX simple (Actualitzar/Revisar canvis/Deixar de seguir, mai vocabulari de "fork"), relació amb el Knowledge Graph i amb ADR-004, i classificació per apartat. Conclou que la decisió Visió A/B (SaaS vs. comunitat Open Source) és real però no bloqueja aquest ADR.

**Impacta**: EPIC 1, EPIC 2, EPIC 3, EPIC 4, EPIC 5, EPIC 9.

## ADR-002 · Arquitectura d'IA

RAG (com es recupera el context), model de permisos (què pot veure la IA de cada organització), estratègia de citació de fonts, política de privadesa de dades clíniques, traçabilitat de respostes. El proveïdor d'IA (Claude, OpenAI, model local) és gairebé la darrera decisió, no la primera.

**Impacta**: EPIC 5 (cerca semàntica), EPIC 6.

## ADR-003 · Estratègia Offline

Quines entitats han de funcionar sense connexió, quines són només lectura, quines es poden editar offline, política de sincronització, resolució de conflictes, estratègia de versions en conflicte. L'stack local (sqlite/drift) és un detall d'implementació posterior, no la decisió en si.

**Impacta**: EPIC 4, EPIC 7.

## ADR-004 · Versionat del coneixement

El patró capçalera+versions (draft→revisió→publicat→arxivat) s'ha construït 3 vegades de forma independent (`group_documents`, `trays`, `preference_cards`), sense abstracció compartida. Cal decidir si continuar duplicant-lo per cada entitat nova (instrumental personalitzat, esterilització/fitxes tècniques — Product Evolution) o extreure'n un component genèric abans de construir-ne una quarta còpia.

**Impacta**: EPIC 1, EPIC 2, EPIC 3, EPIC 4.

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

## EPIC 9 · Community & Editorial Governance

### Objectiu

Cada organització és propietària del seu coneixement privat — Instriq no hi intervé.

Però en el futur Instriq tindrà una Biblioteca Pública compartida per tota la comunitat, que no pot editar-se sense un model de governança: candidatures de col·laborador, nivells (Contributor/Reviewer/Editorial Board), àrees de col·laboració, flux editorial (proposta → revisió → comentaris → correccions → aprovació → publicació) i perfil públic.

**Document d'arquitectura complet, sense codi ni migracions**: [`docs/EPIC_COMMUNITY_GOVERNANCE.md`](EPIC_COMMUNITY_GOVERNANCE.md) — entitats, relacions, flux de candidatura i editorial, anàlisi crítica dels 4 nivells proposats (es recomana 2 eixos: 3 esglaons de flux de treball + etiqueta d'expertesa per àrea, no una escala de 4), compatibilitat amb el Knowledge Graph/permisos/multiorganització, riscos i classificació apartat per apartat (ja implementat / parcial / no implementat).

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

**Estat: primer tramo fet (2026-08), ampliant la fitxa en lloc de substituir-la.** Es va preguntar l'abast (pantalla nova que substitueixi `GroupDocumentDetailScreen` a tota la nav vs. ampliar la fitxa existent in situ) i es va triar ampliar-la — baix risc, cap punt de navegació canvia. Sense RPC d'agregació nova: tot servible amb les consultes existents (bucle petit per instrument relacionat, mateix criteri que la resta de l'app; el bulk-fetch només es justifica a escala de "tot el catàleg", com a EPIC 5). Afegit: resum d'esterilització/fabricant per cada instrument relacionat, checklist de la safata expandit inline (`ExpansionTile`), i una secció nova de targetes de preferència **de l'espai** (no "del procediment" — no existeix cap relació real entre una targeta i una tècnica concreta al model de dades, només comparteixen espai; el nom de la secció ho deixa clar per no insinuar una precisió que no hi ha). Vídeos, material fungible/sutures/implants i posicionament del pacient **no existeixen com a entitat enlloc** — queden fora, documentats com a pendents de disseny propi.

`flutter analyze`/`flutter test` nets. Verificació en emulador no concloent aquesta vegada (l'emulador ha acumulat molta càrrega després d'una sessió molt llarga i no arrencava amb fluïdesa) — el canvi només toca `GroupDocumentDetailScreen`, inaccessible en mode convidat, així que el risc de regressió en mode convidat és estructuralment nul independentment. Queda pendent, com sempre amb aquests fluxos, la prova real amb compte autenticat.

## EPIC 3 · CSSD Workspace

* **Model de domini**: additiu sobre `instrument_sterilization_methods`/`instrument_technical_info` (ja existents). "Incidències" és taula nova, candidata natural al patró `ref_type`/`ref_id`.
* **Compatibilitat amb el Knowledge Graph**: bon encaix, ja FK'd a Instrument/Manufacturer.
* **Impacte UX**: mitjà — pantalles noves seguint convencions ja usades a la fitxa d'esterilització actual.
* **Compatibilitat amb arquitectura actual**: alta — coincideix exactament amb el "versionat d'esterilització" ja marcat com a pendent des de Fase E.
* **Dependències**: bloquejada per **ADR-001 · Governança del coneixement** — no és "qui aprova", sinó que encara no existeix un model que defineixi què és global, què és privat, què és una adaptació local i qui n'és el propietari.
* **Veredicte**: no planificar fins resoldre ADR-001; en paral·lel a EPIC 1/2 si es resol.

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
* **Dependències**: bloquejat per EPIC 1 i per **ADR-002 · Arquitectura d'IA** — el bloqueig real no és el proveïdor (canviar d'OpenAI a Claude o a un model local és una decisió fàcil i tardana), sinó RAG, permisos, citació de fonts i privadesa; comparteix infraestructura amb la cerca semàntica d'EPIC 5.
* **Veredicte**: últim EPIC a planificar; requereix resoldre ADR-002 abans de dissenyar-lo. El proveïdor es tria al final, no al principi.

## EPIC 7 · Offline First

* **Model de domini**: cap entitat nova; estén el mode sense connexió ja existent (tècniques/protocols/targetes) a Bandejes i afegeix resolució de conflictes real.
* **Compatibilitat amb el Knowledge Graph**: neutre, és una qüestió de client, no d'esquema.
* **Impacte UX**: mitjà — calen indicadors d'estat de sincronització i una UI de conflicte ("la teva versió vs. la del servidor") que avui no existeix enlloc de l'app.
* **Compatibilitat amb arquitectura actual**: **risc mitjà-alt**, però no per l'elecció de sqlite/drift (un detall d'implementació posterior) — per **ADR-003 · Estratègia Offline**: quines entitats funcionen offline, quines són només lectura, quines editables, política de sincronització i resolució de conflictes.
* **Dependències**: l'abast creix amb cada entitat nova (Bandejes, després Clinical Workspace/CSSD); bloquejat per ADR-003.
* **Veredicte**: limitar-lo a Bandejes primer (ja marcat com "a continuar"); no generalitzar-lo fins resoldre ADR-003.

## EPIC 8 · Contextual Learning

* **Model de domini**: sessió d'aprenentatge/pregunta/repetició espaiada, candidat natural al patró `ref_type`/`ref_id` (reutilitzable, no cal dissenyar-lo de zero).
* **Compatibilitat amb el Knowledge Graph**: es beneficia de les relacions per generar preguntes creuades, però pot llançar-se per instrument sol sense el graf complet.
* **Impacte UX**: mitjà — nous punts d'entrada "inicia sessió" des de la fitxa d'instrument/tècnica; la notificació de recordatoris reutilitza la infraestructura push ja existent.
* **Compatibilitat amb arquitectura actual**: compatible, estén el mòdul Aprendre existent.
* **Dependències**: **dependència dura** amb "Sincronitzar el progrés d'aprenentatge amb Supabase" (ja llistat per separat al backlog) — la repetició espaiada necessita estat de programació al servidor, no només local.
* **Veredicte**: seqüenciar just després de la sincronització de progrés, no abans.

**Estat: prerequisit + primer tram fet (2026-08).** Es va preguntar el nivell de complexitat de la repetició espaiada (Leitner d'intervals fixos vs. SM-2 adaptatiu) i es va triar el simple.

*Sincronització de progrés (prerequisit)*: `supabase/schema_v26_learning_progress.sql` — taula `learning_progress` (`ref_type`/`ref_id` polimòrfic, mateix patró que `favorites`) amb `box`/`next_review_at` a la mateixa fila que `learned_at`, RLS per `auth.uid()`, i `profiles.quiz_best_scores` (jsonb) pels millors resultats de quiz. `ProgressService` reescrit amb backend dual: mode convidat continua sent 100% `shared_preferences` (zero regressió, mateixa API pública que ja usaven `flashcards_screen.dart`/`quiz_screen.dart`/`instrument_detail_screen.dart`, cap d'ells tocat), mode autenticat llegeix/escriu Supabase amb migració única (puja el progrés local si el servidor no en té) en iniciar sessió. Enganxat a `authStateChanges` a `main.dart` (`syncFromServer()`/`clear()`).

*EPIC 8 primer tram*: repetició espaiada Leitner (`kLeitnerIntervalsDays = [1, 3, 7, 14, 30]`, `recordReviewResult`/`dueCount`/`boxFor` a `ProgressService`), sessió de repàs contextual d'un únic instrument (`lib/screens/review_session_screen.dart`, nou botó "Inicia sessió de repàs" a `instrument_detail_screen.dart`, mateix patró de targeta que es volteja que `flashcards_screen.dart`), recordatori diari local (`lib/services/reminder_service.dart`, nova dependència `flutter_local_notifications` + `timezone`, una única notificació reprogramada a `refresh()` — no una per ítem) i línia de pendents de repàs avui a `progress_screen.dart`.

Calgué activar `coreLibraryDesugaringEnabled` i afegir `desugar_jdk_libs` a `android/app/build.gradle` — requisit d'AAR de `flutter_local_notifications` no detectat fins al primer build de release. `flutter analyze`/`flutter test` nets. Verificat en emulador que l'app arrenca i la pantalla d'Inici carrega correctament en mode convidat després del canvi (mateix contingut que abans); la navegació fins al botó nou i la sessió de repàs en si no es van poder completar en viu — l'emulador va entrar en ANRs repetits de `system_server` (no de l'app, confirmat amb `dumpsys cpuinfo`) després d'hores d'ús continuat aquesta sessió, el mateix patró ja documentat a EPIC 2. Sincronització real (login, migració única, notificació programada) requereix compte autenticat i queda pendent de prova, com la resta d'aquests fluxos.

## EPIC 9 · Community & Editorial Governance

* **Model de domini**: entitats noves (`contributor_applications`, `contributor_profiles`, `public_documents`/`public_trays` + versions, `editorial_comments`), reutilitzant `specialties`/`tags`/`taggings` existents en comptes de catàlegs nous. Detall complet a [`docs/EPIC_COMMUNITY_GOVERNANCE.md`](EPIC_COMMUNITY_GOVERNANCE.md).
* **Compatibilitat amb el Knowledge Graph**: additiva i de baix risc — `knowledge_links` ja té `organization_id` nul·lable, només calen 2 valors nous al `check` de `from_type`.
* **Impacte UX**: alt — formulari de candidatura, cua de revisió editorial amb fils de comentaris (capacitat nova, no existeix enlloc avui), perfil públic.
* **Compatibilitat amb arquitectura actual**: **parcial** — `WorkspaceRole`/`my_workspace_role()` són sempre relatius a una organització; els nivells de col·laborador són un eix de permisos nou i paral·lel, no una extensió del rol actual.
* **Dependències**: cap bloqueig, ni tècnic ni de disseny. El sistema de candidatures, perfils, flux d'aprovació (Pending/Approved/Rejected) i base de dades es pot implementar sencer sense tenir encara membres del Consell Editorial. Es relaciona amb ADR-001 (governança del coneixement) però no en depèn per començar — EPIC 9 tracta contingut públic/comunitari, no el catàleg privat de cada organització.
* **Veredicte**: **implementable ja**, revisat (2026-08). Únic pendent real: nomenar els primers membres del Consell Editorial abans d'obrir la Biblioteca Pública al públic — és una tasca operativa posterior a la implementació, no un bloqueig previ.

**Estat: primer tram fet (2026-08) — candidatura + perfil de col·laborador.** Implementat sobre `supabase/schema_v27_contributors.sql`: `contributor_applications` (candidatura, `status` pending/approved/rejected, un únic índex parcial evita duplicar-ne una de pendent), `contributor_profiles` (nivell `contributor`/`reviewer`/`editorial_board`, privadesa per defecte amb `is_public`/`show_organization` a `false`), i `taggings.ref_type` ampliat amb `'contributor'` per a les àrees de col·laboració (reutilitzant `tags`, no una taula nova, tal com recomanava `docs/EPIC_COMMUNITY_GOVERNANCE.md` §2.2). Cap policy d'`update` per a "authenticated" a cap de les dues taules — tota escriptura sensible (revisar candidatura, canviar nivell, editar el perfil propi) passa per RPC `security definer` (`review_contributor_application`, `set_contributor_level`, `update_my_contributor_profile`), evitant que un usuari pugui auto-promocionar-se el seu propi `level` via un update directe.

UI: `ContributorApplicationFormScreen` (formulari de candidatura), `ContributorProfileScreen` (perfil propi + `TagPicker` reutilitzat per a les àrees de col·laboració), `ContributorReviewQueueScreen` (cua de revisió, només Editorial Board, mateix patró que `ReviewQueueScreen`). `profile_hub_screen.dart` guanya una secció "Comunitat Instriq" condicional a l'estat: sense candidatura → "Converteix-te en col·laborador"; pendent → estat de sol·licitud; rebutjada → motiu + tornar a sol·licitar; aprovada → accés al perfil (i a la cua de revisió si és Editorial Board).

Fora d'abast d'aquest tram (com ja preveia el document d'arquitectura): la Biblioteca Pública en si (`public_documents`/`public_trays` o la seva alternativa unificada amb `visibility`, pendent de com es resolgui l'aplicació concreta d'ADR-001), `editorial_comments` (fil de comentaris de revisió), i el perfil públic renderitzat (avui només es guarden les dades, no hi ha una pantalla pública de "veure perfil d'un altre col·laborador").

`flutter analyze`/`flutter test` nets. Verificat en emulador en mode convidat: la pestanya Perfil no mostra la secció de comunitat (correctament gated per `loggedIn`), sense cap regressió ni excepció a `logcat`. El flux autenticat (enviar candidatura, revisar-la com a Editorial Board, veure el perfil propi) no s'ha pogut provar en viu — requereix un compte real, mateix punt pendent que la resta de fluxos d'aquesta sessió.

## Seqüenciació recomanada

1. **EPIC 1 · Knowledge Graph** — fundació, desbloqueja la resta.
2. **EPIC 4 · Trays 2.0** en paral·lel — cap dependència, risc baix.
3. **EPIC 5 · Smart Search** (part per nom/entitat) en paral·lel — cap dependència dura.
4. **EPIC 2 · Clinical Workspace** — un cop EPIC 1 tingui les relacions clau (tècnica↔instrumental↔safata).
5. ~~**Sincronitzar progrés d'aprenentatge a Supabase** (millora, no EPIC) → **EPIC 8 · Contextual Learning**~~ — fet, primer tram (2026-08).
6. **EPIC 3 · CSSD Workspace** — només després de resoldre **ADR-001** (governança del coneixement).
7. **EPIC 7 · Offline First** — limitat a Bandejes fins resoldre **ADR-003** (estratègia offline).
8. **EPIC 6 · Clinical AI Assistant** — últim, requereix EPIC 1 consolidat + resoldre **ADR-002** (arquitectura d'IA). El proveïdor es tria al final.
9. **EPIC 9 · Community & Editorial Governance** — **implementable ja**, en paral·lel a qualsevol altre EPIC; el nomenament del Consell Editorial és posterior a la implementació, no una condició prèvia.

Nota transversal: **ADR-004** (versionat del coneixement) no bloqueja cap EPIC en marxa, però hauria de resoldre's abans d'implementar el versionat d'instrumental personalitzat o d'esterilització (Product Evolution) — seria la quarta còpia independent del mateix patró.
