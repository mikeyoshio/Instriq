# ADR-003 · Estratègia Offline — proposta d'arquitectura

**Estat d'aquest document**: proposta, pendent de confirmació del propietari. Secció 0 recull la decisió recomanada; la resta és l'anàlisi que hi porta, basada en una lectura completa del codi real (no de la documentació prèvia, que en un punt es contradiu amb el codi — veure secció 2).

---

## 0. Decisió proposada

**Principi central — el que ja funciona per a tècniques/protocols es generalitza, no es reinventa:**

1. **Obrir un esborrany nou (o aprovar/rebutjar/restaurar una versió) exigeix connexió.** Són punts de coordinació amb estat compartit — reservar un número de versió, decidir qui aprova — i han de passar pel servidor en el moment. **Continuar editant un esborrany ja obert pot fer-se sense connexió**: els canvis de camps es guarden a la cua i es sincronitzen sols en recuperar la xarxa.
2. Amb aquest principi, **la col·lisió de números de versió entre dos dispositius offline és arquitectònicament impossible** — cap dispositiu numera mai una versió pel seu compte; el número només s'assigna en un viatge d'anada i tornada al servidor, que només pot passar en línia.
3. **Lectura offline (contingut ja publicat) és la prioritat real**, per davant de l'edició offline: el motiu original d'aquest ADR és que "molts blocs quirúrgics no tenen cobertura wifi fiable" — i el moment en què això fa més mal és consultant una tècnica o una safata *durant* una intervenció, no editant-la des d'una oficina. S'estén el mateix mecanisme de captura (`OfflineCacheService`) que ja existeix per a tècniques/protocols a safates i targetes de preferència.
4. **Resolució de conflictes: cap fusió automàtica.** Cada RPC de canvi d'estat (`submit_.../approve_.../reject_...`) ja exigeix una precondició (`status = 'draft'`, `author_id = auth.uid()`, etc.) — si un dispositiu reprodueix una operació desada en cua i l'estat ja ha canviat al servidor mentrestant, l'RPC la rebutja amb un error clar. No cal ni s'intenta cap fusió automàtica: la persona torna a obrir l'element en línia i decideix. **Falta construir**: avui aquest rebuig ja passa (`SyncFailure`, `sync_queue_service.dart`) però no hi ha cap pantalla que ho mostri a l'usuari — és un forat real, independent d'aquesta decisió, que cal tancar.
5. **La pila local es queda com és (`shared_preferences`, últim instantani en JSON), no es migra a sqlite/drift ara.** És prou per a l'escala real (desenes/centenars d'elements per espai de treball), i la pròpia ADR-003 original ja ho marcava com "detall d'implementació posterior". Si en el futur la IA local (ADR-002) necessita emmagatzematge vectorial local, aquell serà el moment de introduir una base de dades local de veritat — no cal avançar-s'hi ara sense necessitat real.

**Que això no decideix**: quan s'implementa (és feina d'EPIC 7, no d'aquest document) ni els detalls d'UI concrets. Aquest document només fixa el principi i el model.

---

## 1. Per què calia aquest ADR (recordatori)

`docs/BACKLOG.md` demana: quines entitats funcionen sense connexió, quines són només lectura, quines editables, política de sincronització, resolució de conflictes, estratègia de versions en conflicte. Bloqueja EPIC 7 (Offline First) i, des d'aquesta sessió, també condiciona la futura IA local (EPIC 6/ADR-002) — la infraestructura local que calgui per a una és, en bona part, la mateixa que necessitarà l'altra.

## 2. Estat real del codi (verificat, no documentació)

Dos agents Explore han llegit `offline_cache_service.dart`, `sync_queue_service.dart`, `connectivity_service.dart`, `offline_banner.dart`, i cada servei d'entitat (`group_document_service.dart`, `preference_card_service.dart`, `tray_service.dart`, `custom_instrument_service.dart`) sencers.

| Entitat | Lectura offline | Escriptura offline (cua) | Detecció de conflictes |
|---|---|---|---|
| **Tècniques/protocols** (`GroupDocumentService`) | **Sí** — `shared_preferences`, instantani datat | **Sí** — 3 operacions en cua: crear, desar esborrany, enviar a revisió | Cap — reproducció cega |
| **Targetes de preferència** | **No** | **No** | — |
| **Safates** | **No** | **No** | — |
| **Instrumental personalitzat** | **No** | **No** | — |
| **Esterilització/fitxa tècnica** (EPIC 3, nou) | **No** | **No** | — |

**Discrepància trobada entre documentació i codi**: `docs/BACKLOG.md` (revisió arquitectònica d'EPIC 7) afirma que el mode sense connexió ja cobreix "tècniques/protocols/**targetes**" — el codi diu el contrari. `preference_card_service.dart:13-14` documenta explícitament que l'edició offline de targetes **existia abans i es va treure** quan va arribar el versionat (schema_v22): *"Regressió coneguda i deliberada"*. Cal corregir aquesta línia al backlog independentment de la resta d'aquest ADR.

**Per què safates/targetes/esterilització no tenen res, en paraules del propi codi** (`tray_service.dart:16-21`, `preference_card_service.dart:15-20`): no és cap limitació tècnica (fotos, Storage) — és que el model de treball versionat (esborrany→revisió→aprovació) no encaixa amb una cua FIFO de reproducció cega tal com està construïda avui, i es va prioritzar tenir el flux complet funcionant en línia abans d'afegir-hi aquesta complexitat.

**Un forat real dins de l'única entitat que SÍ té cua**: `startEditing` (crear el primer esborrany quan encara no n'hi ha cap) **exigeix connexió** fins i tot per a tècniques/protocols — només `saveDraft`/`submitForReview`/`createDocument` tenen ruta offline. I `approve`/`reject`/`restore` no tenen cap gestió de connectivitat en absolut (fallarien directament sense xarxa). Això, sense saber-ho, **ja és exactament el principi #1 de la decisió proposada** — el codi ja distingeix "obrir" (en línia) de "continuar editant" (offline-capaç) per a la meitat dels casos; aquest ADR només ho fa explícit i complet.

**Confirmació del risc real de col·lisió** (l'escenari que calia entendre abans de decidir): `preference_card_versions` va tenir, fins a `schema_v28`, ZERO restricció d'unicitat de número de versió — és a dir, dos dispositius creant en local la "versió 2" de la mateixa targeta i sincronitzant després haurien pogut acabar amb dues files "versió 2" a la base de dades sense cap error. Ja arreglat (restricció `unique(card_id, version_number)` + índex únic parcial de "publicada"), però això només converteix el forat en un error clar (`23505 unique_violation`) en lloc de dades corruptes — no en una fusió intel·ligent. La cua (`sync_queue_service.dart:174-184`) tracta qualsevol error que no sigui de xarxa com "error de negoci": **descarta l'operació i l'apunta a una llista de `failures` que avui cap pantalla mostra**.

## 3. Relació amb la resta de decisions d'aquesta sessió

- **ADR-004 (versionat)**: no diu res sobre offline/concurrència — ho deixa explícitament fora d'abast. Aquest ADR-003 el complementa, no el contradiu: el model de versions no canvia, només es decideix quan es permet tocar-lo sense connexió.
- **ADR-002 (IA local)**: la decisió de fer la IA local/offline comparteix el mateix problema d'infraestructura local que aquest ADR. No cal resoldre-la ara — es deixa anotat que quan es dissenyi EPIC 6 caldrà revisar si la pila local (`shared_preferences` vs. una base de dades local de veritat) encara és suficient.
- **EPIC 3 (CSSD, acabat de fer aquesta sessió)**: `instrument_sterilization_method_versions`/`instrument_technical_info_versions` no tenen cap gestió offline avui — són candidats directes a rebre el mateix tractament que safates/targetes quan s'implementi EPIC 7, sense cap disseny nou (mateix model, mateixa cua generalitzada).

## 4. Impacte

**EPIC 7** deixa de estar bloquejat per una pregunta sense resposta — té un principi clar per implementar (generalitzar la cua de 3 operacions ja provada a safates/targetes/esterilització, més estendre `OfflineCacheService` per a lectura). **Product Evolution** (versionat d'instrumental personalitzat/esterilització) hereta el mateix principi sense haver-lo de redecidir.

**Pendent explícit, fora d'abast d'aquest document**: implementar-ho (EPIC 7), i construir la pantalla de "problemes de sincronització" que avui falta per fer visible un rebuig de conflicte a l'usuari.
