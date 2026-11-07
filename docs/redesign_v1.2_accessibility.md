# Accessibilitat i usabilitat clínica real — annex al pla v1.2

> Tasca de **planificació**, no d'implementació — cap pantalla es toca en aquest document, només es llegeix i es mesura. Aprofundeix UNA dimensió que `docs/redesign_v1.2_plan.md` deixa lleugera: accessibilitat (WCAG) i usabilitat real amb guants quirúrgics. No repeteix ni contradiu les decisions de navegació/IA d'aquell pla (§8 ja tancat) — aquí no es parla de Dreceres, cerca unificada ni duplicats. Dos agents bessons cobreixen per separat disseny visual/interacció i personalització/onboarding; aquest document no entra en cap d'aquests dos temes. Basat en lectura real de codi i còmput real de contrast/mides, no en estimació — cada xifra d'aquest document surt d'una fórmula aplicada als valors hexadecimals/numèrics reals del repositori (script Node efímer, descartat; no s'ha afegit cap dependència).

---

## 0. Troballa principal

**L'app ja té una auditoria d'accessibilitat real feta** (`docs/CHANGELOG.md:85`, tram "Auditoria d'accessibilitat"): `Semantics`/`semanticLabel` explícits ja existeixen en 9 dels 88 fitxers de `lib/screens/` (`flashcards_screen.dart`, `review_session_screen.dart`, `tray_preparation_or_mode_screen.dart`, `instriq_autosave.dart`, i les fotos de `instrument_detail_screen.dart`, `custom_instrument_detail_screen.dart`, `tray_detail_screen.dart`, `public_entity_detail_screen.dart`, `community_photos_review_screen.dart`). Aquest document **no refà cap d'això**. El que troba és:

1. Un **forat de zona tàctil propi del tema global de botons** (`InstriqButton`/`FilledButton`/`OutlinedButton`/`TextButton` via `lib/design_system/instriq_theme.dart:86-102`): Material 3 posa per defecte `minimumSize: Size(64, 40)` i cap dels tres `ButtonStyle.styleFrom` d'aquest fitxer el sobreescriu — **tots els botons de l'app (88 pantalles) tenen 40px d'alçada mínima**, per sota dels 44pt (iOS)/48dp (Android) recomanats. És una sola línia per estil, al lloc compartit per on passen tots els botons (criteri d'arrel, no pedaç per pantalla).
2. **El propi control de sortida de Mode Quiròfan (`_HoldToExitControl`, `tray_preparation_or_mode_screen.dart:530-617`) té una zona tàctil real de ~20px d'alçada** — la meitat del mínim recomanat — precisament a la pantalla dissenyada per usar-se amb guants. L'auditoria anterior (CHANGELOG:85) ja hi va treballar, però només va arreglar que un lector de pantalla pogués activar-lo (`excludeSemantics` + acció semàntica pròpia); no va tocar la mida física del gest per a qui el prem amb el dit, amb o sense guant.
3. **Mode Quiròfan és una sola pantalla** (`TrayPreparationOrModeScreen`, obert únicament des de `tray_detail_screen.dart:297`, botó "Preparar bandeja") — no embolcalla l'agenda quirúrgica ni la cua d'incidències. Aquestes dues pantalles (`surgical_agenda_screen.dart`, `incident_capa_queue_screen.dart`) són curtes (194/157 línies), usen widgets Material estàndard (`IconButton` amb `tooltip`, sense `GestureDetector` pelat) i per tant ja tenen una accessibilitat bàsica raonable per defecte — però cap tractament "guants" (fons fosc, files grans, sortida protegida). Si cal estendre-hi el patró és una decisió de producte, no una correcció de bug (§7, pregunta oberta).
4. El **contrast del color de vora (`InstriqColors.borderLight`/`borderDark`) contra la superfície és 1.32:1 i 1.42:1** — per sota del mínim WCAG 1.4.11 de 3:1 per a límits de component d'interfície — i és rellevant perquè `InstriqSurface` (vora d'1px, sense ombra, §1.6 del pla) **no té pràcticament cap altra diferència de color amb el fons** (`surfaceLight`/`backgroundLight` = 1.04:1, `surfaceDark`/`backgroundDark` = 1.09:1): la vora no és un detall estètic, és l'únic senyal visual real que separa una fila tocable del fons de la pantalla.

Cap d'aquests 4 punts necessita cap dependència nova ni cap canvi de `pubspec.yaml`.

---

## 1. Estat actual (evidència)

### 1.1 Abast real del treball d'accessibilitat ja fet

`docs/CHANGELOG.md:85` (tram "Auditoria d'accessibilitat (tram nou)") documenta exactament:
- `flashcards_screen.dart`/`review_session_screen.dart`: volteig de targeta amb `GestureDetector` pelat → `Semantics` + `InkWell`.
- `tray_preparation_or_mode_screen.dart` (Mode Quiròfan): botó de reportar incidència sense `Semantics` i amb zona tàctil per sota del mínim; botó +/- de quantitat igual — **tots dos ja corregits** (confirmat llegint el fitxer sencer: `Semantics(button: true, label: ...)` a la línia 465 i `_StepperButton` a la línia 500, amb comentari explícit "13px -> ~44px de diàmetre total ... per sobre del mínim de zona tàctil recomanat", línia 518-519).
- `quiz_screen.dart`: feedback només per color (verd/vermell) → icona ✓/✗ afegida com a senyal redundant.
- `instriq_autosave.dart`: `liveRegion: true` (línia 152) perquè un lector de pantalla s'assabenti del canvi d'estat "guardant" → "guardat" sense navegar-hi manualment.
- `label` Semantics afegit a fotos de fitxa d'instrument, variant d'instrumental personalitzat, galeria de bandeja, cua de revisió de fotos comunitàries i Biblioteca Pública.
- **Pendent, declarat fora d'abast d'aquell tram**: formularis sense `TextFormField` (errors com a text de color sense lligar-se al camp) i la paleta fixa de Mode Quiròfan que ignora el tema clar/fosc de l'usuari (es deixa sense tocar fins a confirmar si és disseny deliberat).
- `docs/CHANGELOG.md:252`: pendent explícit per a la Fase 2 del redisseny: "una passada amb un auditor automàtic (axe/Lighthouse, no disponible en aquest entorn) abans de certificar WCAG 2.2 AA" — **aquesta limitació segueix sent certa per a aquest document**: tot el que segueix és una revisió de codi, no una passada real amb TalkBack/VoiceOver (§6).

Grep de `Semantics(`/`excludeSemantics`/`semanticLabel`/`MergeSemantics`/`ExcludeSemantics` a tot `lib/`: **9 fitxers de 88 pantalles** (`lib/screens/*.dart`) en tenen. Mostra representativa comprovada explícitament: `home_screen.dart`, `catalog_screen.dart`, `library_screen.dart`, `profile_hub_screen.dart`, `surgical_agenda_screen.dart`, `activity_screen.dart` — **cap d'aquestes 6 té `Semantics` explícit**. No és un problema en si mateix (es basen en la semàntica per defecte de `Text`/`Icon`/`InkWell`/`ListTile`/`IconButton`, que Flutter ja anuncia raonablement), però vol dir que l'etiquetatge explícit de l'app és puntual (fotos, targetes volteables, Mode Quiròfan), no sistemàtic.

### 1.2 Mode Quiròfan: abast real i disseny ja aplicat

`TrayPreparationOrModeScreen` (`lib/screens/tray_preparation_or_mode_screen.dart`), comentari de classe (línies 37-42): *"Checklist de preparación de bandeja pensada para usarse dentro de quirófano o la sala de montaje: filas grandes para tocar con guante, fondo oscuro para no deslumbrar bajo la luz del campo, un único acento de color y salida protegida con mantener pulsado."* Únic punt d'entrada: `tray_detail_screen.dart:297` (`MaterialPageRoute(builder: (_) => TrayPreparationOrModeScreen(tray: _tray))`, botó "Preparar bandeja"). **No embolcalla cap altra pantalla** — ni l'agenda quirúrgica (`SurgicalAgendaScreen`) ni la cua d'incidències (`IncidentCapaQueueScreen`), confirmat per grep: cap referència a `TrayPreparationOrModeScreen` fora de `tray_detail_screen.dart`.

Què fa diferent, concretament (llegit el fitxer sencer, 618 línies):
- **Paleta fixa pròpia**, no el tema clar/fosc de l'app (`_bg = 0xFF0A0F0D`, `_cardBg = 0xFF121815`, `_textPrimary = 0xFFF4F6F4`, `_accent = InstriqColors.accentDark`, línies 12-23) — és exactament el punt que el CHANGELOG ja deixa com a pendent de confirmar si és deliberat.
- **Files de 38px d'indicador + text 19px + 18px de padding vertical** (`_buildRow`, línies 396-497) → zona tàctil real ≈ 38 + 2×18 = 74px d'alçada, molt per sobre del mínim.
- **Sortida protegida amb mantenir premut 650ms** (`_HoldToExitControl`, línies 530-617) en comptes d'un botó "Enrere" normal — evita sortides accidentals amb un guant fregant la pantalla.
- **`PopScope(canPop: false, ...)`** (línia 264) amb avís per toast si es prova de sortir amb gest de retrocés del sistema — mateix criteri de protecció.

No hi ha cap altra pantalla a `lib/screens/` amb aquest patró (fons fosc fix + files grans + sortida protegida). La pregunta del brief ("Mode Quiròfan ja cobreix la necessitat real, o caldria estendre-ho?") es respon parcialment a §1.3/§7: el problema físic real (mida de zona tàctil) **no és exclusiu d'aquesta pantalla** — és un defecte del tema de botons compartit per tota l'app — però el tractament complet (fons fosc antienlluernament + sortida protegida) és una decisió de producte per a cada pantalla, no una correcció.

### 1.3 Mides de zona tàctil reals (calculades, no estimades)

| Component | Càlcul a partir de constants reals | Resultat | Mínim de referència | Compleix? |
|---|---|---|---|---|
| `InstriqListItem` (`lib/design_system/components/instriq_list_item.dart:33,36`) | `EdgeInsets.all(InstriqSpacing.lg)` = 16px + icona 28px: alçada de fila ≥ 28 + 16 + 16 | **≥ 60px** (més si hi ha subtítol, mai menys) | 48dp Android / 44pt iOS | **Sí, amb marge ampli** |
| `InstriqButton` (`FilledButton`/`OutlinedButton`/`TextButton`, tema a `lib/design_system/instriq_theme.dart:86-102`) | Cap `minimumSize` definit als 3 `ButtonStyle.styleFrom` → cau al valor per defecte de Material 3 (`Size(64, 40)`) | **40px d'alçada** | 48dp / 44pt | **No** — per sota dels dos, a tota l'app |
| Mode Quiròfan, `_StepperButton` (+/−) (`tray_preparation_or_mode_screen.dart:500-528`) | `Padding.all(13)` + icona 18px → diàmetre 13+18+13 | **44px** | 48dp / 44pt | Compleix iOS/WCAG (44), **4px curt** del recomanat Android (48) |
| Mode Quiròfan, botó "reportar incidència" (badge, línies 465-490) | `EdgeInsets.symmetric(horizontal: 12, vertical: 13)` + text variable (p.ex. `"×1"`) | Alçada ≈ 44-46px; **amplada pot baixar a ~40px** amb text curt (`"×1"`, `"×2"`) | 48dp / 44pt | Alçada just, **amplada pot incomplir** en quantitats d'un sol dígit |
| Mode Quiròfan, fila d'ítem sencera (`_buildRow`, línies 407-421) | `EdgeInsets.symmetric(vertical: 18)` + contingut (cercle 38px) → 18+38+18 | **74px** | 48dp / 44pt | **Sí, amb marge ampli** |
| **Mode Quiròfan, `_HoldToExitControl`** (línies 530-617), **control de sortida** | `GestureDetector` **sense cap `Padding` propi**, embolcalla `Row([SizedBox 20×20, SizedBox width 7, Text fontSize 11])` → alçada real = max(20, ~14 del text) | **≈ 20px d'alçada** | 48dp / 44pt | **No — menys de la meitat del mínim**, al gest exprés per sortir d'una pantalla pensada per a guants |

El cas de `_HoldToExitControl` és el més rellevant per al context clínic d'aquest document: l'auditoria anterior ja va detectar i corregir que el gest llarg no funcionava amb el pont d'accessibilitat de TalkBack/VoiceOver (comentari línies 564-570, `excludeSemantics: true` + acció semàntica `onLongPress` pròpia) — però això és una via *alternativa* per a lectors de pantalla, no arregla que la zona física (per a qui hi prem amb el dit, amb guant o sense) sigui minúscula. Són dos problemes diferents que l'auditoria anterior només va cobrir un.

### 1.4 Contrast de color real (calculat, fórmula WCAG relativa luminance + ratio)

Valors reals de `lib/design_system/tokens.dart`, contrast calculat amb la fórmula estàndard WCAG (`(L1+0.05)/(L2+0.05)`, `L` = luminància relativa sRGB):

**Mode clar:**

| Parell | Ratio | AA normal (4.5:1) | AA UI/text gran (3:1) |
|---|---|---|---|
| `textPrimaryLight` (#1C1C1A) / `backgroundLight` (#FAFAF9) | 16.34:1 | OK | OK |
| `textSecondaryLight` (#57574F) / `surfaceLight` | 7.29:1 | OK | OK |
| `accent` (#0F766E, `primary`) / `surfaceLight` | 5.47:1 | OK | OK |
| `onAccent` (#FFFFFF) / `accent` (text de botó ple) | 5.47:1 | OK | OK |
| `error` (#BA1A1A) / `surfaceLight` | 6.46:1 | OK | OK |
| **`borderLight` (#E2E0DC) / `surfaceLight`** | **1.32:1** | n/a (no és text) | **No compleix (3:1)** |
| `surfaceLight` (#FFFFFF) / `backgroundLight` (#FAFAF9) (referència: quant es diferencia la targeta del fons pel propi color) | 1.04:1 | — | — (confirma que la vora és l'únic senyal) |

**Mode fosc:**

| Parell | Ratio | AA normal | AA UI |
|---|---|---|---|
| `textPrimaryDark` (#ECEDE9) / `backgroundDark` (#121412) | 15.74:1 | OK | OK |
| `textSecondaryDark` (#B2B4A9) / `surfaceDark` | 8.07:1 | OK | OK |
| `accentDark` (#5EEAD4, `primary`) / `backgroundDark` | 12.51:1 | OK | OK |
| `onAccentDark` (#00332E) / `accentDark` (text de botó ple) | 9.38:1 | OK | OK |
| `errorDark` (#FFB4AB) / `backgroundDark` | 10.90:1 | OK | OK |
| **`borderDark` (#34382F) / `surfaceDark`** | **1.42:1** | n/a | **No compleix (3:1)** |
| `surfaceDark` (#1B1D1B) / `backgroundDark` (referència) | 1.09:1 | — | — |

**Mode Quiròfan (paleta fixa pròpia, `tray_preparation_or_mode_screen.dart:12-23`):**

| Parell | Ratio | Compleix 4.5:1? |
|---|---|---|
| `_textPrimary` (#F4F6F4) / `_bg` (#0A0F0D) | 17.79:1 | OK, de sobres |
| `_textMuted` (#7C9B93) / `_cardBg` (#121815) | 5.97:1 | OK |
| `_warnAccent` (#F5A524) / `_warnBg` (#3A2A12) (fila d'excepció) | 6.77:1 | OK |
| `_cardBorder` (#202B26) / `_cardBg` (UI, 3:1) | 1.23:1 | **No compleix**, mateix patró que `InstriqColors.border*` |

**Lectura**: tot el text (normal i gran, llum i fosc, inclosa la paleta pròpia de Mode Quiròfan) compleix AA amb marge folgat — el sistema de tokens ja és sòlid en contrast de text. **L'únic incompliment sistemàtic és el contrast de vora (`borderLight`/`borderDark`/`_cardBorder`) contra la superfície que delimiten**, i afecta qualsevol component que depengui de `ColorScheme.outline`: `InstriqSurface`/`InstriqListItem` (via `CardThemeData.shape.side`, `instriq_theme.dart:70`), `OutlinedButton` (línia 94), i la pròpia `_cardBorder` de Mode Quiròfan. Com que la superfície (`surfaceLight`/`surfaceDark`) gairebé no es diferencia del fons per color (1.04:1/1.09:1, calculat més amunt), **la vora és, en la pràctica, l'única pista visual que indica "això és una fila/targeta separada"** per a algú amb baixa visió.

### 1.5 Text alternatiu i suport de lector de pantalla

`pubspec.yaml:33` (`flutter_localizations`) + `l10n.yaml` (`arb-dir: lib/l10n`, `template-arb-file: app_ca.arb`, `generate: true`): mecanisme estàndard `AppLocalizations`, ja usat consistentment per a tots els `label`/`tooltip`/`semanticLabel` trobats (p.ex. `l10n.orModeReportIssueTooltip`, `l10n.orModeDecreaseQty` — `lib/l10n/app_ca.arb:820-826`). No hi ha cap mecanisme paral·lel d'i18n per a text d'accessibilitat — una sola font de veritat, correcte.

Patró de `semanticLabel` en fotos (`CachedNetworkImage`, 9 fitxers de `lib/`):
- **Correcte i consistent**: `instrument_detail_screen.dart:566-568` i `:632-634` — `Semantics(image: true, label: instrument.name.forLanguageCode(...))` embolcallant el `ClipRRect`/`CachedNetworkImage`. Mateix patró a `custom_instrument_detail_screen.dart`, `tray_detail_screen.dart`, `public_entity_detail_screen.dart`, `community_photos_review_screen.dart`.
- **Exclusió deliberada i correcta**: `quiz_screen.dart:172-182` — la foto de resposta del quiz **no** porta `semanticLabel` (comentari explícit al fitxer: l'objectiu de la pregunta és "endevinar" l'instrument; etiquetar-la li donaria la resposta). No és un forat, és disseny intencionat — **no es proposa cap canvi aquí**.
- **Forat real, mateix patró no aplicat**: `catalog_screen.dart:285-299` — la miniatura de 48×48 de cada fila de la llista de catàleg (`CachedNetworkImage` dins `ListTile.leading`) **no té cap `Semantics`/`semanticLabel`**. És la pantalla de cerca/navegació d'instruments de més trànsit de l'app i l'única de les 9 amb fotos que es va quedar fora de l'auditoria anterior (probablement perquè la safata de detall ja ho tenia i es va donar per cobert el flux).
- **Forat menor, impacte baix**: `public_entity_form_screen.dart:325-328` — previsualització de la foto que el mateix usuari acaba de triar/pujar en un formulari; sense `semanticLabel`, però el context (camp de formulari "Foto", ja anunciat) mitiga l'impacte; candidat a `excludeSemantics: true` (és merament decoratiu un cop ja hi ha un camp anunciat) més que a afegir-hi un label nou.

---

## 2. Diagnòstic (una frase per punt)

1. El tema compartit de botons (`InstriqButton`) fixa 40px d'alçada mínima a tota l'app — sota el mínim recomanat — per no tenir `minimumSize` definit al `ThemeData`.
2. El control de sortida de Mode Quiròfan, la pantalla pensada per a guants, té la zona tàctil més petita de tot el que s'ha revisat (~20px), ja detectada parcialment (problema de lectors de pantalla) però no de mida física.
3. El contrast de vora (`InstriqColors.borderLight`/`borderDark`) incompleix el mínim WCAG de 3:1 per a components d'interfície, i és l'única pista visual real de separació entre superfícies.
4. El catàleg d'instruments —la pantalla de cerca de més ús— és l'única de les pantalles amb fotos que es va quedar sense `semanticLabel` a l'auditoria anterior.
5. Mode Quiròfan cobreix bé un flux (preparació de safata); l'agenda quirúrgica i la cua d'incidències —altres pantalles d'ús real durant/entre procediments— no tenen cap tractament equivalent, i decidir si el necessiten és una decisió de producte, no un bug.

---

## 3. Propostes (cost primer, sempre el més barat abans)

### 3.1 Fixar `minimumSize` als 3 temes de botó — **gratuït**
`lib/design_system/instriq_theme.dart:86-102`: afegir `minimumSize: const Size(64, 48)` (o `WidgetStatePropertyAll`) a `FilledButton.styleFrom`, `OutlinedButton.styleFrom` i `TextButton.styleFrom`. Un sol lloc, 3 línies, arregla tots els botons de l'app alhora (criteri d'arrel: el forat és al tema compartit, no a cada botó).

### 3.2 Ampliar la zona tàctil de `_HoldToExitControl` — **gratuït**
`tray_preparation_or_mode_screen.dart:574` (`GestureDetector`): embolcallar-lo amb un `Padding` (p.ex. `EdgeInsets.symmetric(vertical: 14, horizontal: 8)`) abans del `Semantics`, igual que ja fa `_StepperButton` (línia 520-521). No canvia l'aparença visual (el cercle i el text es dibuixen igual), només amplia l'àrea on respon el toc/premuda llarga.

### 3.3 Amplada mínima al badge "reportar incidència" — **gratuït**
`tray_preparation_or_mode_screen.dart:473` (`Container` amb el `badgeText`): afegir `constraints: const BoxConstraints(minWidth: 48)` perquè quantitats d'un sol dígit (`"×1"`) no quedin per sota del mínim en amplada.

### 3.4 `Semantics` a la miniatura del catàleg — **gratuït, reutilitza patró existent**
`catalog_screen.dart:285` (`CachedNetworkImage` dins `ListTile.leading`): embolcallar igual que `instrument_detail_screen.dart:566-568` — `Semantics(image: true, label: instrument.name.forLanguageCode(...), child: ClipRRect(...))`. Mateixa línia de codi ja escrita i provada en 5 altres pantalles, només cal copiar-la aquí.

### 3.5 Contrast de vora — **no és un "fix", és una decisió de disseny pendent**
Pujar `borderLight`/`borderDark` fins a 3:1 reals (p.ex. enfosquir `borderLight` cap a un gris ~#B9B6AF o equivalent) és barat en codi (2 constants a `tokens.dart`) però **toca el llenguatge visual de tota l'app** (targetes, botons amb vora, divisors) — exactament el tipus de canvi visual que els agents bessons de disseny estan cobrint. Aquest document només deixa la xifra calculada i la recomanació de revisar-ho conjuntament amb ells (§7); no proposa un valor de substitució concret perquè és terreny de disseny, no d'accessibilitat pura.

### 3.6 Estendre el tractament "Mode Quiròfan" a agenda/incidències — **no es proposa, és pregunta oberta**
Cap canvi de codi aquí. Veure §7.

---

## 4. Cost i risc

| Proposta | Cost | Risc de regressió |
|---|---|---|
| 3.1 `minimumSize` als temes de botó | Gratuït | Baix — pot allargar botons curts uns px; revisar que cap layout ajustat a 40px es desbordi (p.ex. barres d'accions denses) |
| 3.2 Padding a `_HoldToExitControl` | Gratuït | Nul — només amplia l'àrea tocable, no mou res visible |
| 3.3 `minWidth` al badge | Gratuït | Nul |
| 3.4 `Semantics` a miniatura de catàleg | Gratuït | Nul — mateix patró ja validat 5 vegades |
| 3.5 Contrast de vora | Barat en codi, car en coordinació | Mitjà — canvia l'aspecte de tota targeta/vora de l'app, decisió compartida amb disseny |
| 3.6 Estendre Mode Quiròfan | No proposat | — decisió de producte, no d'aquest document |

Cap proposta toca rendiment (§1.7 del pla principal): 3.1-3.4 són canvis de constants/`Semantics`, zero crides de xarxa noves, zero `setState` nou, zero widgets amb cost de build addicional.

---

## 5. Fases (per a una sessió futura)

**Fase A — Zona tàctil (3.1, 3.2, 3.3)**: els 3 canvis de mida més barats i de risc més baix; es poden fer junts en una sola passada perquè toquen fitxers diferents sense dependència entre ells.

**Fase B — Etiquetatge restant (3.4 + decidir `public_entity_form_screen.dart`)**: completar el patró de `semanticLabel` a fotos que ja existeix a 5 pantalles.

**Fase C — Contrast de vora (3.5)**: nomes després de coordinar-ho amb els agents de disseny visual (toca tokens compartits amb el seu abast).

**Fora de fases, pendent de decisió de producte**: 3.6 (estendre Mode Quiròfan) i la paleta fixa de Mode Quiròfan que ignora el tema clar/fosc (ja marcat com a pendent al CHANGELOG, es repeteix aquí perquè és accessibilitat real: algú amb preferència de contrast/lluminositat específica al sistema no la veu respectada en aquesta pantalla concreta).

---

## 6. Límits d'aquesta revisió (honestedat sobre què no es pot confirmar llegint codi)

- **Cap de les xifres de contrast o mida d'aquest document substitueix una passada real amb TalkBack (Android) o VoiceOver (iOS) en un dispositiu físic**, idealment amb un guant quirúrgic real posat. El codi diu què hi ha declarat (`Semantics`, mides, colors); no diu com sona ni com es sent al tacte.
- No s'ha executat cap auditor automàtic (axe/Lighthouse) — mateixa limitació ja anotada a `docs/CHANGELOG.md:252`, encara certa.
- No s'ha pogut mesurar la mida tàctil *percebuda* en diferents densitats de píxel/mides de pantalla real — els càlculs són en píxels lògics de Flutter (≈dp), que és l'estàndard correcte per comparar amb 48dp/44pt, però la sensació real amb guant de làtex/nitril gruixut pot variar.
- No s'ha provat si el canvi de 3.1 (`minimumSize: Size(64,48)`) desborda algun layout dens existent (p.ex. files d'accions amb diversos `TextButton` en poc espai) — cal una revisió visual ràpida abans de donar-ho per tancat, no només `flutter analyze`.
- Per indicació explícita d'aquest encàrrec, **no s'ha executat `flutter analyze` ni `flutter test`** (cap fitxer de codi s'ha tocat).

---

## 7. Preguntes obertes per al propietari

1. **Contrast de vora (§1.4, §3.5)**: enfosquir `borderLight`/`borderDark` per arribar a 3:1 reals — qui ho decideix, aquest document o l'agent de disseny visual? Recomanació: coordinar-ho, no decidir-ho aquí en solitari perquè toca el llenguatge visual comú.
2. **Paleta fixa de Mode Quiròfan** (`_bg`, `_cardBg`, etc., ja detectada com a pendent al CHANGENOTE anterior): és deliberada (baixa lluminositat sempre, independentment del tema triat) o s'hauria de respectar el tema clar/fosc de l'usuari també aquí? Afecta directament algú amb sensibilitat lluminosa específica.
3. **Estendre el patró "guants" a l'agenda quirúrgica i la cua d'incidències**: el brief demanava comprovar-ho explícitament sense assumir-ho — la resposta trobada és que cap de les dues ho necessita *per defecte Material* (ja tenen accessibilitat bàsica raonable), però si el propietari considera que també s'usen "amb el camp obert" (p.ex. consultar l'agenda entremig d'una intervenció), podria valer la pena el mateix tractament. Decisió de producte, no de codi.
4. **Formularis sense `TextFormField`** (ja marcat pendent al CHANGENOTE anterior, fora d'abast d'aquell tram): segueix pendent i no s'ha tornat a tocar aquí — confirmar si entra a l'abast de la v1.2 o es queda per a una altra sessió.

---

## 8. Fora d'abast d'aquest document

- Qualsevol canvi a l'arquitectura d'informació, Dreceres, cerca unificada o duplicats — ja decidit a `docs/redesign_v1.2_plan.md` §8, no es toca ni es contradiu aquí.
- Disseny visual/interacció (iconografia, animacions, llenguatge de targetes) — cobert per l'agent bessó de disseny.
- Personalització i onboarding — cobert per l'agent bessó corresponent.
- Qualsevol dependència nova de testing d'accessibilitat (p.ex. paquets d'auditoria automàtica) — explícitament fora d'abast per indicació de l'encàrrec; les verificacions reals (§6) necessiten dispositiu físic, no una llibreria.
