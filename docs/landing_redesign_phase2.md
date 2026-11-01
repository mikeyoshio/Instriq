# Rediseño landing Instriq — Fase 2 (Arquitectura + Copy)

> Fase 2 del brief del usuario: preparar arquitectura de información, wireframe textual, orden de secciones y copy completo en los 3 idiomas, antes de tocar ningún HTML (Fase 3). Basado en el brief original del usuario + hallazgos reales de la auditoría Fase 1 (`docs/CHANGELOG.md`, entrada "Auditoria de Fase 1 del rediseny del landing").

## Cambios de estructura respecto al brief original (justificar antes de escribir copy)

El brief original proponía 10 secciones. Se reducen a 9, fusionando dos pares que decían lo mismo desde ángulos distintos — razón ya adelantada en la revisión del brief:

1. **Sección 3 ("El público objetivo", dentro del Hero) y Sección 8 ("Adaptado a distintos contextos") se fusionan.** Ambas enumeran perfiles (instrumentista, estudiante, docente, hospital...). En vez de una sección aparte a media página, los contextos de uso se integran como sub-bloque corto dentro de la sección "Organizar en equipo" (la única de las 9 donde "quién lo usa y para qué" aporta algo que el resto de secciones no ya mostró con ejemplos reales).
2. **"Auditoría" baja de prioridad como gancho comercial** (ver crítica ya compartida): no desaparece, pero se menciona junto a versionado/roles sin ser el titular de ningún bloque.
3. **Se añade una mención breve de la analítica agregada (placeholder "Properament")** dentro de "Open Source y Transparencia" — ya existe en el `index.html` real y no aparecía en la arquitectura de 10 secciones del brief.
4. **Se añade un matiz de honestidad institucional** ("sin SLA, sin soporte contractual formal") en la misma sección, para el público de hospitales/universidades que el brief quiere atraer sin sobrevender.

Estructura final (9 secciones + CTA final):

1. Hero
2. El propósito
3. Consultar (Vademécum)
4. Aprender
5. Documentar
6. Compartir conocimiento (Biblioteca Pública)
7. Organizar en equipo (+ contextos de uso)
8. Open Source y Transparencia
9. CTA final

## Navegación principal

Se mantiene la propuesta del brief, con una aclaración: "Documentar" y "Biblioteca Pública" son conceptualmente parte del mismo bloque de landing ("documentar" → "compartir"), pero se mantienen como 2 ítems de navegación separados porque corresponden a 2 destinos muy distintos en la app real (espacio de trabajo privado vs. contenido público) — fusionarlos en el nav confundiría más de lo que simplifica.

```
Inicio · Explorar · Aprender · Documentar · Biblioteca Pública · Proyecto
```

- **Explorar**: Vademécum · Especialidades · Instrumental · Suturas · Esterilización
- **Aprender**: Flashcards · Cuestionarios · Modo Docente · /edu
- **Documentar**: Técnicas y protocolos · Bandejas · Tarjetas de preferencia · Espacios de trabajo
- **Proyecto**: Misión · Cómo colaborar · Novedades · Transparencia · Licencias · Donaciones

Selector de idioma y "Abrir Instriq" siempre visibles. En móvil: menú hamburguesa de un nivel, sin submenús anidados — los 5 subgrupos de arriba se aplanan en una sola lista por sección al desplegar.

---

## 1. HERO

**CTA principal**: Explorar el conocimiento quirúrgico (→ Vademécum)
**CTA secundario**: Abrir Instriq
**Badges**: Open Source · AGPL-3.0 · Sin ánimo de lucro

### CA
- **Títol**: El coneixement de quiròfan, obert i compartit.
- **Subtítol**: Una plataforma oberta per consultar, aprendre i documentar coneixement sobre instrumental, tècniques, protocols, safates i tot allò relacionat amb l'entorn quirúrgic.
- **Text complementari**: Per a professionals, estudiants, docents i qualsevol persona interessada a conèixer i aprendre sobre el món quirúrgic.

### ES
- **Título**: El conocimiento del quirófano, abierto y compartido.
- **Subtítulo**: Una plataforma abierta para consultar, aprender y documentar conocimiento sobre instrumental, técnicas, protocolos, bandejas y todo lo relacionado con el entorno quirúrgico.
- **Texto complementario**: Para profesionales, estudiantes, docentes y cualquier persona interesada en conocer y aprender sobre el mundo quirúrgico.

### EN
- **Title**: Operating room knowledge, open and shared.
- **Subtitle**: An open platform to explore, learn and document knowledge about surgical instruments, techniques, protocols, trays and the operating room environment.
- **Supporting text**: For professionals, students, educators and anyone interested in learning about the surgical environment.

---

## 2. EL PROPÓSITO

### CA
- **Títol**: El coneixement de quiròfan no hauria de dependre d'on estigui guardat.
- **Cos**: Manuals en paper, fitxes tècniques disperses, cada equip anomenant el mateix instrument d'una manera diferent, protocols que ningú actualitza perquè viuen en un document que només té una persona. Instriq no pretén eliminar tot això — pretén donar-li un lloc obert, estructurat i mantenible: un catàleg amb nom i sinònims clars, tècniques amb historial de versions, bandejes amb checklist real. No substitueix la formació reglada, les instruccions del fabricant ni els protocols de la teva institució — hi afegeix un lloc on consultar-ho i mantenir-ho actualitzat.

### ES
- **Título**: El conocimiento del quirófano no debería depender de dónde esté guardado.
- **Cuerpo**: Manuales en papel, fichas técnicas dispersas, cada equipo llamando al mismo instrumento de una forma distinta, protocolos que nadie actualiza porque viven en un documento que solo tiene una persona. Instriq no pretende eliminar todo esto — pretende darle un lugar abierto, estructurado y mantenible: un catálogo con nombre y sinónimos claros, técnicas con historial de versiones, bandejas con checklist real. No sustituye la formación reglada, las instrucciones del fabricante ni los protocolos de tu institución — añade un sitio donde consultarlo y mantenerlo actualizado.

### EN
- **Title**: Surgical knowledge shouldn't depend on where it happens to be stored.
- **Body**: Paper manuals, scattered technical sheets, every team calling the same instrument something different, protocols nobody updates because they live in one person's document. Instriq doesn't aim to eliminate all of that — it aims to give it an open, structured, maintainable home: a catalog with clear names and synonyms, techniques with real version history, trays with a real checklist. It doesn't replace formal training, manufacturer instructions or your institution's own protocols — it adds a place to look things up and keep them current.

---

## 3. CONSULTAR (Vademécum)

**CTA**: Explorar el Vademécum

### CA
- **Títol**: Explora el coneixement quirúrgic.
- **Cos**: El Vademécum públic d'Instriq reuneix 601 instruments en 19 especialitats, 17 sutures i l'equipament d'anestèsia — amb noms, sinònims, fabricants, mètodes d'esterilització i fitxa tècnica. Es consulta sense compte ni registre, en català, castellà i anglès.
- Llista de destacats: 601 instruments · 19 especialitats · Sutures i equipament d'anestèsia · Fabricants i sinònims · Esterilització estructurada

### ES
- **Título**: Explora el conocimiento quirúrgico.
- **Cuerpo**: El Vademécum público de Instriq reúne 601 instrumentos en 19 especialidades, 17 suturas y el equipamiento de anestesia — con nombres, sinónimos, fabricantes, métodos de esterilización y ficha técnica. Se consulta sin cuenta ni registro, en catalán, castellano e inglés.
- Lista de destacados: 601 instrumentos · 19 especialidades · Suturas y equipamiento de anestesia · Fabricantes y sinónimos · Esterilización estructurada

### EN
- **Title**: Explore surgical knowledge.
- **Body**: Instriq's public Vademecum brings together 601 instruments across 19 specialties, 17 sutures and anesthesia equipment — with names, synonyms, manufacturers, sterilization methods and technical sheets. No account or sign-up required, available in Catalan, Spanish and English.
- Highlights: 601 instruments · 19 specialties · Sutures and anesthesia equipment · Manufacturers and synonyms · Structured sterilization info

*(Nota de implementación para Fase 3: estas cifras deben leerse de una única constante compartida entre las 3 versiones de idioma, no repetirse a mano — es justo el problema que causó el bug 17/18/19.)*

---

## 4. APRENDER

**CTA**: Descubrir las herramientas de aprendizaje (→ /edu)

### CA
- **Títol**: Aprendre també forma part del coneixement quirúrgic.
- **Cos**: Flashcards i qüestionaris sobre tot el catàleg, amb repetició espaiada (Leitner) perquè el que ja domines no et faci perdre temps. Identificació visual d'instrumental i, per a qui ja treballa en equip, pràctica d'identificació de safates senceres. Docents i supervisors poden crear qüestionaris propis i seguir el progrés del seu equip.
- Distinció: el catàleg, les flashcards i els qüestionaris individuals no requereixen compte. Els qüestionaris d'equip i el seguiment de supervisor sí, perquè impliquen dades compartides d'un grup.

### ES
- **Título**: Aprender también forma parte del conocimiento quirúrgico.
- **Cuerpo**: Flashcards y cuestionarios sobre todo el catálogo, con repetición espaciada (Leitner) para que lo que ya dominas no te haga perder tiempo. Identificación visual de instrumental y, para quien ya trabaja en equipo, práctica de identificación de bandejas completas. Docentes y supervisores pueden crear cuestionarios propios y seguir el progreso de su equipo.
- Distinción: el catálogo, las flashcards y los cuestionarios individuales no requieren cuenta. Los cuestionarios de equipo y el seguimiento de supervisor sí, porque implican datos compartidos de un grupo.

### EN
- **Title**: Learning is part of surgical knowledge too.
- **Body**: Flashcards and quizzes covering the whole catalog, with spaced repetition (Leitner) so what you already know doesn't waste your time. Visual instrument identification and, for teams, full-tray identification practice. Educators and supervisors can build their own quizzes and track their team's progress.
- Distinction: the catalog, flashcards and individual quizzes need no account. Team quizzes and supervisor tracking do, because they involve a group's shared data.

---

## 5. DOCUMENTAR

**CTA**: Ver cómo funciona la documentación

### CA
- **Títol**: Documenta com es treballa de debò al teu quiròfan.
- **Cos**: Tècniques i protocols amb passos categoritzables a l'estil checklist de l'OMS, safates amb checklist de quantitats i sessions reals de preparació amb control de qualitat, targetes de preferència per cirurgià i procediment, instrumental propi de l'equip. Res se sobreescriu: cada canvi crea un esborrany, qui aprova el revisa i el compara abans de publicar-lo, i l'historial complet queda disponible per restaurar-lo. Exporta qualsevol fitxa a PDF amb la data i la versió exactes.
- Com es relaciona: una tècnica pot enllaçar-se al seu instrumental, a les safates que la fan servir i als vídeos que l'expliquen — el contingut es troba connectat, no en caixes separades.

### ES
- **Título**: Documenta cómo se trabaja de verdad en tu quirófano.
- **Cuerpo**: Técnicas y protocolos con pasos categorizables al estilo checklist de la OMS, bandejas con checklist de cantidades y sesiones reales de preparación con control de calidad, tarjetas de preferencia por cirujano y procedimiento, instrumental propio del equipo. Nada se sobrescribe: cada cambio crea un borrador, quien aprueba lo revisa y compara antes de publicarlo, y el historial completo queda disponible para restaurarlo. Exporta cualquier ficha a PDF con la fecha y la versión exactas.
- Cómo se relaciona: una técnica puede enlazarse a su instrumental, a las bandejas que la usan y a los vídeos que la explican — el contenido está conectado, no en cajas separadas.

### EN
- **Title**: Document how your operating room actually works.
- **Body**: Techniques and protocols with WHO-checklist-style categorizable steps, trays with quantity checklists and real preparation sessions with quality control, preference cards per surgeon and procedure, team-owned custom instruments. Nothing gets overwritten: every change creates a draft, whoever approves it reviews and compares it before publishing, and the full history stays available to restore. Export any record to PDF with the exact date and version.
- How it connects: a technique can link to its instruments, the trays that use it and the videos that explain it — content is connected, not boxed off.

---

## 6. COMPARTIR CONOCIMIENTO (Biblioteca Pública)

**CTA**: Explorar la Biblioteca Pública

### CA
- **Títol**: Coneixement obert, construït i revisat de forma responsable.
- **Cos**: La Biblioteca Pública reuneix tècniques, protocols, safates i instrumental aportats per la comunitat, amb revisió editorial per nivells de col·laboració, fils de comentaris i propostes de correcció, i traduccions proposades per qui vulgui ajudar. Pots seguir les actualitzacions del contingut que t'interessa i adoptar-lo al teu propi espai de treball com a punt de partida.
- **Avís important**: l'aprovació editorial no equival a validació clínica. El contingut públic és una referència de coneixement i un punt de partida — no substitueix la documentació oficial ni els protocols de la teva institució.

### ES
- **Título**: Conocimiento abierto, construido y revisado de forma responsable.
- **Cuerpo**: La Biblioteca Pública reúne técnicas, protocolos, bandejas e instrumental aportados por la comunidad, con revisión editorial por niveles de colaboración, hilos de comentarios y propuestas de corrección, y traducciones propuestas por quien quiera ayudar. Puedes seguir las actualizaciones del contenido que te interesa y adoptarlo en tu propio espacio de trabajo como punto de partida.
- **Aviso importante**: la aprobación editorial no equivale a validación clínica. El contenido público es una referencia de conocimiento y un punto de partida — no sustituye la documentación oficial ni los protocolos de tu institución.

### EN
- **Title**: Open knowledge, built and reviewed responsibly.
- **Body**: The Public Library brings together community-contributed techniques, protocols, trays and instruments, with tiered editorial review, comment threads and correction proposals, and translations proposed by anyone who wants to help. You can follow updates to content you care about and adopt it into your own workspace as a starting point.
- **Important note**: editorial approval does not equal clinical validation. Public content is a knowledge reference and a starting point — it does not replace official documentation or your institution's own protocols.

---

## 7. ORGANIZAR EN EQUIPO (+ contextos de uso)

**CTA**: Dar de alta mi organización

### CA
- **Títol**: Vols documentar i organitzar el coneixement del teu equip?
- **Cos**: Un grup (un hospital, una clínica, una universitat, un centre de formació, un equip privat) s'organitza en espais de treball per especialitat, servei o formació, amb rols (Reader, Editor, Approver, Administrator) individuals o per equip sencer. Funciona offline amb sincronització automàtica, i cada acció sensible queda registrada. No cal crear cap organització per consultar el Vademécum o fer servir les eines d'aprenentatge obertes — això és una capa addicional per a qui vulgui documentar i mantenir el coneixement del seu propi equip, des d'un equip petit fins a una organització amb diverses especialitats.
- **Contextos reals**: consulta individual al quiròfan o a esterilització, estudi i formació com a estudiant o resident, activitat docent amb seguiment d'equip, documentació d'un servei sencer — tots fan servir la mateixa base de coneixement, no una xarxa que els connecta entre si.

### ES
- **Título**: ¿Quieres documentar y organizar el conocimiento de tu equipo?
- **Cuerpo**: Un grupo (un hospital, una clínica, una universidad, un centro de formación, un equipo privado) se organiza en espacios de trabajo por especialidad, servicio o formación, con roles (Reader, Editor, Approver, Administrator) individuales o por equipo entero. Funciona offline con sincronización automática, y cada acción sensible queda registrada. No hace falta crear ninguna organización para consultar el Vademécum o usar las herramientas de aprendizaje abiertas — esto es una capa adicional para quien quiera documentar y mantener el conocimiento de su propio equipo, desde un equipo pequeño hasta una organización con varias especialidades.
- **Contextos reales**: consulta individual en quirófano o esterilización, estudio y formación como estudiante o residente, actividad docente con seguimiento de equipo, documentación de un servicio entero — todos usan la misma base de conocimiento, no una red que los conecta entre sí.

### EN
- **Title**: Want to document and organize your team's knowledge?
- **Body**: A group (a hospital, a clinic, a university, a training center, a private team) is organized into workspaces by specialty, service or training track, with roles (Reader, Editor, Approver, Administrator) assigned individually or to a whole team. It works offline with automatic sync, and every sensitive action is logged. You don't need to create an organization to browse the Vademecum or use the open learning tools — this is an additional layer for anyone who wants to document and maintain their own team's knowledge, from a small team to a multi-specialty organization.
- **Real-world contexts**: individual lookups in the OR or in sterilization, studying as a student or resident, teaching with team progress tracking, documenting a whole department — all drawing on the same knowledge base, not a network connecting them to each other.

---

## 8. OPEN SOURCE Y TRANSPARENCIA

**CTA**: Ver el código en GitHub

### CA
- **Títol**: Obert també en com està construït.
- **Cos**: El codi és públic sota AGPL-3.0; la documentació, sota CC BY-SA 4.0. Instriq no té inversors ni ànim de lucre — es manté fora d'hores, i qualsevol aportació via Buy Me a Coffee ajuda a cobrir el cost del servidor. Quan hi hagi prou activitat, publicarem aquí mètriques agregades i anònimes (l'instrumental més consultat, les especialitats amb més activitat) — mai dades d'una persona o un grup concrets.
- **Honestedat institucional**: cap contracte et lliga a nosaltres — si el projecte s'atura, el codi és teu i el pots executar o encarregar a qui vulguis. Dit això, és un projecte sense SLA ni suport contractual formal; si la teva institució necessita aquestes garanties, parlem-ne abans de dependre'n per a res crític.

### ES
- **Título**: Abierto también en cómo está construido.
- **Cuerpo**: El código es público bajo AGPL-3.0; la documentación, bajo CC BY-SA 4.0. Instriq no tiene inversores ni ánimo de lucro — se mantiene fuera de horas, y cualquier aportación vía Buy Me a Coffee ayuda a cubrir el coste del servidor. Cuando haya suficiente actividad, publicaremos aquí métricas agregadas y anónimas (el instrumental más consultado, las especialidades con más actividad) — nunca datos de una persona o un grupo concretos.
- **Honestidad institucional**: ningún contrato te ata a nosotros — si el proyecto se detiene, el código es tuyo y puedes ejecutarlo o encargarlo a quien quieras. Dicho esto, es un proyecto sin SLA ni soporte contractual formal; si tu institución necesita esas garantías, hablemos antes de depender de ello para algo crítico.

### EN
- **Title**: Open in how it's built, too.
- **Body**: The code is public under AGPL-3.0; the documentation under CC BY-SA 4.0. Instriq has no investors and is not for profit — it's maintained outside working hours, and any contribution via Buy Me a Coffee helps cover server costs. Once there's enough activity, we'll publish aggregated, anonymous usage metrics here (most-viewed instruments, most active specialties) — never data about a specific person or group.
- **Institutional honesty**: no contract ties you to us — if the project ever stops, the code is yours to run yourself or hand to anyone you choose. That said, there's no formal SLA or support contract behind it; if your institution needs those guarantees, let's talk before relying on it for anything critical.

---

## 9. CTA FINAL

### CA
- **Títol**: El coneixement quirúrgic, obert per a tothom.
- **Cos**: Consulta, aprèn i descobreix tot el que pots fer amb Instriq.
- Accions: Explorar el Vademécum · Començar a aprendre · Obrir l'app · Conèixer el projecte

### ES
- **Título**: El conocimiento quirúrgico, abierto para todos.
- **Cuerpo**: Consulta, aprende y descubre todo lo que puedes hacer con Instriq.
- Acciones: Explorar el Vademécum · Empezar a aprender · Abrir la app · Conocer el proyecto

### EN
- **Title**: Surgical knowledge, open for everyone.
- **Body**: Explore, learn and discover everything you can do with Instriq.
- Actions: Explore the Vademecum · Start learning · Open the app · About the project

---

## Misión, visión y valores (ya redactadas en el brief, adaptadas)

### Misión
- **CA**: Fer accessible el coneixement quirúrgic i facilitar-ne l'aprenentatge.
- **ES**: Hacer accesible el conocimiento quirúrgico y facilitar su aprendizaje.
- **EN**: Making surgical knowledge accessible and easier to learn.

### Visión
- **CA**: Esdevenir una referència oberta de coneixement sobre l'entorn quirúrgic.
- **ES**: Convertirse en una referencia abierta de conocimiento sobre el entorno quirúrgico.
- **EN**: Becoming an open reference for knowledge about the surgical environment.

### Valores
Acceso abierto al conocimiento · Aprendizaje y formación continua · Documentación estructurada · Transparencia y trazabilidad · Colaboración y revisión responsable · Software libre y sostenibilidad.

---

## SEO — estrategia por sección (nivel estratégico, no implementación de meta tags)

| Sección | Intención de búsqueda objetivo |
|---|---|
| Hero / Home | instrumental quirúrgico, catálogo de instrumental quirúrgico |
| Consultar / Vademécum | vademécum quirúrgico, tipos de pinzas quirúrgicas, instrumentación quirúrgica |
| Aprender / `/edu` | formación en instrumentación quirúrgica, estudio de instrumental quirúrgico |
| Documentar | técnicas quirúrgicas, bandejas de instrumental |
| Open Source | esterilización de instrumental (ficha técnica + método, ya cubierto por el Vademécum) |

Home (`index.html`), borrador de `<title>`/meta description:
- **ES**: `Instriq — Conocimiento quirúrgico abierto y compartido` / `Vademécum público, flashcards, técnicas y bandejas de instrumental quirúrgico. Consulta y aprende sin registrarte — código abierto, sin ánimo de lucro.`
- **CA**: `Instriq — Coneixement de quiròfan, obert i compartit` / `Vademècum públic, flashcards, tècniques i safates d'instrumental quirúrgic. Consulta i aprèn sense registrar-te — codi obert, sense ànim de lucre.`
- **EN**: `Instriq — Operating room knowledge, open and shared` / `Public vademecum, flashcards, techniques and surgical instrument trays. Explore and learn without an account — open source, not for profit.`

Mantener el resto de la auditoría SEO ya hecha en Fase 1 (hreflang, canonical, JSON-LD) tal cual — está mejor de lo que el brief original asumía.

---

## Pendiente de decisión del usuario antes de Fase 3

1. **`Specialty.general` vs `Specialty.cirugiaGeneral`**: ¿son una especialidad real o deberían fusionarse? Afecta a si "19" sigue siendo la cifra correcta a usar en todo este copy.
2. **Mecanismo de i18n único** (`?lang=` vs rutas `/es/`): decisión de arquitectura técnica, no de copy — necesaria antes de implementar la navegación nueva de forma consistente con el Vademécum.
3. Confirmar que los 9 CTAs de este documento (uno por sección) son los que se quieren, antes de maquetarlos.
