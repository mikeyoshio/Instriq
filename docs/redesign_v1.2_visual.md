# Disseny visual i d'interacció — v1.2 (aprofundiment sobre el pla de Home + IA)

> Aquest document **no és un segon pla d'informació arquitectura**: `docs/redesign_v1.2_plan.md` ja és l'abast aprovat pel propietari (§8), inclosos tots els "qué" (catàleg duplicat a Dreceres i Cercar, "el meu progrés" fora de Dreceres, Documentar amb 5+1 ítems incloent Xarxa de grup, cerca unificada aprovada, personalització per mode estesa a tots els modes). Res d'això es discuteix ni es repeteix aquí. El que segueix és **l'aprofundiment del "com" visual/interacció** que el pla principal deixa deliberadament lleuger (ell mateix ho diu a §10): jerarquia tipogràfica, ritme d'espaiat, estats de càrrega/buit/error, consistència de mode fosc i micro-interaccions acceptables sota el mateix pressupost de rendiment (§5 del pla principal, no es toca). **No tracta personalització ni accessibilitat** — dos agents germans cobreixen això per separat als seus propis documents.

Metodologia: lectura sencera de `lib/design_system/` (16 fitxers), `lib/screens/home_screen.dart` (1211 línies) i `lib/screens/home_dashboard_panel.dart` (562 línies) sencers, més `catalog_screen.dart`, `library_screen.dart`, `tray_detail_screen.dart` i `group_network_screen.dart` (412 línies, sencer) com a mostra de com es tracten avui càrrega/buit/error fora d'Inici, i grep de `docs/CHANGELOG.md` per treballa previ de mode fosc.

---

## 0. Troballa principal

**L'app ja té la resposta correcta a "càrrega/buit/error": `InstriqAsyncView` (`lib/design_system/components/instriq_async_view.dart`).** És un contracte net (spinner centrat → si falla, icona d'error + missatge + botó de reintent explícit → si és buit, `emptyBuilder` del punt de crida → si no, el contingut) i ja l'adopten 11 pantalles de detall/ús i les 5 cues de revisió (via `InstriqReviewQueue`/`InstriqVersionHistory`). **El problema no és que falti disseny, és que les pantalles que aquest redisseny toca de ple — `home_screen.dart` i `group_network_screen.dart` (que entra dins del bloc "Documentar" per decisió §8.4) — no l'usen.** En comptes d'això, hi ha **3 patrons diferents reinventats** dins d'aquests mateixos fitxers, cap tan bo com el que ja existeix: dos d'ells converteixen silenciosament un error de xarxa real en "no hi ha res" (el mateix bug que el comentari de classe d'`InstriqAsyncView` diu explícitament que ve a evitar). Abans d'afegir cap floritura visual nova, el moviment de més valor és acabar d'adoptar el que ja hi ha, exactament a les pantalles que ja estan en abast.

---

## 1. Estat actual (evidència)

### 1.1 Jerarquia tipogràfica i ritme d'espaiat disponibles

`InstriqTypography.textTheme` (`tokens.dart:108-216`) ja dona 3 nivells clarament diferenciats i ja en ús a Dreceres avui:
- `titleMedium` (Inter 16/600) — títol de cada `InstriqListItem` (`instriq_list_item.dart:43`).
- `bodySmall` (Inter 12/400, color `onSurfaceVariant`) — subtítol de `InstriqListItem` (`instriq_list_item.dart:46`).
- `labelMedium` + `letterSpacing: 1.1` + majúscules — `InstriqSectionHeader` (`instriq_section_header.dart:12-18`).

`InstriqSpacing` (`tokens.dart:48-58`, escala 4/8/12/16/24/32/48) ja s'usa avui amb el mateix criteri que el pla principal proposa formalitzar: `sm` (8px) entre ítems solts, `xl` (24px) entre seccions (`home_screen.dart:872`, `_buildDefaultBody`). És a dir: **el vocabulari de 3 nivells tipogràfics + 2 nivells d'espaiat que calen per a les seccions de Dreceres (§3.2/§4.1 del pla principal) ja existeix i ja es fa servir correctament fora de Dreceres** — no cal inventar cap mida ni pes nou, només aplicar-los també *dins* de Dreceres (cosa que el pla principal ja diu).

Detall no cobert pel pla principal: `InstriqRadius`/`CardThemeData` (`instriq_theme.dart:64-72`) ja donen a qualsevol `Card` de Material el mateix radi+vora+`elevation: 0` que `InstriqSurface` — és a dir, **un `Card` cru i un `InstriqSurface` es veuen pràcticament idèntics avui** (mateix llenguatge de "vora plana"). La inconsistència real no és el contenidor, és **la fila de dins**: un `ListTile` per defecte (usat a `group_network_screen.dart`, vegeu §1.3) i un `InstriqListItem` (icona 28px, `InstriqSpacing.lg`=16 de padding, `titleMedium`+`bodySmall`) no comparteixen ni mida d'icona ni escala tipogràfica — són dues "famílies de fila" visualment diferents convivint a la mateixa app.

### 1.2 Mode fosc: sistema explícit, amb bypass puntuals

`InstriqColors` declara parells `*Light`/`*Dark` explícits (no `colorSchemeSeed`) i `InstriqTheme._build` (`instriq_theme.dart:49-104`) construeix un `ColorScheme` complet per a cada mode; `main.dart:178-191` ho connecta amb `ThemeMode` + `theme`/`darkTheme` — és un sistema madur, no un afegit.

Trobat durant la lectura: **3 punts a `group_network_screen.dart` (línies 64, 135, 210) pinten l'error amb `Colors.red` literal** (`Text(_error!, style: const TextStyle(color: Colors.red))`) en comptes de `Theme.of(context).colorScheme.error` — que en mode fosc és `InstriqColors.errorDark` (`0xFFFFB4AB`, pensat per contrastar amb un fons fosc), no el vermell Material per defecte. És exactament la pantalla que la decisió §8.4 del pla principal fusiona dins del bloc "Documentar" — val la pena corregir-ho en el mateix pas. Mateixa classe de bypass, fora del nucli d'aquest document però de la mateixa família, a `instriq_version_diff.dart:144,150,154,182-183,198-201` (`Colors.green`/`Colors.red`/`Colors.grey` literals als diffs de tècniques/bandeixes/fitxes) — una sola passada de "substituir colors Material literals per `scheme.error`/`statusPublished`/`outline`" podria resoldre totes dues famílies alhora.

CHANGELOG: totes les entrades sobre "clar/fosc" (`docs/CHANGELOG.md:260-261,278,283`) són verificacions de **`landing/index.html`** (la web pública), no de l'app Flutter — un artefacte diferent, fora d'abast (pla principal §9). **No hi ha cap auditoria prèvia de mode fosc de les pantalles de l'app**: aquesta troballa és terreny nou, no repeteix cap feina ja feta.

### 1.3 Estats de càrrega/buit/error: inventari real (4 patrons, no 1)

**Patró A — `InstriqAsyncView` (el bo, ja existent):** spinner centrat → icona `error_outline` 40px + missatge + `InstriqButton.secondary` de reintent (`instriq_async_view.dart:66-88`) → `emptyBuilder` del punt de crida. Usat per 11 pantalles de detall (`specialty_detail_screen.dart`, `manufacturer_detail_screen.dart`, `tag_detail_screen.dart`, `surgeon_detail_screen.dart`, `contributor_public_profile_screen.dart`, `incident_capa_queue_screen.dart`, `review_inbox_screen.dart`) i, indirectament, per les 5 cues de revisió i l'historial de versions (`instriq_review_queue.dart`, `instriq_version_history.dart`). **Però en els ~15 punts de crida revisats, l'`emptyBuilder` és sempre el mateix `Center(Padding(Text(...)))` sense cap icona** (p. ex. `group_document_review_queue_screen.dart:140-143`, `public_library_review_queue_screen.dart:69-70`, `manufacturer_detail_screen.dart:80-85`, `tag_detail_screen.dart:85`) — consistent entre si, però visualment pla a totes les 15 pantalles alhora.

**Patró B — `home_screen.dart`, 4 variants diferents dins del mateix fitxer:**

| Secció | Càrrega | Buit | Error |
|---|---|---|---|
| `_buildPendingApprovalSection` (1014-1055) | `CircularProgressIndicator` centrat amb `Padding` (1037-1041) | — | **Cap**: si `_fetchPendingApprovals` (1112-1120, sense `try/catch`) falla, `snapshot.hasError` és `true` però el codi només mira `snapshot.data ?? []` (1024); amb la llista buida i `connectionState == done`, la secció sencera desapareix (1025-1027) — **un error de xarxa real és indistingible de "no hi ha res pendent"**, exactament el bug que el comentari de classe d'`InstriqAsyncView` diu que ve a evitar. |
| `_buildTrayPrepSection` (1060-1088) | **Cap**: si `_loadingGroupContent`, retorna `null` (1061) — la secció no es veu mentre carrega, no hi ha spinner | Retorna `null` si `_traysNeedingPrep()` és buit (1063) | Mateix buit silenciós: si `_loadGroupContent` (241-357, tot embolcallat en `try/catch` que empassa l'error, p. ex. 354-356) falla, `_trays` es queda buit per sempre i aquesta secció simplement no apareix mai — igual que si l'organització no tingués cap safata. |
| `_buildRecentSection` (1122-1151) | `CircularProgressIndicator` centrat, sense `Padding` (1124-1133) — una 3a variant visual de spinner, diferent de la de Pendents | Retorna `null` (1134) | (sense distinció d'error, mateix fons silenciós) |
| `_buildFavoritesSection` (1167-1210) | **Cap**: retorna `null` si `_loadingRecentFavorites` (1169) | Retorna `null` (1170) | (ídem) |
| `_buildSearchResults` (730-855) | — | **L'única secció d'Inici amb un missatge de buit real**: `Center(Text(l10n.homeNoResultsForQuery(_query)))` (734-741) | — |

Resultat: **5 seccions, 4 comportaments de càrrega diferents, cap missatge d'error enlloc d'Inici.**

**Patró C — `home_dashboard_panel.dart`, un 3r contracte independent:** `_DashboardTile` (485-562) rep `loading`/`errorText`/`child` com a paràmetres separats i **sí que mostra l'error** (`Text(errorText!, color: theme.colorScheme.error)`, 540-541) — més correcte que el Patró B en això, però encara reinventa el que `InstriqAsyncView` ja resol, amb un tractament visual diferent (sense icona, sense botó de reintent, només text en color d'error).

**Patró D — `group_network_screen.dart`, el mateix patró casolà repetit 3 vegades al mateix fitxer:** `_GroupNetworkScreenState` (28-90), `_GroupNetworkWorkspacesScreenState` (101-156) i `_GroupNetworkContentScreenState` (167-250) declaren cadascuna el seu propi `bool _loading`/`String? _error`, amb `CircularProgressIndicator` nu sense `Padding` (58, 131, 206), error en `Colors.red` literal (§1.2) i **cap botó de reintent explícit** — només la 1a pantalla té `RefreshIndicator` (59); la 2a i 3a (130-154, 203-249) no en tenen cap, així que un error ahí no té manera de recuperar-se sense sortir i tornar a entrar. A més, usen `Card`+`ListTile` cru (72-84, 140-151, 216-244) en comptes d'`InstriqListItem`, i capçaleres de subgrup amb `Text(..., style: titleMedium)` (214, 230) en comptes d'`InstriqSectionHeader` — la mateixa pantalla que "Documentar" absorbirà (§8.4) té, doncs, 3 inconsistències tipogràfiques/d'estat alhora.

`tray_detail_screen.dart` i `catalog_screen.dart` són més benignes: el contingut principal ja arriba per paràmetre (`widget.tray`/`kInstruments`, dades locals), així que `_load()` (137-200, tot en blocs `try/catch` independents que s'empassen l'error amb comentaris explícits de "no bloquejar la resta") només pot fer desaparèixer metadades secundàries (etiquetes, fotos de comunitat), mai el contingut principal — el `CircularProgressIndicator` nu de `tray_detail_screen.dart:528-529` només cobreix la primera càrrega. `catalog_screen._EmptyFiltered` (362-384) és el 2n lloc (després de la cerca d'Inici) amb un missatge de buit real, també sense icona.

**Conclusió de §1.3: no hi ha "un patró amb inconsistències petites" — hi ha 4 contractes diferents, i els 2 que pitjor es comporten (B i D) són exactament a les pantalles que aquest redisseny ja toca.** Arreglar-ho no és una proposta estètica nova, és acabar una feina de consolidació que el propi design system ja ha fet per a la resta de l'app.

### 1.4 Micro-interaccions existents (el punt de partida)

Únic precedent trobat a tot `lib/`: `AnimatedSwitcher` de 250ms al gir de flashcard (`flashcards_screen.dart:94-97`). **A Inici no hi ha cap transició implícita enlloc.** Cas concret i barat de corregir: la fila "Tècniques" (`home_screen.dart:884-891`) mostra `subtitle: _loadingGroupContent ? null : l10n.techniquesSubtitle` — mentre carrega, la fila és només icona+títol (més baixa); en acabar de carregar, el subtítol apareix de cop i la fila creix de mida sense cap transició — un salt de layout petit però evitable amb un `AnimatedSize` d'implícit, cost nul.

**Cap ús de `MediaQuery.disableAnimations` enlloc de `lib/`** (grep sencer, 0 resultats): qualsevol animació que es proposi aquí és la primera a introduir aquest guard, no n'hi ha cap de retrofit a tocar.

---

## 2. Diagnòstic (una frase per punt)

1. El vocabulari tipogràfic/d'espaiat que calen les noves seccions de Dreceres ja existeix i ja és correcte — no falta disseny, falta aplicar-lo dins de Dreceres (el pla principal ja ho diu, aquí només es confirma amb evidència de tokens).
2. "Càrrega/buit/error" té 4 contractes diferents a l'app, i els 2 pitjors (B: Inici, D: Xarxa de grup) són exactament a les 2 pantalles que aquest redisseny toca de ple — consolidar aquí té més valor que qualsevol floritura nova.
3. Dos punts concrets d'Inici converteixen un error de xarxa real en un fals "no hi ha res" (Pendents d'aprovar §1.3-B, Bandeges per preparar §1.3-B) — és un bug de confiança, no només estètic: un admin pot pensar que no hi ha res pendent quan en realitat la xarxa ha fallat.
4. El mode fosc és un sistema seriós i ben fet, amb 2 punts concrets (`group_network_screen.dart`, `instriq_version_diff.dart`) que el salten amb colors Material literals en comptes dels tokens — exactament a contingut que el redisseny mou de lloc.
5. L'única micro-interacció que falta de debò i és barata de resoldre és evitar el salt de layout quan un subtítol apareix després de carregar — no calen transicions noves de pantalla ni res costós.

---

## 3. Propostes concretes

### 3.1 Adoptar `InstriqAsyncView` a les 5 seccions d'Inici i a les 3 pantalles de Xarxa de grup — **Gratuït–cheap**

És moure codi a un contracte que ja existeix, no inventar-ne un de nou. A Inici: cada secció condicional (`_buildPendingApprovalSection`, `_buildTrayPrepSection`, `_buildRecentSection`, `_buildFavoritesSection`) passa a embolcallar la seva pròpia crida amb `InstriqAsyncView<T>`, amb el seu `emptyBuilder`/`errorMessage` propis (cadascuna ja té el seu text de buit o en necessita un de nou curt). A `group_network_screen.dart`: les 3 pantalles (`_GroupNetworkScreenState`, `_GroupNetworkWorkspacesScreenState`, `_GroupNetworkContentScreenState`) substitueixen el seu `bool _loading`/`String? _error` casolà pel mateix widget — recupera de pas el botó de reintent explícit que les 2 pantalles sense `RefreshIndicator` no tenen avui. Cost real: eliminar codi (menys `setState`/camps d'estat per pantalla), no afegir-ne. **Encaixa directament dins la Fase 1 del pla principal** (que ja divideix `_buildQuickAccessSection` en sub-mètodes) i dins de la feina d'absorbir Xarxa de grup a "Documentar" (§8.4) — és el mateix moment de tocar aquest codi, no una fase extra.

Nota explícita: el bloc "Consultar" (Catàleg, Fàrmacs, Tancament de ferides, Esterilització) i "Aprendre" (Ruta, Aprèn, Progrés — un cop tret de Dreceres) **no necessiten cap d'això**: són enllaços de navegació estàtics, sense `Future` propi. Només "Documentar" (que sí depèn de `_loadingGroupContent`/`_workspaces`) es beneficia realment d'un estat de càrrega visible.

### 3.2 Un `InstriqEmptyState` petit (icona opcional + text), no un component gran — **Cheap**

Els ~15 punts de crida d'`emptyBuilder` revisats repeteixen literalment `Center(Padding(Text(...)))`. Mateix criteri que ja documenta el propi design system per promoure un component (`instriq_count_badge.dart:4-6`: "promogut aquí... en el seu segon ús real"): amb 15 usos gairebé idèntics, el repetit és el candidat, no la floritura. Proposta: un `InstriqEmptyState` minúscul (`icon: IconData?`, `message: String`) que faci exactament el mateix `Center+Padding+Text` d'avui si `icon` és `null` (canvi de comportament zero el primer dia) i afegeixi una icona de 32-40px a sobre quan un punt de crida en vulgui una. Migració incremental, pantalla a pantalla, mai en bloc. Aquest és el component que les noves seccions de Dreceres (§3.1) i Xarxa de grup fan servir com a `emptyBuilder`.

### 3.3 Substituir `Colors.red`/`Colors.green`/`Colors.grey` literals pels tokens de `InstriqColors`/`ColorScheme` — **Gratuït**

A `group_network_screen.dart:64,135,210` (`Colors.red` → `Theme.of(context).colorScheme.error`) com a mínim, ja que és contingut que es mou a "Documentar" en aquesta mateixa ronda. `instriq_version_diff.dart:144,150,154,182-183,198-201` és la mateixa classe de problema però fora del nucli d'aquest redisseny (tècniques/bandeixes/fitxes de preferència, no Inici/navegació) — es deixa com a nota per a una altra sessió, no bloqueja res d'aquí.

### 3.4 `InstriqSectionHeader` en comptes de `Text(..., titleMedium)` per als subgrups de `group_network_screen.dart` — **Gratuït**

Línies 214 i 230 (capçaleres "Bandeges"/"Tècniques" dins del contingut d'una seu germana) usen un estil diferent del que fa servir la resta de l'app per agrupar llistes. Canvi d'una línia cadascuna, mateix moment que §3.1.

### 3.5 `AnimatedSize` al subtítol de "Tècniques"/"Bandeges" mentre `_loadingGroupContent` — **Gratuït**

`home_screen.dart:884-898`: embolcallar el `Column` intern de cada `InstriqListItem` afectat (o el propi `subtitle`) amb un `AnimatedSize` de ~150ms evita el salt de mida quan el subtítol apareix. És l'únic "micro" d'aquest document que introdueix una animació nova — cal el guard de reducció de moviment:
```dart
duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 150),
```
Primer ús d'aquest guard a `lib/` (§1.4) — estableix el patró perquè qualsevol animació futura el segueixi, no només aquesta.

### 3.6 Tipografia de les targetes 2×2 de "Consultar" (§4.2 del pla principal): reutilitzar l'elecció ja feta a `_DashboardTile`, no inventar-ne una altra — **Gratuït**

El pla principal ja diu que cal una targeta "més senzilla que `_DashboardTile`, sense `Future`/estat" (§4.2), però no diu quin estil tipogràfic portar-hi. `_DashboardTile` (`home_dashboard_panel.dart:526`) ja va triar `titleSmall` per al títol de targeta — reutilitzar exactament aquesta mida (en comptes de `titleMedium`, que és el que usa `InstriqListItem` per a files, una gramàtica diferent) fa que les targetes mòbils noves i el panell d'escriptori ja existent comparteixin una sola "gramàtica de targeta" en comptes de dues inventades per separat en sessions diferents.

### 3.7 Ritme d'espaiat dins del bloc "Documentar" ampliat (amb Xarxa de grup, decisió §8.4) — **Gratuït**

El pla principal ja fixa `xl` entre blocs i `sm` entre ítems (§4.1). Matís visual, no d'IA: dins de "Documentar", Xarxa de grup és l'únic ítem condicionat a `hasGroup` (no només `hasHospital`, com la resta de 5) — un `InstriqListItem` idèntic als altres 5 sense cap senyal visual fa que un usuari d'una única seu (sense cadena) no entengui per què l'ítem "Xarxa de grup" no hi apareix mai, com si faltés. No cal una secció pròpia (decisió §8.4 ja descarta això) ni un color diferent (seria inventar un nou tipus d'estat) — n'hi ha prou que sigui, com els altres, el darrer de la llista (ja ho és, `home_screen.dart:927-936`) i prou; es descarta deliberadament qualsevol tractament especial per no contradir la decisió de "no secció pròpia".

---

## 4. Cost per proposta

| Proposta | Cost | Per què |
|---|---|---|
| Adoptar `InstriqAsyncView` a Inici + Xarxa de grup (§3.1) | **Gratuït–cheap** | Esborra codi d'estat casolà, reutilitza un contracte ja construït i provat a 11+ pantalles |
| `InstriqEmptyState` (icona opcional) (§3.2) | **Cheap** | Widget de ~15 línies, migració incremental, zero canvi de comportament el primer dia |
| Tokens de color en comptes de `Colors.*` literals (§3.3) | **Gratuït** | Canviar una referència, cap lògica nova |
| `InstriqSectionHeader` a Xarxa de grup (§3.4) | **Gratuït** | Canvi d'una línia × 2 |
| `AnimatedSize` al subtítol de Documentar (§3.5) | **Gratuït** | Animació implícita de Flutter, sense dependència, amb guard de `disableAnimations` |
| Tipografia de targeta compartida amb `_DashboardTile` (§3.6) | **Gratuït** | Triar un token ja triat en un altre lloc, no inventar-ne un |
| Cap tractament especial per a "Xarxa de grup" dins Documentar (§3.7) | **Gratuït (no fer res)** | Qualsevol senyal visual extra contradiria la decisió §8.4 d'integrar-lo sense secció pròpia |

Cap proposta d'aquest document afegeix una dependència a `pubspec.yaml`, introdueix una animació de llibreria externa, ni toca el nombre de crides de xarxa existents — mateix pressupost que el pla principal (§5/§7, no negociable).

---

## 5. Fases (s'integren dins les fases ja aprovades, no en són una de nova)

- **Dins la Fase 1 del pla principal** (agrupació de Dreceres, sense tocar router): §3.1 (Inici), §3.3/§3.4 (Xarxa de grup, ja que entra a "Documentar" en aquest mateix pas), §3.5, §3.7.
- **Dins la Fase 2** (graella 2×2 de "Consultar"): §3.6.
- **Fora d'abast d'aquesta ronda, opcional per a més endavant**: §3.2 (`InstriqEmptyState`) es pot fer abans o després sense dependre de les fases del pla principal — és ortogonal; la part de `instriq_version_diff.dart` de §3.3 també queda per a una sessió a part, sense bloquejar res d'aquí.

---

## 6. Decisió del propietari

**§3.2 (`InstriqEmptyState`) → aprovat.** Únic component nou d'aquest document; la resta de propostes reutilitzen el que ja existeix al design system.
