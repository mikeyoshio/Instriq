-- Versionado del instrumental personalizado (Product Evolution del backlog,
-- receta de docs/ADR_004_VERSIONING.md §5): hasta ahora `custom_instruments`
-- se editaba en directo (schema_v13), a diferencia de tecnicas/protocols
-- (group_documents), bandejas (trays) y tarjetas de preferencia
-- (preference_cards), que ya siguen el patron cabecera+versions con flujo
-- draft -> in_review -> published -> archived. Ejecutar despues de
-- schema_v38_epic2_expansion.sql.
--
-- Decisiones de producto tomadas explicitamente para esta 4a instancia (ver
-- ADR-004 §5, punto 4 -- "decidir explicitament, no per omissio"):
--   1. Variantes (nombre + foto + nota): pasan a vivir DENTRO de la version
--      como jsonb (`variants`), igual que `items`/`photo_paths` en
--      tray_versions -- editar variantes exige ahora un borrador nuevo, con
--      el mismo flujo de aprobacion que el resto del instrumento. Se migra
--      el contenido actual de `custom_instrument_variants` a la primera
--      version publicada de cada instrumento, y la tabla vieja se elimina
--      (las fotos en Storage no se tocan: sus rutas siguen siendo validas,
--      se conservan tal cual dentro del jsonb).
--   2. Notificacion push en aprobar/rechazar: SI (ver
--      supabase/functions/send-push/index.ts, que anade las 3 acciones
--      nuevas a RELEVANT_ACTIONS y una rama para resolver el autor via
--      custom_instrument_versions).
--   3. Sincronizar knowledge_links: NO aplica en la direccion from_type-> --
--      un instrumento personalizado no referencia el sino que ES la
--      referencia (to_type='custom', to_id=custom_instruments.id). Ese id
--      de cabecera no cambia al versionar, asi que los knowledge_links ya
--      existentes que apuntan a un custom_instrument (creados por
--      approve_group_document_version/approve_tray_version) siguen
--      funcionando sin ningun cambio aqui -- no hay nada que sincronizar
--      desde este lado, no es una omision.
--   4. Borrado: RPC propia (`delete_custom_instrument`) con auditoria via
--      log_audit_event, igual que `delete_group_document`.

-- 1. Tabla de versiones ---------------------------------------------------

create table if not exists custom_instrument_versions (
  id uuid primary key default gen_random_uuid(),
  custom_instrument_id uuid not null references custom_instruments(id) on delete cascade,
  version_number int not null,
  status text not null check (status in ('draft', 'in_review', 'published', 'archived')),
  name text not null default '',
  category text,
  -- Texto libre heredado (ver specialty_id) -- se conserva solo para poder
  -- mostrar/migrar filas antiguas que nunca llegaron a tener specialty_id.
  specialty text,
  specialty_id uuid references specialties(id),
  description text,
  use_text text,
  tip text,
  -- Cada elemento: {"id": text, "name": text, "photo_path": text|null,
  -- "note": text|null} -- ver nota de arriba, calcado de tray_versions.items.
  variants jsonb not null default '[]'::jsonb,
  author_id uuid references auth.users(id) on delete set null,
  comment text,
  based_on_version_id uuid references custom_instrument_versions(id),
  approved_by uuid references auth.users(id) on delete set null,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  unique (custom_instrument_id, version_number)
);

create index if not exists custom_instrument_versions_instrument_idx
  on custom_instrument_versions (custom_instrument_id);
create index if not exists custom_instrument_versions_author_idx
  on custom_instrument_versions (author_id);

-- Como mucho una version publicada por instrumento.
create unique index if not exists custom_instrument_versions_one_published_idx
  on custom_instrument_versions (custom_instrument_id)
  where status = 'published';

-- 2. custom_instruments pasa a ser solo cabecera --------------------------

alter table custom_instruments
  add column if not exists published_version_id uuid references custom_instrument_versions(id);

-- 3. Backfill: cada fila existente se convierte en su version 1, publicada,
--    con el contenido que ya tenia y sus variantes agregadas a jsonb.
insert into custom_instrument_versions (
  custom_instrument_id, version_number, status, name, category, specialty, specialty_id,
  description, use_text, tip, variants, author_id, approved_by, approved_at, created_at
)
select
  ci.id, 1, 'published', ci.name, ci.category, ci.specialty, ci.specialty_id,
  ci.description, ci.use_text, ci.tip,
  coalesce(
    (
      select jsonb_agg(jsonb_build_object(
        'id', civ.id::text,
        'name', civ.name,
        'photo_path', civ.photo_path,
        'note', civ.note
      ) order by civ.created_at)
      from custom_instrument_variants civ
      where civ.custom_instrument_id = ci.id
    ),
    '[]'::jsonb
  ),
  ci.created_by, ci.created_by, ci.created_at, ci.created_at
from custom_instruments ci
where ci.published_version_id is null;

update custom_instruments ci
set published_version_id = v.id
from custom_instrument_versions v
where v.custom_instrument_id = ci.id
  and v.version_number = 1
  and ci.published_version_id is null;

-- 4. El contenido ya vive solo en las versiones: se eliminan las columnas
--    duplicadas de custom_instruments y la tabla vieja de variantes (las
--    fotos en Storage no se tocan -- sus rutas ya quedaron guardadas en
--    `variants` arriba).
drop trigger if exists custom_instruments_set_updated_at on custom_instruments;
drop function if exists set_custom_instrument_updated_at();

alter table custom_instruments drop column if exists name;
alter table custom_instruments drop column if exists category;
alter table custom_instruments drop column if exists specialty;
alter table custom_instruments drop column if exists specialty_id;
alter table custom_instruments drop column if exists description;
alter table custom_instruments drop column if exists use_text;
alter table custom_instruments drop column if exists tip;
alter table custom_instruments drop column if exists updated_at;

drop table if exists custom_instrument_variants;

-- 5. RLS ------------------------------------------------------------------

alter table custom_instrument_versions enable row level security;

-- custom_instruments: la policy de select no cambia (schema_v13). Insert
-- directo desde el cliente ya no tiene sentido (la cabecera se crea dentro
-- de create_custom_instrument, security definer) -- se restringe a
-- defensa en profundidad, igual que trays_insert_role. Update directo
-- tampoco: published_version_id solo lo tocan las funciones de abajo.
drop policy if exists "custom_instruments_insert_role" on custom_instruments;
create policy "custom_instruments_insert_role" on custom_instruments
  for insert with check (
    organization_id = my_hospital_id()
    and my_workspace_role(workspace_id) in ('editor', 'approver', 'administrator')
  );

drop policy if exists "custom_instruments_update_role" on custom_instruments;
create policy "custom_instruments_update_role" on custom_instruments
  for update using (my_workspace_role(workspace_id) in ('approver', 'administrator'));

drop policy if exists "custom_instruments_delete_role" on custom_instruments;
create policy "custom_instruments_delete_role" on custom_instruments
  for delete using (my_workspace_role(workspace_id) in ('approver', 'administrator'));

-- custom_instrument_versions: identico a tray_versions (schema_v15).
drop policy if exists "custom_instrument_versions_select_role" on custom_instrument_versions;
create policy "custom_instrument_versions_select_role" on custom_instrument_versions
  for select using (
    my_workspace_role((select workspace_id from custom_instruments where id = custom_instrument_id)) is not null
    and (
      status = 'published'
      or author_id = auth.uid()
      or my_workspace_role((select workspace_id from custom_instruments where id = custom_instrument_id))
         in ('approver', 'administrator')
    )
  );

drop policy if exists "custom_instrument_versions_insert_role" on custom_instrument_versions;
create policy "custom_instrument_versions_insert_role" on custom_instrument_versions
  for insert with check (
    status = 'draft'
    and author_id = auth.uid()
    and my_workspace_role((select workspace_id from custom_instruments where id = custom_instrument_id))
        in ('editor', 'approver', 'administrator')
  );

drop policy if exists "custom_instrument_versions_update_own_draft_role" on custom_instrument_versions;
create policy "custom_instrument_versions_update_own_draft_role" on custom_instrument_versions
  for update using (
    status = 'draft'
    and author_id = auth.uid()
    and my_workspace_role((select workspace_id from custom_instruments where id = custom_instrument_id))
        in ('editor', 'approver', 'administrator')
  );

-- 6. Transiciones de workflow (security definer), calcadas de
--    create_tray/submit_tray_version_for_review/approve_tray_version/
--    reject_tray_version/restore_tray_version (schema_v15/schema_v20), mas
--    delete_custom_instrument (calcada de delete_group_document,
--    schema_v10/schema_v20) por la decision de borrado con auditoria.

create or replace function create_custom_instrument(p_workspace_id uuid)
returns custom_instrument_versions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_instrument_id uuid;
  v_version custom_instrument_versions;
begin
  if my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para crear instrumental personalizado en este espacio';
  end if;

  select organization_id into v_organization_id from workspaces where id = p_workspace_id;
  if v_organization_id is null then
    raise exception 'Espacio no encontrado';
  end if;

  insert into custom_instruments (organization_id, workspace_id, created_by)
  values (v_organization_id, p_workspace_id, auth.uid())
  returning id into v_instrument_id;

  insert into custom_instrument_versions (custom_instrument_id, version_number, status, name, author_id)
  values (v_instrument_id, 1, 'draft', '', auth.uid())
  returning * into v_version;

  perform log_audit_event(
    v_organization_id,
    'custom_instrument_created',
    'custom_instrument',
    v_instrument_id,
    p_workspace_id,
    '{}'::jsonb
  );

  return v_version;
end;
$$;

create or replace function submit_custom_instrument_version_for_review(p_version_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instrument_id uuid;
  v_workspace_id uuid;
  v_organization_id uuid;
begin
  select custom_instrument_id into v_instrument_id
  from custom_instrument_versions
  where id = p_version_id and status = 'draft' and author_id = auth.uid();

  if v_instrument_id is null then
    raise exception 'No autorizado o version no valida para enviar a revision';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id
  from custom_instruments where id = v_instrument_id;

  update custom_instrument_versions
  set status = 'in_review'
  where id = p_version_id;

  perform log_audit_event(
    v_organization_id,
    'custom_instrument_version_submitted',
    'custom_instrument_version',
    p_version_id,
    v_workspace_id,
    jsonb_build_object('custom_instrument_id', v_instrument_id)
  );
end;
$$;

create or replace function approve_custom_instrument_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instrument_id uuid;
  v_workspace_id uuid;
  v_organization_id uuid;
begin
  select custom_instrument_id into v_instrument_id
  from custom_instrument_versions
  where id = p_version_id and status = 'in_review';

  if v_instrument_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id
  from custom_instruments where id = v_instrument_id;

  if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'Solo quien aprueba en este espacio puede aprobar cambios';
  end if;

  update custom_instrument_versions
  set status = 'archived'
  where custom_instrument_id = v_instrument_id and status = 'published';

  update custom_instrument_versions
  set status = 'published',
      approved_by = auth.uid(),
      approved_at = now(),
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  update custom_instruments
  set published_version_id = p_version_id
  where id = v_instrument_id;

  perform log_audit_event(
    v_organization_id,
    'custom_instrument_version_approved',
    'custom_instrument_version',
    p_version_id,
    v_workspace_id,
    jsonb_build_object('custom_instrument_id', v_instrument_id)
  );
end;
$$;

create or replace function reject_custom_instrument_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instrument_id uuid;
  v_workspace_id uuid;
  v_organization_id uuid;
begin
  select custom_instrument_id into v_instrument_id
  from custom_instrument_versions
  where id = p_version_id and status = 'in_review';

  if v_instrument_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id
  from custom_instruments where id = v_instrument_id;

  if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'Solo quien aprueba en este espacio puede rechazar cambios';
  end if;

  update custom_instrument_versions
  set status = 'draft',
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  perform log_audit_event(
    v_organization_id,
    'custom_instrument_version_rejected',
    'custom_instrument_version',
    p_version_id,
    v_workspace_id,
    jsonb_build_object('custom_instrument_id', v_instrument_id)
  );
end;
$$;

create or replace function restore_custom_instrument_version(p_version_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instrument_id uuid;
  v_workspace_id uuid;
  v_organization_id uuid;
  v_next_version int;
  v_new_id uuid;
begin
  select custom_instrument_id into v_instrument_id
  from custom_instrument_versions
  where id = p_version_id;

  if v_instrument_id is null then
    raise exception 'Version no encontrada';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id
  from custom_instruments where id = v_instrument_id;

  if my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado';
  end if;

  select coalesce(max(version_number), 0) + 1 into v_next_version
  from custom_instrument_versions
  where custom_instrument_id = v_instrument_id;

  insert into custom_instrument_versions (
    custom_instrument_id, version_number, status, name, category, specialty, specialty_id,
    description, use_text, tip, variants, author_id, comment, based_on_version_id
  )
  select
    v_instrument_id, v_next_version, 'draft', name, category, specialty, specialty_id,
    description, use_text, tip, variants, auth.uid(),
    'Restaurada desde una version anterior', p_version_id
  from custom_instrument_versions
  where id = p_version_id
  returning id into v_new_id;

  perform log_audit_event(
    v_organization_id,
    'custom_instrument_version_submitted',
    'custom_instrument_version',
    v_new_id,
    v_workspace_id,
    jsonb_build_object('custom_instrument_id', v_instrument_id, 'restored_from', p_version_id)
  );

  return v_new_id;
end;
$$;

create or replace function delete_custom_instrument(p_instrument_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_workspace_id uuid;
  v_name text;
begin
  select organization_id, workspace_id into v_organization_id, v_workspace_id
  from custom_instruments where id = p_instrument_id;

  if v_organization_id is null then
    raise exception 'Instrumento no encontrado';
  end if;

  if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'No autorizado para eliminar instrumental personalizado en este espacio';
  end if;

  select name into v_name
  from custom_instrument_versions
  where custom_instrument_id = p_instrument_id
  order by version_number desc
  limit 1;

  delete from custom_instruments where id = p_instrument_id;

  perform log_audit_event(
    v_organization_id,
    'custom_instrument_deleted',
    'custom_instrument',
    p_instrument_id,
    v_workspace_id,
    jsonb_build_object('name', v_name)
  );
end;
$$;
