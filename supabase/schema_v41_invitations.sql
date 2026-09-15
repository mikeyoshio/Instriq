-- Invitación por email a una persona concreta, con rol de espacio ya
-- asignado de entrada -- vía adicional al código de invitación de
-- organización (join_hospital_with_code, schema_v31), que se mantiene tal
-- cual para el alta autoservicio. Tercer punto de la revisión UX externa
-- d'aquesta sessió: el codi únic no permet assignar un rol concret a una
-- persona concreta abans que accepti, ni revocar l'accés d'una sola persona
-- sense invalidar-lo per a tothom.
--
-- Decisions preses explícitament (no per omissió):
-- 1) Només Owner/Administrator D'ORGANITZACIÓ pot enviar invitacions (no
--    Administrator d'espai) -- mateix nivell que `regenerate_invite_code`.
-- 2) El rol assignable és nomás reader/editor/approver (rol per espai, ver
--    workspace_members) -- fer algú Administrator d'organització segueix sent
--    una acció separada i posterior (`set_hospital_admin`), no es folda aquí.
-- 3) "Expirat" és un estat DERIVAT (status='pending' i expires_at < now()),
--    no una columna que calgui actualitzar amb un cron -- una menys peça
--    d'infraestructura a mantenir.
-- 4) L'enviament real del correu és fora d'aquest fitxer SQL: un Database
--    Webhook (configuració manual al dashboard, mateix patró que send-push
--    a schema_v12_push_notifications.sql) sobre INSERT a `invitations`
--    crida la nova Edge Function `send-invitation-email` (Resend). "Reenviar"
--    es resol al client fent revoke + create_invitation altra vegada (un nou
--    INSERT), sense necessitat de configurar un segon esdeveniment de webhook.
--
-- Pasos que el usuario debe hacer A MANO después de aplicar esta migración
-- (ninguno de estos pasos lo hace este archivo):
--   1. Supabase Dashboard -> Database -> Webhooks -> crear un webhook sobre
--      la tabla invitations, evento INSERT, que llame a la Edge Function
--      "send-invitation-email" (URL tipo
--      https://<project-ref>.supabase.co/functions/v1/send-invitation-email).
--   2. Supabase Dashboard -> Edge Functions -> Secrets -> añadir
--      RESEND_API_KEY (API key de Resend -- distinta de la que ya usa
--      Supabase Auth para sus propios correos vía SMTP). Esta clave NO se
--      escribe en ningún archivo del repo.
--   3. Desde la máquina del usuario, con la CLI de Supabase ya logueada:
--      `supabase functions deploy send-invitation-email`.

create table if not exists invitations (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  workspace_id uuid not null references workspaces(id) on delete cascade,
  email text not null,
  role text not null check (role in ('reader', 'editor', 'approver')),
  token uuid not null default gen_random_uuid(),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'revoked')),
  invited_by uuid references profiles(id) on delete set null,
  invited_by_name text,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '14 days'),
  accepted_at timestamptz,
  accepted_by uuid references profiles(id) on delete set null
);

create unique index if not exists invitations_token_idx on invitations (token);
create index if not exists invitations_org_idx on invitations (organization_id);
-- Como mucho una invitación PENDIENTE por email+espacio a la vez -- "reenviar"
-- pasa primero por revoke_invitation, que libera este índice para el
-- create_invitation siguiente.
create unique index if not exists invitations_pending_email_workspace_idx
  on invitations (workspace_id, lower(email))
  where status = 'pending';

alter table invitations enable row level security;

-- Solo lectura para admins de la propia organización (lista "Invitaciones
-- pendientes" en gestión de organización) -- ninguna política de insert/
-- update/delete: toda escritura pasa por las funciones de abajo.
create policy "org admins can view invitations" on invitations
  for select using (my_is_hospital_admin() and organization_id = my_hospital_id());

create or replace function create_invitation(p_workspace_id uuid, p_email text, p_role text)
returns invitations
language plpgsql
security definer
set search_path = 'public'
as $function$
declare
  v_organization_id uuid;
  v_normalized_email text := lower(trim(p_email));
  v_inviter_name text;
  v_new invitations;
begin
  if not my_is_hospital_admin() then
    raise exception 'Solo un administrador de la organización puede enviar invitaciones';
  end if;
  if p_role not in ('reader', 'editor', 'approver') then
    raise exception 'Rol no válido';
  end if;
  if v_normalized_email = '' or v_normalized_email !~ '^[^@\s]+@[^@\s]+\.[^@\s]+$' then
    raise exception 'Correo no válido';
  end if;

  select organization_id into v_organization_id from workspaces where id = p_workspace_id;
  if v_organization_id is null or v_organization_id <> my_hospital_id() then
    raise exception 'Espacio no encontrado en tu organización';
  end if;

  if exists (
    select 1 from invitations
    where workspace_id = p_workspace_id and lower(email) = v_normalized_email and status = 'pending'
  ) then
    raise exception 'Ya hay una invitación pendiente para ese correo en este espacio';
  end if;

  select display_name into v_inviter_name from profiles where id = auth.uid();

  insert into invitations (organization_id, workspace_id, email, role, invited_by, invited_by_name)
  values (v_organization_id, p_workspace_id, v_normalized_email, p_role, auth.uid(), v_inviter_name)
  returning * into v_new;

  perform log_audit_event(
    v_organization_id,
    'invitation_sent',
    'invitation',
    v_new.id,
    p_workspace_id,
    jsonb_build_object('email', v_normalized_email, 'role', p_role)
  );

  return v_new;
end;
$function$;

create or replace function revoke_invitation(p_invitation_id uuid)
returns void
language plpgsql
security definer
set search_path = 'public'
as $function$
declare
  v_organization_id uuid;
  v_workspace_id uuid;
begin
  if not my_is_hospital_admin() then
    raise exception 'Solo un administrador de la organización puede revocar invitaciones';
  end if;

  select organization_id, workspace_id into v_organization_id, v_workspace_id
  from invitations where id = p_invitation_id;

  if v_organization_id is null or v_organization_id <> my_hospital_id() then
    raise exception 'Invitación no encontrada en tu organización';
  end if;

  update invitations set status = 'revoked' where id = p_invitation_id and status = 'pending';

  perform log_audit_event(v_organization_id, 'invitation_revoked', 'invitation', p_invitation_id, v_workspace_id, '{}'::jsonb);
end;
$function$;

-- Callable sin sesión (anon): quien recibe el enlace todavía puede no tener
-- cuenta. Solo expone lo necesario para decidir si crear cuenta/aceptar --
-- nunca datos de otros miembros ni nada fuera de esta única invitación, y
-- solo es alcanzable conociendo el token (uuid aleatorio, no enumerable).
create or replace function get_invitation_preview(p_token uuid)
returns table (
  organization_name text,
  workspace_name text,
  role text,
  email text,
  status text,
  invited_by_name text
)
language plpgsql
security definer
set search_path = 'public'
as $function$
declare
  v invitations;
begin
  select * into v from invitations where token = p_token;
  if v.id is null then
    raise exception 'Invitación no encontrada';
  end if;

  return query
  select
    o.name,
    w.name,
    v.role,
    v.email,
    case
      when v.status = 'pending' and v.expires_at < now() then 'expired'
      else v.status
    end,
    v.invited_by_name
  from organizations o, workspaces w
  where o.id = v.organization_id and w.id = v.workspace_id;
end;
$function$;

create or replace function accept_invitation(p_token uuid, p_display_name text default null)
returns table (id uuid, name text, invite_code text, cif text, owner_id uuid)
language plpgsql
security definer
set search_path = 'public'
as $function$
declare
  v_user_id uuid := auth.uid();
  v_caller_email text;
  v invitations;
begin
  if v_user_id is null then
    raise exception 'Cal iniciar sessió per acceptar una invitació.';
  end if;
  if exists (select 1 from profiles where id = v_user_id and organization_id is not null) then
    raise exception 'Ja pertanys a un grup -- surt-ne abans d''acceptar una invitació.';
  end if;

  select * into v from invitations where token = p_token for update;
  if v.id is null then
    raise exception 'Invitación no encontrada';
  end if;
  if v.status <> 'pending' then
    raise exception 'Esta invitación ya no está disponible (%).', v.status;
  end if;
  if v.expires_at < now() then
    raise exception 'Esta invitación ha caducado';
  end if;

  select email into v_caller_email from auth.users where id = v_user_id;
  if v_caller_email is null or lower(v_caller_email) <> lower(v.email) then
    raise exception 'Esta invitación es para otra dirección de correo';
  end if;

  perform set_config('app.bypass_profile_guard', 'on', true);
  insert into profiles (id, organization_id, is_admin, display_name)
  values (v_user_id, v.organization_id, false, p_display_name)
  on conflict (id) do update set
    organization_id = excluded.organization_id,
    is_admin = excluded.is_admin,
    display_name = coalesce(excluded.display_name, profiles.display_name);

  insert into workspace_members (workspace_id, user_id, role)
  values (v.workspace_id, v_user_id, v.role)
  on conflict (workspace_id, user_id) do update set role = excluded.role;

  update invitations set status = 'accepted', accepted_at = now(), accepted_by = v_user_id where id = v.id;

  perform log_audit_event(
    v.organization_id, 'invitation_accepted', 'invitation', v.id, v.workspace_id,
    jsonb_build_object('role', v.role)
  );

  return query select o.id, o.name, o.invite_code, o.cif, o.owner_id from organizations o where o.id = v.organization_id;
end;
$function$;

-- Declinar no exige sesión (igual que la previsualización): alguien puede
-- querer decir "no, gracias" sin llegar a crear cuenta. No se audita -- es un
-- evento de bajo riesgo (nunca concede acceso), mismo criterio que otros
-- metadatos accesorios de esta base de código que no pasan por audit_log.
create or replace function decline_invitation(p_token uuid)
returns void
language plpgsql
security definer
set search_path = 'public'
as $function$
begin
  update invitations set status = 'revoked' where token = p_token and status = 'pending';
end;
$function$;

revoke all on function create_invitation(p_workspace_id uuid, p_email text, p_role text) from public;
grant execute on function create_invitation(p_workspace_id uuid, p_email text, p_role text) to authenticated;
revoke all on function revoke_invitation(p_invitation_id uuid) from public;
grant execute on function revoke_invitation(p_invitation_id uuid) to authenticated;
revoke all on function accept_invitation(p_token uuid, p_display_name text) from public;
grant execute on function accept_invitation(p_token uuid, p_display_name text) to authenticated;
-- Estas dos SÍ se conceden también a anon (ver comentarios de cada función):
-- quien recibe el enlace de invitación puede no tener cuenta todavía.
revoke all on function get_invitation_preview(p_token uuid) from public;
grant execute on function get_invitation_preview(p_token uuid) to anon, authenticated;
revoke all on function decline_invitation(p_token uuid) from public;
grant execute on function decline_invitation(p_token uuid) to anon, authenticated;
