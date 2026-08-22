# Instriq Product Backlog

## Design System (auditoria UX + implementació)

Document de referència: auditoria completa de les 61 pantalles + Design System proposat, aprovat per l'usuari. Full de ruta en 3 nivells (consolidació → navegació → bugs de dades, aquests últims abordats juntament amb els altres dos, no per separat).

**Estat: Nivell 1 i 2 fets i pujats (2026-08, commit `6689eec`).**

* **Nivell 1 — consolidació.** 5 components genèrics nous (`InstriqAsyncView`, `InstriqEntityUsageList`, `InstriqVersionHistory`/`InstriqVersionDiff`, `InstriqReviewQueue`) substitueixen ~20 pantalles gairebé triplicades (historial/diff/cua de revisió de safata-document-targeta, fabricant/etiqueta/cirurgià/especialitat, formulari/detall de Biblioteca Pública). Bugs reals corregits de pas: direcció de diff invertida en comparar versions arxivades, `draft`/`archived` amb el mateix color, ids crus al diff de documents, canvis de quantitat/posició invisibles al diff de safates, editor clínic que només tocava el primer mètode d'esterilització (`methods.first`), dues etiquetes incorrectes a la fitxa de cirurgià, i fallos de xarxa mostrats com a "buit" en 4 pantalles d'entitat.
* **Nivell 2 — navegació.** `WorkspaceListScreen` es col·lapsa sola quan hi ha un únic espai de treball. Embut d'autenticació unificat: `WelcomeScreen`/`SignUpScreen`/`JoinHospitalScreen`/`RegisterHospitalScreen` eliminats, substituïts per un únic `GroupEntryScreen` amb la decisió unir-se/crear resolta d'entrada i sense pantalla d'èxit dedicada (el codi d'invitació surt ara en un diàleg amb botó de copiar). Pestanya Activitat/cua de revisió ara visible per `canApprove` (rol `approver` a qualsevol espai), no només `isAdmin`. Nova capacitat de promoure/treure administrador des de `manage_hospital_screen.dart` (`set_hospital_admin`, `supabase/schema_v30_hospital_admin_promotion.sql`, bloqueja treure l'últim admin).

`flutter analyze`/`flutter test` nets a totes dues fases.

**Pendent:**
* Verificació manual amb compte autenticat real: **feta parcialment (2026-08-11)**, primer flux autenticat provat de tota la sessió — embut d'autenticació (`GroupEntryScreen`), crear→desar→enviar a revisió→aprovar→publicat, i el flux offline complet, tot verificat en viu amb 2 comptes reals. **Encara sense provar**: la promoció d'admin (`set_hospital_admin`).
* ~~Un únic punt d'entrada/bústia amb comptador agregat de les cues de revisió (col·laboradors, contingut públic, canvis de grup)~~ **Fet (2026-08-11)**: `ReviewInboxScreen`, accessible des d'Activitat i des de Perfil (cada fila es mostra només si l'usuari té el permís corresponent — no hi ha cap permís únic que cobreixi les 3 cues).
* ~~El `catch(_)` general de `tray_detail_screen.dart`/`preference_card_detail_screen.dart` (anul·lava `_ownPendingDraft` i altres seccions en qualsevol error, no només de xarxa)~~ **Corregit (2026-08-11)**: cada bloc de dades independent té ara el seu propi `try/catch`. (`group_document_detail_screen.dart` ja tenia `_loadOwnDraft()` aïllat correctament — no calia tocar-lo.)
* Nivell 3 restant: **la unificació dels 6 sinònims de rol de permisos** s'ha resolt parcialment (2026-08-11) — afegit `WorkspaceRole.isAdministrator`, substituint l'única comparació ad-hoc (`workspace_detail_screen.dart`) que reinventava aquest concepte sense nom propi; la resta (`ProfileService.isAdmin`, `WorkspaceMember.isHospitalAdmin`, `.effectiveRole`, `.canApprove`, `canApproveAnyWorkspace`) es van revisar i confirmar **legítimament separats**, no redundants (cada un respon una pregunta diferent, ja documentada al codi). **Encara sense abordar**: accessibilitat exhaustiva camp a camp i adopció completa del breakpoint responsive a totes les pantalles — són passades exhaustives sobre les 61 pantalles, mida pròpia, no incloses en aquest tram.

---

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

## Navegació

* ~~Pestanya "Activitat" era un carreró sense sortida per a qui no és admin~~ — **arreglat (2026-08)**. `ActivityScreen` només mostra un text de "només administradors" per a la resta d'usuaris (la majoria: personal de quiròfan, no admins). `lib/navigation/app_shell.dart` ara filtra els destins visibles del `NavigationBar`/`NavigationRail` segons `ProfileService.instance.isAdmin` (les 5 rames de `StatefulShellRoute.indexedStack` no es toquen, només què es mostra) — 4 pestanyes per a no-admin, 5 per a admin.

---

## Bugs coneguts (pendents d'investigar)

* ~~Filtre de Mode de Treball no sembla tenir efecte~~ — **arreglat (2026-08)**. Causa real: `PopupMenuButton<T>` de Flutter confon "menú tancat sense triar" amb "s'ha triat `value: null`" (`showMenu` retorna `null` en tots dos casos), així que `onSelected` mai s'executava en tocar "Sense preferència" a `lib/navigation/work_mode_header.dart` — el mode mai es reiniciava i el botó tornava a mostrar l'anterior. El selector de xips de "El meu compte" (`work_mode_picker.dart`) ja funcionava bé, no tenia aquest problema. Verificat amb `flutter analyze`/`flutter test`; **pendent de provar en viu amb usuari autenticat** (el header només es mostra amb hospital connectat, no reproduïble en mode convidat).
* ~~Tancar sessió no refrescava Inici/Biblioteca/nav~~ — **arreglat (2026-08-17)**. Trobat en una bateria de proves en viu (compte approver): després de tancar sessió, la capçalera d'organització, la pestanya "Activitat" i el contingut d'espai a Biblioteca es quedaven visibles fins reiniciar l'app. Causa real: `ProfileService` muta el seu estat (`organizationName`, `isAdmin`, `canApproveAnyWorkspace`...) sense cap mecanisme reactiu — només `activeWorkModeNotifier` ho tenia, i només per al mode de treball — així que `AppShell`/`WorkModeHeader`/`HomeScreen`/`LibraryScreen` (cadascun en la seva pròpia branca del shell) no es reconstruïen quan `ProfileHubScreen` feia el seu propi `setState` local en signar-se fora. Afegit `ProfileService.profileRevision` (mateix patró que `activeWorkModeNotifier`); els 4 widgets ara hi escolten. Verificat en viu: build fresc instal·lat a l'emulador, login+signout com a approver, Inici/Perfil/nav reflecteixen l'estat de convidat a l'instant sense reiniciar.
* ~~Resoldre una incidència d'instrument exigia admin d'organització, no approver d'espai~~ — **arreglat (2026-08-17)**. Trobat provant EPIC 3 en viu: la RLS d'`instrument_incidents` (schema_v32) ja exigia `approver`/`administrator` d'espai, però `instrument_detail_screen.dart` mostrava el botó "Marcar com a resolta" només a `ProfileService.isAdmin`, copiant per error el gate del botó d'editar esterilització/fitxa tècnica de la mateixa pantalla. Una incidència és un assumpte operatiu de l'organització (igual que aprovar una tècnica o una safata), no una edició del catàleg global — ara segueix el mateix criteri que `canApproveAnyWorkspace` a `app_shell.dart`. Verificat en viu amb el compte approver de prova: reportar + resoldre una incidència real de cap a cap.
* ~~Aprovar QUALSEVOL mètode d'esterilització o fitxa tècnica fallava~~ — **arreglat (2026-08-20)**. Trobat provant EPIC 3 en viu per primera vegada des de la implementació original (BACKLOG ja marcava aquest flux com a "pendent de provar en viu"): l'RPC d'aprovació fallava amb `PostgrestException: record "new" has no field "updated_at"` (42703), sempre, catàleg global i instrumental personalitzat per igual. Causa real: `schema_v15_clinical_knowledge_model.sql` va crear `instrument_sterilization_methods`/`instrument_technical_info` amb una columna `updated_at` i un trigger `BEFORE UPDATE` que l'actualitza; `schema_v32_cssd_workspace.sql` (EPIC 3) va eliminar la columna però mai el trigger corresponent — des de llavors, cap `UPDATE` a aquestes capçaleres (incloent `published_version_id` en aprovar) havia funcionat mai. `schema_v37_fix_stale_updated_at_triggers.sql` elimina els 2 triggers i les seves funcions. Verificat en viu de cap a cap.
* **EPIC 3 ampliat a l'instrumental personalitzat (2026-08-20)**: el backend (schema_v32) ja acceptava `instrument_ref_type = 'custom'` des del principi, però només `instrument_detail_screen.dart` (catàleg global) tenia la UI d'esterilització/fitxa tècnica/incidències. Extret `ClinicalDataFormSheet` a `lib/widgets/clinical_data_form_sheet.dart` (parametritzat per `refType`/`refId`/`organizationId`/`workspaceId`) i afegides les 3 seccions a `custom_instrument_detail_screen.dart`, gatejades per `myRole?.canEdit` (no `isAdmin` — editar l'instrumental propi de l'equip és una acció d'espai). Verificat en viu de cap a cap: crear instrument → editar esterilització/fitxa tècnica → enviar a revisió → aprovar com a approver → contingut publicat visible.

---

# Millores pendents

## 🟢 Technical Debt

No són EPICs — són deute tècnic, sense decisió d'arquitectura pendent.

* ~~Migrar Flutter al nou sistema "Built-in Kotlin"~~ — **investigat (2026-08), bloquejat aigües amunt**. L'avís ve de dos plugins (`package_info_plus`, `shared_preferences_android`), no del `build.gradle` propi (AGP 9.0.1/Kotlin 2.3.20 ja són moderns). `package_info_plus` té un salt de versió major disponible (8.x→10.x) que podria arreglar-ho, però és *breaking* i caldria revisar els punts d'ús. `shared_preferences_android` no té cap versió més nova disponible encara (2.4.27 és el màxim resoluble) — la migració depèn de si aquest paquet fa el seu propi pas a Built-in Kotlin, no és cosa nostra encara. No urgent (avís, no error).
* ~~Unificar les dues taxonomies actuals d'especialitats (14 i 16 categories)~~ — **fet (2026-08)**. La llista de 14 (`lib/data/surgical_specialties.dart`, RD 183/2008) era codi mort: cap pantalla la important mai. Eliminada. La llista de 16 (`Specialty` enum + taula `specialties`, Fase C) és l'única real i ja cobreix les 14 categories oficials (2 addicions pròpies: laparoscòpia/energia avançada i cirurgia robòtica). Actualitzats els 2 comentaris SQL obsolets que hi feien referència.
* ~~Internacionalitzar les observacions d'esterilització~~ — **fet (2026-08)**. Les ~50 files sembrades del catàleg global (`supabase/seed_v1_catalog_sterilization_defaults.sql`) repetien literalment 4 frases fixes en castellà. Traduïdes com a claus l10n (`sterilizationObsGenericReusable`/`Disposable`/`ScalpelHandle`/`ScalpelBlade`) i localitzades a la UI (`sterilizationObservationsText()` a `lib/widgets/sterilization_method_label.dart`) quan el text guardat coincideix exactament amb una plantilla coneguda; el text propi d'un hospital (escrit pel seu equip) es mostra tal qual, mateix criteri que la resta de contingut d'autor lliure de l'app (`group_documents.content`, notes de safates, etc. — cap altra taula separa per idioma).
* Eliminar textos fixos únicament disponibles en castellà — **parcial (2026-08)**: arreglats `audit_log_screen.dart` (títol, accions, rols, "fa X temps", estat buit) i `WorkspaceRole.label` (usat també a `manage_workspace_members_screen.dart`, reemplaçat per `workspaceRoleLabel()` a `lib/widgets/workspace_role_label.dart`, mateix patró que `sterilizationMethodValueLabel`). Pendent: cap més detectat en aquesta passada, però no s'ha fet una auditoria exhaustiva de tot el repositori.

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

## Accessibilitat i onboarding

* ~~Pantalla "Com funciona" (llenguatge planer) + revisió tècnica bàsica d'accessibilitat~~ — **fet (2026-08)**.

**Estat: fet.** Nova `lib/screens/how_it_works_screen.dart`, accessible des de Perfil per a tothom (també en mode convidat, sense necessitat de compte). Deliberadament una sola pàgina que es desplaça (sense `ExpansionTile` ni pestanyes — cap contingut amagat rere un toc addicional), text a mida `bodyLarge` (16sp, no `bodyMedium`), frases curtes sense argot tècnic. Explica què fa cada pestanya (Inici/Cercar/Biblioteca/Activitat/Perfil), dona consells d'ús, i una secció d'accessibilitat pròpia (mida de lletra del sistema, lector de pantalla, tema fosc, idioma).

Revisió tècnica bàsica feta en paral·lel: (1) contrast de color dels tokens (`InstriqColors`) verificat manualment — text secundari sobre fons ja supera 7:1 en tema clar i 8.8:1 en tema fosc, per sobre del mínim AA (4.5:1); (2) confirmat que l'app no sobreescriu `textScaleFactor` enlloc, així que respecta la mida de lletra del sistema; (3) trobats i arreglats **20 `IconButton` sense `tooltip`** (invisibles per a lectors de pantalla com TalkBack/VoiceOver) a 12 pantalles diferents — ara tots tenen una etiqueta accessible, amb 13 claus l10n noves (`editTooltip`/`deleteTooltip` genèrics per a botons d'una pantalla de detall d'una sola entitat, etiquetes específiques per a accions destructives dins de llistes); de pas, `audit_log_screen.dart` va deixar de tenir el títol i el tooltip de refrescar fixos en castellà (reutilitzant una clau `auditLogTitle` que ja existia i no s'usava).

No inclòs en aquest tram (fora de l'abast acordat): auditoria exhaustiva de totes les pantalles (mida de zones tàctils pantalla per pantalla, ordre de focus per a lector de pantalla, `Semantics` personalitzats), i la resta de textos fixos en castellà d'`audit_log_screen.dart` (`_actionLabels`, `_roleLabel`, etc. — ja documentat per separat a Technical Debt). `flutter analyze`/`flutter test` nets. Verificat en emulador en mode convidat: la pantalla "Com funciona" es desplaça correctament amb totes les seccions llegibles, sense cap regressió a la resta de Perfil.

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

RAG (com es recupera el context), model de permisos (què pot veure la IA de cada organització), estratègia de citació de fonts, política de privadesa de dades clíniques, traçabilitat de respostes.

**Primera restricció confirmada (2026-08, decisió del propietari)**: la IA ha de ser **local/offline**, no un LLM ni una API externa. Dos motius: (1) molts blocs quirúrgics no tenen cobertura wifi fiable — un assistent que depengui d'internet falla justament quan més calen, (2) les dades clíniques que li donarien contingut són sensibles i no s'han d'enviar a un tercer. Encara pendent dins d'aquesta restricció: inferència al dispositiu (model petit embarcat) vs. servidor local a la xarxa de l'hospital (sense sortir a internet); en tots dos casos el RAG/embeddings també han de viure en local, no al Postgres al núvol on avui hi ha `pgvector` instal·lat. La resta de l'ADR (model de permisos, citació de fonts, traçabilitat) segueix oberta.

**Impacta**: EPIC 5 (cerca semàntica — la part semàntica, no la de nom/entitat ja feta), EPIC 6. Es relaciona amb **ADR-003** (estratègia offline, ja decidit — `docs/ADR_003_OFFLINE_STRATEGY.md`): la infraestructura local que calgui per a la IA és, en essència, el mateix problema que ADR-003 ja ha resolt per a la resta de l'app.

## ADR-003 · Estratègia Offline

Quines entitats han de funcionar sense connexió, quines són només lectura, quines es poden editar offline, política de sincronització, resolució de conflictes, estratègia de versions en conflicte. L'stack local (sqlite/drift) és un detall d'implementació posterior, no la decisió en si.

**Document d'arquitectura complet**: [`docs/ADR_003_OFFLINE_STRATEGY.md`](ADR_003_OFFLINE_STRATEGY.md) — anàlisi de l'estat real del codi (només tècniques/protocols tenen cap suport offline avui; safates/targetes/esterilització cap), una discrepància trobada entre aquest backlog i el codi (veure nota a EPIC 7 més avall), i una proposta: obrir un esborrany nou (o aprovar/rebutjar/restaurar) exigeix connexió — continuar editant un esborrany ja obert no. Amb això, la col·lisió de números de versió entre dispositius offline queda arquitectònicament impossible per construcció, no per detecció. Lectura offline de contingut publicat (no l'edició) es tracta com la prioritat real, alineat amb el motiu original de l'ADR (cobertura wifi poc fiable al bloc quirúrgic).

**Estat: decidit (2026-08).** Premissa confirmada pel propietari: els canvis de contingut es fan en moments de calma (mai durant una intervenció), quan es dona per fet que hi ha connexió — per això exigir-la per obrir un esborrany o aprovar/rebutjar és acceptable; el que passa *durant* una intervenció és consultar, no editar, per això la lectura offline és la prioritat real.

**Impacta**: EPIC 4, EPIC 7, i (per la infraestructura local compartida) ADR-002/EPIC 6.

## ADR-004 · Versionat del coneixement

El patró capçalera+versions (draft→revisió→publicat→arxivat) s'ha construït 3 vegades de forma independent (`group_documents`, `trays`, `preference_cards`), sense abstracció compartida. Cal decidir si continuar duplicant-lo per cada entitat nova (instrumental personalitzat, esterilització/fitxes tècniques — Product Evolution) o extreure'n un component genèric abans de construir-ne una quarta còpia.

**Document d'arquitectura complet**: [`docs/ADR_004_VERSIONING.md`](ADR_004_VERSIONING.md) — comparativa exacta de columnes/RPC/codi Dart dels 3 casos, veredicte: **cap taula SQL genèrica** (el propi codi ja demostra per què — `knowledge_links` existeix precisament perquè consultar dins un jsonb no era prou bo), sí una **recepta documentada** per a instàncies noves + una base compartida a Dart (`VersionedContentService`, widget de revisió genèric) **només per a la 4a instància**, sense retro-migrar els 3 serveis existents. De pas, es va trobar i corregir un bug real: `preference_card_versions` no tenia les restriccions d'unicitat que sí tenen les altres dues (`schema_v28_preference_card_constraints_fix.sql`, verificat sense dades que el violessin abans d'aplicar-lo).

**Estat: decidit i bug corregit (2026-08).** Pendent: aplicar la recepta a instrumental personalitzat/esterilització d'organització (Product Evolution) — encara no fet.

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

**Estat: fet (2026-08)**, sobre el principi decidit a `docs/ADR_003_OFFLINE_STRATEGY.md`.

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

### Fet (2026-08)

Generalitzada la cua/caché que ja existia només per a tècniques/protocols (`sync_queue_service.dart`/`offline_cache_service.dart`) a Bandeges, targetes de preferència i esterilització/fitxa tècnica (EPIC 3), seguint exactament el principi de l'ADR-003: **crear una entitat nova buida i continuar editant un esborrany ja obert** (`saveDraft`/`submitForReview`) es pot encolar sense connexió; **obrir el primer esborrany d'una entitat existent** (`startEditing`, i els `create_*` d'esterilització/fitxa tècnica que resolen doble autoria global/organització) sempre exigeix connexió — són punts de coordinació amb el servidor.

* Bandeges i targetes de preferència: cua completa (crear/desar esborrany/enviar a revisió) + lectura offline (`OfflineCacheService`, `OfflineBanner` a les pantalles de llista).
* Esterilització/fitxa tècnica: desar esborrany/enviar a revisió encuats; sense caché de lectura encara (es consulten per instrument, no hi ha una llista navegable — queda pendent si l'ús real ho demana).
* `pendingSync` afegit als 4 models de versió nous (calcat de `GroupDocumentVersion`), amb `PendingSyncChip` mostrat allà on ja es mostrava el borrador propi pendent.
* **Forat tancat**: pantalla nova `sync_issues_screen.dart` (accessible des de `profile_hub_screen.dart`) que mostra els `SyncFailure` que abans es registraven però no es veien enlloc — rebuigs de conflicte (algú altre ja va aprovar/rebutjar mentre estaves sense connexió) ara són visibles i es poden descartar.
* **Pendent explícit, fora d'abast**: pujar fotos (`uploadPhoto` de Bandeges) segueix exigint connexió — no hi ha ruta de cua per a Storage.

### Verificat en viu (2026-08-11) — primer flux autenticat provat de tota la sessió

Fins ara cap flux autenticat s'havia provat mai en viu (emulador + compte real) — era el forat més gran acumulat, repetit a gairebé cada EPIC d'aquest document. Es va tancar: 2 comptes de prova reals (editor + approver) a l'espai "Hospital Demo", flux complet crear→desar→enviar a revisió→aprovar→publicat verificat de cap a cap, i el flux offline (mode avió real amb `svc wifi/data disable`, no `airplane_mode_on` que no talla la xarxa de l'emulador) verificat: banner "sense connexió", cua de sincronització, i sincronització automàtica en recuperar connexió, tot confirmat directament contra la base de dades.

**Bugs reals trobats i arreglats** (cap relacionat amb el codi escrit avui per EPIC 7 — tots preexistents, només mai executats en viu fins ara):

1. **10 fitxers** (`group_document_list_screen.dart`, `trays_screen.dart`, `preference_cards_screen.dart`, `audit_log_screen.dart`, `custom_instruments_screen.dart`, `manage_teams_screen.dart` ×2, `manage_workspace_members_screen.dart`, `public_library_screen.dart` ×2, `workspace_list_screen.dart`, `admin/manage_hospital_screen.dart`) cridaven `AppLocalizations.of(context)` de manera síncrona dins d'un mètode `_load()` invocat des de `initState()` abans de cap `await` — Flutter ho prohibeix explícitament i llançava una excepció no gestionada, deixant la pantalla penjada en un spinner infinit. Corregit movent la crida a `l10n` al bloc `catch`, sempre després d'un `await`.
2. **`startEditing()`/equivalents als 5 serveis versionats** (`GroupDocumentService`, `TrayService`, `PreferenceCardService`, `SterilizationService` ×2) permetien reobrir per "continuar editant" una versió ja `in_review` — però la política d'UPDATE de Supabase només permet escriure sobre `status = 'draft'`, així que desar/enviar fallava sempre amb un `PostgrestException` críptic. Corregit: si la versió trobada és `in_review`, es llança un error clar en lloc d'obrir el formulari d'edició.
3. **`WorkspaceService.fetchMyRole()`** no tenia cap gestió de xarxa — cridat des de 14 llocs (Inici, fitxes de detall...), sense connexió llançava una excepció no capturada que feia que tocar una drecera d'Inici (p.ex. "Safates d'instrumental") no fes absolutament res, sense cap avís. Corregit amb una caché en memòria per workspace: sense connexió, cau al darrer rol conegut (o `null` si mai s'ha obtingut).
4. **6 formularis de creació/edició** (`tray_form_screen.dart`, `group_document_form_screen.dart`, `preference_card_form_screen.dart`, `instrument_detail_screen.dart` ficha tècnica, `public_entity_form_screen.dart`) tenien el mateix patró: un fetch auxiliar (instrumental personalitzat, especialitats, cirurgians, fabricant/IFU) s'esperava *abans* de la crida real de creació/edició d'esborrany, sense captura d'errors. Sense connexió, el fetch auxiliar fallava i avortava tot el `_init()` — impedint que la trucada real (que sí sap encolar-se offline, feina d'avui mateix) s'arribés a executar. El cas de `instrument_detail_screen.dart` era el pitjor: `_persistInfoDraft` cridava `createOrGet` de fabricant/IFU (que insereix sempre, sense dedup) *abans* de `saveTechnicalInfoDraft` a *cada* desat amb camps IFU omplerts, no només la primera vegada — perdent canvis silenciosament cada cop, no només sense connexió. Corregit aïllant cada fetch auxiliar en el seu propi `try/catch`, descartant només errors de xarxa i deixant la trucada real fora, sense guardar.
5. **`public_entity_form_screen.dart`**: `_saveDraft()` no tenia `catch` (només `finally`), i `_submitForReview()` cridava `_saveDraft()` fora del seu propi `try` — qualsevol error s'escapava sense cap avís a l'usuari. Corregit amb gestió d'error pròpia a `_saveDraft()` i coordinació neta amb `_submitForReview()` per no duplicar avisos.

`flutter analyze`/`flutter test` nets després de cada tanda de fixes.

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

**Estat: primer tramo fet (2026-08), ampliant la fitxa en lloc de substituir-la.** Es va preguntar l'abast (pantalla nova que substitueixi `GroupDocumentDetailScreen` a tota la nav vs. ampliar la fitxa existent in situ) i es va triar ampliar-la — baix risc, cap punt de navegació canvia. Sense RPC d'agregació nova: tot servible amb les consultes existents (bucle petit per instrument relacionat, mateix criteri que la resta de l'app; el bulk-fetch només es justifica a escala de "tot el catàleg", com a EPIC 5). Afegit: resum d'esterilització/fabricant per cada instrument relacionat, checklist de la safata expandit inline (`ExpansionTile`), i una secció nova de targetes de preferència **de l'espai** (no "del procediment" — no existeix cap relació real entre una targeta i una tècnica concreta al model de dades, només comparteixen espai; el nom de la secció ho deixa clar per no insinuar una precisió que no hi ha).

**Segon tram fet (2026-08-22)**, tancant el forat de Vídeos/material fungible/sutures/posicionament que aquest mateix apartat deixava documentat com a pendent de disseny propi — confirmat com a prioritari per una comparativa amb apps competidores (procedimientosenquirofano.es i similars). `consumables`/`patient_positioning`/`anesthesia_notes`/`related_suture_ids` són 4 columnes noves a `group_document_versions` (mateix criteri que `content`/`steps`: contingut de la mateixa fitxa versionada, no una entitat amb flux propi — cap RPC nova). Sutures té catàleg propi (`lib/data/sutures_data.dart`, 17 sutures reals), deliberadament separat del d'instruments (és consumible amb propietats pròpies: material, calibre, agulla), amb `SutureCatalogScreen`/`SutureDetailScreen`/`SuturePickerSheet` i drecera a Inici; enllaçable a tècniques i sincronitzat a `knowledge_links` (`to_type='suture'`) en aprovar. Anestèsia (equip reutilitzable, no consumible) reutilitza el 100% de la infraestructura d'instruments — nova especialitat "Anestesiologia i Reanimació" + 8 entrades noves al catàleg, sense cap taula ni codi nou. Vídeos és `group_document_videos`, taula plana moderada calcada d'`instrument_incidents` (pending/approved/rejected, mateix gate `canApproveAnyWorkspace||isAdmin` per aprovar) — només URL externa (YouTube/Vimeo), mai pujada de fitxer. Verificat en viu de cap a cap: crear+aprovar un vídeo amb els comptes editor+approver reals, catàleg i fitxa de sutures, i les 4 seccions noves renderitzant al formulari.

Implants, com a entitat pròpia, segueix fora d'abast — no hi ha encara cap cas d'ús concret que en justifiqui el model (a diferència de sutures/consumibles, que ja tenien exemples reals a la comparativa).

`flutter analyze`/`flutter test` nets. Verificació en emulador no concloent aquesta vegada (l'emulador ha acumulat molta càrrega després d'una sessió molt llarga i no arrencava amb fluïdesa) — el canvi només toca `GroupDocumentDetailScreen`, inaccessible en mode convidat, així que el risc de regressió en mode convidat és estructuralment nul independentment. Queda pendent, com sempre amb aquests fluxos, la prova real amb compte autenticat.

## EPIC 3 · CSSD Workspace

* **Model de domini**: additiu sobre `instrument_sterilization_methods`/`instrument_technical_info` (ja existents). "Incidències" és taula nova, candidata natural al patró `ref_type`/`ref_id`.
* **Compatibilitat amb el Knowledge Graph**: bon encaix, ja FK'd a Instrument/Manufacturer.
* **Impacte UX**: mitjà — pantalles noves seguint convencions ja usades a la fitxa d'esterilització actual.
* **Compatibilitat amb arquitectura actual**: alta — coincideix exactament amb el "versionat d'esterilització" ja marcat com a pendent des de Fase E.
* **Dependències**: ~~bloquejada per **ADR-001**~~ — desbloquejada (ADR-001 decidit).
* **Veredicte**: ~~no planificar fins resoldre ADR-001~~ **fet (2026-08)**.

**Estat: fet (2026-08).** Implementat sobre `supabase/schema_v32_cssd_workspace.sql`: `instrument_sterilization_methods`/`instrument_technical_info` (71 files reals, cap pèrdua verificada) es converteixen en capçalera+versions (`instrument_sterilization_method_versions`/`instrument_technical_info_versions`), amb el mateix cicle draft→revisió→publicat→arxivat que tècniques/safates/targetes — decisió del propietari: **versionat complet, catàleg global inclòs**. La pregunta que ADR-004 deixava sense resposta ("qui aprova un canvi al catàleg global") es resol reutilitzant el sistema de col·laboradors/Editorial Board ja construït per a la Biblioteca Pública (`my_is_reviewer_or_above()`) en lloc d'inventar un rol nou; files d'organització s'aproven pel rol d'espai (`approver`/`administrator`) com sempre. Camps nous estructurats (abans text lliure): lubricació (`lubrication_required`/`type`/`notes`) i manteniment (`maintenance_interval_days`/`last_maintenance_at`). Taula nova `instrument_incidents` (gravetat baixa/mitjana/alta, estat obert/resolt) — sense versionat, és un registre operatiu, no contingut a aprovar.

Codi Dart: `SterilizationService` ampliat amb el flux complet (crear/començar a editar/desar esborrany/enviar a revisió/aprovar/rebutjar/restaurar) per a totes dues entitats; nou `InstrumentIncidentService`. UI: la fitxa d'instrument reutilitza `InstriqVersionHistory`/`InstriqVersionDiff` (Nivell 1 del Design System) en lloc de construir-ne una 4a/5a versió a mà — exactament el cas per al qual es van generalitzar. `ReviewQueueScreen` guanya 2 pestanyes (files d'organització); nova `GlobalCatalogReviewQueueScreen` per a l'Editorial Board, accessible des de "Comunitat Instriq" a Perfil.

`flutter analyze`/`flutter test` nets. Verificat: comptatge de files idèntic abans/després de la migració, `published_version_id` mai nul, `get_advisors` sense avisos nous fora del patró ja acceptat. Pendent, com sempre amb aquests fluxos: provar en viu (emulador, compte autenticat) el flux complet — proposar un mètode global i veure que només l'Editorial Board el pot aprovar, editar una fitxa tècnica d'espai i veure que l'aprova un `approver` d'aquell espai, reportar una incidència i marcar-la resolta.

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

* **Model de domini**: sense impacte fins introduir embeddings/vector search.
* **Compatibilitat amb el Knowledge Graph**: dependència dura explícita al propi document — no començar sense EPIC 1 consolidat.
* **Impacte UX**: alt i nou paradigma (xat/preguntes); ha de citar sempre la font i **no ha de poder citar esborranys**, només contingut publicat/aprovat — coherent amb el model de confiança draft→revisió→publicat ja establert a tota la resta de l'app.
* **Compatibilitat amb arquitectura actual**: la de més superfície nova de tots els EPICS, i ara amb un requisit afegit (decisió del propietari, 2026-08): **la IA ha de ser local/offline, no un LLM extern per API**. Motiu doble: molts blocs quirúrgics no tenen cobertura wifi fiable (un assistent que depengui d'una crida a internet no serviria precisament quan més falta fa), i les dades clíniques que li donarien contingut (tècniques, targetes de preferència, notes) són sensibles — no s'han d'enviar mai a un proveïdor extern. Això descarta la integració via Edge Function + API de tercers (Claude/OpenAI) que es donava per fet fins ara, i obre una pregunta pròpia dins d'ADR-002: **inferència al dispositiu** (model petit embarcat a l'app, límits reals de mida/qualitat en mòbil) vs. **servidor local a la xarxa de l'hospital** (una màquina/GPU dins del mateix bloc quirúrgic, sense sortir a internet) — cap de les dues s'ha decidit encara. El mateix val per a la cerca RAG: els embeddings/vector search també haurien de viure en local, no al Postgres al núvol de Supabase (on ja hi ha `pgvector` instal·lat, però pensat per a un altre escenari).
* **Dependències**: bloquejat per EPIC 1 i per **ADR-002 · Arquitectura d'IA** (ara amb el requisit local/offline com a primera restricció confirmada). ~~ADR-003~~ ja no bloqueja aquest EPIC — decidit, veure `docs/ADR_003_OFFLINE_STRATEGY.md` — però la pila local que en surti (avui `shared_preferences`, "detall d'implementació posterior") val la pena revisar-la quan es dissenyi la IA local de veritat, per si cal alguna cosa més robusta per a l'emmagatzematge vectorial. La cerca semàntica d'EPIC 5 (pensada per compartir infraestructura amb aquest EPIC) també s'ha de revisar amb el mateix criteri quan arribi el moment.
* **Veredicte**: **ajornat deliberadament (2026-08, decisió del propietari)** — no és el darrer EPIC per falta de prioritat, sinó perquè encara no hi ha la restricció d'arquitectura completa (local vs. servidor d'hospital). No planificar-lo en detall fins resoldre ADR-002.

## EPIC 7 · Offline First

* **Model de domini**: cap entitat nova; estén el mode sense connexió ja existent a Bandejes, targetes de preferència i esterilització/fitxa tècnica. **Correcció (2026-08)**: aquest punt deia fins ara que targetes ja tenien mode sense connexió — no és cert, el codi ho treu explícitament (`preference_card_service.dart`, "regressió coneguda i deliberada" en migrar al versionat). Avui **només** tècniques/protocols en tenen. Veure `docs/ADR_003_OFFLINE_STRATEGY.md`.
* **Compatibilitat amb el Knowledge Graph**: neutre, és una qüestió de client, no d'esquema.
* **Impacte UX**: mitjà — calen indicadors d'estat de sincronització i una UI de conflicte ("la teva versió vs. la del servidor") que avui no existeix enlloc de l'app.
* **Compatibilitat amb arquitectura actual**: risc baix ara que **ADR-003** està decidit — principi clar (obrir esborrany/aprovar exigeix connexió, continuar editant no) que evita la col·lisió de versions per construcció, sense necessitat de canviar la pila local (`shared_preferences` és suficient per ara).
* **Dependències**: l'abast creix amb cada entitat nova (Bandejes, targetes, esterilització/CSSD); ~~bloquejat per ADR-003~~ **desbloquejat (ADR-003 decidit)**.
* **Veredicte**: **implementable ja** — principi clar (obrir esborrany/aprovar exigeix connexió, continuar editant no), veure `docs/ADR_003_OFFLINE_STRATEGY.md`. Generalitzar la cua de 3 operacions ja provada a tècniques/protocols a safates, targetes i esterilització; estendre `OfflineCacheService` per a lectura.

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

**Estat: segon tram fet (2026-08) — Biblioteca Pública.** Implementat sobre `supabase/schema_v29_public_library.sql`, seguint la recepta d'ADR-004 i la decisió revisada d'ADR-001 (taules separades, no `visibility` a `group_documents`/`trays` — veure `docs/ADR_001_KNOWLEDGE_GOVERNANCE.md` §0): `public_documents`/`public_document_versions` i `public_trays`/`public_tray_versions` (mateixa forma que les taules privades, sense `organization_id`/`workspace_id` -- ortogonals al model multiorganització, mateix criteri que `manufacturers`/`tags`/`specialties`), `editorial_comments` (fil de comentaris multi-ronda, capacitat genuïnament nova), i helpers `my_is_active_contributor()`/`my_is_reviewer_or_above()`. Lectura pública total dels capçaleres i de les versions publicades (RLS `using (true)`/`status = 'published'`, també per a `anon`); proposar/editar un esborrany exigeix ser col·laborador actiu; aprovar/rebutjar exigeix nivell reviewer o superior. `knowledge_links` amplia el `check` de `from_type`/`to_type` (additiu) però **no sincronitza automàticament** per a contingut públic en aquest tram — decisió conscient, documentada, no una omissió.

Codi Dart: base compartida `PublicVersionedContentService<T>` (`lib/services/public_versioned_content_service.dart`) per al flux submit/approve/reject/fetchReviewQueue, decisió d'ADR-004 §3 d'usar-la per a instàncies noves sense retro-migrar els 3 serveis privats existents. `PublicLibraryScreen` (2 pestanyes, lectura oberta a tothom + botó "Proposa" si ets col·laborador), pantalles de detall/formulari per a documents i safates, `PublicLibraryReviewQueueScreen` (nomes Editorial Board/reviewer) amb el fil de comentaris integrat. Accés des de la pestanya Biblioteca, secció pròpia sempre visible (no exigeix hospital connectat, a diferència de la resta de la pantalla).

Fora d'abast d'aquest tram: adopció d'una organització sobre contingut públic (Source/Parent/Sync Status d'ADR-001 -- encara no aplicat), sincronització de `knowledge_links`, i la pantalla de perfil públic d'un altre col·laborador (les dades ja existeixen, `is_public`/`show_organization`, però no hi ha una pantalla per veure-les). `flutter analyze`/`flutter test` nets. Verificat en emulador en mode convidat: la Biblioteca Pública s'obre sense sessió, mostra les 2 pestanyes buides (encara no hi ha contingut publicat) sense cap excepció a `logcat`. El flux de proposta/revisió/aprovació complet no s'ha pogut provar en viu — requereix un compte de col·laborador real, mateix punt pendent que la resta de fluxos d'aquesta sessió.

## Seqüenciació recomanada

1. **EPIC 1 · Knowledge Graph** — fundació, desbloqueja la resta.
2. **EPIC 4 · Trays 2.0** en paral·lel — cap dependència, risc baix.
3. **EPIC 5 · Smart Search** (part per nom/entitat) en paral·lel — cap dependència dura.
4. **EPIC 2 · Clinical Workspace** — un cop EPIC 1 tingui les relacions clau (tècnica↔instrumental↔safata).
5. ~~**Sincronitzar progrés d'aprenentatge a Supabase** (millora, no EPIC) → **EPIC 8 · Contextual Learning**~~ — fet, primer tram (2026-08).
6. ~~**EPIC 3 · CSSD Workspace** — només després de resoldre **ADR-001** (governança del coneixement).~~ **Fet (2026-08)** — veure detall a la secció EPIC 3 més amunt.
7. ~~**EPIC 7 · Offline First** — limitat a Bandejes fins resoldre **ADR-003**~~ **Fet (2026-08)** — veure detall a la secció EPIC 7 més amunt.
8. **EPIC 6 · Clinical AI Assistant** — **ajornat deliberadament (2026-08, decisió del propietari)**: ha de ser IA local/offline (cobertura wifi poc fiable a molts blocs quirúrgics + dades clíniques sensibles que no poden sortir a un tercer), no un LLM extern per API com es donava per fet fins ara. No es planifica en detall fins resoldre **ADR-002** (versió local: al dispositiu o a un servidor de la xarxa de l'hospital) — ADR-003 ja no el bloqueja, però la infraestructura local que en surti val la pena revisar-la quan arribi el moment.
9. **EPIC 9 · Community & Editorial Governance** — **implementable ja**, en paral·lel a qualsevol altre EPIC; el nomenament del Consell Editorial és posterior a la implementació, no una condició prèvia.

Nota transversal: ~~**ADR-004** (versionat del coneixement) no bloqueja cap EPIC en marxa, però hauria de resoldre's abans d'implementar el versionat d'instrumental personalitzat o d'esterilització (Product Evolution) — seria la quarta còpia independent del mateix patró.~~ **Resolt (2026-08)**, veure `docs/ADR_004_VERSIONING.md` — la recepta ja existeix, falta aplicar-la.
