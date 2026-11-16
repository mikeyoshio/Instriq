# Auditoria completa (2026-11) i direcció: v1.2 → v2.0

Auditoria en tres fronts (codi/arquitectura, seguretat/backend, producte/UX/contingut)
feta el 2026-11-13 sobre l'estat real del repositori, just després de l'ampliació
massiva de catàleg (700 instruments, 102 fàrmacs), el llançament a Microsoft Store
i el canvi de canal de donacions a Patreon. Aquest document NO substitueix els 4
documents de redisseny v1.2 ja decidits (`redesign_v1.2_*.md`) ni el `BACKLOG.md`
— els integra en una seqüència única amb el que la auditoria ha trobat de nou.

## Radiografia (verificat, no impressions)

- 93 pantalles (22.983 L), 54 serveis (5.942 L), 45 models, `instruments_data.dart` = 16.508 L.
- Patró d'estat únic i consistent: serveis singleton + `ValueNotifier` + `setState` (cap barreja de frameworks).
- 57/57 taules amb RLS; ~120 RPCs `security definer`, totes amb `search_path` fixat.
- l10n: 1.173 claus exactes als 3 `.arb`, catàleg complet en 3 llengües.
- Tests: 12 fitxers, tot unit de models/utils purs. **0 tests de widgets, 0 d'integració.**
- Imatges reals: 28% instruments, 12% fàrmacs. Tips: 57% instruments.
- Biblioteca Pública: sistema complet, contingut gairebé buit (4 setups pilot).

## Trobat de nou per aquesta auditoria (no era al BACKLOG)

### Crítics — arreglar JA, independentment de versions

1. **Fuga cross-organització a l'agenda quirúrgica** (`schema_v64_surgical_agenda.sql:265-329`).
   `surgical_agenda_ics_token` i `regenerate_surgical_agenda_ics_token` autoritzen amb
   `my_is_hospital_admin() OR ...`, però `my_is_hospital_admin()` no compara
   l'organització de l'admin amb la del cirurgià: un admin de QUALSEVOL organització
   pot llegir el token .ics (tota l'agenda operatòria d'un cirurgià d'una altra org)
   o rotar-lo (trencant-li les subscripcions de calendari). Fix: exigir
   `v_organization_id = my_hospital_id()` al costat del check d'admin (2 línies,
   2 funcions, migració `schema_v67`). *Confirmat al codi; provar en viu amb 2 orgs.*
2. **Dues rutes reals de pèrdua de treball al sync offline**:
   - `_resolvedVersionIds` (mapa id local→real) viu només en memòria
     (`sync_queue_service.dart:111`): si l'app mor entre el `create` encuat i els
     `saveDraft` dependents, aquests arriben amb id `local_*`, fallen com a error
     de negoci i es **descarten**. Fix: persistir el mapa amb la cua.
   - `saveDraft` és `update().eq('id')` cec (`tray_service.dart:176`):
     last-writer-wins sense detecció de conflicte. **Severitat revisada en
     implementar els hotfixos**: la RLS només deixa editar un esborrany al seu
     autor (`tray_versions_update_own_draft_role`, v15) i les cadenes v65 són
     de només lectura, així que l'escenari real és només "la mateixa persona,
     dos dispositius, un d'ells offline". Baixa a importat/v1.3: fer-ho bé
     exigeix columna de revisió a les ~6 taules de versions (cap té
     `updated_at`) + UX de conflicte, no és un hotfix.
3. **Storage sense límits**: cap bucket defineix `file_size_limit` ni
   `allowed_mime_types`, i l'INSERT de `catalog-community-photos` (v16:202) només
   exigeix el bucket — qualsevol compte autenticat pot pujar fitxers il·limitats
   (abús de cost, no de fuga: el SELECT de v66 sí gateja lectures). Fix: límits
   per bucket + convenció de ruta validada a la policy.

### Importants — dins de v1.2 o just després

4. **Sense pipeline de migracions**: 66 SQL aplicats a mà, `schema.sql` base
   desfasat (encara conté la policy oberta que v31 va eliminar — qui munti un
   entorn des de zero pot ressuscitar-la). Adoptar supabase CLI o, com a mínim,
   regenerar un bootstrap canònic i declarar l'ordre.
5. **CSP del landing bloqueja Supabase**: `connect-src` no inclou `*.supabase.co`
   però `index.html` fa fetch del comptador "Equips actius" — probablement trencat
   en silenci (el `.catch` ho amaga). Verificar a la consola i afegir l'origen.
6. **Cap retry/backoff**: un 503 transitori de Supabase es classifica com a error
   de negoci i l'operació es descarta. Afegir reintents amb backoff per a errors 5xx.
7. `record_usage_event` invocable per convidats sense límit (spam de files, cost).

## v1.2 — abast tancat

Tot el gros ja està decidit als 4 docs de redisseny; la auditoria hi afegeix els
fixos crítics i una peça de monetització. Ordre d'execució recomanat (risc
ascendent, valor immediat primer):

1. **Hotfixos de seguretat/integritat** — FET 2026-11-13: `schema_v67`
   (.ics cross-org + límits de storage) i `_resolvedVersionIds` persistit.
2. **Accessibilitat Fase A+B** (S, risc mínim): `minimumSize: Size(64,48)` als 3
   temes de botó (tota l'app passa de 40→48px tocant 1 lloc), zona tàctil de
   `_HoldToExitControl` (~20px→44px a LA pantalla de guants), `Semantics` a la
   miniatura de catàleg.
3. **Personalització** (S): `_sectionOrderForMode` als 7 modes, prompt del
   WorkModePicker al primer `hasHospital`, nudge cap a LearningPathScreen,
   arreglar la promesa trencada d'OnboardingScreen pàg. 3, confirmació a `_join()`.
4. **IA/Home Fases 1-2** (S-M): agrupació de Dreceres en Consultar/Aprendre/
   Documentar + grid 2×2; aprofitar el mateix pas per adoptar `InstriqAsyncView`
   a Inici i Xarxa de grup (2 bugs reals de confiança), `InstriqEmptyState` i
   tokens de color.
5. **Cerca unificada** (M, el més arriscat — l'últim): extreure
   `_computeSearchResults`, redirigir `/buscar`, integrar filtres de CatalogScreen.
6. **Fila "Dona suport al projecte" a Perfil** (S): 1 `InstriqListItem` +
   url_launcher cap a Patreon. Compte: a Google Play les donacions externes tenen
   restriccions de política — gate-jar per plataforma quan arribi el build de Play.
7. **Decisió pendent del propietari**: contrast de vora 1.32:1 → 3:1 (canvia el
   llenguatge visual sencer; es pot decidir ara i executar a v1.3).
8. Resoldre l'entrada "Previst" obsoleta de novedades.html (sync d'aprenentatge
   ja parcialment fet) i reactivar el registre públic de repartiment de fons
   (promès; amb Patreon torna a ser rellevant).

Cap dependència nova a tot el paquet. Estimació global: majoria S, dues M.

## v1.3 (pont) — "Confiança"

Release sense features visibles, dedicada al que fa por tocar a v2:

- **Tests on fan mal**: `SyncQueueService` i `OfflineCacheService` (la lògica més
  intricada del client, cobertura zero), + smoke E2E dels 9 fluxos mai verificats
  que llista el BACKLOG.
- **Pipeline de migracions** (punt 4) + test d'integració de les RPCs crítiques
  contra una base efímera.
- **Retry/backoff** a la cua (punt 6) i rate limiting bàsic (punt 7).
- **Detecció de conflicte d'esborranys** entre dispositius del mateix autor
  (columna de revisió a les taules de versions + avís a l'editor).
- Decisió de patró d'estat per a v2 (el singleton+ValueNotifier ja va tocar
  sostre una vegada; EPIC 1/2 multipliquen estat creuat — decidir ABANS de
  construir, no durant).

## v2.0 — direcció

**Tesi: de catàleg compartit a graf de coneixement operatiu multi-seu.**
La infraestructura social (orgs, cadenes, Biblioteca Pública, moderació) ja
existeix; el que falta és que el coneixement estigui CONNECTAT (tècnica ↔
instrumental ↔ bandeja ↔ fàrmac) i que el contingut creixi sense release.

Pilars, en ordre:

0. **Decisió de negoci prèvia (ADR-001, només el propietari)**: Visió A (SaaS
   gestionat) vs Visió B (comunitat/federació). Condiciona governança,
   monetització i prioritats de tot el que segueix. És LA decisió oberta.
1. **EPIC 1 — Knowledge Graph** (fundació declarada dels EPICs 2, 5 i 6):
   consolidar `knowledge_links`, tancar el forat tècnica↔instrumental. Habilita
   el comparador d'instruments i la futura cerca.
2. **Catàleg com a dades, no com a codi**: decidir si `instruments_data.dart`
   (16,5k L compilades, parsejades per regex pel Vademècum) passa a
   Supabase/asset descarregable. Avui és una postura de seguretat deliberada
   ("només canvia amb un commit") — a v2, amb Store de per mig (dies de
   certificació per cada alta de contingut), és el coll d'ampolla editorial.
   Si es manté compilat, assumir-ho explícitament i automatitzar el release-train.
3. **Google Play** (promesa pública pendent) + completar ADR-003 (lectura offline
   de tot el publicat).
4. **Contingut com a fossat**: campanya d'imatges (28%→60%+; les fonts lliures
   estan esgotades — el mecanisme comunitari existeix, falta priorització i
   potser recompensa via tiers de Patreon), i Consell Editorial per omplir la
   Biblioteca Pública (EPIC 9: construït però buit).
5. **Quick wins físics d'alt valor**: compartir fitxa amb enllaç profund + QR
   imprimible (caixa CSSD → checklist), comparador, bústia personal d'activitat.

**Deliberadament FORA de v2**: IA/cerca semàntica fins que ADR-002 tingui
arquitectura local/offline resolta; pàgines públiques per fàrmac (decisió de
seguretat vigent — trànsit buscant dosis); targetes de preferència entre orgs
(decisió d'abast de v65).

## Resum executiu

| Horitzó | Contingut | Naturalesa |
|---|---|---|
| Ara mateix (FET) | Hotfixos crítics: cross-org .ics, mapa d'ids del sync persistit, límits de storage | Seguretat/integritat |
| v1.2 | Redisseny ja decidit (4 docs) + monetització a Perfil + promeses públiques | UX/producte, majoria S |
| v1.3 | Tests al sync, pipeline de migracions, retry, decisió d'estat | Confiança/infra |
| v2.0 | ADR-001 → Knowledge Graph → catàleg-com-a-dades → Play → contingut | Direcció |
