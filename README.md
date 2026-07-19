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
- **Tarjetas de preferencia**: instrumental específico por cirujano y procedimiento, compartido entre el personal del mismo grupo vía Supabase, con marca de "validado por el cirujano".
- **Alta de grupo por autoservicio**: cualquier persona (jefa de quirófano o quien quiera) puede registrar su grupo y queda como administradora — puede regenerar el código de invitación y gestionar miembros.
- **Modo claro/oscuro** con toggle manual persistente.

## Stack técnico

- **Flutter** (Dart) — Android, iOS y Web desde el mismo código.
- **Supabase** — Auth (email/contraseña), Postgres con Row Level Security, API REST autogenerada.
- **shared_preferences** para progreso y preferencia de tema local (funciona sin cuenta).

## Estructura del proyecto

```
lib/
  models/       # Instrument, PreferenceCard, Hospital (= grupo), HospitalMember
  data/         # Catálogo de instrumental (const, ~70 instrumentos)
  services/     # Supabase, auth, perfil/grupo, progreso, tema
  screens/
    auth/       # Bienvenida, login/registro, alta de grupo, flujo de conexión
    admin/      # Gestión del grupo (código, miembros)
    ...         # Catálogo, Aprende (flashcards/quiz), progreso, tarjetas
  utils/        # Generador de código de invitación
supabase/       # Esquema SQL (ejecutar en orden: schema.sql, schema_v2, schema_v3, schema_v4)
```

## Desarrollo

```bash
flutter pub get
flutter run                 # dispositivo/emulador Android o iOS conectado
flutter run -d chrome        # navegador
```

### Backend (Supabase)

1. Crea un proyecto en [supabase.com](https://supabase.com).
2. En el SQL Editor, ejecuta en orden: `supabase/schema.sql`, `supabase/schema_v2_hospital_admin.sql`, `supabase/schema_v3_fix_rls_recursion.sql`, `supabase/schema_v4_group_documents.sql`.
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
- [ ] Exportar/eliminar cuenta (GDPR)
- [ ] Analítica de comunidad agregada y anónima (instrumental más consultado, especialidades con más actividad)
- [ ] Sistema de donaciones transparente
