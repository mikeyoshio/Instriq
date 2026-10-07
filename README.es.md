# Instriq

🌐 [Català](README.md) · **Castellano** · [English](README.en.md)

Plataforma profesional de conocimiento colaborativo para el bloque quirúrgico (Flutter: Android, iOS, Web). Reúne instrumental, técnicas, protocolos y la experiencia real del equipo en un solo lugar, y permite a cualquier grupo (un hospital, un bloque quirúrgico, un servicio, un equipo de instrumentistas, un centro de formación...) documentar su propia manera de trabajar — sustituyendo las carpetas de papel desactualizadas por algo que se lleva en la tableta o en el móvil.

El uso básico (catálogo, flashcards, quiz, progreso) **no requiere cuenta**. Solo hace falta iniciar sesión si quieres unirte o crear el espacio compartido de tu grupo.

## Capturas

| Entrada al grupo | Catálogo | Detalle | Flashcards |
|---|---|---|---|
| ![Entrada al grupo](docs/screenshots/welcome.png) | ![Catálogo](docs/screenshots/catalogo.png) | ![Detalle](docs/screenshots/detalle_instrumento.png) | ![Flashcards](docs/screenshots/flashcards.png) |

## Funcionalidades

- **Catálogo**: 342 instrumentos organizados en 17 especialidades/áreas (cirugía general, laparoscopia y energía avanzada, cirugía robótica, traumatología y ortopedia, neurocirugía, cardiovascular, ginecología y obstetricia, urología, otorrinolaringología, angiología y cirugía vascular, cirugía oral y maxilofacial, cirugía pediátrica, cirugía plástica, estética y reparadora, cirugía torácica, dermatología médico-quirúrgica y venereología, oftalmología, anestesiología y reanimación) y por categoría funcional (corte, disección, sutura, separación, succión, equipos y máquinas, especiales). Cada instrumento tiene el nombre y los alias (nombres comerciales y fabricante, ej. "LigaSure" de Medtronic, "Harmonic" de Ethicon) y, para el resto del contenido (descripción, uso, consejo clínico), todo completamente traducido a los 3 idiomas de la app — no un simple texto fijo en un único idioma.
- **Aprende**: flashcards y quiz de opción múltiple con mejor puntuación guardada.
- **Progreso**: seguimiento local de instrumentos aprendidos por categoría.
- **Asistente de creación de espacio de trabajo**: al dar de alta un grupo nuevo, un asistente guiado pregunta el tipo de organización y la especialidad principal, y ofrece adoptar de entrada un paquete inicial de bandejas recomendadas ya publicadas en la Biblioteca Pública — en lugar de empezar de cero.
- **Organización, no solo hospital**: el grupo puede ser un hospital, una clínica, una universidad, un centro de simulación, un fabricante o un equipo privado (`org_type`), cada uno organizado en varios **espacios de trabajo** (por especialidad, servicio, formación...); técnicas, protocolos y tarjetas de preferencia dependen de un espacio, no solo de la organización entera.
- **Modelo de datos relacional**: fabricante, cirujano, especialidad y etiquetas son entidades propias con sus propias tablas y FK, no texto libre — "no guardar texto cuando puede existir una relación". Menos duplicación, búsquedas y filtros más fiables.
- **Técnicas quirúrgicas y protocolos**: contenido propio del espacio, con **versionado y flujo de aprobación** — cada edición crea un borrador; quien aprueba lo revisa, lo compara campo a campo con la versión publicada y lo aprueba o lo rechaza. Nada se sobrescribe: hay historial completo y restauración a versiones anteriores. Especialidad estandarizada según el catálogo oficial de especialidades quirúrgicas (Real Decreto 183/2008). Los pasos de un protocolo se pueden agrupar en **categorías opcionales** (estilo checklist de seguridad quirúrgica de la OMS: Preoperatorio, Anestesia, Equipamiento, Instrumental, Seguridad, o una categoría propia).
- **Tarjetas de preferencia**: instrumental específico por cirujano y procedimiento, compartido entre el personal del mismo espacio vía Supabase, con marca de "validado por el cirujano" y el **mismo versionado y flujo de aprobación** (borrador → revisión → publicada → archivada) que técnicas/protocolos/bandejas.
- **Roles granulares por espacio, individuales o por equipo**: Owner y Administrator a nivel de organización; Approver, Editor y Reader asignados por espacio a una persona o a un **equipo entero** de una vez (`teams`/`team_members`) — el rol efectivo es el máximo entre el directo y el heredado del equipo.
- **Alta de grupo por autoservicio**: cualquier persona (jefe de quirófano o quien quiera) puede registrar su organización. La persona que la crea es Owner y Administrator — puede regenerar el código de invitación, gestionar miembros, equipos, roles por espacio y transferir la propiedad.
- **Auditoría**: registro de quién hizo qué y cuándo sobre acciones sensibles (aprobar/rechazar, crear/borrar documentos, cambios de rol, transferencia de propiedad, inicio de sesión), visible para admin/owner.
- **Cobertura de conocimiento y analítica de uso**: dashboard agregado de cuántas técnicas/protocolos hay documentados por especialidad (publicados vs. en revisión) y totales de espacios/miembros, más **analítica de uso real** (instrumental y contenido más consultado, búsquedas más frecuentes, búsquedas sin resultado) — agregada por organización y visible solo para admin, sin datos individuales por persona.
- **RGPD**: exportar los propios datos (perfil, contenido creado/aprobado, roles) como JSON, y eliminar la cuenta — el contenido que se haya creado o aprobado se conserva anonimizado para el equipo ("Usuario eliminado"), no se pierde el conocimiento compartido.
- **Aviso de actualización** (Android/iOS): comprueba si hay una versión más reciente publicada y lo notifica sin bloquear el uso.
- **Multiidioma**: catalán por defecto, castellano e inglés seleccionables desde un icono en el propio Inicio, con la elección guardada en el dispositivo. La landing pública sigue el mismo criterio.
- **Instrumental personalizado del equipo**: cada espacio de trabajo puede dar de alta su propio instrumental (con variantes y foto), privado para ese hospital/espacio — nunca se mezcla con el catálogo global ni es visible fuera de tu equipo. Cada foto subida por un equipo lleva un aviso explícito de que no está verificada por Instriq (a diferencia de las del catálogo global, con licencia libre comprobada).
- **Modo sin conexión**: técnicas, protocolos y tarjetas de preferencia se almacenan localmente y se pueden consultar sin red; crear o editar contenido sin conexión se pone en cola y se sincroniza solo al recuperarla.
- **Notificaciones push**: aviso cuando un contenido entra en revisión, se aprueba o se rechaza (Firebase Cloud Messaging), sin depender de abrir la app para enterarse.
- **Modo de Trabajo**: cada persona activa un único modo (instrumentista, supervisión de quirófano, esterilización/CSSD, enfermería quirúrgica, cirujano/a, estudiante, docente), cambiable al instante desde la cabecera. No es un sistema de permisos — solo reordena qué información de cada instrumento se muestra primero según este modo, sin ocultar nunca el resto de la ficha.
- **Esterilización estructurada**: cada instrumento puede llevar uno o varios métodos de esterilización (vapor, plasma de peróxido, óxido de etileno, baja temperatura, de un solo uso, no esterilizable) con sus propios parámetros (temperatura, tiempo, presión, ciclo recomendado, compatibilidad, restricciones), más una ficha técnica (fabricante, IFU, mantenimiento, inspección, vida útil) — no es texto libre, es un dato consultable.
- **Bandejas de instrumental**: sets de instrumental (cajas/bandejas) con checklist de instrumentos, cantidad esperada y posición física de cada uno, fotos, versionado y flujo de aprobación igual que técnicas/protocolos, duplicar una bandeja como base de otra, y **sesiones reales de preparación**: cada montaje físico después de lavado/esterilización queda registrado ítem a ítem, con control de calidad/validación de otra persona (o la misma) sobre esa sesión concreta.
- **Biblioteca Pública con traducciones comunitarias**: técnicas/protocolos, bandejas e instrumental publicados a nivel público (no vinculados a ninguna organización), con el mismo flujo borrador → revisión → publicación. Cualquier contribuidor puede proponer una traducción de un contenido ya publicado a otro idioma (ca/es/en): se clona como un borrador independiente en el nuevo idioma, que pasa por el mismo flujo de revisión — nunca traducción automática, siempre revisado por una persona. **Mis aportaciones**: pantalla dedicada para que un contribuidor encuentre y retome sus propios borradores de contenido público, todavía no publicados.
- **Diseño propio y navegación responsive**: sistema de diseño unificado (tipografía, color, espaciados) con una única experiencia de navegación — barra lateral en escritorio, navegación inferior en móvil — igual en todas las pantallas; el contenido se centra con un ancho máximo en pantallas grandes, en lugar de estirarse de borde a borde.
- **Inicio centrado en la búsqueda**: la pantalla de inicio se abre con un buscador global (instrumental, técnicas, protocolos, tarjetas, bandejas), actividad reciente y favoritos, en lugar de un dashboard estático.
- **Modo claro/oscuro** con interruptor manual persistente.

## Stack técnico

- **Flutter** (Dart) — Android, iOS y Web desde el mismo código.
- **Supabase** — Auth (email/contraseña), Postgres con Row Level Security, Storage (fotos de instrumental personalizado), Edge Functions, API REST autogenerada.
- **Firebase Cloud Messaging** — envío de notificaciones push (disparadas por un Database Webhook sobre el log de auditoría).
- **Resend** — email transaccional de Supabase Auth (confirmación de cuenta, recuperar contraseña) desde `hola@instriq.org`.
- **connectivity_plus + shared_preferences** — detección de conexión y caché/cola de sincronización para el modo sin conexión (sin base de datos local nueva).
- **shared_preferences** para progreso y preferencia de tema local (funciona sin cuenta).

## Estructura del proyecto

```
lib/
  l10n/         # ARB (catalán/castellano/inglés) + AppLocalizations generado (flutter gen-l10n)
  models/       # Instrument, PreferenceCard(Version), GroupDocument(Version, ProtocolStep), Workspace(Role/Member),
                # Organization (= grupo, con org_type), AuditEntry, HospitalContentStats, CustomInstrument(Variant),
                # WorkMode, SterilizationMethodEntry/InstrumentTechnicalInfo, Tray(Version, Item),
                # Manufacturer, Surgeon, SpecialtyEntity, Tag, ReferenceDocument, Team, UsageStats
  data/         # Catálogo de instrumental (118) y especialidades quirúrgicas estándar
  design_system/ # Tokens (color, tipografía, espaciado) y componentes compartidos del sistema visual
  navigation/   # Shell responsive (StatefulShellRoute): barra lateral en escritorio, navegación inferior en móvil
  services/     # Supabase, auth, perfil/organización, espacios, progreso, tema, idioma, cuenta (RGPD),
                # versión de la app, auditoría, analítica de uso, instrumental personalizado,
                # conectividad, caché/cola de sincronización sin conexión, notificaciones push,
                # esterilización, bandejas, equipos (teams), tarjetas de preferencia (versionado)
  screens/
    auth/       # Entrada única (unirse/crear grupo con cuenta en el mismo formulario), login, flujo de conexión
    admin/      # Gestión de la organización (código, miembros, equipos, propiedad)
    ...         # Inicio (búsqueda global), Catálogo, Aprende, progreso, espacios, técnicas/protocolos,
                # tarjetas de preferencia (versionado), cuenta y privacidad, auditoría, cobertura de
                # conocimiento y analítica de uso, instrumental personalizado del equipo, bandejas,
                # Biblioteca Pública (contenido y traducciones), mis aportaciones
  utils/        # Generador de código de invitación
supabase/
  schema_v*.sql    # Esquema SQL (ejecuta en orden: schema.sql → schema_v29_public_library.sql → ...)
  functions/       # Edge Functions (send-push: envía notificaciones vía FCM a partir del log de auditoría)
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
   `schema.sql` → `schema_v2_hospital_admin.sql` → `schema_v3_fix_rls_recursion.sql` → `schema_v4_group_documents.sql` → `schema_v5_group_document_versions.sql` → `schema_v6_workspaces.sql` → `schema_v7_roles.sql` → `schema_v8_app_config.sql` → `schema_v9_gdpr.sql` → `schema_v10_audit.sql` → `schema_v11_analytics.sql` → `schema_v12_push_notifications.sql` → `schema_v13_custom_instruments.sql` → `schema_v14_security_hardening.sql` → `schema_v15_clinical_knowledge_model.sql` → `schema_v16_community_photos.sql` → `schema_v17_fix_anon_sterilization_read.sql` → `schema_v18_work_mode_favorites_recent.sql` → `schema_v19_core_domain_model.sql` → `schema_v20_organizations_rename.sql` → `schema_v21_teams_and_login_audit.sql` → `schema_v22_preference_card_versioning.sql` → `schema_v23_usage_analytics.sql` → `schema_v24_knowledge_links.sql` → `schema_v25_tray_preparation.sql` → `schema_v26_learning_progress.sql` → `schema_v27_contributors.sql` → `schema_v28_preference_card_constraints_fix.sql` → `schema_v29_public_library.sql` → `schema_v30_hospital_admin_promotion.sql` → `schema_v31_profile_security_hardening.sql` → `schema_v32_cssd_workspace.sql` → `schema_v33_public_knowledge_links_and_profile.sql` → `schema_v34_rpc_grants_hardening.sql` → `schema_v35_rpc_grants_hardening_fix.sql` → `schema_v36_public_growth_counter.sql` → `schema_v37_fix_stale_updated_at_triggers.sql` → `schema_v38_epic2_expansion.sql` → `schema_v39_custom_instrument_versioning.sql` → `schema_v40_duplicate_content.sql` → `schema_v41_invitations.sql` → `schema_v42_tray_adoption.sql` → `schema_v43_security_hardening.sql` → `schema_v44_storage_path_validation.sql` → `schema_v45_catalog_content_reports.sql` → `schema_v46_feature_suggestions.sql` → `schema_v47_authz_null_bypass_fix.sql` → `schema_v48_public_instruments.sql` → `schema_v49_workspace_wizard.sql` → `schema_v50_public_translations.sql`.
3. Copia la URL y la **publishable key** (Project Settings → API) en `lib/services/supabase_config.dart`. Es pública/segura de hacer commit — la seguridad real la da Row Level Security, no el secreto de esta key.
4. Para las notificaciones push: despliega `supabase/functions/send-push` (`supabase functions deploy send-push`), añade el secreto `FCM_SERVICE_ACCOUNT_JSON` (JSON del service account de Firebase) en Edge Functions → Secrets, y confirma que exista un Database Webhook o trigger que llame a esta función en cada `insert` sobre `audit_log` (`schema_v12` ya deja el trigger listo si tu proyecto tiene `pg_net`).
5. Para las invitaciones por email: despliega `supabase/functions/send-invitation-email` (`supabase functions deploy send-invitation-email`), añade el secreto `RESEND_API_KEY` (distinto del SMTP que ya usa Supabase Auth para sus propios correos), y configura en el dashboard (Database → Webhooks) un webhook sobre `insert` en `invitations` que apunte a esta función.
6. Los dos webhooks anteriores deben autenticarse ante su función con un secreto compartido, para que nadie con la publishable key pública pueda invocarlos directamente (ver `schema_v43_security_hardening.sql`): genera un valor aleatorio, guárdalo como secreto `WEBHOOK_SHARED_SECRET` en Edge Functions → Secrets (para ambas funciones), guárdalo también en Supabase Vault con el nombre `webhook_shared_secret` (`select vault.create_secret('<valor>', 'webhook_shared_secret', '...')`, `trigger_send_push()` ya lo lee de ahí), y añade la cabecera `X-Webhook-Secret: <mismo valor>` al webhook de `invitations` que configuraste en el paso anterior.
7. Para el instrumental personalizado: confirma que el bucket privado `custom-instrument-photos` existe en Storage (la migración `schema_v13` lo crea; en algunos proyectos hay que crearlo a mano desde el dashboard con el mismo nombre).
8. Ejecuta `flutterfire configure` (requiere un proyecto Firebase) para generar `lib/firebase_options.dart` y el `google-services.json`/`GoogleService-Info.plist` de cada plataforma — ninguno de los tres se hace commit (ver `.gitignore`): son claves de cliente Firebase, no secretas en sí mismas, pero cada uno las genera contra su propio proyecto en lugar de compartir una común. La protección real de estas claves es restringirlas en Google Cloud Console (paquete Android + SHA-1, bundle iOS, referrer HTTP en Web), no mantenerlas fuera del repositorio.

## Despliegue

- **App** (`app.instriq.org`): Vercel. El repositorio incluye `vercel.json` + `vercel_build.sh` — como Vercel no trae Flutter preinstalado, el script clona el SDK stable en cada build, genera las localizaciones (`flutter gen-l10n`) y compila con `flutter build web --release`. Basta con importar el repositorio en Vercel (framework preset "Other") y conectar el subdominio desde Cloudflare con un CNAME a `cname.vercel-dns.com`. `lib/firebase_options.dart` no se hace commit (ver `.gitignore` — claves de cliente Firebase, seguras de exponer solo si están restringidas en Google Cloud Console, pero cada entorno genera las suyas en lugar de compartir un archivo común); `vercel_build.sh` lo regenera en build time a partir de estas variables de entorno de Vercel (Project Settings → Environment Variables), con los valores de la app **Web** en Firebase Console → Project Settings → General:
  - `FIREBASE_WEB_API_KEY`, `FIREBASE_WEB_APP_ID`, `FIREBASE_MESSAGING_SENDER_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_AUTH_DOMAIN`, `FIREBASE_STORAGE_BUCKET`, `FIREBASE_MEASUREMENT_ID`.
- **Landing** (`instriq.org` y `www.instriq.org`): carpeta `landing/`, HTML estático sin build, servido por un Cloudflare Worker (Route `instriq.org/*` y `www.instriq.org/*`, ambos registros DNS proxied). Catalán por defecto, con selector ES/EN persistido en `localStorage` **y** en la URL (`?lang=es`/`?lang=en`) — cada variante tiene su propio `hreflang`/canonical, para que los buscadores puedan indexar las tres versiones, no solo la catalana. Cabeceras de seguridad (`landing/_headers`: CSP, X-Frame-Options, HSTS...). Incluye la política de privacidad (`landing/privacidad.html`).
- **Android (Google Play)**: `targetSdk`/`compileSdk` 36 (Android 16), requisito de Google Play desde el 2026-08-31 — Flutter 3.44.8, AGP 9.0.1, Kotlin 2.3.20, Gradle 9.1.0, JDK 17. AAB firmado generado (`android/app/instriq-release.jks`, `android/key.properties` no versionado); solo falta la subida manual a Play Console.

## Licencias

- **Código**: [AGPL-3.0](LICENSE).
- **Documentación**: CC BY-SA 4.0.
- **Fotos de instrumental**: Wikimedia Commons con licencia libre verificada (CC0/CC-BY/CC-BY-SA); la atribución de cada una se muestra en la propia app, al lado de la imagen.

## Estado / roadmap

**v1.0.0** (2026-09-30). El proyecto continúa en desarrollo activo. Todo lo que hay en la sección "Funcionalidades" de arriba ya está desplegado y funcionando en producción.

- **Historial completo de todo lo que se ha entregado** (orden cronológico, con el contexto/bug/decisión de cada entrada): **[docs/CHANGELOG.md](docs/CHANGELOG.md)**.
- **Pendiente** (EPICs de producto, deuda técnica y revisión arquitectónica previa a cada uno): **[docs/BACKLOG.md](docs/BACKLOG.md)**.

## Patrocina

Instriq es gratuito y sin inversores, mantenido fuera de horas. Si te resulta útil, puedes patrocinar el proyecto en [GitHub Sponsors](https://github.com/sponsors/mikeyoshio) — cualquier aportación ayuda a cubrir el coste del servidor y el tiempo dedicado.

## Contacto

[hola@instriq.org](mailto:hola@instriq.org)
