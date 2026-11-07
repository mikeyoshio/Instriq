# Pla de redisseny de navegació — v1.2 (Home + IA, planificació)

> Tasca de **planificació**, no d'implementació. Objectiu del propietari, amb les seves paraules: fer la visualització més fàcil, que navegar i cercar es senti modern i còmode, **sense sacrificar rendiment**. No es toca cap pantalla en aquest tram — només aquest document. Basat en lectura real del codi (`lib/screens/home_screen.dart` sencer, `lib/navigation/`, `lib/design_system/`, grep de `lib/screens/`), no en suposicions. Mateix esperit que `docs/landing_redesign_phase2.md`: concret, amb l'evidència citada, amb els trade-offs explícits.

---

## 0. Troballa principal (per no enterrar-la)

**El problema no és "falta un sistema de navegació modern" — ja existeix i funciona.** `lib/navigation/router.dart` + `lib/navigation/app_shell.dart` ja implementen una `StatefulShellRoute.indexedStack` de go_router amb 5 destins fixos (`NavigationBar` en mòbil, `NavigationRail` en pantalla ampla ≥840px): **Inici · Cercar · Biblioteca · Activitat · Perfil**. `LibraryScreen` i `ProfileHubScreen` ja agrupen el seu contingut per seccions amb `InstriqSectionHeader`. El problema real, confirmat llegint `home_screen.dart` sencer (1211 línies), és:

1. La pestanya **"Inici" conté una secció "Dreceres" (`_buildQuickAccessSection`) que és una única llista vertical plana de fins a 13 `InstriqListItem`**, sense cap agrupació visual ni jerarquia — tot al mateix nivell, mateixa mida d'icona, mateix pes tipogràfic.
2. **Hi ha accessos duplicats a la mateixa pantalla des de llocs diferents del shell** (detallat a §1.5) — no és "massa contingut", és contingut no organitzat i repetit.
3. **Ja existeix una cerca global potent** (`_computeSearchResults` a `home_screen.dart`, 9 tipus d'entitat) amagada dins l'camp de cerca d'Inici, mentre la pestanya "Cercar" del shell obre només `CatalogScreen` (cerca d'instruments, no de tot). És un desaprofitament del que ja hi ha, no una funcionalitat que calgui construir.

La recomanació principal (§3-4) és, doncs, **reorganitzar i consolidar amb els components i el shell que ja existeixen**, no construir cap sistema de navegació nou.

---

## 1. Estat actual (evidència)

### 1.1 Shell de navegació real

`lib/navigation/router.dart` — `GoRouter` amb `initialLocation: '/inicio'`, 1 ruta fora del shell (`/invite/:token`) i 5 branques dins de `StatefulShellRoute.indexedStack`:

| # | Ruta | Pantalla | Icona |
|---|---|---|---|
| 0 | `/inicio` | `HomeScreen` | `home_outlined` |
| 1 | `/buscar` | `CatalogScreen` | `search_outlined` |
| 2 | `/biblioteca` | `LibraryScreen` | `local_library_outlined` |
| 3 | `/actividad` | `ActivityScreen` | `notifications_outlined` |
| 4 | `/perfil` | `ProfileHubScreen` | `person_outline` |

`lib/navigation/app_shell.dart`: `NavigationBar` (<840px) o `NavigationRail` (≥840px), amb `WorkModeHeader` (52px, nom d'organització + selector de mode de treball, amagat sense hospital) sempre visible per sobre del contingut de la branca activa. La pestanya "Activitat" s'amaga si `!isAdmin && !canApproveAnyWorkspace` (`_activityBranchIndex`).

**No cal dissenyar cap bottom nav nou: ja hi és, ja és responsive (nav bar ↔ nav rail), i ja amaga pestanyes segons rol.**

### 1.2 Inventari real de "Dreceres" (Inici, sense cerca activa)

Llegit sencer de `_buildQuickAccessSection` (`home_screen.dart:881-1012`). Llista única, sense subcapçaleres, ordre fix:

| # | Ítem | Visible per a | Destí |
|---|---|---|---|
| 1 | Ruta d'aprenentatge | tothom | `LearningPathScreen` |
| 2 | Catàleg | tothom | `CatalogScreen` |
| 3 | Vademècum de fàrmacs | tothom | `DrugCatalogScreen` |
| 4 | Tancament de ferides | tothom | `WoundClosureCatalogScreen` |
| 5 | Esterilització (referència) | tothom | `SterilizationReferenceCatalogScreen` |
| 6-7 | Tècniques, Bandeixes | amb hospital connectat | `GroupDocumentListScreen`/`TraysScreen` |
| 8-9 | Fitxes de preferència, Protocols | amb hospital connectat | `PreferenceCardsScreen`/`GroupDocumentListScreen` |
| 10 | Agenda quirúrgica | amb hospital connectat | `SurgicalAgendaScreen` |
| 11 | Xarxa de grup | amb hospital **i** cadena (`hasGroup`) | `GroupNetworkScreen` |
| 12 | Aprèn (flashcards/quiz) | tothom | `LearnScreen` |
| 13 | El meu progrés | tothom | `ProgressScreen` |

En mode "Cirurgià" els ítems 6-10 canvien d'ordre (preferència+protocols primero) — única personalització existent, via `_sectionOrderForMode`/el bloc `mode == WorkMode.cirujano ? [...] : [...]`.

**Per tant: entre 7 (convidat) i 13 (soci d'una organització amb cadena) files idèntiques en pes visual, en una sola columna.** A ~76-84px per fila (icona 28px + 2 línies de text + padding `InstriqSpacing.lg`=16 + separador `sm`=8), només "Dreceres" ja ocupa ~1000-1150px de scroll en mòbil, abans de qualsevol altra secció.

### 1.3 Altres seccions d'Inici (condicionals, per sobre o per sota de Dreceres segons `_sectionOrderForMode`)

- **Pendents d'aprovar** (`_buildPendingApprovalSection`) — només admin/approver, fins a 5 ítems + "Veure-ho tot".
- **Safates per preparar** (`_buildTrayPrepSection`) — només mode Instrumentista, fins a 5.
- **Progrés de l'equip** (`_buildTeamProgressSection`) — només mode Docent + rol d'aprovació, 1 enllaç.
- **Activitat recent** (`_buildRecentSection`) — usuari autenticat, fins a 8.
- **Favorits** (`_buildFavoritesSection`) — usuari autenticat, sense límit, agrupats per tipus.

Pitjor cas real (admin en mode Supervisió, hospital+cadena, amb pendents i favorits): **Pendents d'aprovar + 13 Dreceres + Recents + Favorits**, tot en un únic `SingleChildScrollView` vertical (`_buildDefaultBody`, línia 875).

### 1.4 Cerca ja existent (reutilitzar, no reinventar)

El camp de cerca d'Inici (`TextField` a `build()`, línia 674) ja crida `_computeSearchResults` (línia 544), que filtra en client **9 tipus d'entitat alhora**: instruments de catàleg, tècniques, protocols, safates, instrumental personalitzat, instrumental de Biblioteca Pública, fabricants, cirurgians i etiquetes — amb `fuzzyContains` (`lib/utils/fuzzy_match.dart`, sense dependència externa) i debounce de 150ms (`_liveSearchDebounce`) ja afinat per rendiment (comentari explícit a la línia 176-180 sobre per què cal el debounce). Els resultats es renderitzen amb `ListView.builder` + `InstriqSectionHeader` per tipus (línies 744-855) — **exactament el patró de "llista agrupada per seccions" que aquest pla recomana estendre a Dreceres** (§3.2).

La pestanya "Cercar" del shell, en canvi, **no usa res d'això**: obre `CatalogScreen`, que només cerca dins del catàleg d'instruments (`matchesInstrumentFilters`, `catalog_screen.dart:22`) amb filtres de categoria/especialitat propis. Són dues cerques diferents amb abast diferent sota noms que suggereixen el mateix.

### 1.5 Duplicacions detectades (evidència, no suposició)

| Contingut | Accessible des de | Fitxers |
|---|---|---|
| Catàleg d'instruments | Dreceres (#2) **i** pestanya "Cercar" (`/buscar`) | `home_screen.dart:951-958`, `router.dart:51` — mateix `CatalogScreen` |
| El meu progrés | Dreceres (#13) **i** Perfil → "Preferències" | `home_screen.dart:1002-1009`, `profile_hub_screen.dart:257-258` — mateix `ProgressScreen` |
| Tècniques, Bandeixes, Protocols, Fitxes de preferència | Dreceres (#6-9) **i** Biblioteca → "Les meves col·leccions" | `home_screen.dart:883-917`, `library_screen.dart:121-186` — mateixos destins, resolts amb la mateixa lògica d'espai (`_openWorkspaceCollection` vs `_openCollection`) |

`LibraryScreen` ja fa, per a 5 col·leccions de grup (hi afegeix Instrumental personalitzat, que Dreceres no té), exactament el que Dreceres intenta fer per a 4 d'elles — amb capçaleres de secció (`InstriqSectionHeader`) que Dreceres no té. No calen pantalles noves: **cal decidir on viu cada cosa un sol cop** (§3.3, i és una de les decisions obertes de §8).

### 1.6 Design system disponible (construir-hi a sobre, no reinventar)

`lib/design_system/`:
- **Tokens** (`tokens.dart`): `InstriqColors` (accent teal fix, no `colorSchemeSeed`), `InstriqSpacing` (escala 4/8/12/16/24/32/48, cap número solt), `InstriqRadius` (8/12/16), `InstriqBreakpoints` (`tablet`=840, `desktop`=1280, `maxContentWidth`=720, `dashboardWideGrid`=1500), `InstriqTypography` (Manrope per a títols, Inter per a cos — ja carregades, 0 fonts noves).
- **Components reutilitzables**: `InstriqListItem` (icona+títol+subtítol+chevron, usat ja a Inici/Biblioteca/Activitat/Perfil), `InstriqSectionHeader` (etiqueta majúscules, `letterSpacing: 1.1`), `InstriqSurface` (reemplaça `Card`: vora d'1px + radi, sense ombra Material — ja és el llenguatge visual pla/sobri de tota l'app), `InstriqBadge`, `InstriqCountBadge`, `InstriqResponsiveContent` (centra contingut a `maxContentWidth` en pantalla ampla, no-op en mòbil).
- **Precedent directe de graella de targetes ja construït**: `HomeDashboardPanel` (`lib/screens/home_dashboard_panel.dart`, substitueix Dreceres en escriptori ample ≥1280px per a admins) ja fa un `Wrap` de `_DashboardTile` (targeta `Card` amb icona+títol+contingut+enllaç) amb 2-3 columnes segons amplada. **És exactament el patró visual que aquest pla proposa portar a mòbil per a Dreceres** (§4.2) — no cal inventar cap component nou, cal generalitzar-ne un que ja existeix i ja es construeix (`cols = constraints.maxWidth >= dashboardWideGrid ? 3 : 2`).

### 1.7 Rendiment ja resolt, a respectar

- `cached_network_image` ja gestiona totes les fotos (catàleg, comunitat) — cap re-descàrrega en fred (`CHANGELOG.md:46`).
- Debounce de 150ms en cerca en viu + 500ms en analítica de cerca, deliberat i documentat al propi codi (`home_screen.dart:170-181`).
- `ListView.builder` (no `ListView(children: [...])`) als resultats de cerca per no construir desenes d'ítems de cop (`home_screen.dart:743-746`).
- `InstriqResponsiveContent` ja resol "no estirar de vora a vora en escriptori" sense cap `LayoutBuilder` per pantalla.
- Cap paquet d'icones, animació ni UI extern: tot Material `Icons.*` + `flutter/material.dart`.

**Cap d'aquestes garanties es toca en aquest pla.** Qualsevol proposta de §3-4 reusa `ListView`/`Wrap`/`InstriqSurface` existents — res que introdueixi un nou re-render global, una nova crida de xarxa a cada frame, ni una animació costosa.

---

## 2. Diagnòstic (en una frase per punt)

1. Dreceres és una llista plana de 7-13 ítems sense agrupació — l'usuari ha d'escanejar-ho tot per trobar-ne un.
2. 3 blocs de contingut (catàleg, progrés, col·leccions de grup) tenen **2 camins diferents** cap al mateix destí, sense que cap sigui "el" camí canònic.
3. La pestanya "Cercar" del shell no és la cerca potent que ja existeix (la d'Inici) — és un nom que promet més del que la pantalla fa.
4. No hi ha cap jerarquia visual dins de Dreceres: un ítem molt usat (Catàleg) pesa visualment igual que un de nínxol (Xarxa de grup, només per a qui té cadena).
5. El Design System ja té el vocabulari (tokens, `InstriqSurface`, el patró de graella de `HomeDashboardPanel`) per resoldre 1 i 4 sense dependències noves.

---

## 3. Arquitectura d'informació proposada

### 3.1 Mantenir els 5 destins fixos del shell tal qual

Inici · Cercar · Biblioteca · Activitat · Perfil ja cobreixen una IA de nivell superior raonable (vista general / cerca / contingut d'equip / cua de treball / compte). **No es proposa cap pestanya nova ni eliminar-ne cap** — Activitat ja es correctíssimament oculta per a qui no en té ús. Canviar aquest nivell ara seria refer feina de "Nivell 2 — navegació" del Design System (`docs/BACKLOG.md:71`), ja feta i estable.

### 3.2 Reagrupar Dreceres en blocs amb capçalera, no una llista plana

Mateix patró que `_buildSearchResults` ja usa (`addSection(title, items)`, `home_screen.dart:748-757`): agrupar, no aplanar. Proposta de blocs (reutilitzant el llenguatge d'IA ja aprovat pel propietari al landing — `docs/landing_redesign_phase2.md:34-37` — per coherència entre landing i app, no per casualitat):

- **Consultar** (sempre visible, sense compte): Catàleg, Vademècum de fàrmacs, Tancament de ferides, Esterilització.
- **Aprendre** (sempre visible): Ruta d'aprenentatge, Aprèn (flashcards/quiz), El meu progrés.
- **Documentar** (només amb hospital connectat): Tècniques, Protocols, Bandeixes, Fitxes de preferència, Agenda quirúrgica.
- **Equip** (només amb cadena, `hasGroup`): Xarxa de grup — 1 sol ítem, no justifica secció pròpia; candidat a §8 (decisió oberta: fusionar-lo dins "Documentar" o deixar-lo fora de Dreceres i accessible només des de Biblioteca/Perfil).

Cost: **gratuït** — és reordenar literals dins del mateix `Column`, intercalant `InstriqSectionHeader` entre blocs, exactament com ja fa `_buildSearchResults`.

### 3.3 Consolidar els 3 duplicats de §1.5 (decisió pendent de quin costat guanya)

Per a cadascun, 2 opcions, cap decidida aquí (veure §8):

- **Catàleg**: (a) treure'l de Dreceres i confiar que la pestanya "Cercar" ja hi porta, o (b) deixar-lo a Dreceres perquè és l'accés més usat i no tothom associa "Cercar" amb "catàleg d'instruments".
- **El meu progrés**: (a) treure'l de Dreceres (ja és a Perfil → Preferències), o (b) deixar-lo perquè "progrés" és contingut de consulta freqüent, no de configuració, i Perfil és conceptualment "compte", no "el meu rendiment".
- **Tècniques/Protocols/Bandeixes/Fitxes de preferència**: (a) treure-les de Dreceres i deixar que "Documentar" a Inici sigui només un enllaç a Biblioteca (1 ítem, "Les meves col·leccions"), o (b) mantenir-les a Dreceres com a drecera real i deixar Biblioteca com el lloc "d'inventari complet" (hi afegeix Instrumental personalitzat i "El meu grup").

### 3.4 Cerca: fer de "Cercar" la cerca real, no el catàleg

Extreure `_computeSearchResults`/`_SearchResults`/`_buildSearchResults` de `home_screen.dart` a un servei o widget compartit (p.ex. `lib/widgets/global_search.dart` o un `GlobalSearchService`), i:
- Inici el manté igual (cerca inline, mateix comportament d'avui).
- La pestanya "Cercar" (`/buscar`) hi passa a apuntar en comptes d'a `CatalogScreen` — amb el filtre de categoria/especialitat de `CatalogScreen` com una pestanya/filtre més dins d'aquesta cerca unificada, no eliminat.

Cost: **cheap** — és moure codi Dart ja escrit i provat (cap algorisme nou, cap dependència nova), però toca 2 pantalles i el router, per això va a una fase pròpia (§6, Fase 3) i no a la Fase 1.

---

## 4. Canvis visuals/interacció concrets

### 4.1 Capçaleres de secció dins Dreceres (§3.2)

`InstriqSectionHeader` per bloc, `InstriqSpacing.xl` (24px) entre blocs en comptes de `sm` (8px) entre ítems solts — ja és la mateixa escala que separa seccions avui (`_buildDefaultBody` ja posa `InstriqSpacing.xl` entre `Pendents`/`Dreceres`/`Recents`/`Favorits`; només cal aplicar-la també *dins* de Dreceres).

### 4.2 Graella de targetes 2 columnes per al bloc "Consultar" en mòbil (inspirat en `HomeDashboardPanel`, §1.6)

Els 4 ítems de "Consultar" (Catàleg, Fàrmacs, Tancament de ferides, Esterilització) són els de contingut de referència pur (sense estat, sense dades personals) — bons candidats a una graella 2×2 de targetes compactes (icona gran + títol, sense subtítol) en comptes de 4 files completes d'`InstriqListItem`. Reaprofita `InstriqSurface` + `Wrap` amb `tileWidth = (amplada - gap)/2`, el mateix càlcul que ja fa `HomeDashboardPanel._buildTiles` per a 2-3 columnes. "Aprendre" i "Documentar" es queden com a llista (`InstriqListItem`) perquè alguns dels seus ítems sí porten subtítol/estat útil (p.ex. bandeixes "per preparar").

Cost: **cheap** — `Wrap`+`InstriqSurface` ja existeixen, només cal una targeta més senzilla que `_DashboardTile` (sense `Future`/stat, estàtica).

### 4.3 Iconografia: cap canvi de llibreria

Totes les icones actuals ja són `Icons.*` (Material). Cap proposta d'aquest pla necessita una icona que no existeixi ja a Material Icons — **no s'afegeix cap paquet d'icones**.

### 4.4 Bottom nav: no es toca

Ja és `NavigationBar`/`NavigationRail` responsiu (§1.1). Cap canvi proposat aquí.

### 4.5 Sense animacions nous

Cap transició, `Hero`, ni `AnimatedContainer` nou proposat. Les targetes de §4.2 es pinten estàtiques, igual que `_DashboardTile` avui (cap animació a l'entrada/sortida).

---

## 5. Cost per proposta (per triar sempre el més barat primer)

| Proposta | Cost | Per què |
|---|---|---|
| Agrupar Dreceres amb `InstriqSectionHeader` (§3.2, §4.1) | **Gratuït** | Reordenar widgets existents, reusar `addSection` ja escrit a `_buildSearchResults` |
| Decidir i eliminar els 3 duplicats (§3.3) | **Gratuït–cheap** | Esborrar codi (menys `build()`, no més); l'únic cost és decidir quin costat es queda (§8) |
| Graella 2×2 per a "Consultar" (§4.2) | **Cheap** | `Wrap`+`InstriqSurface` ja existents; nova classe de targeta petita, sense `Future`/estat |
| Extreure cerca global a servei compartit + redirigir "Cercar" (§3.4) | **Cheap** | Codi Dart ja escrit i provat, moure'l no reescriure'l; toca router + 2 pantalles |
| Qualsevol compressió d'imatges/icones noves, paquet d'il·lustració, Lottie, etc. | **No proposat** | Fora d'abast — regressió de pes/rendiment, cap necessitat detectada |

Ordre d'execució recomanat: sempre gratuït abans que cheap (§6).

---

## 6. Fases d'implementació (per a una sessió futura)

### Fase 1 — Agrupació sense tocar destins ni rutes
- Dividir `_buildQuickAccessSection` en sub-mètodes per bloc (`_buildConsultarBlock`, `_buildAprendreBlock`, `_buildDocumentarBlock`) amb `InstriqSectionHeader` entre ells.
- Aplicar la decisió presa a §8.1-8.3 sobre quins dels 3 duplicats s'eliminen de Dreceres.
- Cap canvi de router, cap pantalla nova.

### Fase 2 — Graella de targetes per al bloc "Consultar" en mòbil
- Nou widget petit (p.ex. `_QuickAccessTile`, inspirat en `_DashboardTile` sense `Future`) + `Wrap` 2 columnes.
- Mantenir el mateix bloc com a llista (`InstriqListItem`) en pantalla ampla si `HomeDashboardPanel` ja hi mostra el panell d'escriptori (evitar duplicar dues graelles diferents per al mateix contingut a la mateixa amplada).

### Fase 3 — Cerca unificada a la pestanya "Cercar"
- Extreure `_SearchResults`/`_computeSearchResults`/`_buildSearchResults` a un lloc compartit.
- Redirigir `/buscar` cap a la cerca unificada; integrar els filtres de categoria/especialitat de `CatalogScreen` com a filtre dins d'aquesta cerca (no eliminar-los).
- És la fase de més risc d'integració (toca router + 2 pantalles ja en producció) — recomanat fer-la per separat, amb el seu propi cicle de verificació complet.

Cap fase introdueix una dependència nova a `pubspec.yaml`.

---

## 7. Verificació després de cada fase

- `flutter analyze` i `flutter test` nets (0 avisos, 0 fallades) — no negociable, igual que la resta del projecte.
- Passada en viu amb Playwright contra `flutter build web` servit en local (mateix criteri que la migració de go_router, `docs/BACKLOG.md:21`): comprovar que les 5 pestanyes carreguen, que Dreceres mostra els blocs correctes segons rol/mode (convidat, usuari amb hospital, admin en mode Supervisió/Instrumentista/Docent/Cirurgià), captures de pantalla abans/després.
- Sense regressió de temps de càrrega percebut d'Inici: mateix nombre de crides de xarxa que avui (`_loadGroupContent`/`_loadRecentAndFavorites` no es toquen, només com es pinta el resultat).
- Verificar explícitament que el debounce de cerca (150ms/500ms) i `cached_network_image` seguixen intactes després de la Fase 3 (és la fase que toca codi de cerca).
- Comprovar responsive real a 3 amplades (mòbil <840px, tablet 840-1280px, escriptori ≥1280px amb `HomeDashboardPanel`) — no assumir-ho, igual que l'auditoria d'accessibilitat/responsive ja feta (`docs/BACKLOG.md:81`) va trobar que cap pantalla limitava l'amplada abans d'`InstriqResponsiveContent`.

---

## 8. Decisions preses pel propietari (2026-11-07 — ja no estan obertes)

1. **Catàleg a Dreceres i a "Cercar" alhora → es manté als dos llocs.** Més fàcil de descobrir per a algú nou; no tothom associa "Cercar" amb el catàleg.
2. **"El meu progrés" a Dreceres i a Perfil alhora → es treu de Dreceres.** Es queda només a Perfil → Preferències; és contingut "sobre el compte", no una consulta diària.
3. **Tècniques/Protocols/Bandeixes/Fitxes de preferència → es mantenen com a drecera directa a Inici.** És el contingut més usat del dia a dia per a qui ja té hospital connectat; forçar un pas extra via Biblioteca alentiria el cas més freqüent. El bloc "Documentar" es queda amb els 5 ítems.
4. **"Xarxa de grup" → dins del bloc "Documentar"**, no una secció pròpia (no la justifica un sol ítem) ni fora de Dreceres.
5. **Fase 3 (cerca unificada a "Cercar") → aprovada, entra dins l'abast de la 1.2.** És el canvi més visible del pla (la pestanya deixa de ser "el catàleg" i passa a ser cerca real entre tot).
6. **Personalització per mode de treball → s'estén a tots els modes**, no només Cirurgià. Instrumentista veu "Documentar" (bandeixes) primer, Docent veu "Aprendre"/progrés de l'equip primer, etc. — mateix criteri que ja prioritza seccions a altres parts d'Inici.

Amb això, les 3 fases de §6 passen de "proposta" a "abast confirmat" -- la feina pendent real és aprofundir el COM (disseny visual/interacció, personalització real més enllà de l'ordre de blocs, accessibilitat), no el QUÈ. Veure §10.

---

## 9. Fora d'abast d'aquest pla

- Qualsevol canvi a `catalog_screen.dart`, `library_screen.dart`, `profile_hub_screen.dart` o al router més enllà del descrit a la Fase 3 — aquest document no els toca, només els llegeix com a evidència.
- Redisseny del landing (`landing/index.html`) — ja té el seu propi pla a `docs/landing_redesign_phase2.md`/`landing_redesign_phase5_informe.md`, és un artefacte diferent (web pública, no l'app Flutter).
- Cerca semàntica/IA (EPIC 5 part semàntica, EPIC 6) — bloquejada per ADR-002, no relacionada amb aquest redisseny visual.
- Qualsevol dependència nova (paquet d'icones, animació, disseny) — explícitament descartat; tot el proposat es construeix amb el que ja hi ha a `pubspec.yaml` i `lib/design_system/`.
