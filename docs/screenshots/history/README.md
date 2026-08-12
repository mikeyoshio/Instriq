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

Actualitzades per primera vegada el 2026-08-11 (fins llavors mai s'havien tocat des del primer commit, 2026-07-18):

| Captura | Inici | Avui |
|---|---|---|
| Entrada al grup | `docs_welcome_2026-07-18.png` (`WelcomeScreen`, eliminada) | `docs_welcome_2026-08-11.png` (`GroupEntryScreen`, la substitueix) |
| Catàleg | `docs_catalogo_2026-07-18.png` | `docs_catalogo_2026-08-11.png` |
| Fitxa d'instrument | `docs_detalle_instrumento_2026-07-18.png` | `docs_detalle_instrumento_2026-08-11.png` |
| Flashcards | `docs_flashcards_2026-07-18.png` | `docs_flashcards_2026-08-11.png` |

La d'"Entrada al grup" és un cas especial: no és el mateix component refrescat, és la pantalla que el va substituir. `WelcomeScreen`/`SignUpScreen`/`JoinHospitalScreen`/`RegisterHospitalScreen` es van eliminar sencers al Nivell 2 del Design System (2026-08), substituïts per una única `GroupEntryScreen` — la captura d'"inici" queda com l'única prova visual de com era l'onboarding abans del canvi.

## Convenció per a futures captures

Quan es refresqui una captura (a `landing/screenshots/` o `docs/screenshots/`), abans de sobreescriure-la: copiar la versió vigent aquí com `<origen>_<nom>_<data-d'avui>.png`. Així cada refresc queda com un punt més d'aquest historial, no com una substitució silenciosa.
