# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

La app es Flutter (Android, iOS, Web, Windows) con un sistema de diseño propio que no cambia según el sistema operativo. La web pública (`landing/`) es HTML/CSS estático servido con Cloudflare (`wrangler deploy`).

## Users

instriq.org atiende por igual a tres públicos, y cada uno tiene su propio camino desde la portada:

- **Enfermería de quirófano e instrumentistas**: llegan a título individual, a menudo desde el móvil o la tableta en el propio bloque. Quieren encontrar una pieza, una técnica o un protocolo, y aprender a moverse en quirófano.
- **Supervisión y jefes de bloque**: deciden si su equipo u hospital adopta Instriq. Valoran el espacio compartido del grupo, el versionado con aprobación, los roles y la auditoría.
- **Formación (estudiantes, residentes, docentes y centros de simulación)**: usan el catálogo, las tarjetas, el quiz, la ruta de aprendizaje, las escalas y el ECG. Tienen su página propia (`landing/edu.html`).

## Product Purpose

Instriq reúne en un solo sitio el instrumental, las técnicas, los protocolos y la experiencia real del bloque quirúrgico, para sustituir la carpeta de papel desactualizada. El uso básico no pide cuenta.

Una visita a instriq.org es un éxito si el visitante hace cualquiera de estas cosas:

- abre la app web (app.instriq.org);
- la descarga de Microsoft Store;
- da de alta el espacio de su grupo;
- consulta el Vademécum público (es la entrada SEO: alguien busca una pieza y se queda a explorar).

## Positioning

- **Gratis y de código abierto** (AGPL-3.0): sin coste y sin depender de un proveedor.
- **El conocimiento es del propio equipo**: cada grupo documenta su forma de trabajar, con versiones, aprobación e historial; no es un manual genérico.
- **Hecho por enfermería de quirófano**: nace dentro del bloque y está en catalán, castellano e inglés.

## Operating Context

- Se usa de pie en el bloque, en la tableta o el móvil, a menudo sin conexión: técnicas, protocolos y tarjetas quedan en caché y lo que se crea sin red espera en cola.
- Gira en torno a rituales reales del quirófano:
  - montar y validar bandejas después de esterilizar;
  - tarjetas de preferencia del cirujano;
  - la agenda quirúrgica y los casos del día (Radar);
  - incidencias con acción correctiva;
  - checklist al estilo OMS.
- Cada persona elige un modo de trabajo: instrumentista, supervisión, esterilización/CSSD, enfermería quirúrgica, cirujano/anestesia, estudiante o docente. El modo solo cambia el orden de la información; no da ni quita permisos.
- La app tiene 4 pestañas (Hoy, Buscar, Mi equipo, Aprender), con el Perfil en la cabecera.

## Capabilities and Constraints

- **Catálogo**: 806 entradas en 20 especialidades, con fotos de licencia libre verificada. También incluye robótica (14 plataformas), farmacología, cierre de heridas y esterilización estructurada.
- **Referencia**:
  - 13 posiciones quirúrgicas;
  - 41 guías perioperatorias (asepsia, seguridad, paciente, material, técnicas y urgencias);
  - 12 escalas con cálculo guiado;
  - 103 siglas;
  - calculadoras clínicas;
  - ECG con 20 ritmos y práctica con tiras siempre distintas.
- **Aprendizaje**: ruta de aprendizaje, tarjetas, quiz, progreso y «Mis técnicas», que solo se guarda en el dispositivo.
- **Grupos**:
  - espacios de trabajo;
  - roles por espacio (Owner, Admin, Approver, Editor, Reader), también asignables a un equipo entero;
  - bandejas, técnicas, protocolos y tarjetas de preferencia, todo versionado y con aprobación;
  - auditoría;
  - Biblioteca Pública con traducciones de la comunidad revisadas por personas.
- **Idiomas**: catalán por defecto, castellano e inglés. La web sigue el mismo criterio.
- **Restricciones firmes**:
  - **Nunca dosis de fármacos** ni calculadoras de dosis.
  - **Ninguna función de contenido generado por IA** dentro de Instriq.
  - Todo el contenido es propio; nunca se copia de terceros.
  - La analítica de uso es anónima: recuentos diarios, sin guardar usuario ni hora. Se explica en «Qué datos recoge Instriq».
  - Instriq es una herramienta educativa y de apoyo: siempre se sigue el protocolo de cada centro.
- **Pendiente de decidir**: la publicación en Android e iOS (de momento solo hay Microsoft Store), y el inicio de sesión con Google/Microsoft dentro de la app de Windows (ya funciona en la web).

## Brand Commitments

- Nombre: **Instriq**. Dominios: instriq.org (web y Vademécum) y app.instriq.org (app).
- Logo e icono: `assets/icon/icon.png` y `landing/favicon.png`.
- Tono:
  - profesional, de tú a tú con quien trabaja en el quirófano, sin exagerar;
  - términos clínicos correctos en cada idioma;
  - la versión catalana es la de referencia.
- Siempre se acompaña del aviso de que es una herramienta de apoyo y de seguir el protocolo del centro.

## Evidence on Hand

Material real disponible:

- Capturas reales de la app:
  - `docs/screenshots/`;
  - `landing/screenshots/`;
  - `landing/help-screens/`;
  - `store_screenshots/{ca,es,en}/` (9 por idioma, 1920×1080).
- Vademécum público generado desde el catálogo: `landing/vademecum/`.
- Historial de novedades #1–#101: `landing/novedades.html`.
- Texto de la ficha de la Store: `docs/store_listing_1.3.1.md`.
- Imagen para compartir: `landing/og-image.png`.

Lo que **no hay** y no se puede inventar: testimonios, hospitales clientes con nombre, cifras de usuarios, prensa y certificaciones.

## Product Principles

1. **Sin barreras para empezar**: se consulta y se aprende sin cuenta y sin instalar nada; la cuenta solo hace falta para compartir con el grupo.
2. **El equipo es el autor**: el conocimiento lo escribe y aprueba una persona del grupo, con historial. Nada se sobrescribe y nada lo genera una máquina.
3. **Rigor clínico antes que volumen**: contenido propio y revisado, fuentes citadas (por ejemplo, ERC 2025), sin dosis y sin afirmaciones que no se puedan sostener.
4. **Pensado para el bloque**: funciona sin conexión, en la tableta y en tres idiomas, para cualquier perfil del quirófano.
5. **Abierto y de todos**: código abierto, Biblioteca Pública y Vademécum gratuito.

## Accessibility & Inclusion

- Paridad completa en tres idiomas (ca/es/en) en la app y en la web.
- La app tiene tema claro y oscuro, con contraste revisado en 1.3.1.
- No se ha fijado formalmente ningún estándar (por ejemplo, WCAG AA). Es una decisión abierta.
