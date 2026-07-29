-- Fase de notificaciones push. Ejecutar DESPUES de schema_v11_analytics.sql.
--
-- Diseno: en vez de montar un mecanismo paralelo para decidir "que evento
-- dispara que notificacion", reusamos el log de auditoria que ya existe
-- (schema_v10_audit.sql, tabla audit_log + funcion log_audit_event()). Cada
-- accion sensible ya se registra ahi (document_version_approved,
-- document_version_rejected, document_created, etc.). Anadimos una accion
-- mas (document_version_submitted, ver mas abajo) y dejamos que un Database
-- Webhook de Supabase sobre "INSERT en audit_log" dispare la Edge Function
-- send-push (supabase/functions/send-push/index.ts), que decide a quien
-- avisar segun record.action y envia el push via FCM (API HTTP v1).
--
-- Ventajas de este enfoque: una sola fuente de verdad para "que paso y
-- quien lo hizo" (audit_log), cero logica de negocio duplicada en dos
-- sitios, y el webhook es asincrono respecto a la transaccion SQL (si FCM
-- esta caido no bloquea ni revierte la accion del usuario).
--
-- Esta migracion SOLO crea la tabla de tokens de dispositivo (device_tokens)
-- y las funciones RPC para que el cliente Flutter registre/desregistre su
-- token, mas el "create or replace" de submit_group_document_version_for_review
-- para que tambien quede en el audit_log (hoy no se registraba en absoluto).
-- La Edge Function y el resto de la infraestructura (proyecto Firebase
-- instriq-53015, service account) viven fuera de SQL.
--
-- Pasos que el usuario debe hacer A MANO despues de aplicar esta migracion
-- (ninguno de estos pasos lo hace este archivo ni ninguna Edge Function):
--   1. Supabase Dashboard -> Database -> Webhooks -> crear un webhook sobre
--      la tabla audit_log, evento INSERT, que llame a la Edge Function
--      "send-push" (URL tipo https://<project-ref>.supabase.co/functions/v1/send-push).
--   2. Supabase Dashboard -> Edge Functions -> Secrets -> anadir
--      FCM_SERVICE_ACCOUNT_JSON con el contenido completo del JSON del
--      service account de Firebase (proyecto instriq-53015). Esta clave NO
--      se escribe en ningun archivo del repo.
--   3. Desde la maquina del usuario, con la CLI de Supabase ya logueada:
--      `supabase functions deploy send-push`.

-- 1. Tabla de tokens de dispositivo -------------------------------------------

create table if not exists device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  fcm_token text not null,
  platform text not null check (platform in ('android', 'ios', 'web')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, fcm_token)
);

create index if not exists device_tokens_user_idx on device_tokens (user_id);

alter table device_tokens enable row level security;

-- Cada usuario solo ve/inserta/borra sus propios tokens. Nadie mas puede
-- leerlos desde el cliente: la Edge Function los lee con la service role
-- key, que bypassa RLS por completo, asi que no hace falta (ni conviene)
-- una policy de select para "todos los tokens".
drop policy if exists "device_tokens_select_own" on device_tokens;
create policy "device_tokens_select_own" on device_tokens
  for select using (user_id = auth.uid());

drop policy if exists "device_tokens_insert_own" on device_tokens;
create policy "device_tokens_insert_own" on device_tokens
  for insert with check (user_id = auth.uid());

drop policy if exists "device_tokens_delete_own" on device_tokens;
create policy "device_tokens_delete_own" on device_tokens
  for delete using (user_id = auth.uid());

-- No hace falta policy de update: register_device_token (abajo) es
-- security definer y hace su propio upsert; nadie actualiza device_tokens
-- directamente desde el cliente.

-- 2. RPCs para el cliente Flutter ---------------------------------------------

create or replace function register_device_token(p_fcm_token text, p_platform text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_platform not in ('android', 'ios', 'web') then
    raise exception 'Plataforma no valida';
  end if;

  insert into device_tokens (user_id, fcm_token, platform)
  values (auth.uid(), p_fcm_token, p_platform)
  on conflict (user_id, fcm_token)
  do update set updated_at = now(), platform = excluded.platform;
end;
$$;

create or replace function unregister_device_token(p_fcm_token text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  delete from device_tokens
  where user_id = auth.uid() and fcm_token = p_fcm_token;
end;
$$;

-- 3. submit_group_document_version_for_review pasa a quedar registrada en
--    el audit_log (antes no se registraba esta accion en absoluto). Mismo
--    cuerpo vigente en schema_v5_group_document_versions.sql, se anaden las
--    consultas necesarias para obtener workspace_id/hospital_id/title (igual
--    patron que approve/reject_group_document_version en schema_v10_audit.sql)
--    y la llamada final a log_audit_event. metadata incluye el titulo del
--    documento para que send-push pueda componer el cuerpo de la
--    notificacion sin tener que volver a consultar group_document_versions;
--    workspace_id no hace falta repetirlo en metadata porque ya viaja en la
--    columna audit_log.workspace_id.

create or replace function submit_group_document_version_for_review(p_version_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_document_id uuid;
  v_workspace_id uuid;
  v_hospital_id uuid;
  v_title text;
begin
  update group_document_versions
  set status = 'in_review'
  where id = p_version_id
    and status = 'draft'
    and author_id = auth.uid();

  if not found then
    raise exception 'No autorizado o version no valida para enviar a revision';
  end if;

  select document_id, title into v_document_id, v_title
  from group_document_versions
  where id = p_version_id;

  select workspace_id, hospital_id into v_workspace_id, v_hospital_id
  from group_documents where id = v_document_id;

  perform log_audit_event(
    v_hospital_id,
    'document_version_submitted',
    'group_document_version',
    p_version_id,
    v_workspace_id,
    jsonb_build_object('document_id', v_document_id, 'title', v_title)
  );
end;
$$;
