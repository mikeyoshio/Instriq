# EPIC · Community & Editorial Governance — document d'arquitectura

**Estat d'aquest document**: anàlisi funcional i d'arquitectura. Cap codi, cap migració, cap interfície. Tot el que es descriu aquí és una proposta pendent d'aprovació — no s'ha implementat res del que segueix.

**Mètode**: cada afirmació sobre "que ja existeix" s'ha verificat contra el codi real d'aquesta sessió (schema SQL, models Dart, serveis), no assumida. Es cita el fitxer quan és rellevant.

---

## 1. Principis (recollits de l'encàrrec)

* Cada organització és propietària del seu coneixement privat — Instriq no hi intervé.
* La Biblioteca Pública és independent dels espais privats (hospitals/grups/organitzacions).
* Cap contribució pública s'aprova automàticament.
* Traçabilitat obligatòria — tota acció editorial queda registrada.
* Tot el contingut públic és versionable i auditable.

Aquests principis **ja tenen precedent directe** al codi actual: el patró capçalera+versions amb `draft→in_review→published→archived` (`group_documents`/`trays`/`preference_cards`) i `audit_log` (Fase D) ja apliquen "versionable i auditable" al coneixement privat. Aquest EPIC no inventa el patró — l'estén a un espai sense organització propietària.

---

## 2. Entitats noves necessàries

### 2.1 `contributor_applications` (candidatura)

Una fila per candidatura. Mai s'auto-aprova (principi explícit).

Camps: `id`, `user_id` (referencia `auth.users` — cal tenir compte abans de candidatar-se, per traçabilitat real, no candidatures anònimes), `full_name`, `email`, `country`, `organization_name` (text lliure, opcional), `professional_role`, `specialty_ids` (relació amb `specialties`, Fase C — **reutilitza l'entitat existent, no en crea una de nova**), `years_experience`, `linkedin_url`, `certifications`, `publications_or_teaching` (opcional), `collaboration_area_ids` (veure 2.2), `motivation_letter`, `status` (`pending`/`approved`/`rejected`), `reviewed_by`, `reviewed_at`, `review_notes`, `created_at`.

### 2.2 Àrees de col·laboració — recomanació: **reutilitzar `tags`**, no crear una taula nova

L'encàrrec demana "Instrumentació, CSSD, Esterilització, Qualitat, Cirurgia General, Traumatologia..." — és a dir, una barreja d'especialitats clíniques (que ja existeixen com a `specialties`, Fase C) i rols funcionals (Formació, Traduccions, Revisió documental — que NO són especialitats clíniques). Crear una tercera taula de catàleg (després de `specialties` i `tags`) per a un concepte que és, funcionalment, "una etiqueta lliure aplicable a un col·laborador" és exactament el que `tags`/`taggings` (Fase C) ja resol — un catàleg global + una relació polimòrfica `ref_type`/`ref_id`. **Recomanació**: afegir `'contributor'` al `check` de `ref_type` de `taggings` (mateix patró ja usat 8 vegades) en comptes d'una entitat nova. Un col·laborador pot tenir diverses etiquetes (ja ho permet `taggings`).

### 2.3 `contributor_profiles`

Es crea **només** quan una candidatura s'aprova (1:1 amb `auth.users`, únic per usuari).

Camps: `id`, `user_id` (únic), `level` (`contributor`/`reviewer`/`editorial_board` — veure §4, es proposa retirar "Subject Matter Expert" com a nivell), `public_display_name`, `public_bio`, `show_organization` (bool, per defecte `false` — privadesa per defecte, no opt-out), `linkedin_url`, `is_public` (bool, per defecte `false` — el perfil públic és opt-in, no automàtic en aprovar-se), `status` (`active`/`suspended`/`retired`), `approved_by`, `approved_at`.

### 2.4 Biblioteca Pública — taules noves, calcades del patró ja provat 3 vegades

`public_documents`/`public_document_versions` (tècniques/protocols públics) i `public_trays`/`public_tray_versions` (safates públiques) — **mateixa forma exacta** que `group_documents`/`group_document_versions` i `trays`/`tray_versions`, però:
- Sense `organization_id`/`workspace_id` — no pertanyen a cap organització (compleix "no depèn dels hospitals/grups/organitzacions" literalment, no amb una columna nul·lable com es fa avui amb `manufacturers`/`tags`/`specialties`, sinó amb l'absència total de la columna, exactament el mateix criteri que aquestes tres taules globals ja usen).
- El camp `author_id`/`created_by` apunta a `contributor_profiles`, no a un membre d'organització.
- El mateix `status` (`draft`/`in_review`/`published`/`archived`).

**Per què taules noves i no reutilitzar `group_documents`/`trays` amb `organization_id` nul·lable**: barrejar contingut privat i públic a la mateixa taula obligaria a unes polítiques RLS que distingeixin els dos móns dins de la mateixa taula — més complex i més arriscat que tenir-hi taules separades amb el mateix patró (mateix criteri pel qual aquesta sessió ja va descartar un graf genèric `entities`/`entity_relations`: la complexitat de RLS barrejant contextos no compensa l'estalvi de no duplicar l'esquema).

### 2.5 `editorial_comments` — capacitat genuïnament nova

**Cap dels 3 fluxos de versionat actuals (tècniques, safates, targetes de preferència) té un fil de comentaris real** — confirmat llegint el cos de `reject_group_document_version`: un únic camp `comment text`, es sobreescriu, sense fil de conversa. L'encàrrec demana explícitament "Revisió → Comentaris → Correccions", que és una conversa de diversos missatges, no un camp. Cal una taula nova: `editorial_comments(id, ref_type check in ('public_document_version','public_tray_version'), ref_id, author_id, body, created_at, resolved boolean)` — mateix patró polimòrfic `ref_type`/`ref_id` ja establert (`taggings`, `knowledge_links`).

Això és una millora que, un cop construïda, beneficiaria també els 3 fluxos privats existents — però **no és a l'abast d'aquest EPIC** ampliar-los-hi; es construeix només per a la Biblioteca Pública i es documenta com a candidata a generalitzar-se després.

---

## 3. Relacions (diagrama conceptual)

```
auth.users ──1:1── profiles (organization_id NULLABLE, ja avui)
     │
     └──0:1── contributor_applications (candidatura, pot no derivar en res)
                     │ aprovada
                     ▼
     └──0:1── contributor_profiles ──N:M── taggings (ref_type='contributor') ──N:1── tags
                     │                                                          (àrees de col·laboració)
                     │ author_id
                     ▼
              public_document_versions ──N:1── public_documents
              public_tray_versions ──N:1── public_trays
                     │
                     ├──ref_id── editorial_comments (ref_type='public_document_version'|'public_tray_version')
                     │
                     └──to_id── knowledge_links (from_type ampliat: 'public_document'|'public_tray')
```

Notar: `contributor_profiles` **no** substitueix `profiles` — un col·laborador comunitari pot (i sovint serà) també membre d'una organització privada amb el seu propi `WorkspaceRole`. Són dos eixos de permisos independents que coexisteixen sobre el mateix `auth.users`.

---

## 4. Rols de la comunitat — anàlisi crítica de l'estructura proposada

L'encàrrec demana analitzar si Contributor / Reviewer / Subject Matter Expert / Editorial Board és adequat. **Proposta alternativa, justificada**:

**El problema amb 4 nivells lineals**: "Subject Matter Expert" no és un esglaó de permisos, és una etiqueta de confiança/experiència **per àrea** — i l'encàrrec ja diu explícitament que un col·laborador pot pertànyer a diverses àrees. Fer de SME un 4t nivell lineal força que algú sigui "expert" globalment quan en realitat pot ser expert en Traumatologia i novell en Traduccions — un desajust estructural real.

**Recomanació — 2 eixos, no 1 escala**:

1. **Nivell de flux de treball (lineal, 3 esglaons, no 4)**:
   - **Contributor**: pot crear propostes (`draft`) i enviar-les a revisió. No pot aprovar ni publicar res, ni pròpia ni aliena.
   - **Reviewer**: pot comentar (`editorial_comments`), demanar correccions, i marcar un comentari com a resolt. No té l'última paraula d'aprovació — evita que "qui revisa" i "qui aprova" siguin sempre la mateixa persona (separació de funcions, redueix el risc de captura editorial).
   - **Editorial Board**: aprova/publica (equivalent a `approve_..._version`/`reject_..._version` ja existents, adaptats), gestiona candidatures (`contributor_applications`), i promou/degrada nivells d'altres col·laboradors.

2. **Etiqueta d'expertesa (per àrea, no lineal)**: "Subject Matter Expert a `<àrea>`" es modela com una etiqueta més sobre `taggings` (p.ex. `sme:traumatologia`), atorgable per l'Editorial Board, **visible al perfil públic com a reconeixement**, però sense cap permís addicional implícit — un SME que vulgui aprovar contingut ha de ser també Editorial Board. Això separa "qui sap molt" de "qui té l'última paraula", que són coses diferents i sovint persones diferents.

**Criteris de promoció (proposta)**: mai automàtics per mètrica (evita "gaming" i coincideix amb "cap aprovació automàtica"). Contributor→Reviewer i Reviewer→Editorial Board: nominació + vot/decisió de l'Editorial Board existent, registrada a `audit_log` amb qui ho ha decidit i quan. **Problema d'arrencada explícit**: el primer Editorial Board no pot auto-nominar-se pel sistema — cal un nomenament fundacional fora de l'aplicació (manual, per qui operi Instriq). Es documenta com a risc, no es resol aquí.

---

## 5. Flux de candidatura

```
Formulari (candidatura) → pending
         │
         ▼
Editorial Board revisa ──rebutjada──▶ rejected (motiu registrat, l'usuari en queda notificat)
         │
      aprovada
         ▼
contributor_profiles creat (level = 'contributor', is_public = false per defecte)
```

Mateix patró que `create_tray`/`create_group_document`: una RPC `security definer` (`review_contributor_application(p_application_id, p_approved, p_notes)`) que, si s'aprova, crea la fila de `contributor_profiles` i registra `log_audit_event` — no un `insert` directe des del client.

## 6. Flux editorial

```
Draft (Contributor) → Submitted for review → Comments (Reviewer, 0..N rondes) → Corrections (Contributor)
   → Approval (Editorial Board) → Published → [canvi futur] → nova versió (draft) del mateix document
```

Diferència clau respecte als 3 fluxos privats existents: **el bucle Comentaris↔Correccions és iteratiu** (`editorial_comments` amb `resolved`), no un únic `comment` sobreescrit. La resta (draft/in_review/published/archived, `based_on_version_id`, restauració de versions anteriors) reutilitza el patró exacte ja provat.

---

## 7. Biblioteca Pública — resum del model

Independent per disseny: sense `organization_id`, sense `workspace_id`. Lectura pública sense autenticació (RLS `select using (status = 'published' or ...)`, mateix criteri que ja usen `manufacturers`/`tags`/`specialties` per a tothom). Escriptura només via les RPC del flux editorial, mai `insert`/`update` directe.

## 8. Perfil públic

Recomanació: **opt-in explícit** (`is_public`), mai automàtic en aprovar la candidatura — un col·laborador pot voler contribuir sense exposició pública. Contingut del perfil: nom, àrees (`taggings`), organització (només si `show_organization = true`), contribucions publicades (query per `author_id` sobre `public_document_versions`/`public_tray_versions` amb `status='published'`), revisions fetes (si `level >= reviewer`, comptatge d'`editorial_comments`), historial (dates de canvis de nivell, des d'`audit_log`).

**Insígnies: recomanació — derivades, no emmagatzemades**. Una taula d'insígnies atorgables manualment seria una segona superfície de moderació (qui les atorga, amb quin criteri, com s'auditen) per a un problema que ja es pot resoldre com a **vista calculada** sobre dades existents ("10+ contribucions publicades", "SME a `<àrea>`" ja ve de `taggings`). Evita inventar un sistema de reconeixement discrecional nou.

---

## 9. Compatibilitat (resposta directa a les preguntes de l'encàrrec)

* **Quines entitats noves calen?** `contributor_applications`, `contributor_profiles`, `public_documents`/`public_document_versions`, `public_trays`/`public_tray_versions`, `editorial_comments`. Cap entitat nova per a "àrees de col·laboració" (reutilitza `tags`) ni per a especialitats (reutilitza `specialties`).
* **Com es relacionen amb les existents?** Totes pengen d'`auth.users`/`profiles` (que ja permet `organization_id` nul, confirmat). Reutilitzen `specialties`/`tags`/`taggings` sense modificar-los.
* **Compatible amb el Knowledge Graph?** Sí, additiu i de baix risc: `knowledge_links.organization_id` ja és nul·lable i el `check` de `from_type`/`to_type` només necessita dos valors nous (`'public_document'`, `'public_tray'`) — mateixa migració additiva que EPIC 1 ja va fer un cop.
* **Compatible amb el sistema de permisos actual?** **Parcialment.** `WorkspaceRole`/`my_workspace_role()` són, per disseny, sempre relatius a una organització/espai — no hi ha cap concepte de rol de plataforma avui. Els nivells de col·laborador **no s'han d'implementar com una extensió de `WorkspaceRole`**: són un eix de permisos nou i paral·lel (`contributor_profiles.level`), amb les seves pròpies RPC i RLS, que coexisteix sense tocar el model actual.
* **Compatible amb el model multiorganització?** Sí — la Biblioteca Pública és, per disseny, ortogonal a `organizations`: no hi participa cap columna `organization_id`, igual que `manufacturers`/`tags`/`specialties` ja fan avui.
* **Pot créixer a milers de col·laboradors?** Les taules en si, sí (mateixa escala que `profiles`). El risc real d'escala és la **cua de revisió de l'Editorial Board**: amb milers de col·laboradors i propostes, una cua única sense filtre per àrea es tornaria inviable — es recomana, quan arribi el moment, filtrar `fetchReviewQueue`-style per àrea de col·laboració, no ara.

---

## 10. Riscos

* **Spam/candidatures falses a escala pública**: mitigat parcialment (verificació de correu ja existent via Supabase Auth + revisió humana obligatòria per principi), però cap límit de freqüència per correu/IP — no es resol aquí, es documenta.
* **Arrencada de l'Editorial Board**: cap mecanisme del sistema pot nomenar el primer Editorial Board — requereix acció manual fundacional, fora de l'abast d'aquest disseny.
* **Privadesa**: `organization_name` i `show_organization` han de ser opt-in per defecte `false` — mai mostrar l'organització d'algú sense consentiment explícit.
* **Quarta implementació "calcada" del patró de versionat**: després de tècniques/protocols, safates i targetes de preferència, aquesta seria la 4a còpia independent del mateix patró capçalera+versions. Reforça (no resol) l'argument ja anotat en aquesta sessió que valdria la pena extreure un component genèric de versionat/diff — no urgent per bloquejar aquest EPIC, però el cost d'ajornar-ho segueix pujant.

## 11. Recomanacions (resum executiu)

1. Reutilitzar `specialties`/`tags`/`taggings` en comptes de crear catàlegs nous — menys entitats, mateix resultat.
2. Modelar rols en 2 eixos (flux de treball lineal de 3 esglaons + etiqueta d'expertesa per àrea), no una escala de 4 nivells.
3. Taules noves i separades per a la Biblioteca Pública (no barrejar amb `group_documents`/`trays` existents).
4. Construir `editorial_comments` com a capacitat nova, documentant-la com a candidata a generalitzar-se als 3 fluxos privats en un futur EPIC separat.
5. Insígnies derivades, mai una taula d'atorgament manual.
6. No implementar res d'això fins decidir qui són els primers membres de l'Editorial Board (problema humà, no tècnic).

---

## 12. Classificació per apartat

| Apartat | Estat | Canvi necessari |
|---|---|---|
| Model d'organitzacions/permisos privats (`WorkspaceRole`, `my_workspace_role`) | Ja implementat | Cap canvi (es manté intacte, els nivells de col·laborador hi coexisteixen sense tocar-lo) |
| Especialitats (`specialties`) i etiquetes (`tags`/`taggings`) | Ja implementat | Cap canvi per a especialitats; refactorització parcial a `taggings` (afegir `'contributor'` al check de `ref_type`) |
| Patró de versionat draft→revisió→publicat→arxivat | Ja implementat (3 vegades) | Cap canvi al patró; nova EPIC per aplicar-lo a taules públiques noves |
| Comentaris de revisió multi-ronda (`editorial_comments`) | **Implementat (2026-08)** | — Fil de comentaris a la cua de revisió, `lib/screens/public_library_review_queue_screen.dart` |
| Candidatura de col·laborador (`contributor_applications`) | **Implementat (2026-08)** | — (`supabase/schema_v27_contributors.sql`, `ContributorApplicationFormScreen`) |
| Nivells de col·laborador (`contributor_profiles`) | **Implementat (2026-08)** | — (2 eixos aplicats: `level` lineal 3 esglaons + `taggings` per àrea d'expertesa) |
| Biblioteca Pública (`public_documents`/`public_trays`) | **Implementat (2026-08), segon tram** | — Taules noves separades (confirmat, no `visibility` a taules existents — veure `docs/ADR_001_KNOWLEDGE_GOVERNANCE.md` §0 revisat i `docs/ADR_004_VERSIONING.md`). Lectura pública, proposta/revisió/aprovació per col·laboradors, `lib/screens/public_library_screen.dart`. Pendent: adopció a organitzacions (depèn de com s'apliqui ADR-001 §2 Opció C en detall — mida d'EPIC sencera, no un forat petit; encara sense fer) |
| Perfil públic (dades) | **Implementat (2026-08)** | — (`ContributorProfileScreen`, `is_public`/`show_organization` opt-in) |
| Perfil públic (pantalla de veure el d'un altre col·laborador) | **Implementat (2026-08)** | — (`ContributorPublicProfileScreen`, accessible des de l'autor a `PublicEntityDetailScreen`; organització revelada només amb consentiment via `get_public_contributor_organization`, `schema_v33`) |
| Insígnies/reconeixements | No implementat (i es recomana que sigui una vista, no una taula) | Nova EPIC (petita, un cop hi hagi dades reals de contribucions) |
| Knowledge Graph compatible amb contingut públic | **Implementat (2026-08)** | — `knowledge_links` amplia `from_type`/`to_type` amb `public_document`/`public_tray`, i `approve_public_document_version`/`approve_public_tray_version` sincronitzen igual que les seves bessones privades (`schema_v33`) |
| Auditoria (`audit_log`) aplicada a accions editorials/de candidatura | **Implementat (2026-08) per a candidatures** (`review_contributor_application`/`set_contributor_level` ja hi registren); pendent per a accions editorials (encara no existeixen) | Refactorització parcial quan es construeixi la Biblioteca Pública |
