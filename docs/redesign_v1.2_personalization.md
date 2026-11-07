# Redisseny v1.2 — Personalització i Onboarding (aprofundiment)

> Complement de `docs/redesign_v1.2_plan.md` (que ja cobreix IA/agrupació de Dreceres i que NO es toca ni es contradiu aquí). Aquest document aprofundeix NOMÉS en dues coses que aquell pla va deixar lleugeres: (1) com personalitzar Inici/onboarding segons qui l'usa (mode de treball, rol, progrés, si pertany a un hospital/cadena) i (2) la primera experiència real de qui obre l'app per primer cop. No toca disseny visual/interacció (ho cobreix un altre informe) ni accessibilitat (ídem). Basat en lectura real de `lib/models/work_mode.dart`, `lib/screens/home_screen.dart` sencer (les seccions rellevants), `lib/navigation/work_mode_header.dart`, `lib/screens/learning_path_screen.dart` sencer, `lib/screens/auth/group_entry_screen.dart` sencer, `lib/screens/auth/accept_invitation_screen.dart`, `lib/screens/auth/hospital_connect_flow.dart`, `lib/main.dart`, `lib/screens/onboarding_screen.dart`, `lib/services/profile_service.dart` i `lib/services/progress_service.dart`. Zero dependències noves a `pubspec.yaml`, zero esquema nou de Supabase (es flagen explícitament els punts on caldria).

---

## 0. Troballa principal

**El mecanisme de personalització per mode de treball ja existeix, és barat (cap crida de xarxa extra, cap estat nou) i ja té exactament la forma que calia generalitzar — però avui només "parla" per a 3 dels 7 modes a nivell de secció, i per a 1 dels 7 a nivell d'ítem.** `_sectionOrderForMode` (`home_screen.dart:87-98`) només reordena per a `supervision`/`instrumentista`/`docente`; `esterilizacion`, `enfermeria`, `cirujano` i `estudiante` reben l'ordre per defecte, idèntic al de "sense preferència". Dins de Dreceres, només `cirujano` reordena ítems (`home_screen.dart:924-926`). La decisió §8.6 del pla principal ("estendre a tots els modes") és, doncs,**omplir els 4 forats que ja hi ha en una funció que ja existeix**, no construir res nou.

**El segon forat és més greu: ningú diu mai a un usuari nou que el selector de mode de treball existeix.** `WorkModeHeader` és l'ÚNIC lloc on es canvia de mode des d'Inici, i està completament amagat fins que `hasHospital` és cert (`work_mode_header.dart:34`) — i encara amb hospital, és un `PopupMenuButton` discret a la barra de 52px, sense cap moment de l'app que el senyali. `WorkModePicker` (el mateix widget, reutilitzat a Perfil → Compte i privacitat, `account_privacy_screen.dart:147-150`) té un comentari de la seva pròpia classe que afirma "reutilitzat en el registre/alta de grup" (`work_mode_picker.dart:6-10`) — **fals avui**: `group_entry_screen.dart` sencer no l'importa ni l'usa. Resultat: tota la feina de §3 d'aquest document (personalitzar per mode) és inert per a qualsevol usuari que no obri per voluntat pròpia un menú de configuració que no se li ha ensenyat mai.

**El tercer forat: hi ha 3 camins reals de "primera sessió amb hospital" (§1.4) i cap dels 3 porta a `LearningPathScreen`, que és exactament la pantalla que ja existeix per a això.**

---

## 1. Estat actual (evidència)

### 1.1 El mecanisme existent de personalització per mode (per generalitzar, no reinventar)

Dues funcions, dos nivells, mateix patró `switch`/llista literal que ja usa `_modeSectionOrder` a `lib/models/work_mode.dart:75-166` per a l'ordre de seccions de la fitxa d'instrument:

- **Nivell 1 — blocs d'Inici** (`HomeSectionKey`, `home_screen.dart:73`): `_sectionOrderForMode` (`home_screen.dart:87-98`) anteposa un bloc concret a l'ordre per defecte (`quickAccess, recent, favorites`, `home_screen.dart:75-79`) només per a 3 modes:
  | Mode | Bloc anteposat | Font del contingut |
  |---|---|---|
  | `supervision` | Pendents d'aprovar | `_fetchPendingApprovals` (`home_screen.dart:1112-1120`), ja cridat/cachejat |
  | `instrumentista` | Safates per preparar | `_traysNeedingPrep()`, ja calculat sobre dades ja carregades |
  | `docente` | Progrés de l'equip | només un enllaç (`home_screen.dart:1096-1110`), sense dades pròpies |
  | `esterilizacion`, `enfermeria`, `cirujano`, `estudiante` | **cap** | — |

  Important: `_buildTrayPrepSection` i `_buildTeamProgressSection` **no comproven el mode internament** (`home_screen.dart:1057-1088` i `1090-1110`) — el gate és només a `_sectionOrderForMode`. `_buildPendingApprovalSection` sí té el seu propi gate de rol (`isAdmin || canApproveAnyWorkspace`, línia 1019), independent del mode. És a dir: **el mode decideix NOMÉS quin bloc s'ofereix abans; si el bloc després decideix no mostrar-se (p. ex. un `docente` sense rol d'aprovació), ja es gestiona sol** (`if (section != null)`, línia 870).

- **Nivell 2 — ítems dins de Dreceres** (`_buildQuickAccessSection`, `home_screen.dart:881-1012`): només `cirujano` reordena, anteposant "Fitxes de preferència/Protocols" a "Tècniques/Bandeixes" (`home_screen.dart:924-926`, comentari explicatiu a 900-903). Els altres 6 modes reben sempre `[tècniques, bandeixes, fitxes, protocols, agenda]` en aquest ordre fix.

Cost de llegir `ProfileService.instance.activeWorkModeNotifier.value` dins de `build()`: **zero** — és un `ValueNotifier` ja en memòria, actualitzat una vegada a `loadProfile()` (`profile_service.dart:79-126`, dues consultes en paral·lel, ja pagat al començament de sessió) i a `setActiveWorkMode` (línia 131-135, un `update` directe, sense RPC). Cap proposta d'aquest document toca aquest cost.

### 1.2 El selector de mode, amagat fins i tot quan existeix

`WorkModeHeader` (`lib/navigation/work_mode_header.dart`):
- Amagat del tot sense hospital (`!hasHospital → SizedBox.shrink()`, línia 34; comentat explícitament a 19-21: "el modo de trabajo no tiene sentido para alguien sin grupo").
- Amb hospital, és un `PopupMenuButton` de 52px (línies 36-90) — discret, mai assenyalat, mai amb cap tutorial ni badge "nou".
- `WorkModePicker` (el widget reutilitzable, `lib/widgets/work_mode_picker.dart:11-61`) només s'usa de debò a `account_privacy_screen.dart:147-150` ("Mi modo de trabajo" dins Perfil → Compte i privacitat). El seu propi comentari de classe (línies 6-10) diu que també s'usa "en el registre/alta de grup" — **comprovat fals**: cap referència a `WorkModePicker` ni `WorkMode` a `group_entry_screen.dart` sencer.

**Conseqüència directa per a §3 d'aquest document:** la personalització per mode només pot arribar a usuaris que (a) tenen hospital connectat I (b) han trobat per iniciativa pròpia un menú de configuració. Avui, per a la immensa majoria d'usuaris nous, `activeWorkModeNotifier.value == null` per sempre, i tot `_sectionOrderForMode`/`groupItems` reorder és mort.

### 1.3 Senyals ja disponibles (res a inventar, res a demanar al backend)

De `ProfileService` (`lib/services/profile_service.dart:22-77`), tots ja carregats a `loadProfile()` sense cap crida addicional:

| Senyal | Getter | Què permet personalitzar |
|---|---|---|
| Mode de treball actiu | `activeWorkModeNotifier.value` (`WorkMode?`) | Ordre de seccions/ítems (§1.1) |
| Pertany a un hospital | `hasHospital` (`_organizationId != null`, línia 59) | Mostrar Documentar/WorkModeHeader |
| Pertany a una cadena | `hasGroup` (`_groupId != null`, línia 63) | Mostrar "Xarxa de grup" |
| És admin de l'organització | `isAdmin` (línia 56) | Pendents d'aprovar, Progrés d'equip |
| És propietari (creador) | `isOwner` (línia 57, `_ownerId == user.id`, línia 117) | Distingir "acabo de crear l'hospital" d'"m'hi he unit" |
| Pot aprovar en algun espai | `canApproveAnyWorkspace` (línia 70) | ídem admin, més ampli |
| Pot editar en algun espai | `canEditAnyWorkspace` (línia 77) | Mostrar CTA de "crear contingut" |
| Nom d'organització/cadena | `organizationName`/`groupName` | Text de capçalera, salutació |

De `ProgressService` (`lib/services/progress_service.dart`), funciona també en mode invitat (comentari de classe 44-57: backend dual, `shared_preferences` sense sessió):

| Senyal | Getter | Què permet |
|---|---|---|
| Instruments après/total | `learnedCount`/`totalCount` (línies 178-182) | Subtítol real a "El meu progrés" en lloc del text estàtic actual |
| Progrés global (0-1) | `overallProgress` (línia 184) | Barra/indicador, si el disseny visual ho vol |

De `LearningPathScreen` (`lib/screens/learning_path_screen.dart`), **local i privat avui**: el set `_completed` es guarda a `SharedPreferences` amb la clau `learning_path_completed_steps` (línia 43), però és un camp privat de `_LearningPathScreenState` — cap altra pantalla hi pot llegir sense que aquesta clau es converteixi en una constant compartida (canvi mínim, cap esquema nou, veure §4.2).

### 1.4 Els 3 camins reals de "primera sessió amb hospital" — i on aterren

Llegits sencers els 3 fitxers. Cap porta a `LearningPathScreen` ni pregunta mai pel mode de treball:

1. **Guest pur → crear/unir-se** (`GroupEntryScreen`, sencer, `lib/screens/auth/group_entry_screen.dart`): `_join()` (línies 86-118) i `_create()` (línies 120-168) acaben cridant `widget.onCompleted()`, que simplement fa `pop`/`setState` a qui l'hagi obert (`HospitalConnectFlow._refresh`, línia 56-58, o `LibraryScreen`/`LearningPathScreen`, veure sota). **Només el camí de crear** mostra un diàleg de confirmació amb el codi (`_showCreatedDialog`, línies 170-220); **el camí d'unir-se no mostra res** — ni una `SnackBar` — després d'un `_join()` correcte.
2. **Enllaç d'invitació per email** (`AcceptInvitationScreen`, `lib/screens/auth/accept_invitation_screen.dart`): ruta de nivell superior (`/invite/:token`, `router.dart:35-38`), fora del shell. `_accept()` (línies 90-104) acaba amb `context.go('/inicio')` — directe a Inici, sense cap pas intermedi.
3. **Hospital Connect Flow** (`lib/screens/auth/hospital_connect_flow.dart`): el seu propi comentari de classe (línies 8-11) diu que es "empuja desde el Home cuando alguien pulsa 'Mi hospital' sin estar conectado" — **comprovat fals**: cap crida a `HospitalConnectFlow(` dins de `home_screen.dart`. Els únics dos llocs reals que l'obren són `learning_path_screen.dart:113` (pas "Uneix-te a un equip") i `library_screen.dart:86` (un banner dins la pestanya Biblioteca). És a dir, **els dos únics punts d'entrada reals exigeixen que l'usuari ja hagi trobat sol la Ruta d'aprenentatge o la pestanya Biblioteca** — cap dels dos és el flux d'onboarding en si.

Els 3 camins convergeixen al mateix lloc (`HomeScreen`, amb `hasHospital` ja cert) sense cap senyal diferenciat de "és la teva primera vegada aquí amb hospital".

### 1.5 `LearningPathScreen`: ja cobreix bé el contingut, no la descoberta

`LearningPathScreen` (`lib/screens/learning_path_screen.dart`, llegit sencer) és exactament el que `docs/redesign_v1.2_plan.md` dona per fet com a "flux d'onboarding guiat ja construït" — i de contingut ho fa bé: seqüencia catàleg → flashcards → quiz → biblioteca pública → (unir-se a equip O bandeixes, mútuament excloents segons `hasHospital`, línies 157-172) amb checklist local persistit. Comentari de classe (línies 26-34) ho deixa clar: "no és contingut nou, només seqüencia pantalles que ja existeixen en un ordre amb sentit".

**El forat no és de contingut, és de descoberta**: l'única manera d'arribar-hi és l'ítem #1, amb el mateix pes visual que els altres 12, dins de Dreceres (`home_screen.dart:942-949` — confirmat únic punt d'entrada, `grep LearningPathScreen` a tot `lib/` només el troba allà i a la pròpia definició). Res la obre automàticament ni la recomana activament:

- `main.dart:_checkOnboarding` (línies 116-130) mostra `OnboardingScreen` (3 pàgines) **una sola vegada**, abans que el router toqui res, independent de sessió — però `OnboardingScreen` (`lib/screens/onboarding_screen.dart`) és purament informatiu: 3 pàgines amb `Skip`/`Next`, el botó final (`isLast ? onboardingStart : onboardingNext`, línia 183) només fa `Navigator.pop` (`_finish`, línia 63-65). **La pàgina 3 ven una promesa que la pantalla no compleix**: el text (`app_en.arb:18-19`) diu "Join your team whenever you're ready" / "join with their code" — però no hi ha cap botó que obri `GroupEntryScreen`/`HospitalConnectFlow`. És descripció, no acció.
- Després d'`OnboardingScreen`, l'usuari aterra directe a `HomeScreen` com a guest, veient Dreceres (7 ítems guest-visibles avui; blocs Consultar+Aprendre amb la nova IA) sense cap indicador de "comença per aquí".

---

## 2. Diagnòstic (una frase per punt)

1. El mecanisme de personalització per mode ja existeix i és gratuït d'estendre, però només "parla" per a 3 modes de 7 a nivell de bloc i 1 de 7 a nivell d'ítem — la resta reben l'ordre neutre, indistingible de "sense preferència".
2. El selector de mode (`WorkModeHeader`/`WorkModePicker`) no s'ensenya mai a ningú — tota la personalització de §1.1 depèn que l'usuari trobi sol un `PopupMenuButton` de 52px o una pantalla de configuració.
3. Els 3 camins reals de "primer cop amb hospital connectat" (guest→crear/unir-se, invitació per email, Hospital Connect Flow) aterren tots a Inici sense cap distinció ni cap empenta cap a `LearningPathScreen`.
4. `LearningPathScreen` ja fa bé la feina de contingut; el problema és 100% de descoberta, no de disseny del flux intern.
5. Els senyals que calen per resoldre 1-4 (mode, rol, `hasHospital`/`hasGroup`, progrés local) ja existeixen tots a `ProfileService`/`ProgressService`/`SharedPreferences` — cap necessita telemetria nova ni esquema nou.

---

## 3. Proposta: estendre la personalització per mode (mateix mecanisme, els 4 forats que falten)

Generalitzar `_sectionOrderForMode` i el reorder d'ítems de `_buildQuickAccessSection` perquè cada mode tingui una resposta deliberada — amb el mateix criteri de "què consultaria primer aquesta professió concreta" que ja fonamenta `_modeSectionOrder` a `work_mode.dart:75-166` (reaprofitant-ne fins i tot el raonament ja escrit allà, perquè la ficha d'instrument i Inici haurien de "pensar" el mateix sobre cada mode).

### 3.1 Nivell 2 (dins de Dreceres, un cop apliqui l'agrupació en blocs Consultar/Aprendre/Documentar de §3.2 del pla principal)

L'ordre per defecte actual d'`_buildQuickAccessSection` ja és, de fet, Consultar → Documentar → Aprendre (catàleg/fàrmacs/ferides/esterilització primer, grup al mig, aprèn/progrés al final) — és a dir, **el "default" de la taula següent no canvia res del que ja hi ha avui**; només calen els 4 modes que se'n desvien:

| Mode | Ordre de blocs proposat | Per què (mateix criteri que `work_mode.dart`) |
|---|---|---|
| `instrumentista` | **Documentar**, Consultar, Aprendre | Ja és la decisió explícita del propietari (§8.6 del pla); coherent amb `work_mode.dart:79-89` (ús/esterilització primer) |
| `docente` | **Aprendre**, Consultar, Documentar | Decisió explícita del propietari; coherent amb `work_mode.dart:141-151` (material docent) |
| `cirujano` | **Documentar**, Consultar, Aprendre | Reforça la personalització ja existent dins de Documentar (línies 924-926: fitxes/protocols primer); `work_mode.dart:128-138` prioritza consell clínic d'ús, no detall tècnic |
| `supervision` | **Documentar**, Consultar, Aprendre | Gestiona el dia a dia del quiròfan (agenda, protocols); coherent amb el bloc "Pendents d'aprovar" que ja se li anteposa |
| `estudiante` | **Aprendre**, Consultar, Documentar | `work_mode.dart:155-165`: ordre didàctic explícit; a més, un estudiant sol no tenir `hasHospital`, així que Documentar sovint ni es mostra |
| `esterilizacion` | Consultar, Documentar, Aprendre (= per defecte) | El seu contingut de referència (Esterilització, catàleg) ja viu a Consultar en primera posició |
| `enfermeria` | Consultar, Documentar, Aprendre (= per defecte) | `work_mode.dart:93-103`: context clínic ampli primer, igual que l'ordre per defecte ja fa |

Dins del bloc "Documentar", mantenir el reorder ja existent de `cirujano` (línies 924-926) tal qual — no cal tocar-lo, ja fa el correcte per a aquest mode.

**"Xarxa de grup" dins de Documentar** (decisió §8.4 del pla principal): cap canvi necessari per a la majoria de modes; únicament `supervision` (gestiona relació entre seus) podria anteposar-lo dins del bloc — marcat com a detall de baixa prioritat a §7 (Preguntes obertes), no val la pena una regla pròpia per 1 ítem i 1 mode.

### 3.2 Nivell 1 (`HomeSectionKey`, blocs fora de Dreceres)

Aquí la resposta honesta és **no inventar cap bloc nou** per a `esterilizacion`/`enfermeria`/`cirujano`/`estudiante`: els 3 blocs especials que ja existeixen (Pendents d'aprovar, Safates per preparar, Progrés de l'equip) estan lligats a dades molt concretes (cua d'aprovació, safates que necessiten preparació, rol de supervisió) que no tenen un equivalent natural per a aquests 4 modes — inventar-ne un forçaria una diferència artificial, exactament el que el propi comentari de `_sectionOrderForMode` (línies 81-86) ja diu que cal evitar. **La personalització real per a aquests 4 modes ha de viure al Nivell 2 (§3.1), no aquí.** Deixar `_sectionOrderForMode` tal qual per a aquests 4 modes és la resposta correcta, no un forat pendent.

### Cost

**Gratuït**: generalitzar una funció que ja existeix (`_sectionOrderForMode`) i aplicar el mateix patró de `switch`/llista a un segon punt (ordre de blocs dins `_buildQuickAccessSection`), igual que el pla principal ja proposa dividir aquesta funció en sub-mètodes per bloc (Fase 1, §6 del pla principal). Cap crida de xarxa nova — tot llegeix `activeWorkModeNotifier.value`, ja en memòria.

---

## 4. Proposta: personalització per rol i progrés (no lligada al mode)

Dos eixos que el mode de treball no cobreix i que el pla principal no toca:

### 4.1 Rol (admin/approver): comptador ja calculat, cap crida nova

`_fetchPendingApprovals()` (`home_screen.dart:1112-1120`) ja compta els pendents per a qui veu aquest bloc. Mostrar aquest mateix nombre com a `InstriqCountBadge` (component ja existent, citat a `docs/redesign_v1.2_plan.md:89`) a la capçalera del bloc és **cost zero**: és el mateix `Future` ja en marxa, no una consulta nova. (Detall purament visual — es deixa a l'informe de disseny/interacció si val la pena o no; aquí només es flaga que el número ja existeix sense cost afegit.)

### 4.2 Progrés local: substituir subtítols estàtics per dades reals ja carregades

- **"El meu progrés"** (`home_screen.dart:1002-1009`): subtítol avui estàtic (`myProgressSubtitle` = "Check your progress by category", `app_en.arb:64`). Es pot substituir per `${ProgressService.instance.learnedCount}/${ProgressService.instance.totalCount}` — getters síncrons ja en memòria (`progress_service.dart:178-182`), zero cost.
- **"Ruta d'aprenentatge"** (`home_screen.dart:942-949`): mateixa idea amb els passos completats de `LearningPathScreen`, però **requereix un canvi petit, no esquema nou**: avui `_completed`/`_prefsKey` (`learning_path_screen.dart:43-46`) són privats de `_LearningPathScreenState`. Cal moure la clau `'learning_path_completed_steps'` (i, idealment, un mètode `Future<int> completedCount()`) a un lloc compartit (p. ex. un petit mètode estàtic a `LearningPathScreen` o extret a un servei minúscul) perquè `home_screen.dart` el pugui llegir sense duplicar l'string literal. Segueix sent 100% local (`SharedPreferences`), zero xarxa, zero taula nova.

### 4.3 El que SÍ necessitaria feina de backend (flagat explícitament, no assumit gratis)

- Fer visible el progrés de la Ruta d'aprenentatge **entre dispositius** o **a un admin que vol veure quant ha avançat el seu equip** exigiria pujar aquest checklist a una taula (similar a `learning_progress`, que `ProgressService` ja sincronitza per a instruments/quiz, `progress_service.dart:44-57`) — avui és deliberadament local (comentari de `learning_path_screen.dart:19-23`: "nadie necesita ver esta checklist desde otro dispositivo ni el equipo necesita verla de nadie más"). Si el propietari vol aquesta visibilitat d'equip, és un ítem de schema nou, no una tasca d'aquesta ronda de disseny.

---

## 5. Onboarding: el forat real i propostes concretes

### 5.1 Recomanació principal: un únic punt de disparament a `HomeScreen`, no 3 d'ampliats

En lloc d'afegir lògica a cadascun dels 3 camins de §1.4 (`GroupEntryScreen`, `AcceptInvitationScreen`, `HospitalConnectFlow`), la solució més barata i més robusta és **un sol check a `HomeScreen`**, el lloc on els 3 convergeixen: si `hasHospital == true` i `activeWorkModeNotifier.value == null` i un flag local nou (p. ex. `has_prompted_work_mode`, mateix patró que `has_seen_onboarding`) encara no s'ha marcat, mostrar un cop el `WorkModePicker` (ja construït, `lib/widgets/work_mode_picker.dart`) com a full-screen/sheet, i marcar el flag independentment de si l'usuari tria un mode o el salta. **És la recomanació de més impacte d'aquest document**: sense això, tot §3 (set de taules de personalització per mode) continua sent inert per a qualsevol usuari que no descobreixi `account_privacy_screen.dart` pel seu compte — avui, ningú.

Cost: **gratuït–cheap**. Reutilitza `WorkModePicker` i `setActiveWorkMode` (`profile_service.dart:131-135`, ja un `update` directe sense RPC) tal qual; només cal un flag `SharedPreferences` nou (mateix patró ja usat 2 cops al projecte: `has_seen_onboarding` a `main.dart:123`, `dismissed_version_notice_*` a `main.dart:140`) i una comprovació a `initState`/`build` de `HomeScreen`.

### 5.2 Nudge cap a `LearningPathScreen` per a qui encara no ha completat res

Un cop `has_seen_onboarding` és cert i l'usuari és a Inici com a guest (sense hospital, o amb hospital però 0 passos completats), afegir una targeta/enllaç destacat dins del bloc "Aprendre" (no una secció nova — encaixa dins l'estructura ja aprovada al pla principal, §3.2) que porti a `LearningPathScreen`, visible només mentre `learning_path_completed_steps` (§4.2) sigui buit, i que es descarti sola (mateix flag local) un cop s'hi ha entrat o s'ha descartat explícitament.

**Alternativa més intrusiva, no recomanada per defecte** (per si el propietari la prefereix): encadenar `LearningPathScreen` just després d'`OnboardingScreen` a `_checkOnboarding` (`main.dart:121-130`), mateix patró de `push` únic. Desavantatge: força un flux de 5 pantalles a algú que només vulgui mirar una fitxa d'instrument ràpidament — per això es proposa la targeta discreta (§5.2 principal) com a opció per defecte, i aquesta com a fallback si el propietari vol una empenta més forta.

### 5.3 Arreglar la promesa trencada d'`OnboardingScreen`, pàgina 3

El text actual (`app_en.arb:18-19`, pàgina 3 d'`onboarding_screen.dart`) promet una acció ("join with their code") que la pantalla no ofereix — només `Skip`/`Next`/`Start`, tots purament de navegació interna del `PageView`. Dues opcions, cap decidida aquí:
- (a) Afegir un botó real a la pàgina 3 que obri `HospitalConnectFlow` directament (reutilitza el widget tal qual, cost mínim), o
- (b) Suavitzar el text perquè no prometi una acció que no hi és, deixant que §5.1/§5.2 siguin el camí real cap a connectar un hospital.

### 5.4 Simetria crear vs. unir-se

`_create()` mostra un diàleg de confirmació amb el codi (`group_entry_screen.dart:170-220`); `_join()` no mostra res després d'un èxit (`group_entry_screen.dart:86-118`) — simplement torna enrere en silenci. No és un flux trencat (qui ho ha obert des de `LearningPathScreen` o `LibraryScreen` ja veu el canvi reflectit allà mateix), però és una asimetria real. Es flaga com a detall menor, de presentació (confirmació visible sí/no) — es deixa la forma concreta (diàleg, `SnackBar`...) a l'informe de disseny visual; aquí només es constata que avui no hi ha cap senyal de "ja ets dins" al camí d'unir-se.

---

## 6. Cost per proposta

| Proposta | Cost | Per què |
|---|---|---|
| Estendre `_sectionOrderForMode`/reorder d'ítems als 7 modes (§3) | **Gratuït** | Mateix patró `switch`/llista ja existent, cap crida nova |
| Comptador de pendents com a `InstriqCountBadge` (§4.1) | **Gratuït** | Reutilitza un `Future` ja en marxa |
| Subtítols de progrés reals a "El meu progrés"/"Ruta d'aprenentatge" (§4.2) | **Gratuït–cheap** | Getters ja en memòria; calcula compartir una clau `SharedPreferences` avui privada |
| Prompt de mode de treball al primer `hasHospital == true` (§5.1) | **Cheap** | 1 flag local nou + 1 pantalla ja construïda (`WorkModePicker`) |
| Targeta/nudge cap a `LearningPathScreen` (§5.2) | **Cheap** | 1 flag local nou, cap pantalla nova |
| Botó real o text corregit a `OnboardingScreen` pàgina 3 (§5.3) | **Gratuït–cheap** | 1 botó que obre un widget ja existent, o només canvi de text |
| Confirmació visible al camí d'unir-se (§5.4) | **Cheap** | Detall de presentació, delegat al disseny visual |
| Progrés d'equip de la Ruta d'aprenentatge al servidor (§4.3) | **No proposat aquí — necessita esquema nou** | Flagat explícitament, no assumit gratis |

---

## 7. Fases (per a una sessió futura, després de les 3 fases del pla principal)

### Fase A — Personalització per mode (independent de la resta, es pot fer abans o després de la Fase 1 del pla principal)
- Generalitzar `_sectionOrderForMode` i l'ordre de blocs dins `_buildQuickAccessSection`/blocs nous (§3.1-3.2).
- Subtítols de progrés reals (§4.2), compartint la clau `learning_path_completed_steps`.

### Fase B — Onboarding (depèn de res de la Fase A, pot anar en paral·lel)
- Prompt de mode de treball al primer `hasHospital == true` (§5.1) — la de més impacte, prioritzar-la primer dins d'aquesta fase.
- Targeta/nudge cap a `LearningPathScreen` (§5.2).
- Arreglar pàgina 3 d'`OnboardingScreen` (§5.3).

### Fase C — Polish menor
- Comptador de pendents com a badge (§4.1).
- Confirmació visible al camí d'unir-se (§5.4).

Cap fase introdueix dependències noves ni esquema nou (excepte si el propietari demana explícitament §4.3).

---

## 8. Preguntes obertes per al propietari

1. **Prompt de mode de treball (§5.1): obligatori o descartable?** Es proposa que es pugui saltar (com ja fa `WorkModePicker` amb l'opció "Sense preferència"), però cal decidir si es torna a oferir mai més passiu (p. ex. un recordatori únic més endavant) o si saltar-lo és definitiu fins que l'usuari el trobi sol a Perfil.
2. **Nudge cap a `LearningPathScreen` (§5.2): targeta discreta o empenta forta (auto-navegar un cop)?** Es recomana la targeta per defecte (menys intrusiva), però es flaga l'alternativa si el propietari prioritza que ningú es perdi la ruta.
3. **"Xarxa de grup" per a `supervision` dins de Documentar (§3.1, final)**: val la pena una regla d'ordre específica per 1 sol ítem i 1 sol mode, o es deixa sempre al final del bloc per a tothom (més simple)?
4. **§4.3 (progrés d'equip de la Ruta d'aprenentatge visible a un admin)**: és una necessitat real avui, o es queda fora d'abast com està ara (local, per dispositiu)? Si és que sí, cal una ronda de disseny de schema pròpia, no incrustar-ho aquí.
5. **Pàgina 3 d'`OnboardingScreen` (§5.3)**: botó real cap a `HospitalConnectFlow`, o simplement suavitzar el text? Afecta directament si aquesta pantalla passa a dependre de xarxa/sessió (avui no en depèn gens).

---

## 9. Fora d'abast d'aquest document

- Qualsevol canvi visual/d'interacció (colors, components, animacions, layout) — cobert per l'informe germà de disseny visual.
- Accessibilitat (contrast, mida de toc, lectors de pantalla) — cobert per l'informe germà d'accessibilitat.
- L'agrupació de Dreceres en blocs Consultar/Aprendre/Documentar/Equip en si (§3.2 i §8 de `docs/redesign_v1.2_plan.md`) — ja decidida, no es toca ni es contradiu aquí; aquest document només hi afegeix l'ordre *dins* d'aquesta estructura per mode.
- Qualsevol dependència nova o esquema nou de Supabase — explícitament descartat, excepte el que es flaga a §4.3 com a decisió pendent del propietari.
