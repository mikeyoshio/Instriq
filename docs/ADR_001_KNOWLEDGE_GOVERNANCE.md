# ADR-001 · Governança i herència del coneixement — proposta d'arquitectura

**Estat d'aquest document**: **decidit (2026-08)**. Secció 0 recull els principis i el model de dades confirmats pel propietari. La resta del document és l'anàlisi comparativa que hi va portar. Encara sense codi ni migracions — la implementació es fa EPIC a EPIC (es comença per EPIC 9, que no toca el model de contingut versionat).

---

## 0. Decisió final (confirmada pel propietari, 2026-08)

**Visió del producte**: ni SaaS (Visió A) ni comunitat pura estil Wikipedia — una **infraestructura Open Source** per gestionar coneixement clínic. La comunitat la fa créixer, les organitzacions la fan servir, Instriq és el facilitador, no el propietari del contingut. Model mental: GitHub, no Wikipedia — Instriq no és propietari del "codi" (coneixement), només proporciona la plataforma.

**Principis confirmats**:

1. Instriq és una infraestructura Open Source per gestionar coneixement clínic, no el propietari del contingut.
2. Cada organització és propietària del seu coneixement privat.
3. La Biblioteca Pública és una biblioteca de referència mantinguda per la comunitat i l'Editorial Board — **no és una autoritat clínica**.
4. Una organització pot crear una versió local d'un contingut públic. **Vocabulari d'usuari**: "Versió local", "Actualitzar des de la Biblioteca Pública", "Continuar amb la meva versió" — mai "fork"/"merge".
5. Les actualitzacions de la Biblioteca Pública **mai** s'apliquen automàticament — cada organització decideix si les adopta.
6. El Knowledge Graph funciona igual sobre contingut públic o privat — les relacions existeixen igual, el motor respecta els permisos de qui consulta.
7. La IA (EPIC 6, quan es dissenyi) respectarà el mateix model — només pot fer servir el coneixement al qual l'usuari consultant ja tingui accés.

**Model de dades simplificat per a V1** (substitueix la comparativa de camps de §5 del document original — es descarta el diff/comparació camp a camp per ara):

Cada contingut versionable porta:

* **Owner** — organització, usuari o comunitat/Editorial Board.
* **Source** — d'on prové (referència a l'element públic d'origen), si escau.
* **Visibility** — privat / públic.
* **Version** — ja existent (patró capçalera+versions actual).
* **Parent** *(opcional)* — apunta a una **versió concreta** (no només a l'entitat) d'on deriva, per poder saber més tard si l'origen ha canviat des de l'adopció.
* **Sync Status** — enum de 3 estats, **emmagatzemat, no derivat en cada lectura**: `synced` (segueix la referència), `customized` (deriva però té canvis locals), `independent` (ja no manté relació amb l'original). Millora respecte a la proposta inicial d'aquest document (que ho calculava com un booleà a partir d'un hash/timestamp) — un camp explícit és més barat de consultar i més fàcil de mostrar a la UI; es manté amb una transició d'estat en cada edició local (`synced`→`customized` en el primer canvi) i en l'acció explícita "Continuar amb la meva versió" (→`independent`).

**Implicació sobre EPIC 9 / ADR-004 — revisada i decidida (2026-08)**: es va investigar si `Visibility` permetria reutilitzar `group_documents`/`trays` en comptes de taules `public_*` separades. **Descartat després d'investigar-ho**: `organization_id`/`workspace_id` són `NOT NULL` a nivell de BD a les 4 taules (`group_documents`, `group_document_versions`, `trays`, `tray_versions`) des de `schema_v4`/`schema_v15` — reutilitzar-les exigiria treure aquesta restricció (arriscat sobre taules ja en producció), reescriure la RLS de les 4 taules (avui `my_workspace_role(workspace_id)` sempre retorna `null` si `workspace_id` és null, cap política té la branca `or organization_id is null` que sí tenen `taggings`/`instrument_sterilization_methods`/`knowledge_links`), i reescriure els punts de consulta de `GroupDocumentService`/`TrayService` (`fetchDocuments`/`fetchTrays` exigeixen sempre un `workspaceId` no nul) i diverses RPC (`create_group_document`, `create_tray`, `approve_*`). En conjunt, **comparable en esforç a taules noves** — sense el risc de tocar taules ja provades. **Decisió final: taules separades `public_documents`/`public_trays`**, tal com recomanava originalment `docs/EPIC_COMMUNITY_GOVERNANCE.md` §2.4, seguint la recepta d'ADR-004 (`docs/ADR_004_VERSIONING.md` §5). `knowledge_links` no necessita cap canvi — ja és agnòstic a quina taula/visibilitat té l'entitat referenciada (`from_id`/`to_id` sense FK).

---

**Encàrrec**: analitzar si el model de coneixement d'Instriq hauria de funcionar de manera similar a Git (herència, forks, sincronització, versions) o si existeix un model millor per a una plataforma de coneixement clínic multiorganització, comparar estratègies i recomanar-ne una.

---

## 1. La pregunta real

Avui el sistema té dos móns totalment desconnectats:

* **Catàleg global** (`instruments`, `manufacturers`, `specialties`, `sterilization_methods`) — de només lectura, sense propietari, igual per a tothom.
* **Contingut d'organització** (`group_documents`, `trays`, `preference_cards`, instrumental personalitzat) — estrictament privat per `organization_id`, sense cap relació amb res fora de l'organització.

EPIC 9 introdueix un tercer món: la **Biblioteca Pública** (`public_documents`/`public_trays`), oberta a contribucions de la comunitat. Però el disseny d'EPIC 9 (`docs/EPIC_COMMUNITY_GOVERNANCE.md`) **no respon** què passa quan una organització vol *utilitzar* contingut de la Biblioteca Pública com a punt de partida del seu propi contingut privat. Aquest és el buit real que ADR-001 ha de tancar — no "qui aprova un canvi", sinó **com es relaciona el coneixement compartit amb el coneixement privat d'una organització al llarg del temps**.

### Visió A vs Visió B — per què aquest ADR no n'espera la resposta

S'ha plantejat si Instriq és una plataforma SaaS amb la comunitat com a extra (Visió A) o una comunitat Open Source amb els hospitals com a funcionalitat (Visió B). És una decisió de producte/negoci real, però **no bloqueja aquest ADR**: el mecanisme tècnic que es recomana més avall (§4, Opció C) funciona igual sota les dues visions — l'única diferència és *quanta* organitzacions l'utilitzaran (poques, en Visió A; la majoria, en Visió B) i el pes relatiu de l'Editorial Board davant dels administradors d'organització. Es documenta com a decisió de producte separada, pendent, però no cal resoldre-la per avançar amb l'arquitectura d'herència.

---

## 2. Models candidats

### Opció A — Model Git (DAG complet: branques, forks, merges de tres vies)

Cada adopció d'un element públic per una organització seria un "commit" en un graf dirigit acíclic; l'organització podria crear branques, i un merge de tres vies (base comuna + versió local + versió upstream) resoldria conflictes automàticament quan fos possible.

* **Avantatges**: màxima flexibilitat i traçabilitat de llinatge; és el model que ha demostrat funcionar millor per a col·laboració massiva descentralitzada (programari).
* **Inconvenients**: Git fa *merge de tres vies sobre text pla, línia a línia* — un algorisme que no es trasllada directament a dades estructurades (una safata amb ítems, quantitats, posicions i fotos no és un fitxer de text; "què vol dir un conflicte" en una taula relacional no té una resposta genèrica). Construir un motor de merge estructurat real és un problema d'enginyeria de mesos, no de dies. A més, cap usuari objectiu d'aquesta app (un supervisor de quiròfan) ha de raonar mai en termes de "branca" o "merge" — el propi encàrrec ho assenyala com un risc, i hi estic d'acord.
* **Veredicte**: descartat com a model d'usuari. Es recupera parcialment la idea (detecció de divergència) a l'Opció C, sense exposar mai el vocabulari ni la complexitat de Git.

### Opció B — Model Wikipedia (una sola veritat compartida, sense forks)

Tot el contingut és d'una sola línia de veritat amb historial de versions; no existeix el concepte de còpia local divergent — o s'edita l'original (amb permisos) o no s'edita.

* **Avantatges**: extremadament simple; és, de fet, el patró que ja existeix avui per al contingut privat d'una organització (`draft→in_review→published→archived`, una sola línia per document).
* **Inconvenients**: no permet el cas d'ús real que origina aquest ADR — un hospital que vol partir d'una safata pública però adaptar-la a la seva pràctica local sense deixar d'estar-hi "relacionada". Amb aquest model, l'única opció és una còpia completament desconnectada (equivalent a l'Opció D) o no adoptar-la mai.
* **Veredicte**: insuficient per si sola — no resol el problema, només l'evita.

### Opció D — Còpia sense procedència (l'statu quo implícit)

Una organització "copia" manualment el contingut públic (equivalent avui a repetir-lo a mà a `group_documents`/`trays`), sense cap enllaç de tornada a l'origen.

* **Avantatges**: zero cost d'implementació — és el que passaria per defecte si no es fa res.
* **Inconvenients**: cap notificació d'actualitzacions, cap diferenciació de producte, cap manera de saber quantes organitzacions usen un element públic (útil per EPIC 5/EPIC 9). És exactament el buit que aquest ADR intenta tancar.
* **Veredicte**: és la base de comparació ("no fer res"), no una proposta.

### Opció C — Referència upstream amb sincronització conscient de la divergència (recomanada)

No és un DAG de commits ni una única veritat: és una **capa de procedència lleugera** sobre el patró de versionat que ja existeix (capçalera+versions, provat 3 vegades). Idea central:

1. Quan una organització "adopta" un element de la Biblioteca Pública (una safata, una tècnica), es crea una fila normal i corrent a `trays`/`group_documents` (privada, igual que avui), però amb dos camps nous: `upstream_ref_id` (l'element públic d'origen) i `upstream_version_at_adoption` (la versió pública en el moment de l'adopció).
2. El sistema no manté cap graf ni branca — només compara, quan cal, si la còpia de l'organització **ha divergit** de la versió pública original des de l'adopció (té edicions locals pròpies) o **no** (és, de fet, idèntica a l'origen, encara "seguint" l'upstream).
3. Quan la Biblioteca Pública publica una versió nova de l'element:
   - Si l'organització **no ha divergit** → se li notifica amb un únic botó "Actualitzar" (accepta la nova versió sencera; res a perdre, no hi ha edicions locals).
   - Si l'organització **ha divergit** (té personalitzacions) → se li notifica amb "Revisar canvis" (comparació estructurada camp a camp — no diff de text, veure §5) i pot triar: acceptar la versió nova sencera (descartant les seves edicions, amb confirmació), o mantenir la seva versió (ignorar l'actualització, seguir "seguint" l'upstream per a la propera vegada).
   - En qualsevol moment, l'organització pot "Deixar de seguir" (`upstream_ref_id = null`) — l'equivalent més proper a un fork permanent: a partir d'aquí és contingut 100% propi, sense relació amb futures actualitzacions públiques.

* **Avantatges**: reutilitza el patró de versionat ja provat (no n'inventa un quart de zero — s'hi lliga directament amb ADR-004, veure §7); el "merge" mai és automàtic ni silenciós, sempre és una decisió humana explícita amb tres opcions simples; el vocabulari d'usuari mai menciona "branca"/"fork"/"merge" (veure §6); escala bé perquè la comparació és sempre 1 element públic contra 1 còpia privada, no un graf complet.
* **Inconvenients**: cal construir un comparador estructurat (no de text) — treball d'enginyeria real, encara que molt més petit que un motor de merge tipus Git (veure §5, recomanació d'abast reduït per a la primera versió).
* **Veredicte**: recomanada.

### Taula comparativa

| | Model Git (A) | Model Wikipedia (B) | Còpia sense procedència (D) | Upstream + divergència (C, recomanada) |
|---|---|---|---|---|
| Permet adaptació local real | Sí | No | Sí (però desconnectada) | Sí |
| Complexitat d'implementació | Molt alta (merge estructurat general) | Baixa | Nul·la | Mitjana (diff estructurat acotat) |
| Vocabulari expulsat a l'usuari | Branca/fork/merge (risc real) | Cap | Cap | Cap (Actualitzar/Revisar/Deixar de seguir) |
| Notifica canvis upstream | Sí (complex) | N/A | Mai | Sí, adaptat a l'estat |
| Reutilitza el patró ja construït | No | Sí | Sí | Sí |
| Resol el cas d'ús real | Sí, amb sobrecost enorme | No | No | Sí |

---

## 3. Resposta directa a les cinc preguntes

**1. Què és global?** El catàleg ja global avui (`instruments`, `manufacturers`, `sterilization_methods`, `specialties`) — sense canvis. S'hi afegeix la Biblioteca Pública d'EPIC 9 (`public_documents`/`public_trays`) un cop publicada.

**2. Què és privat?** Tot el que penja d'`organization_id` avui: tècniques/protocols, safates, targetes de preferència, instrumental personalitzat, notes, fotos internes. Es manté privat per defecte, sense excepcions — només es converteix en "relacionat" amb la Biblioteca Pública quan l'organització adopta explícitament un element (§2, Opció C) o publica explícitament una contribució pròpia (flux d'EPIC 9).

**3. Què és heretable?** Només **una** aresta nova cal modelar: Biblioteca Pública → Organització (`upstream_ref_id`). Els dos esglaons inferiors que es mencionen a l'exemple (Equip, Usuari) **ja estan resolts** amb mecanismes existents que no necessiten herència de tipus fork: pertinença a `workspaces` (equip) i preferències personals com `active_work_mode`/favorits (usuari, patró `ref_type`/`ref_id` ja usat). No cal —ni convé— que un usuari o un equip "bifurquin" res; ja tenen el seu propi nivell de personalització sense tocar el contingut de l'organització.

**4. Què passa quan la Biblioteca Pública canvia?** Depèn de l'estat de divergència (§2, Opció C): sincronitzat → notificació + un toc per actualitzar; personalitzat → notificació + revisió comparativa; independent (ja desenganxat) → res, per disseny.

**5. Existeix el concepte de fork?** Sí, però **implícit i automàtic**, no una acció deliberada de "crear una branca". Una organització simplement edita la seva còpia adoptada; el sistema la reclassifica sol com a "divergent" en detectar el primer canvi. És més proper a com un tema fill de WordPress o una plantilla duplicada de Notion se separen del seu origen que no pas a com Git ho fa.

---

## 4. Traducció a UX simple

Tres estats visuals, mai vocabulari tècnic:

* 🟢 **Sincronitzat** — idèntic a l'origen públic. Un botó: **"Actualitzar"** (sense fricció, no hi ha res a perdre).
* 🟡 **Personalitzat** — té edicions locals pròpies. Quan l'origen canvia: **"Revisar canvis"** (comparació camp a camp, mai un merge automàtic).
* ⚪ **Independent** — ja no segueix cap origen (l'organització ho ha decidit explícitament amb **"Deixar de seguir"**). No rep més notificacions.

Cap paraula "fork", "branch" o "merge" apareix mai a la interfície — són vocabulari d'implementació d'aquest document, no de producte.

---

## 5. Diff estructurat, no diff de text — i una recomanació d'abast reduït

Git compara línies de text perquè no sap què representen. Instriq sí ho sap: una safata és una llista d'ítems tipats (instrument, quantitat, posició); una tècnica és un conjunt de camps (títol, descripció, passos). Això fa que un **diff camp a camp** sigui molt més simple de construir que un merge de text genèric — no cal reinventar `diff3`, només comparar valor a valor sobre una estructura ja tipada.

**Recomanació per a la primera versió, per no sobredimensionar l'abast**: no cal diff camp a camp des del primer dia. La primera versió pot tractar la divergència com un **booleà únic per document** (ha canviat / no ha canviat des de l'adopció, comparant un hash o `updated_at` contra el moment d'adopció) — sense mostrar encara quins camps concretament. Això cobreix el 90% del valor (saber si puc actualitzar sense por o si he de revisar) amb una fracció del cost. El diff camp a camp detallat es pot afegir després, si els hospitals ho demanen, sense canviar el model de dades subjacent.

---

## 6. Knowledge Graph i procedència

Si una safata privada s'adopta d'un origen públic, les relacions (`knowledge_links`) que ja tenia l'element públic (p. ex. "safata general → conté → Kelly") s'haurien de considerar **heretades** per la còpia adoptada, mentre no hagi divergit en aquell punt concret. Això no requereix cap mecanisme nou: n'hi ha prou que `knowledge_links` es recalculi (com ja fa avui en publicar una versió) contra la còpia de l'organització després de l'adopció — les relacions "vénen soles" perquè es deriven del contingut, no d'un graf de procedència separat. Si l'organització diverge i elimina un ítem, la relació corresponent desapareix igual que ja passa avui quan s'elimina qualsevol relació (trigger de neteja ja existent, `schema_v24`).

---

## 7. Relació amb ADR-004 (versionat)

Aquest ADR (governança/herència, el *concepte*) i ADR-004 (patró tècnic de versionat, la *implementació*) són decisions diferents però estretament lligades: el component genèric de versionat que es recomana a ADR-004 hauria de **néixer ja preparat** per portar `upstream_ref_id`/estat de divergència com a camps opcionals des del primer dia — construir-lo primer sense aquesta noció i afegir-la després seria, molt probablement, una migració dolorosa. Per això es recomana resoldre ADR-001 (aquest document, la decisió conceptual) abans de tancar el disseny tècnic d'ADR-004, encara que es puguin dissenyar en la mateixa sessió de treball.

---

## 8. Impacte sobre els EPICs

* **EPIC 1 (Knowledge Graph)**: additiu — les relacions heretades (§6) no requereixen canvis d'esquema, només una regla de càlcul.
* **EPIC 2 (Clinical Workspace)**: additiu — un distintiu visual petit (🟢/🟡/⚪) a les seccions que mostrin contingut adoptat.
* **EPIC 3 (CSSD)**: el mateix model de 3 estats es pot aplicar a canvis de dades globals d'esterilització — resol la pregunta original "qui aprova" com a cas particular d'aquest ADR.
* **EPIC 4 (Trays 2.0)**: **el primer candidat real** — les safates ja tenen versionat i duplicació (`duplicate_tray`); adoptar-ne una de pública és una extensió natural, no un redisseny.
* **EPIC 5 (Smart Search)**: pot mostrar senyals comunitaris ("N hospitals utilitzen aquesta safata pública") — no urgent, es pot ajornar.
* **EPIC 9 (Community Governance)**: la Biblioteca Pública **és** l'upstream d'aquest model — aquest ADR tanca el buit que el document d'EPIC 9 deixava obert (què passa un cop una organització vol *usar* contingut públic, no només *contribuir-hi*).

---

## 9. Riscos

* **Actualització silenciosa en un domini clínic-adjacent**: encara que una còpia estigui "sincronitzada" (sense divergència), mai s'hauria de sobreescriure sense, com a mínim, notificar-ho abans — un hospital pot tenir una safata "congelada" per motius d'auditoria/validació encara que tècnicament no l'hagi editat. Recomanació: notificació + un toc per acceptar, **mai** un cron que actualitzi sol en silenci.
* **Cost real d'enginyeria del comparador estructurat**: no és trivial, encara que sigui molt més petit que un merge de tipus Git — cal pressupostar-lo com a feina pròpia, no com un "detall" d'ADR-004.
* **Càrrega de moderació**: si l'adopció té èxit (sobretot en Visió B), el volum de contingut públic i el seu manteniment creixen — reforça el risc ja anotat a EPIC 9 sobre l'escalabilitat de la cua de l'Editorial Board.

---

## 10. Recomanacions (resum executiu)

1. Adoptar el model d'**Opció C** (referència upstream + divergència), no un DAG estil Git ni una còpia sense procedència.
2. Resoldre ADR-001 (aquest document) abans de tancar el disseny tècnic d'ADR-004 — han de dissenyar-se pensant l'un en l'altre.
3. Primera versió: divergència com a booleà (canviat/no canviat), no diff camp a camp — afegir-hi detall només si cal.
4. Vocabulari d'usuari: "Actualitzar" / "Revisar canvis" / "Deixar de seguir" — mai "fork", "branch" ni "merge".
5. Mai actualització silenciosa automàtica, ni tan sols en l'estat "sincronitzat" — sempre amb confirmació humana explícita.
6. La decisió Visió A / Visió B (SaaS vs. comunitat) és real però **no bloqueja** aquest ADR — es documenta com a decisió de producte separada, pendent.

---

## 11. Classificació per apartat

| Apartat | Estat | Canvi necessari |
|---|---|---|
| Catàleg global (`instruments`, `manufacturers`, etc.) | Ja implementat | Cap canvi |
| Contingut privat per organització | Ja implementat | Cap canvi |
| Biblioteca Pública (`public_documents`/`public_trays`) | No implementat (disseny a EPIC 9) | Nova EPIC |
| Referència upstream (`upstream_ref_id`, estat de divergència) | No implementat | Nova EPIC, depèn d'EPIC 9 i d'ADR-004 |
| Comparador estructurat (diff camp a camp o booleà) | No implementat | Nova EPIC, abast reduït recomanat per a la v1 |
| Herència de relacions del Knowledge Graph | No implementat (però additiu, sense canvi d'esquema) | Refactorització parcial quan existeixi l'adopció |
| Decisió Visió A / Visió B (SaaS vs. comunitat) | No decidit | Decisió de producte, no tècnica — fora de l'abast d'aquest ADR |
