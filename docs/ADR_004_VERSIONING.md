# ADR-004 · Versionat del coneixement — component genèric o quarta duplicació

**Estat d'aquest document**: **decidit (2026-08)**. Anàlisi factual dels 3 patrons de versionat ja existents (`group_documents`, `trays`, `preference_cards`) i recomanació concreta. Inclou 2 accions ja aplicades (correcció d'un bug real trobat durant la investigació + base compartida a Dart per a instàncies noves) i deixa explícitament fora d'abast la migració retroactiva de les 3 implementacions existents.

---

## 0. La pregunta

El patró capçalera+versions (`draft→in_review→published→archived`) s'ha construït 3 vegades de forma independent. Abans d'afegir-hi una 4a instància (versionat d'instrumental personalitzat / informació d'esterilització, Product Evolution del backlog), calia decidir: **extreure un component genèric, o seguir duplicant?**

## 1. Els 3 casos, comparats

| | `group_document_versions` | `tray_versions` | `preference_card_versions` |
|---|---|---|---|
| Columnes "closca" (status, author_id, approved_by, approved_at, comment, based_on_version_id, version_number, created_at) | ✅ | ✅ | ✅ |
| `UNIQUE(header_id, version_number)` | ✅ | ✅ | ❌ **falta** |
| Índex únic "només 1 publicada" | ✅ | ✅ | ❌ **falta** |
| Payload propi del tipus | `title`, `content`, `steps` (jsonb), `specialty_id` | `name`, `description`, `items` (jsonb), `photo_paths` (jsonb) | `procedure_name`, `surgeon_id` (**FK real**), `items` (jsonb), `validated_by_surgeon` |
| Sincronitza `knowledge_links` en aprovar | ✅ | ✅ | ❌ (exclòs a propòsit) |
| Notificació push en aprovar/rebutjar | ✅ (`RELEVANT_ACTIONS` a l'Edge Function) | ❌ | ❌ |
| Eliminació | RPC pròpia (`delete_group_document`, amb auditoria) | `.delete()` directe des del client | `.delete()` directe des del client |
| Extres exclusius del servei Dart | Cau offline + `SyncQueueService` | Pujada de fotos a Storage, `duplicateTray` | `setValidatedBySurgeon`, `fetchForSurgeon` (query per `surgeon_id`) |

**Troballa clau**: `preference_card_versions` li falten les dues restriccions d'unicitat que SÍ tenen les altres dues — **és un bug real de deriva per duplicació manual**, no una decisió deliberada. Es corregeix en aquest mateix tram (§4).

## 2. Per què NO una taula SQL genèrica única

El propi codi ja demostra que no funcionaria bé: `knowledge_links` existeix precisament perquè consultar/filtrar dades **dins** d'un jsonb (`tray_versions.items`, `related_instrument_ids`) no era prou bo — calia materialitzar un índex relacional derivat. `preference_card_versions.surgeon_id` és una FK real (no jsonb) perquè `fetchForSurgeon` necessita una consulta indexada `.eq('surgeon_id', ...)` entre espais de treball — ficar-ho dins un jsonb trencaria aquesta consulta o exigiria un altre índex derivat. El patró `ref_type`/`ref_id` ja provat 8+ vegades (`taggings`, `knowledge_links`, `favorites`...) funciona perquè aquelles taules són **anotacions primes** sobre una entitat, no el contingut consultable amb flux de treball propi de la pròpia entitat.

A més, els 3 casos ja divergeixen de veritat en comportament (push només per a documents, sync de `knowledge_links` només per a documents/safates, eliminació amb/sense RPC) — un component genèric hauria de tenir "forats" (hooks) per a cada divergència, cosa que en SQL/RLS de Supabase no surt més barata que repetir-ho.

**Veredicte SQL**: no es construeix cap taula ni herència genèrica. En comptes d'això:
1. Es corregeix el bug concret de `preference_card_versions` (§4) — independent de la resta d'aquest ADR.
2. Per a instàncies futures, es documenta una **recepta** (no una abstracció) — veure §5 — perquè qui construeixi la 4a/5a instància tingui una checklist en comptes de copiar i enganxar a ull.

## 3. Sí, un component compartit a Dart — però nomes per a instàncies noves

A diferència de SQL, el codi Dart de servei (`GroupDocumentService`/`TrayService`/`PreferenceCardService`) sí és ~80% còpia literal dels mateixos 10 mètodes (fetch/fetchVersionHistory/create/startEditing/saveDraft/submitForReview/approve/reject/restore/fetchReviewQueue), i les 3 pestanyes de `ReviewQueueScreen` (`_DocumentReviewQueue`/`_TrayReviewQueue`/`_PreferenceCardReviewQueue`) són gairebé duplicació exacta (mateix diàleg, mateix snackbar, mateixa targeta) — això sí és duplicació accidental, no estructural.

**Decisió**: es crea una base compartida (`VersionedContentService` mixin/classe abstracta amb els 5 mètodes de flux de treball, parametritzada per nom de taula) i un widget genèric de pestanya de revisió, **però no es retoquen els 3 serveis/pantalles ja existents i provats** — funcionen, i tocar-los ara seria refactoritzar sense necessitat (fora de l'abast d'aquesta tasca). La base nova s'usa per a la **4a instància** (custom instruments/informació d'esterilització d'organització) quan es construeixi, i queda documentada per a qui vulgui migrar-hi els 3 serveis existents en un futur EPIC separat, si mai compensa.

## 4. Bug corregit ara: `preference_card_versions`

Migració `supabase/schema_v28_preference_card_constraints_fix.sql` — afegeix `UNIQUE(card_id, version_number)` i l'índex únic parcial "només una versió publicada per targeta", exactament com ja tenen `group_document_versions`/`tray_versions`. Sense aquesta restricció, res impedia (a nivell de base de dades) que dues versions de la mateixa targeta compartissin `version_number`, o que n'hi hagués dues alhora en estat `published`.

## 5. Recepta per a la propera instància (custom instruments / informació d'esterilització d'organització)

Quan es construeixi el versionat d'instrumental personalitzat i d'informació d'esterilització **d'organització** (no de catàleg global — això últim depèn de qui aprova canvis globals, EPIC 3, encara sense resoldre):

1. Taula capçalera: `id`, `organization_id`, `workspace_id`, `created_by`, `created_at`, `published_version_id`.
2. Taula de versions: `id`, `<header>_id`, `version_number`, `status` (mateix check de 4 valors), payload propi **com a columnes reals** (mai jsonb per a res que calgui consultar/filtrar/indexar), `author_id`, `comment`, `based_on_version_id`, `approved_by`, `approved_at`, `created_at`.
3. **Obligatori des del primer dia**: `UNIQUE(<header>_id, version_number)` + índex únic parcial `where status='published'` — el bug de §4 no es torna a repetir.
4. RPC `create_/submit_.../approve_/reject_/restore_` seguint exactament el flux dels 3 casos existents; decidir explícitament (no per omissió) si aquesta instància necessita sync de `knowledge_links`, notificació push, i RPC d'eliminació amb auditoria — no assumir que "no cal" perquè els altres 3 casos no ho tenen tots.
5. Servei Dart: estendre la nova base compartida (§3) per als 5 mètodes de flux de treball; afegir com a extensió pròpia només allò que sigui genuïnament diferent.
6. UI de revisió: reutilitzar el widget genèric de pestanya (§3) en comptes de crear una 4a classe `_XReviewQueue` quasi-idèntica.

## 6. Impacte i relació amb altres ADR/EPICs

* **ADR-001**: la referència upstream (Opció C) i l'estat `Sync Status` que proposa haurien de viure a la mateixa taula de versions d'aquesta recepta (`Source`/`Parent`/`Sync Status` com a columnes addicionals), no en una estructura separada.
* **EPIC 9 (Biblioteca Pública)**: si acaba reutilitzant `group_documents`/`trays` amb `visibility` (idea anotada a ADR-001 §0) enlloc de taules `public_*` noves, ja hereta automàticament aquesta recepta — no cal repensar-la.
* **EPIC 3 (CSSD)**: versionar dades de catàleg GLOBAL (no d'organització) segueix bloquejat per la mateixa pregunta de sempre (qui aprova) — aquesta recepta és per a dades d'organització, no la resol.

## 7. Classificació

| Apartat | Estat | Canvi necessari |
|---|---|---|
| Restriccions d'unicitat de `preference_card_versions` | **Corregit (2026-08)** | Cap — ja aplicat |
| Component SQL genèric | Descartat deliberadament | Cap — recepta documentada enlloc d'abstracció |
| Base compartida Dart (`VersionedContentService` + widget de revisió genèric) | No implementat encara | Es crea quan es construeixi la 4a instància (custom instruments) |
| Retro-migrar els 3 serveis existents a la base compartida | No implementat, no recomanat ara | Futur EPIC separat, només si compensa |
| Versionat d'instrumental personalitzat / esterilització d'organització | No implementat | Seguir la recepta de §5 |
| Versionat de dades de catàleg global | Bloquejat | Depèn d'EPIC 3 / qui aprova canvis globals |
