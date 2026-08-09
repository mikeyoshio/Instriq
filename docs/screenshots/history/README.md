# Historial visual d'Instriq

Captures reals de l'app i de la landing, extretes de l'historial de git, per veure com ha evolucionat el projecte des del principi. No són muntatges — són fitxers commitejats de veritat en cada moment indicat.

## Landing (`landing/screenshots/`)

Tres de les quatre captures de la landing s'han actualitzat diverses vegades a mesura que l'app canviava de disseny. Cada parella mostra la primera versió commitejada i la vigent avui.

| Captura | Inici | Avui |
|---|---|---|
| Catàleg | `landing_catalogo_2026-07-18.png` | `landing_catalogo_2026-08-10.png` |
| Inici (cercador) | `landing_home_2026-07-30.png` | `landing_home_2026-08-10.png` |
| Fitxa d'instrument | `landing_instrumento_2026-07-20.png` | `landing_instrumento_2026-08-10.png` |

`grupo.png` no hi és: només s'ha commitejat una vegada (2026-07-20) i mai s'ha actualitzat, així que no hi ha "abans/després" real a mostrar.

## README de GitHub (`docs/screenshots/`)

Aquestes 4 mai s'han actualitzat des del primer commit (2026-07-18) — són, de fet, ja l'"inici":

- `docs_welcome_2026-07-18.png` — la pantalla de Benvinguda original. **Ja no existeix a l'app**: l'embut d'autenticació es va refer sencer (Nivell 2 del Design System, 2026-08) i `WelcomeScreen`/`SignUpScreen`/`JoinHospitalScreen`/`RegisterHospitalScreen` es van eliminar, substituïts per una única `GroupEntryScreen`. Aquesta captura és avui l'única prova visual de com era l'onboarding abans del canvi.
- `docs_catalogo_2026-07-18.png`, `docs_detalle_instrumento_2026-07-18.png`, `docs_flashcards_2026-07-18.png` — mateix cas: són la versió "inici", encara sense parella d'"avui".

**Pendent** (necessita emulador, no disponible en aquesta sessió): capturar les 4 pantalles equivalents d'avui — sobretot `GroupEntryScreen` per substituir la de Benvinguda al README — i afegir-les aquí com `docs_*_<data>.png` seguint la mateixa convenció.

## Convenció per a futures captures

Quan es refresqui una captura (a `landing/screenshots/` o `docs/screenshots/`), abans de sobreescriure-la: copiar la versió vigent aquí com `<origen>_<nom>_<data-d'avui>.png`. Així cada refresc queda com un punt més d'aquest historial, no com una substitució silenciosa.
