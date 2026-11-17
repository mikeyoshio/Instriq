-- schema_v68: Instriq 2.0-alfa "Caso" -- el procediment com a entitat.
--
-- Un procediment (p.ex. "Colecistectomia laparoscopica") es un INDEX lleuger
-- per espai de treball que agrupa contingut que ja existeix i ja passa la
-- seva propia revisio: safates, tecniques/protocols i targetes de
-- preferencia. No fusiona res (decisio EPIC 2, docs/BACKLOG.md:589).
-- Decisions del propietari (2026-11-17): per espai de treball, i edicio
-- directa per editor/approver/administrator SENSE versionat, amb registre
-- d'auditoria -- igual que surgical_slots (v64).
--
-- Mateix model de confiança que surgical_slots: lectura per a qualsevol
-- membre de l'espai, escriptura nomes via RPC security definer. Cap RPC usa
-- my_is_hospital_admin() sense acotar l'organitzacio (error ja corregit a
-- v67): els permisos son sempre per rol a l'espai concret.

create table if not exists procedures (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  workspace_id uuid not null references workspaces(id) on delete cascade,
  specialty_id uuid references specialties(id) on delete set null,
  name text not null check (length(trim(name)) between 1 and 200),
  description text check (description is null or length(description) <= 4000),
  archived_at timestamptz,
  created_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists procedures_workspace_idx on procedures (workspace_id) where archived_at is null;

alter table procedures enable row level security;

drop policy if exists "procedures_select" on procedures;
create policy "procedures_select" on procedures for select using (
  my_workspace_role(workspace_id) is not null
);

-- item_id sense FK: apunta a 3 taules diferents segons item_type. La
-- pertinença al mateix espai es valida a set_procedure_items; els items que
-- deixin d'existir s'ometen en llegir (sense triggers de neteja).
create table if not exists procedure_items (
  id uuid primary key default gen_random_uuid(),
  procedure_id uuid not null references procedures(id) on delete cascade,
  item_type text not null check (item_type in ('tray', 'group_document', 'preference_card')),
  item_id uuid not null,
  position int not null default 0,
  unique (procedure_id, item_type, item_id)
);

create index if not exists procedure_items_procedure_idx on procedure_items (procedure_id);

alter table procedure_items enable row level security;

drop policy if exists "procedure_items_select" on procedure_items;
create policy "procedure_items_select" on procedure_items for select using (
  exists (
    select 1 from procedures p
    where p.id = procedure_items.procedure_id and my_workspace_role(p.workspace_id) is not null
  )
);

alter table surgical_slots add column if not exists procedure_id uuid references procedures(id) on delete set null;

-- ---------------------------------------------------------------------------
-- RPCs
-- ---------------------------------------------------------------------------

create or replace function upsert_procedure(
  p_id uuid,
  p_workspace_id uuid,
  p_name text,
  p_specialty_id uuid default null,
  p_description text default null
)
returns procedures
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_organization_id uuid;
  v_existing_workspace uuid;
  v_row procedures;
begin
  select organization_id into v_organization_id from workspaces where id = p_workspace_id;
  if v_organization_id is null then
    raise exception 'Espacio de trabajo no encontrado';
  end if;
  if coalesce(my_workspace_role(p_workspace_id), '') not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para editar procedimientos en este espacio';
  end if;

  if p_id is null then
    insert into procedures (organization_id, workspace_id, specialty_id, name, description, created_by)
    values (v_organization_id, p_workspace_id, p_specialty_id, trim(p_name), p_description, auth.uid())
    returning * into v_row;
    perform log_audit_event(v_organization_id, 'procedure_created', 'procedure', v_row.id, p_workspace_id,
      jsonb_build_object('name', v_row.name));
  else
    select workspace_id into v_existing_workspace from procedures where id = p_id;
    -- No es pot moure un procediment a un altre espai (ni d'una altra org).
    if v_existing_workspace is null or v_existing_workspace <> p_workspace_id then
      raise exception 'Procedimiento no encontrado en este espacio';
    end if;
    update procedures set
      specialty_id = p_specialty_id,
      name = trim(p_name),
      description = p_description,
      updated_at = now()
    where id = p_id
    returning * into v_row;
    perform log_audit_event(v_organization_id, 'procedure_updated', 'procedure', p_id, p_workspace_id,
      jsonb_build_object('name', v_row.name));
  end if;
  return v_row;
end;
$function$;

-- p_items: [{"item_type": "tray", "item_id": "<uuid>"}, ...] en l'ordre
-- desitjat. Substitueix la llista sencera.
create or replace function set_procedure_items(p_procedure_id uuid, p_items jsonb)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_workspace_id uuid;
  v_organization_id uuid;
  v_item jsonb;
  v_type text;
  v_id uuid;
  v_position int := 0;
begin
  select workspace_id, organization_id into v_workspace_id, v_organization_id
  from procedures where id = p_procedure_id and archived_at is null;
  if v_workspace_id is null then
    raise exception 'Procedimiento no encontrado';
  end if;
  if coalesce(my_workspace_role(v_workspace_id), '') not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para editar procedimientos en este espacio';
  end if;
  if jsonb_typeof(coalesce(p_items, '[]'::jsonb)) <> 'array' then
    raise exception 'Formato de elementos no valido';
  end if;

  delete from procedure_items where procedure_id = p_procedure_id;

  for v_item in select * from jsonb_array_elements(coalesce(p_items, '[]'::jsonb)) loop
    v_type := v_item->>'item_type';
    v_id := (v_item->>'item_id')::uuid;
    -- Cada element ha de ser del MATEIX espai: impedeix enllaçar contingut
    -- d'un altre espai o d'una altra organitzacio.
    if v_type = 'tray' then
      if not exists (select 1 from trays where id = v_id and workspace_id = v_workspace_id) then
        raise exception 'Bandeja no encontrada en este espacio';
      end if;
    elsif v_type = 'group_document' then
      if not exists (select 1 from group_documents where id = v_id and workspace_id = v_workspace_id) then
        raise exception 'Tecnica o protocolo no encontrado en este espacio';
      end if;
    elsif v_type = 'preference_card' then
      if not exists (select 1 from preference_cards where id = v_id and workspace_id = v_workspace_id) then
        raise exception 'Tarjeta de preferencia no encontrada en este espacio';
      end if;
    else
      raise exception 'Tipo de elemento no valido: %', v_type;
    end if;

    insert into procedure_items (procedure_id, item_type, item_id, position)
    values (p_procedure_id, v_type, v_id, v_position)
    on conflict (procedure_id, item_type, item_id) do nothing;
    v_position := v_position + 1;
  end loop;

  update procedures set updated_at = now() where id = p_procedure_id;
  perform log_audit_event(v_organization_id, 'procedure_items_changed', 'procedure', p_procedure_id, v_workspace_id,
    jsonb_build_object('count', v_position));
end;
$function$;

create or replace function archive_procedure(p_procedure_id uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_workspace_id uuid;
  v_organization_id uuid;
begin
  select workspace_id, organization_id into v_workspace_id, v_organization_id
  from procedures where id = p_procedure_id and archived_at is null;
  if v_workspace_id is null then
    raise exception 'Procedimiento no encontrado';
  end if;
  if coalesce(my_workspace_role(v_workspace_id), '') not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para archivar procedimientos en este espacio';
  end if;

  update procedures set archived_at = now(), updated_at = now() where id = p_procedure_id;
  -- Les cites que l'apuntaven el deixen d'apuntar (es manté el text de procedure_name).
  update surgical_slots set procedure_id = null where procedure_id = p_procedure_id;
  perform log_audit_event(v_organization_id, 'procedure_archived', 'procedure', p_procedure_id, v_workspace_id, '{}'::jsonb);
end;
$function$;

-- ---------------------------------------------------------------------------
-- Agenda: create/update_surgical_slot accepten p_procedure_id (mateix espai).
-- Drop + create perquè canvia la signatura (patró de v49/v65).
-- ---------------------------------------------------------------------------

drop function if exists create_surgical_slot(uuid, uuid, timestamptz, timestamptz, uuid, uuid, uuid, text, text, text);
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
  p_notes text default null,
  p_procedure_id uuid default null
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

  if coalesce(my_workspace_role(p_workspace_id), '') not in ('editor', 'approver', 'administrator') then
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

  if p_procedure_id is not null and not exists (
    select 1 from procedures where id = p_procedure_id and workspace_id = p_workspace_id and archived_at is null
  ) then
    raise exception 'Procedimiento no encontrado en este espacio';
  end if;

  insert into surgical_slots (
    organization_id, workspace_id, surgeon_id, preference_card_id, document_id, tray_id,
    procedure_name, location, starts_at, ends_at, notes, created_by, procedure_id
  ) values (
    v_organization_id, p_workspace_id, p_surgeon_id, p_preference_card_id, p_document_id, p_tray_id,
    p_procedure_name, p_location, p_starts_at, p_ends_at, p_notes, auth.uid(), p_procedure_id
  ) returning * into v_row;

  perform log_audit_event(
    v_organization_id, 'surgical_slot_created', 'surgical_slot', v_row.id, p_workspace_id,
    jsonb_build_object('surgeon_id', p_surgeon_id)
  );
  return v_row;
end;
$function$;

drop function if exists update_surgical_slot(uuid, uuid, timestamptz, timestamptz, uuid, uuid, uuid, text, text, text);
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
  p_notes text default null,
  p_procedure_id uuid default null
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

  if coalesce(my_workspace_role(v_workspace_id), '') not in ('editor', 'approver', 'administrator') then
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

  if p_procedure_id is not null and not exists (
    select 1 from procedures where id = p_procedure_id and workspace_id = v_workspace_id and archived_at is null
  ) then
    raise exception 'Procedimiento no encontrado en este espacio';
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
    notes = p_notes,
    procedure_id = p_procedure_id
  where id = p_slot_id
  returning * into v_row;

  perform log_audit_event(
    v_organization_id, 'surgical_slot_updated', 'surgical_slot', p_slot_id, v_workspace_id,
    jsonb_build_object('surgeon_id', p_surgeon_id)
  );
  return v_row;
end;
$function$;

revoke all on function upsert_procedure(uuid, uuid, text, uuid, text) from public, anon;
grant execute on function upsert_procedure(uuid, uuid, text, uuid, text) to authenticated;
revoke all on function set_procedure_items(uuid, jsonb) from public, anon;
grant execute on function set_procedure_items(uuid, jsonb) to authenticated;
revoke all on function archive_procedure(uuid) from public, anon;
grant execute on function archive_procedure(uuid) to authenticated;
revoke all on function create_surgical_slot(uuid, uuid, timestamptz, timestamptz, uuid, uuid, uuid, text, text, text, uuid) from public, anon;
grant execute on function create_surgical_slot(uuid, uuid, timestamptz, timestamptz, uuid, uuid, uuid, text, text, text, uuid) to authenticated;
revoke all on function update_surgical_slot(uuid, uuid, timestamptz, timestamptz, uuid, uuid, uuid, text, text, text, uuid) from public, anon;
grant execute on function update_surgical_slot(uuid, uuid, timestamptz, timestamptz, uuid, uuid, uuid, text, text, text, uuid) to authenticated;

-- Verificació (executar després d'aplicar, amb dos comptes de proves):
--   -- Usuari sense rol a l'espai X: ha de fallar.
--   select upsert_procedure(null, '<workspace_X>', 'Prova');
--   -- Editor de l'espai A enllaçant una safata de l'espai B: ha de fallar.
--   select set_procedure_items('<procedure_A>', '[{"item_type":"tray","item_id":"<tray_B>"}]');
--   -- Membre d'un altre espai: ha de retornar 0 files.
--   select count(*) from procedures where workspace_id = '<workspace_A>';
