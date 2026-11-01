-- Agenda quirurgica a nivel de grupo + feed .ics suscribible (Outlook/
-- Calendario de iPhone/Google Calendar). Un cirujano o su secretaria (rol
-- editor+ en el espacio, igual que ya gestiona bandejas o tarjetas de
-- preferencia) crea huecos de cirugia (fecha/hora, cirujano, opcionalmente
-- enlazado a tarjeta de preferencia/tecnica-protocolo/bandeja). Sin
-- versionado ni flujo de aprobacion: dato operativo transitorio, modelado
-- igual que tray_preparation_sessions (schema_v25) -- tabla plana, lectura
-- abierta a cualquier miembro del espacio, escritura solo via RPC security
-- definer. NUNCA datos de paciente (ni nombre ni identificador): esto es
-- agenda operativa, no historia clinica; el campo `notes` lleva aviso
-- explicito en la UI y la Edge Function del feed .ics jamas lo lee ni lo
-- expone.
--
-- El token del feed .ics vive en su propia tabla (surgeon_ics_tokens), nunca
-- como columna en `surgeons`: `surgeons` se lee entero por cualquier miembro
-- del espacio para el Autocomplete de SurgeonService, asi que una columna
-- ahi filtraria el token a cualquier reader. surgeon_ics_tokens tiene RLS
-- activo y CERO politicas para authenticated (ni select de la propia fila):
-- es un secreto de portador, no dato operacional -- se lee/escribe solo via
-- las 2 RPC de token de abajo, y la Edge Function la consulta con el
-- cliente service-role (que bypasa RLS por diseno).
--
-- Convencion de permisos de funcion igual que schema_v55 (mas reciente que
-- la de schema_v25, que no la lleva): `revoke all ... from public, anon;
-- grant execute ... to authenticated;` al final de cada funcion.

create table if not exists surgical_slots (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  workspace_id uuid not null references workspaces(id) on delete cascade,
  surgeon_id uuid not null references surgeons(id),
  preference_card_id uuid references preference_cards(id) on delete set null,
  document_id uuid references group_documents(id) on delete set null,
  tray_id uuid references trays(id) on delete set null,
  procedure_name text,
  location text,
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  notes text,
  status text not null default 'scheduled' check (status in ('scheduled', 'cancelled')),
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  cancelled_by uuid references auth.users(id),
  cancelled_at timestamptz,
  cancellation_reason text,
  check (ends_at > starts_at)
);

create index if not exists surgical_slots_workspace_starts_idx on surgical_slots (workspace_id, starts_at);
create index if not exists surgical_slots_surgeon_starts_idx on surgical_slots (surgeon_id, starts_at);
create index if not exists surgical_slots_organization_idx on surgical_slots (organization_id);

alter table surgical_slots enable row level security;

drop policy if exists "surgical_slots_select" on surgical_slots;
create policy "surgical_slots_select" on surgical_slots for select using (
  my_workspace_role(workspace_id) is not null or my_is_hospital_admin()
);
-- Sin insert/update/delete directos para authenticated: se escribe solo via
-- las RPC siguientes, mismo modelo de confianza que tray_preparation_sessions/
-- instrument_incidents.

create table if not exists surgeon_ics_tokens (
  surgeon_id uuid primary key references surgeons(id) on delete cascade,
  token uuid not null default gen_random_uuid(),
  created_at timestamptz not null default now(),
  rotated_at timestamptz,
  unique (token)
);

alter table surgeon_ics_tokens enable row level security;
-- Deliberadamente SIN ninguna policy para authenticated (ni select): es un
-- secreto de portador para el feed .ics publico, no un dato operacional --
-- se lee/escribe solo via las 2 RPC de token de abajo, y la Edge Function lo
-- consulta con el cliente service-role (que bypasa RLS por diseno). RLS
-- activo + 0 politicas = nadie autenticado puede leer/escribir directo, ni
-- siquiera su propia fila.

create or replace function create_surgical_slot(
  p_workspace_id uuid,
  p_surgeon_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_preference_card_id uuid default null,
  p_document_id uuid default null,
  p_tray_id uuid default null,
  p_procedure_name text default null,
  p_location text default null,
  p_notes text default null
)
returns surgical_slots
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_organization_id uuid;
  v_row surgical_slots;
begin
  select organization_id into v_organization_id from workspaces where id = p_workspace_id;
  if v_organization_id is null then
    raise exception 'Espacio de trabajo no encontrado';
  end if;

  if my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para crear slots de agenda en este espacio';
  end if;

  if p_ends_at <= p_starts_at then
    raise exception 'La hora de fin debe ser posterior a la de inicio';
  end if;

  if not exists (select 1 from surgeons where id = p_surgeon_id and organization_id = v_organization_id) then
    raise exception 'Cirujano no encontrado en este grupo';
  end if;

  if p_preference_card_id is not null and not exists (
    select 1 from preference_cards where id = p_preference_card_id and workspace_id = p_workspace_id
  ) then
    raise exception 'Tarjeta de preferencia no encontrada en este espacio';
  end if;

  if p_document_id is not null and not exists (
    select 1 from group_documents where id = p_document_id and workspace_id = p_workspace_id
  ) then
    raise exception 'Tecnica o protocolo no encontrado en este espacio';
  end if;

  if p_tray_id is not null and not exists (
    select 1 from trays where id = p_tray_id and workspace_id = p_workspace_id
  ) then
    raise exception 'Bandeja no encontrada en este espacio';
  end if;

  insert into surgical_slots (
    organization_id, workspace_id, surgeon_id, preference_card_id, document_id, tray_id,
    procedure_name, location, starts_at, ends_at, notes, created_by
  ) values (
    v_organization_id, p_workspace_id, p_surgeon_id, p_preference_card_id, p_document_id, p_tray_id,
    p_procedure_name, p_location, p_starts_at, p_ends_at, p_notes, auth.uid()
  ) returning * into v_row;

  perform log_audit_event(
    v_organization_id, 'surgical_slot_created', 'surgical_slot', v_row.id, p_workspace_id,
    jsonb_build_object('surgeon_id', p_surgeon_id)
  );
  return v_row;
end;
$function$;

create or replace function update_surgical_slot(
  p_slot_id uuid,
  p_surgeon_id uuid,
  p_starts_at timestamptz,
  p_ends_at timestamptz,
  p_preference_card_id uuid default null,
  p_document_id uuid default null,
  p_tray_id uuid default null,
  p_procedure_name text default null,
  p_location text default null,
  p_notes text default null
)
returns surgical_slots
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_workspace_id uuid;
  v_organization_id uuid;
  v_row surgical_slots;
begin
  select workspace_id, organization_id into v_workspace_id, v_organization_id
  from surgical_slots where id = p_slot_id;

  if v_workspace_id is null then
    raise exception 'Slot de agenda no encontrado';
  end if;

  if my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para editar slots de agenda en este espacio';
  end if;

  if p_ends_at <= p_starts_at then
    raise exception 'La hora de fin debe ser posterior a la de inicio';
  end if;

  if not exists (select 1 from surgeons where id = p_surgeon_id and organization_id = v_organization_id) then
    raise exception 'Cirujano no encontrado en este grupo';
  end if;

  if p_preference_card_id is not null and not exists (
    select 1 from preference_cards where id = p_preference_card_id and workspace_id = v_workspace_id
  ) then
    raise exception 'Tarjeta de preferencia no encontrada en este espacio';
  end if;

  if p_document_id is not null and not exists (
    select 1 from group_documents where id = p_document_id and workspace_id = v_workspace_id
  ) then
    raise exception 'Tecnica o protocolo no encontrado en este espacio';
  end if;

  if p_tray_id is not null and not exists (
    select 1 from trays where id = p_tray_id and workspace_id = v_workspace_id
  ) then
    raise exception 'Bandeja no encontrada en este espacio';
  end if;

  update surgical_slots set
    surgeon_id = p_surgeon_id,
    preference_card_id = p_preference_card_id,
    document_id = p_document_id,
    tray_id = p_tray_id,
    procedure_name = p_procedure_name,
    location = p_location,
    starts_at = p_starts_at,
    ends_at = p_ends_at,
    notes = p_notes
  where id = p_slot_id
  returning * into v_row;

  perform log_audit_event(
    v_organization_id, 'surgical_slot_updated', 'surgical_slot', p_slot_id, v_workspace_id,
    jsonb_build_object('surgeon_id', p_surgeon_id)
  );
  return v_row;
end;
$function$;

create or replace function cancel_surgical_slot(p_slot_id uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_workspace_id uuid;
  v_organization_id uuid;
  v_status text;
begin
  select workspace_id, organization_id, status into v_workspace_id, v_organization_id, v_status
  from surgical_slots where id = p_slot_id;

  if v_workspace_id is null then
    raise exception 'Slot de agenda no encontrado';
  end if;
  if v_status = 'cancelled' then
    raise exception 'Este slot ya esta cancelado';
  end if;
  if my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para cancelar slots de agenda en este espacio';
  end if;

  update surgical_slots set
    status = 'cancelled', cancelled_by = auth.uid(), cancelled_at = now(), cancellation_reason = p_reason
  where id = p_slot_id;

  perform log_audit_event(
    v_organization_id, 'surgical_slot_cancelled', 'surgical_slot', p_slot_id, v_workspace_id, '{}'::jsonb
  );
end;
$function$;

create or replace function surgical_agenda_ics_token(p_surgeon_id uuid)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_organization_id uuid;
  v_token uuid;
begin
  select organization_id into v_organization_id from surgeons where id = p_surgeon_id;
  if v_organization_id is null then
    raise exception 'Cirujano no encontrado';
  end if;
  if not (
    my_is_hospital_admin() or exists (
      select 1 from workspace_members wm join workspaces w on w.id = wm.workspace_id
      where wm.user_id = auth.uid() and wm.role in ('editor', 'approver', 'administrator')
        and w.organization_id = v_organization_id
    )
  ) then
    raise exception 'No autorizado para ver el enlace de calendario de este cirujano';
  end if;

  select token into v_token from surgeon_ics_tokens where surgeon_id = p_surgeon_id;
  if v_token is null then
    insert into surgeon_ics_tokens (surgeon_id) values (p_surgeon_id) returning token into v_token;
  end if;
  return v_token;
end;
$function$;

create or replace function regenerate_surgical_agenda_ics_token(p_surgeon_id uuid)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_organization_id uuid;
  v_token uuid;
begin
  select organization_id into v_organization_id from surgeons where id = p_surgeon_id;
  if v_organization_id is null then
    raise exception 'Cirujano no encontrado';
  end if;
  if not (
    my_is_hospital_admin() or exists (
      select 1 from workspace_members wm join workspaces w on w.id = wm.workspace_id
      where wm.user_id = auth.uid() and wm.role in ('editor', 'approver', 'administrator')
        and w.organization_id = v_organization_id
    )
  ) then
    raise exception 'No autorizado para regenerar el enlace de calendario de este cirujano';
  end if;

  insert into surgeon_ics_tokens (surgeon_id, token, rotated_at)
  values (p_surgeon_id, gen_random_uuid(), now())
  on conflict (surgeon_id) do update set token = excluded.token, rotated_at = now()
  returning token into v_token;

  perform log_audit_event(v_organization_id, 'surgical_agenda_ics_token_regenerated', 'surgeon', p_surgeon_id, null, '{}'::jsonb);
  return v_token;
end;
$function$;

revoke all on function create_surgical_slot(uuid, uuid, timestamptz, timestamptz, uuid, uuid, uuid, text, text, text) from public, anon;
grant execute on function create_surgical_slot(uuid, uuid, timestamptz, timestamptz, uuid, uuid, uuid, text, text, text) to authenticated;

revoke all on function update_surgical_slot(uuid, uuid, timestamptz, timestamptz, uuid, uuid, uuid, text, text, text) from public, anon;
grant execute on function update_surgical_slot(uuid, uuid, timestamptz, timestamptz, uuid, uuid, uuid, text, text, text) to authenticated;

revoke all on function cancel_surgical_slot(uuid, text) from public, anon;
grant execute on function cancel_surgical_slot(uuid, text) to authenticated;

revoke all on function surgical_agenda_ics_token(uuid) from public, anon;
grant execute on function surgical_agenda_ics_token(uuid) to authenticated;

revoke all on function regenerate_surgical_agenda_ics_token(uuid) from public, anon;
grant execute on function regenerate_surgical_agenda_ics_token(uuid) to authenticated;
