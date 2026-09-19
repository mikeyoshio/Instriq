# Auditoría de seguridad — 2026-09 (sesión independiente)

Alcance: `supabase/schema.sql` + `schema_v2` .. `schema_v46` (46 migraciones, ~9.900 líneas SQL), Edge Functions (`send-push`, `send-invitation-email`), landing (`landing/sugerencias.html`), y código Flutter en `lib/services/` y `lib/screens/` con énfasis en `home_dashboard_panel.dart` y `public_library_screen.dart`. Auditoría de solo lectura: no se ha modificado ningún archivo ni ejecutado SQL contra producción.

No se re-reportan aquí los hallazgos ya cerrados según `README.md` ("Estado / roadmap"): auto-promoción a admin, `organizations` legible por cualquiera, expulsión/promoción de miembro sin verificar en servidor, `organizations.owner_id` modificable directamente, `group_document_videos` exponiendo pendientes/rechazados, webhooks `send-push`/`send-invitation-email` invocables sin secreto — todos verificados como efectivamente corregidos (ver Informativo I-5).

## Resumen de severidad

| ID | Severidad | Título |
|----|-----------|--------|
| C-1 | **Crítico** | NULL tratado como falso en ~34 RPC `security definer`: el guard `my_workspace_role(...) not in (...)` no rechaza a quien no tiene rol — cualquier cuenta autenticada (incluida una recién auto-registrada) puede escribir en organizaciones ajenas |
| C-2 | **Crítico** | 12 RPC de `schema_v39`–`schema_v42` nunca revocan `EXECUTE` a `anon` (mismo gotcha ya corregido para `resolve_catalog_content_report` en v45) — combinado con C-1, son explotables sin ninguna cuenta |
| M-1 | Medio | `create_sterilization_method`/`create_technical_info` (v32): `p_organization_id` es enteramente controlado por el cliente y nunca se valida contra el `workspace_id` real |
| M-2 | Medio | `feature_suggestions`/`feature_suggestion_votes` (v46): sin límite de tasa server-side; `client_id` es autoatestiguado, por lo que "un voto por persona" no es exigible más allá de un `UNIQUE` cosmético |
| M-3 | Medio | 3 RPC de invitaciones (v41) nunca revocan `EXECUTE` a `anon` (mismo patrón que C-2, pero sin impacto práctico porque su guard interno sí es NULL-safe) |
| L-1 | Bajo | `send-push` confía en el contenido del payload del webhook sin releerlo de la tabla, a diferencia de `send-invitation-email` |
| L-2 | Bajo | `can_access_tray_photo`/`can_access_custom_instrument_photo` y varias funciones-trigger nunca revocan `EXECUTE` a `anon`/`public` (impacto mínimo, son predicados de solo lectura) |
| L-3 | Bajo | `manufacturers`/`tags`: cualquier usuario autenticado inserta filas globales sin moderación ni deduplicación (ya reconocido como deuda técnica en los comentarios de `schema_v19`) |
| I-1..I-5 | Informativo | Puntos verificados como correctos (ver abajo) |

---

## C-1 — CRÍTICO: NULL tratado como falso rompe el guard de autorización en ~34 funciones `security definer`

**Qué está mal.** El patrón de autorización repetido en casi toda función que crea/aprueba/rechaza/restaura/duplica contenido de espacio de trabajo es:

```sql
if my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
  raise exception 'No autorizado...';
end if;
```

`my_workspace_role(uuid)` (definida en `schema_v21_teams_and_login_audit.sql:102`, y antes en `schema_v20_organizations_rename.sql:190`/`schema_v7_roles.sql:110`) **devuelve `NULL`** — no lanza excepción, no devuelve `''` — en cualquiera de estos casos:
- quien llama no pertenece a la organización dueña de `p_workspace_id` (`v_organization_id <> my_hospital_id()` con `my_hospital_id()` NULL o distinto),
- quien llama es una cuenta autenticada que todavía no se ha unido/creado ningún grupo (estado perfectamente alcanzable: basta `POST /auth/v1/signup` con la anon key pública, sin pasar por `register_hospital`/`join_hospital_with_code`),
- quien llama es `anon` (sin sesión en absoluto).

`NULL NOT IN ('editor','approver','administrator')` se evalúa a SQL `NULL` (ninguna de las comparaciones de igualdad puede ser verdadera contra `NULL`). Y en PL/pgSQL, un `IF` cuya condición evalúa a `NULL` **se trata igual que `false`**: la rama `THEN` se salta y la ejecución continúa después del `END IF` — no se lanza ninguna excepción, no hay ningún error. Confirmado contra la documentación oficial de PostgreSQL (sección "IF-THEN-ELSE": *"letting you specify an alternative set of statements that should be executed if the condition is not true (note this includes the case where the condition evaluates to NULL)"*).

Esto es exactamente lo contrario de lo que el código pretende: alguien SIN rol en el espacio (el caso que el guard debería bloquear con más fuerza que nadie) es precisamente quien hace que el guard se salte en silencio.

Esto **no** es un problema de las políticas RLS que también usan `my_workspace_role(...) in (...)` (sin `not`) — esas SÍ son seguras, porque en una cláusula `USING`/`WITH CHECK` de RLS, Postgres trata un resultado `NULL` como "esta fila no pasa" (igual que una `WHERE`), es decir, cierran en falso. El problema es específico del **doble negativo** `NOT IN (...)` + `IF` dentro de una función PL/pgSQL, que abre en falso.

**Por qué las rondas de hardening previas no lo detectaron.** `schema_v14/v31/v34/v35/v43_security_hardening.sql` se centraron en *quién puede llamar* a la función (`GRANT`/`REVOKE`) y en columnas de `profiles`/`organizations`; ninguna revisó la lógica *interna* de autorización de cada función. Este bug existe desde `schema_v7_roles.sql` (2026, fase temprana) y se ha ido copiando literalmente en cada nueva entidad versionada desde entonces.

**Funciones actualmente vigentes afectadas** (la última `create or replace function` de cada una — verificado que ninguna redefinición posterior corrige el patrón):

| Función | Archivo:línea |
|---|---|
| `create_group_document` | `schema_v20_organizations_rename.sql:339` |
| `delete_group_document` | `schema_v20_organizations_rename.sql:387` |
| `approve_group_document_version` | `schema_v38_epic2_expansion.sql:65` |
| `reject_group_document_version` | `schema_v20_organizations_rename.sql:486` |
| `restore_group_document_version` | `schema_v24_knowledge_links.sql:227` |
| `create_tray` | `schema_v20_organizations_rename.sql:557` |
| `approve_tray_version` | `schema_v24_knowledge_links.sql:132` |
| `reject_tray_version` | `schema_v20_organizations_rename.sql:695` |
| `restore_tray_version` | `schema_v20_organizations_rename.sql:738` |
| `qc_tray_preparation_session` | `schema_v25_tray_preparation.sql:112` |
| `duplicate_tray` | `schema_v25_tray_preparation.sql:157` |
| `create_preference_card` | `schema_v22_preference_card_versioning.sql:112` |
| `approve_preference_card_version` | `schema_v22_preference_card_versioning.sql:188` |
| `reject_preference_card_version` | `schema_v22_preference_card_versioning.sql:231` |
| `restore_preference_card_version` | `schema_v22_preference_card_versioning.sql:266` |
| `create_sterilization_method` | `schema_v32_cssd_workspace.sql:305` (rama `else`) |
| `approve_sterilization_method_version` | `schema_v32_cssd_workspace.sql:383` (rama `else`) |
| `reject_sterilization_method_version` | `schema_v32_cssd_workspace.sql:429` (rama `else`) |
| `restore_sterilization_method_version` | `schema_v32_cssd_workspace.sql:472` (rama `else`) |
| `create_technical_info` | `schema_v32_cssd_workspace.sql:524` (rama `else`) |
| `approve_technical_info_version` | `schema_v32_cssd_workspace.sql:602` (rama `else`) |
| `reject_technical_info_version` | `schema_v32_cssd_workspace.sql:648` (rama `else`) |
| `restore_technical_info_version` | `schema_v32_cssd_workspace.sql:691` (rama `else`) |
| `create_custom_instrument` | `schema_v39_custom_instrument_versioning.sql:200` |
| `approve_custom_instrument_version` | `schema_v39_custom_instrument_versioning.sql:289` |
| `reject_custom_instrument_version` | `schema_v39_custom_instrument_versioning.sql:341` |
| `restore_custom_instrument_version` | `schema_v39_custom_instrument_versioning.sql:385` |
| `delete_custom_instrument` | `schema_v39_custom_instrument_versioning.sql:436` |
| `duplicate_group_document` | `schema_v40_duplicate_content.sql:36` |
| `duplicate_preference_card` | `schema_v40_duplicate_content.sql:100` |
| `duplicate_custom_instrument` | `schema_v40_duplicate_content.sql:162` |
| `adopt_public_tray` | `schema_v42_tray_adoption.sql:91` |
| `stop_following_public_tray` | `schema_v42_tray_adoption.sql:162` |
| `update_tray_from_upstream` | `schema_v42_tray_adoption.sql:204` |

(Las versiones ya reemplazadas en `schema_v5/v7/v10/v15/v20/v24` de estas mismas funciones tenían el mismo defecto desde el origen — no es una regresión reciente.)

**Escenario de explotación concreto.** Cualquier persona registra una cuenta gratuita en Instriq (auto-servicio, sin verificación — `register_hospital`/self-signup). Sin necesidad de unirse a ningún grupo real, obtiene un JWT válido de `authenticated`. Con ese JWT, y conociendo (u obteniendo por cualquier vía: un enlace compartido, un `knowledge_link`, fuerza bruta sobre IDs correlativos si los hubiera, ingeniería social) el UUID de un `p_instrument_id` de OTRA organización:

```
POST /rest/v1/rpc/delete_custom_instrument
Authorization: Bearer <jwt de cualquier cuenta recién creada, sin organización>
apikey: <anon key pública>
{ "p_instrument_id": "<uuid de un custom_instrument de otro hospital>" }
```

`my_workspace_role(v_workspace_id)` devuelve `NULL` (quien llama no tiene fila en `workspace_members` de ese espacio ni es admin de esa organización) → `NULL not in ('approver','administrator')` → `NULL` → el `IF` no lanza la excepción → `delete from custom_instruments where id = p_instrument_id;` se ejecuta. El instrumental personalizado de otra organización queda borrado. El mismo mecanismo permite `approve_group_document_version`/`approve_sterilization_method_version` sobre contenido ajeno (publicar una versión no aprobada, incluidos parámetros de esterilización falsos, con implicación directa en seguridad clínica), o `create_technical_info`/`create_sterilization_method` inyectando contenido en el espacio de otra organización.

**Corrección recomendada.** Sustituir cada guard `X not in (lista)` por una forma NULL-safe. La más simple y uniforme (mínimo diff, mismo mensaje de error, no requiere tocar la firma de `my_workspace_role`):

```sql
if my_workspace_role(p_workspace_id) is null
   or my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
  raise exception 'No autorizado...';
end if;
```

o, más limpio y sin repetir la llamada, envolver el resultado en una variable local antes del `IF`:

```sql
v_role := my_workspace_role(p_workspace_id);
if v_role is null or v_role not in ('editor', 'approver', 'administrator') then
  raise exception 'No autorizado...';
end if;
```

Dado el volumen (34 funciones), conviene una migración `schema_v47_authz_null_bypass_fix.sql` que recree las 34 funciones con este cambio único, más una revisión de `create_sterilization_method`/`create_technical_info` (ver M-1) en el mismo archivo. **Necesita verificación adicional**: repasar cualquier otra función `security definer` futura que reincida en el mismo patrón (búsqueda recomendada: `grep -n "not in (" supabase/*.sql` tras cada nueva migración, o mejor, un test automatizado que llame a cada RPC con un usuario recién registrado sin organización y compruebe que **siempre** lanza excepción sobre un recurso ajeno).

---

## C-2 — CRÍTICO: `EXECUTE` nunca revocado a `anon` en 12 RPC de `schema_v39`–`schema_v42` (mismo gotcha que v45 corrigió)

**Qué está mal.** Confirmado en esta sesión (ver contexto de la tarea) que `revoke all on function X from public` **no** quita el `EXECUTE` que Supabase concede de forma directa a `anon`/`authenticated`/`service_role` al crear la función (vía `ALTER DEFAULT PRIVILEGES`, al margen del pseudo-rol `PUBLIC`). El único cierre real es un `revoke ... from anon` explícito — así se corrigió `resolve_catalog_content_report` en `schema_v45_catalog_content_reports.sql:127-129`.

`schema_v40_duplicate_content.sql` reproduce **literalmente el mismo error** que ya se había cometido y corregido una vez (`schema_v34` → `schema_v35`): hace `revoke all ... from public` + `grant execute ... to authenticated` para 9 funciones, pero nunca `revoke ... from anon`. El propio comentario del archivo (líneas 210-216) lo admite: *"revoke a PUBLIC + grant explícito solo a authenticated [...] el riesgo práctico ya era bajo (las 9 se protegen igualmente por dentro con auth.uid()/rol)"* — pero esa protección interna es precisamente el guard `my_workspace_role(...) not in (...)` de **C-1**, que está roto. Las dos cosas se combinan: sin el `revoke` de `anon`, y con el guard interno que falla en abierto, estas funciones son invocables **sin ninguna cuenta**, solo con la anon key pública (embebida en el propio cliente Flutter Web / la landing).

`schema_v42_tray_adoption.sql` tiene el mismo defecto para sus 3 funciones nuevas.

**Funciones sin `revoke ... from anon` en ningún archivo posterior** (verificado por búsqueda exhaustiva de `revoke.*from anon` y `revoke.*from.*anon` en las 46 migraciones — ninguna de estas 12 aparece):

- `create_custom_instrument`, `submit_custom_instrument_version_for_review`, `approve_custom_instrument_version`, `reject_custom_instrument_version`, `restore_custom_instrument_version`, `delete_custom_instrument` — `schema_v39_custom_instrument_versioning.sql` (grants en `schema_v40_duplicate_content.sql:224-235`)
- `duplicate_group_document`, `duplicate_preference_card`, `duplicate_custom_instrument` — `schema_v40_duplicate_content.sql:14/80/141` (grants en `schema_v40_duplicate_content.sql:217-222`)
- `adopt_public_tray`, `stop_following_public_tray`, `update_tray_from_upstream` — `schema_v42_tray_adoption.sql:79/146/181` (grants en `schema_v42_tray_adoption.sql:262-267`)

De estas 12, las **9 primeras están además en la lista de C-1** (usan el guard `not in` roto) → explotables **sin cuenta alguna**. `adopt_public_tray`/`stop_following_public_tray`/`update_tray_from_upstream` también están en C-1.

**Escenario de explotación concreto** (sin ninguna cuenta, solo la anon key pública que cualquiera puede extraer de `lib/services/supabase_config.dart` compilado o de la propia app web):

```
POST https://ssskgmlubgcjvhdmayhp.supabase.co/rest/v1/rpc/create_custom_instrument
apikey: sb_publishable__XOw6FPg8ehjHfyPY-GhIg_Sq1yZtuv
Content-Type: application/json
{ "p_workspace_id": "<uuid de un workspace de cualquier hospital>" }
```

`my_workspace_role` devuelve `NULL` (no hay `auth.uid()` en absoluto) → el guard no lanza excepción → se inserta una fila de `custom_instruments` con `created_by = NULL` en el espacio de un hospital al que el atacante nunca ha accedido.

**Corrección recomendada.** Añadir a la migración de C-1 (o una `schema_v47`/`v48` dedicada):

```sql
revoke all on function create_custom_instrument(uuid) from anon;
revoke all on function submit_custom_instrument_version_for_review(uuid) from anon;
revoke all on function approve_custom_instrument_version(uuid, text) from anon;
revoke all on function reject_custom_instrument_version(uuid, text) from anon;
revoke all on function restore_custom_instrument_version(uuid) from anon;
revoke all on function delete_custom_instrument(uuid) from anon;
revoke all on function duplicate_group_document(uuid) from anon;
revoke all on function duplicate_preference_card(uuid) from anon;
revoke all on function duplicate_custom_instrument(uuid) from anon;
revoke all on function adopt_public_tray(uuid, uuid) from anon;
revoke all on function stop_following_public_tray(uuid) from anon;
revoke all on function update_tray_from_upstream(uuid) from anon;
```

**Necesita verificación en vivo** (esto es un hecho sobre el estado de GRANTs en la base real, no deducible solo del texto de las migraciones si alguna vez se tocaron permisos a mano desde el dashboard): ejecutar

```
npx supabase db query --linked -f - <<'SQL'
select routine_name, grantee
from information_schema.role_routine_grants
where routine_name in (
  'create_custom_instrument','submit_custom_instrument_version_for_review',
  'approve_custom_instrument_version','reject_custom_instrument_version',
  'restore_custom_instrument_version','delete_custom_instrument',
  'duplicate_group_document','duplicate_preference_card','duplicate_custom_instrument',
  'adopt_public_tray','stop_following_public_tray','update_tray_from_upstream'
) and grantee = 'anon';
SQL
```

Si esta consulta devuelve alguna fila, confirma que `anon` puede ejecutar hoy esa función.

---

## M-1 — MEDIO: `p_organization_id` controlado por el cliente en `create_sterilization_method`/`create_technical_info`, sin validar contra `p_workspace_id`

**Qué está mal.** `create_sterilization_method(p_instrument_ref_type, p_instrument_ref_id, p_organization_id, p_workspace_id, p_method)` (`schema_v32_cssd_workspace.sql:284-325`) y `create_technical_info(...)` (`schema_v32_cssd_workspace.sql:504-544`) insertan directamente:

```sql
insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, organization_id, workspace_id, created_by)
values (p_instrument_ref_type, p_instrument_ref_id, p_organization_id, p_workspace_id, auth.uid())
```

`p_organization_id` es un parámetro que el cliente envía literalmente — a diferencia de casi cualquier otra función de este mismo archivo/patrón (que siempre resuelven `v_organization_id` con un `select ... from workspaces where id = p_workspace_id`), aquí no hay ninguna comprobación de que `p_organization_id` sea realmente el dueño de `p_workspace_id`. El trigger genérico `check_workspace_matches_hospital()` (que sí existe y hace exactamente esta validación) está enganchado a `custom_instruments` (`schema_v13_custom_instruments.sql:51-53`), `trays`/`tray_versions` (`schema_v15_clinical_knowledge_model.sql:251`) y las tablas de `schema_v6_workspaces.sql:93/98` — **nunca** a `instrument_sterilization_methods` ni a `instrument_technical_info` (verificado por búsqueda exhaustiva de `check_workspace_matches_hospital` en las 46 migraciones).

**Escenario de explotación.** Combinado con C-1 (el guard de rol en la rama `else` de ambas funciones también falla en abierto), cualquier cuenta puede llamar con un `p_workspace_id` real de OTRA organización y un `p_organization_id` que coincida exactamente con esa organización — el resultado es una fila de método de esterilización o ficha técnica **perfectamente consistente en apariencia** (organization_id y workspace_id correctos entre sí) insertada en el catálogo de otra organización, indistinguible de una contribución legítima de ese hospital. Al tratarse de parámetros de esterilización (temperatura, tiempo, presión, ciclo recomendado), un contenido falso o erróneo introducido así — y luego aprobado explotando el mismo C-1 sobre `approve_sterilization_method_version` — tiene implicación directa en seguridad clínica, no solo en integridad de datos.

**Corrección recomendada.** Además del fix de C-1, añadir en ambas funciones, justo tras resolver el caso `p_organization_id is not null`:

```sql
if not exists (select 1 from workspaces where id = p_workspace_id and organization_id = p_organization_id) then
  raise exception 'El espacio no pertenece a la organización indicada';
end if;
```

o, más simple, dejar de aceptar `p_organization_id` como parámetro y derivarlo siempre server-side con `select organization_id into v_organization_id from workspaces where id = p_workspace_id` (el patrón que ya usan todas las demás funciones de creación de contenido en este mismo archivo).

---

## M-2 — MEDIO: `feature_suggestion_votes` — "un voto por persona" es solo un `UNIQUE` sobre un valor autoatestiguado

**Qué está mal.** `schema_v46_feature_suggestions.sql:45-51` sí tiene una restricción real a nivel de base de datos: `unique (suggestion_id, client_id)`. Esto responde directamente a la pregunta de la tarea: **no es solo lógica de cliente**, es un constraint de PostgreSQL, y evita correctamente el doble voto *accidental* (recarga de página, doble clic).

Pero `client_id` es un UUID generado en el navegador y guardado en `localStorage` (`landing/sugerencias.html:392-400`), sin ninguna autenticación. La política de inserción es `for insert to anon, authenticated with check (true)` (`schema_v46_feature_suggestions.sql:62-64`) — no hay ninguna comprobación de que el `client_id` enviado corresponda a quien dice ser. El propio comentario del archivo lo admite como decisión consciente (líneas 6-14): *"no evita un abuso deliberado con multiples client_id"*.

**Escenario de explotación.** Un script trivial puede votar de forma ilimitada por la misma sugerencia repitiendo:

```
POST /rest/v1/feature_suggestion_votes
apikey: <anon key pública>
{ "suggestion_id": "<uuid>", "client_id": "<nuevo random cada vez>" }
```

`list_feature_suggestions` (`schema_v46_feature_suggestions.sql:70-95`) ordena por `count(v.id) desc`, así que esto permite manipular directamente qué sugerencia parece más popular en la landing pública — impacto bajo (no hay datos sensibles ni acceso a la app real en juego, es una lista de sugerencias de producto), pero sí es una manipulación real y trivial del orden mostrado.

**Corrección recomendada.** Esto es un trade-off de producto ya documentado y consciente, no un descuido — no se recomienda bloquear el envío anónimo (rompería el propósito de la página). Si se quiere subir el listón sin pedir cuenta: limitar por IP a nivel de Edge Function/Cloudflare Worker delante de esta tabla en vez de exponer el insert directo con la anon key, o exigir un captcha ligero (p. ej. Cloudflare Turnstile, ya que `sugerencias.html` se sirve vía Cloudflare) antes de emitir un nuevo `client_id`.

---

## M-3 — MEDIO: `create_invitation`/`revoke_invitation`/`accept_invitation` — mismo gotcha de `anon` que C-2, pero sin guard interno roto

**Qué está mal.** `schema_v41_invitations.sql:264-269` revoca de `public` y concede a `authenticated`, pero nunca revoca de `anon` (mismo patrón exacto que C-2). A diferencia de las 12 funciones de C-2, aquí el guard interno **sí es NULL-safe**: `create_invitation`/`revoke_invitation` comprueban `if not my_is_hospital_admin() then raise exception` (`my_is_hospital_admin()` está `coalesce(..., false)` en su definición, `schema_v3_fix_rls_recursion.sql:18-26` — nunca devuelve `NULL`), y `accept_invitation` comprueba explícitamente `if v_user_id is null then raise exception 'Cal iniciar sessió...'` (`schema_v41_invitations.sql:203-205`). Por eso, aunque `anon` pueda invocar estas tres funciones, obtiene siempre un rechazo limpio — no hay bypass práctico hoy.

Se reporta igualmente porque (a) es exactamente el patrón que la tarea pidió auditar de forma exhaustiva, (b) es una inconsistencia con el propio criterio que el equipo ya aplicó en v45/v36, y (c) es defensa en profundidad barata: si en el futuro se modifica el cuerpo de estas funciones y se introduce sin querer una ruta que no dependa de `my_is_hospital_admin()`/`v_user_id is null`, el hueco de grants ya estaría ahí esperando.

**Corrección recomendada.**
```sql
revoke all on function create_invitation(uuid, text, text) from anon;
revoke all on function revoke_invitation(uuid) from anon;
revoke all on function accept_invitation(uuid, text) from anon;
```

---

## L-1 — BAJO: `send-push` no re-verifica el payload del webhook contra la tabla (a diferencia de `send-invitation-email`)

`supabase/functions/send-invitation-email/index.ts:96-107` documenta y aplica explícitamente "defensa en profundidad": aunque ya exige `WEBHOOK_SHARED_SECRET`, vuelve a leer la fila real de `invitations` por `id` y nunca usa los valores del payload directamente para el contenido del correo. `supabase/functions/send-push/index.ts` no hace lo equivalente: `resolveNotificationPlan()` (líneas 173-246) usa `record.action`, `record.workspace_id`, `record.organization_id`, `record.entity_id`, `record.actor_id` tal cual llegan en el payload, sin releerlos de `audit_log`. Impacto real bajo (exige que `WEBHOOK_SHARED_SECRET` ya esté comprometido, momento en el que el problema de fondo es otro), pero es una inconsistencia de defensa en profundidad entre las dos funciones que sería barato igualar: añadir `admin.from('audit_log').select(...).eq('id', record.id).single()` antes de usar cualquier campo del payload.

## L-2 — BAJO: funciones de solo lectura sin `revoke ... from anon` explícito

`can_access_tray_photo`/`can_access_custom_instrument_photo` (`schema_v44_storage_path_validation.sql`) y las funciones-trigger `trigger_send_push()`, `mark_tray_customized_on_content_change()`, `guard_profile_privilege_columns()`, `guard_organization_owner_column()`, `check_workspace_matches_hospital()`, `set_updated_at()`/`set_custom_instrument_updated_at()` nunca tienen un `revoke` explícito. Para las funciones-trigger el riesgo es teórico (Postgres impide invocar directamente por RPC una función que `returns trigger`, al no poder construir un contexto `NEW`/`OLD`). Para `can_access_tray_photo`/`can_access_custom_instrument_photo`, si `anon` las invoca directamente vía `/rpc/`, `my_workspace_role()` devuelve `NULL` y la función devuelve `false` de forma segura (no hay bypass) — el único efecto es un oráculo de bajo valor (permite comprobar si un `tray_id`/`workspace_id` concretos están asociados, sin más). Se recomienda cerrarlas igualmente por higiene y consistencia con el criterio ya aplicado en v45/v36:

```sql
revoke all on function can_access_tray_photo(text, boolean) from anon;
revoke all on function can_access_custom_instrument_photo(text, boolean) from anon;
```

## L-3 — BAJO: `manufacturers`/`tags` — inserción global sin moderación

`schema_v19_core_domain_model.sql:59-61,153-155`: cualquier usuario autenticado (de cualquier organización) puede insertar filas en `manufacturers`/`tags`, catálogos compartidos entre *todas* las organizaciones, sin deduplicación ni moderación. Ya reconocido explícitamente en los comentarios del propio archivo como trabajo futuro ("fusionar duplicados es trabajo futuro"). Impacto bajo (solo permite ensuciar un catálogo de nombres, no acceder a datos ajenos), se incluye por completitud.

---

## Verificado como correcto (Informativo)

**I-1 — Secretos.** Búsqueda exhaustiva en el árbol de trabajo y en todo el historial de git (`git grep`/`git log -p`) de patrones de `service_role`, claves privadas PEM/PGP, `sk_live`, claves AWS, etc.: no se encontró ninguna `service_role key`, clave privada ni otro secreto real committeado. `lib/services/supabase_config.dart:4` contiene únicamente la publishable key pública (`sb_publishable_...`), consistente con lo que el propio `README.md` documenta como seguro de exponer. La JWT `eyJhbGci...` embebida en `schema_v43_security_hardening.sql:149` y en `landing/sugerencias.html:390` se decodificó y confirma `"role":"anon"` — es la misma anon key pública, no una filtración. `WEBHOOK_SHARED_SECRET`/`RESEND_API_KEY`/`FCM_SERVICE_ACCOUNT_JSON` se leen correctamente vía `Deno.env.get(...)`/Vault en ambas Edge Functions, nunca hardcodeados.

**I-2 — `lib/screens/home_dashboard_panel.dart`.** Cada lectura que la pantalla oculta tras `ProfileService.instance.isAdmin`/`canApproveAnyWorkspace`/`ContributorService.instance.isEditorialBoard` está también restringida server-side, de forma independiente del cliente:
- `hospital_content_stats(p_hospital_id)` valida `if p_hospital_id is null or p_hospital_id <> my_hospital_id() then raise exception` (`schema_v20_organizations_rename.sql:908`, ya así desde `schema_v11_analytics.sql:32`) — un `p_hospital_id` ajeno es rechazado.
- `organization_usage_stats(p_organization_id)` exige además `my_is_hospital_admin()` (`schema_v23_usage_analytics.sql:81`) — coalescida a booleano, sin el bypass de C-1.
- Las colas de revisión (`GroupDocumentService`/`TrayService`/`PreferenceCardService`/`SterilizationService`/`CustomInstrumentService`/`ContributorService`/`PublicDocumentService`/`PublicTrayService`) dependen de RLS `select` que ya filtra por rol real, no del gate del widget.
- `audit_log` está protegido por `audit_log_select_admin` (`hospital_id = my_hospital_id() and my_is_hospital_admin()`, `schema_v10_audit.sql:38-42`): si un usuario no-admin llegase a disparar `AuditService.fetchAuditLog()` (el `Future` se crea en `_reload()` sin depender de `isAdmin`, aunque el *tile* que lo muestra sí está detrás de `if (ProfileService.instance.isAdmin)`, línea 342), RLS simplemente devuelve cero filas — no hay fuga.

Conclusión: los gates de `home_dashboard_panel.dart` son control de UX, no el límite real de seguridad, y el límite real sostiene correctamente en los tres casos comprobados.

**I-3 — `lib/screens/public_library_screen.dart` / `ContributorService`.** `_canContribute`/`_canReview` solo esconden botones. El camino real de escritura (`create_public_document`/`create_public_tray`, `schema_v29_public_library.sql:208-256`) exige `my_is_active_contributor()` **dentro del propio RPC**, y la tabla además tiene su propia RLS `public_documents_insert`/`public_document_versions_insert with check (my_is_active_contributor() and ...)` (`schema_v29_public_library.sql:144-159`) — doble capa, RPC y RLS coinciden. Igual para aprobar/rechazar: `my_is_reviewer_or_above()` (booleano coalescido, `schema_v29_public_library.sql:116-128`, sin el bypass de C-1) se comprueba en `approve_public_document_version`/`approve_public_tray_version` y en la RLS de `editorial_comments`. Un usuario que fuerce las llamadas sin pasar por la UI (`ContributorService`/`PublicDocumentService` directamente) recibe el mismo rechazo. `_ContributeBanner` es puramente informativo, no ejecuta ninguna escritura.

**I-4 — Landing `sugerencias.html`.** `escapeHtml()` (línea 414) se aplica correctamente a `row.title`/`row.description` antes de insertarlos en `innerHTML` (líneas 439-440) — sin XSS almacenado pese a que el contenido lo escribe cualquier visitante sin cuenta. (`row.status` se interpola sin escapar en el nombre de clase CSS, línea 431-433, pero ese campo viene de una columna con `check (status in ('open','planned','shipped','declined'))` que solo cambia por SQL manual de la fundadora — no es una vía de ataque real.)

**I-5 — Hardenings previos re-verificados, siguen cerrados.** `organizations.owner_id` solo cambia vía `transfer_hospital_ownership()` gracias al trigger `guard_organization_owner_column` (`schema_v43_security_hardening.sql:22-39`); `group_document_videos_select` ya filtra por `status`/autor/rol (`schema_v43_security_hardening.sql:88-97`); ambas Edge Functions comprueban `x-webhook-secret` antes de cualquier otra cosa (confirmado leyendo el código real, no solo el comentario de la migración).

---

## Nota sobre integridad de datos (fuera de lo ya cubierto arriba)

- FKs de autoría (`created_by`/`author_id`/`approved_by`) usan consistentemente `on delete set null`, permitiendo el borrado GDPR (`delete_my_account`) sin dejar referencias colgantes — verificado en `schema_v9_gdpr.sql` y su reescritura en `schema_v20_organizations_rename.sql:771-887`. `export_my_account_data()`/`delete_my_account()` están correctamente acotadas a `auth.uid()`, sin fuga de datos de terceros.
- `custom_instrument_versions`/`tray_versions`/`public_document_versions`/etc. tienen `unique index ... where status = 'published'` para garantizar como mucho una versión publicada por cabecera — constraint real, no solo disciplina de aplicación.
- `feature_suggestion_votes.unique(suggestion_id, client_id)` es real (ver M-2) — responde a la pregunta de la tarea: sí es un constraint de base de datos, no solo lógica de cliente, aunque su eficacia esté limitada por no haber identidad autenticada detrás de `client_id`.

## Cómo verificar en vivo sin ejecutar SQL yo mismo

Para las dos preguntas de esta auditoría que dependen del estado real de GRANTs (no solo del texto de las migraciones, por si algo se tocó a mano desde el dashboard):

```
npx supabase db query --linked -f - <<'SQL'
select routine_name, grantee
from information_schema.role_routine_grants
where grantee in ('anon')
  and routine_name in (
    'create_custom_instrument','submit_custom_instrument_version_for_review',
    'approve_custom_instrument_version','reject_custom_instrument_version',
    'restore_custom_instrument_version','delete_custom_instrument',
    'duplicate_group_document','duplicate_preference_card','duplicate_custom_instrument',
    'adopt_public_tray','stop_following_public_tray','update_tray_from_upstream',
    'create_invitation','revoke_invitation','accept_invitation',
    'can_access_tray_photo','can_access_custom_instrument_photo'
  )
order by routine_name;
SQL
```

Cualquier fila devuelta confirma que `anon` puede ejecutar hoy esa función en producción.
