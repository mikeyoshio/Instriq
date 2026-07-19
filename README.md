# Instriq

Plataforma profesional de conocimiento colaborativo para el bloque quirúrgico (Flutter: Android, iOS, Web). Reúne instrumental, técnicas, protocolos y la experiencia real del equipo en un solo lugar, y permite a cualquier grupo (un hospital, un bloque quirúrgico, un servicio, un equipo de instrumentistas, un centro de formación...) documentar su propia forma de trabajar — sustituyendo las carpetas de papel desactualizadas por algo que se lleva en la tablet o el móvil.

El uso básico (catálogo, flashcards, quiz, progreso) **no requiere cuenta**. Solo hace falta iniciar sesión si quieres unirte o crear el espacio compartido de tu grupo.

## Capturas

| Bienvenida | Catálogo | Detalle | Flashcards |
|---|---|---|---|
| ![Bienvenida](docs/screenshots/welcome.png) | ![Catálogo](docs/screenshots/catalogo.png) | ![Detalle](docs/screenshots/detalle_instrumento.png) | ![Flashcards](docs/screenshots/flashcards.png) |

## Funcionalidades

- **Catálogo**: instrumental organizado por especialidad (cirugía general, laparoscopia/energía avanzada, robótica, ortopedia/trauma, neurocirugía, cardiovascular, ginecología/obstetricia, urología, ORL) y por categoría funcional (corte, disección, sutura, separación, succión, especiales). Cada instrumento incluye nombres comerciales y fabricante como alias (ej. "LigaSure" de Medtronic, "Harmonic" de Ethicon).
- **Aprende**: flashcards y quiz de opción múltiple con mejor puntuación guardada.
- **Progreso**: seguimiento local de instrumentos aprendidos por categoría.
- **Organización → Espacios de trabajo**: cada grupo puede tener varios espacios (por especialidad, servicio, formación...); técnicas, protocolos y tarjetas de preferencia cuelgan de un espacio, no solo del grupo entero.
- **Técnicas quirúrgicas y protocolos**: contenido propio del espacio, con **versionado y flujo de aprobación** — cada edición crea un borrador; quien aprueba lo revisa, compara campo a campo con la versión publicada y aprueba o rechaza. Nada se sobrescribe: hay historial completo y restauración a versiones anteriores. Especialidad estandarizada según el catálogo oficial de especialidades quirúrgicas (Real Decreto 183/2008).
- **Tarjetas de preferencia**: instrumental específico por cirujano y procedimiento, compartido entre el personal del mismo espacio vía Supabase, con marca de "validado por el cirujano".
- **Roles granulares por espacio**: Owner y Administrator a nivel de grupo; Approver, Editor y Reader asignados por espacio — quién puede leer, crear/editar borradores, o aprobar/rechazar cambios.
- **Alta de grupo por autoservicio**: cualquier persona (jefa de quirófano o quien quiera) puede registrar su grupo. La persona que lo crea es Owner y Administrator — puede regenerar el código de invitación, gestionar miembros, roles por espacio y transferir la propiedad.
- **GDPR**: exportar los propios datos (perfil, contenido creado/aprobado, roles) como JSON, y eliminar la cuenta — el contenido que se haya creado o aprobado se conserva anonimizado para el equipo ("Usuario eliminado"), no se pierde el conocimiento compartido.
- **Aviso de actualización** (Android/iOS): comprueba si hay una versión más reciente publicada y lo notifica sin bloquear el uso.
- **Modo claro/oscuro** con toggle manual persistente.

## Stack técnico

- **Flutter** (Dart) — Android, iOS y Web desde el mismo código.
- **Supabase** — Auth (email/contraseña), Postgres con Row Level Security, API REST autogenerada.
- **shared_preferences** para progreso y preferencia de tema local (funciona sin cuenta).

## Estructura del proyecto

```
lib/
  models/       # Instrument, PreferenceCard, GroupDocument(Version), Workspace(Role/Member), Hospital (= grupo)
  data/         # Catálogo de instrumental (~70) y especialidades quirúrgicas estándar
  services/     # Supabase, auth, perfil/grupo, espacios, progreso, tema, cuenta (GDPR), versión de la app
  screens/
    auth/       # Bienvenida, login/registro, alta de grupo, flujo de conexión
    admin/      # Gestión del grupo (código, miembros, propiedad)
    ...         # Catálogo, Aprende, progreso, espacios, técnicas/protocolos, tarjetas, cuenta y privacidad
  utils/        # Generador de código de invitación
supabase/       # Esquema SQL (ejecutar en orden: schema.sql → schema_v9_gdpr.sql, ver más abajo)
```

## Desarrollo

```bash
flutter pub get
flutter run                 # dispositivo/emulador Android o iOS conectado
flutter run -d chrome        # navegador
```

### Backend (Supabase)

1. Crea un proyecto en [supabase.com](https://supabase.com).
2. En el SQL Editor, ejecuta en orden todos los `supabase/schema_v*.sql` (y `schema.sql` primero):
   `schema.sql` → `schema_v2_hospital_admin.sql` → `schema_v3_fix_rls_recursion.sql` → `schema_v4_group_documents.sql` → `schema_v5_group_document_versions.sql` → `schema_v6_workspaces.sql` → `schema_v7_roles.sql` → `schema_v8_app_config.sql` → `schema_v9_gdpr.sql`.
3. Copia la URL y la **publishable key** (Project Settings → API) a `lib/services/supabase_config.dart`. Es pública/segura de commitear — la seguridad real la da Row Level Security, no el secreto de esta key.

## Despliegue

- **App** (`app.instriq.org`): Vercel. El repo incluye `vercel.json` + `vercel_build.sh` — como Vercel no trae Flutter preinstalado, el script clona el SDK stable en cada build y compila con `flutter build web --release`. Basta con importar el repo en Vercel (framework preset "Other") y conectar el subdominio desde Cloudflare con un CNAME a `cname.vercel-dns.com`.
- **Landing** (`instriq.org`): carpeta `landing/`, HTML estático sin build — pensada para Cloudflare Pages (directorio raíz `landing/`). Incluye la política de privacidad (`landing/privacidad.html`).

## Licencias

- **Código**: [AGPL-3.0](LICENSE).
- **Documentación**: CC BY-SA 4.0.
- **Fotos de instrumental**: Wikimedia Commons con licencia libre verificada (CC0/CC-BY/CC-BY-SA); la atribución de cada una se muestra en la propia app, junto a la imagen.

## Estado / roadmap

- [x] Fotos reales de instrumental con licencia libre (19/70, resto sigue con icono por categoría)
- [x] Landing informativa + política de privacidad en `instriq.org`
- [x] Organización → Espacios de trabajo
- [x] Técnicas quirúrgicas y protocolos, con versionado y flujo de aprobación
- [x] Roles granulares por espacio (Owner, Administrator, Approver, Editor, Reader)
- [x] Exportar/eliminar cuenta (GDPR)
- [x] Aviso de actualización de la app
- [ ] Analítica de comunidad agregada y anónima (instrumental más consultado, especialidades con más actividad)
- [ ] Auditoría completa de acciones y red de conocimiento (instrumental ↔ técnicas ↔ protocolos)
- [ ] Interfaz en catalán (por defecto), castellano e inglés
- [ ] Sistema de donaciones transparente
