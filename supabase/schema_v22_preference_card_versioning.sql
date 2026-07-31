-- Fase E: versionado universal aplicado a preference_cards -- mismo patron
-- exacto que trays/tray_versions (cabecera estable + versiones, RPCs
-- create_/submit_.../approve_.../reject_..., security definer, log de
-- auditoria). Hasta ahora una tarjeta de preferencia se editaba directo, sin
-- borrador ni aprobacion -- dato clinico (que instrumental quiere un
-- cirujano para un procedimiento) que merece el mismo control de cambios que
-- ya tienen tecnicas/protocolos/bandejas.
--
-- custom_instruments e instrument_sterilization_methods/instrument_technical_info
-- quedan deliberadamente FUERA de esta migracion (ver plan de esta sesion):
-- custom_instruments tiene fotos+variantes que complican donde vive la
-- version, y el dato de esterilizacion es global-vs-hospital (quien aprueba
-- un cambio al catalogo global es una decision de producto sin responder,
-- no se improvisa).

-- La RLS de preference_cards (cards_select/insert/update/delete_role, ver
-- schema_v7_roles.sql) ya usa my_workspace_role() igual que group_documents/
-- trays -- no hace falta tocarla, sigue aplicando igual sobre la cabecera.

alter table preference_cards add column if not exists published_version_id uuid;

create table if not exists preference_card_versions (
  id uuid primary key default gen_random_uuid(),
  card_id uuid not null references preference_cards(id) on delete cascade,
  version_number integer not null,
  status text not null check (status in ('draft', 'in_review', 'published', 'archived')),
  surgeon_id uuid references surgeons(id),
  procedure_name text not null,
  items jsonb not null default '[]'::jsonb,
  general_notes text,
  validated_by_surgeon boolean not null default false,
  author_id uuid references auth.users(id),
  approved_by uuid references auth.users(id),
  approved_at timestamptz,
  comment text,
  based_on_version_id uuid references preference_card_versions(id),
  created_at timestamptz not null default now()
);

-- Backfill: cada fila ya existente de preference_cards (hoy datos reales,
-- aunque pocos) se convierte en su version 1, ya publicada -- nada se pierde
-- al pasar de "editable directo" a "cabecera + version".
insert into preference_card_versions (
  card_id, version_number, status, surgeon_id, procedure_name, items, general_notes,
  validated_by_surgeon, author_id, approved_by, approved_at, created_at
)
select
  id, 1, 'published', surgeon_id, procedure_name, items, general_notes,
  validated, created_by, created_by, created_at, created_at
from preference_cards;

update preference_cards pc
set published_version_id = pcv.id
from preference_card_versions pcv
where pcv.card_id = pc.id and pcv.version_number = 1;

alter table preference_cards drop column if exists surgeon_id;
alter table preference_cards drop column if exists procedure_name;
alter table preference_cards drop column if exists items;
alter table preference_cards drop column if exists general_notes;
alter table preference_cards drop column if exists validated;
alter table preference_cards drop column if exists updated_at;

alter table preference_cards
  add constraint preference_cards_published_version_id_fkey
  foreign key (published_version_id) references preference_card_versions(id);

create index if not exists preference_card_versions_card_idx on preference_card_versions (card_id);

alter table preference_card_versions enable row level security;

-- Mismo idiom de RLS que group_document_versions/tray_versions: visibilidad
-- via my_workspace_role() de la cabecera (preference_cards.workspace_id).
create policy preference_card_versions_select on preference_card_versions
  for select using (
    exists (
      select 1 from preference_cards pc
      where pc.id = preference_card_versions.card_id
      and my_workspace_role(pc.workspace_id) is not null
    )
  );

create policy preference_card_versions_insert on preference_card_versions
  for insert with check (
    exists (
      select 1 from preference_cards pc
      where pc.id = preference_card_versions.card_id
      and my_workspace_role(pc.workspace_id) in ('editor', 'approver', 'administrator')
    )
  );

create policy preference_card_versions_update on preference_card_versions
  for update using (
    exists (
      select 1 from preference_cards pc
      where pc.id = preference_card_versions.card_id
      and my_workspace_role(pc.workspace_id) in ('editor', 'approver', 'administrator')
    )
  );

create or replace function create_preference_card(p_workspace_id uuid)
returns preference_card_versions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_card_id uuid;
  v_version preference_card_versions;
begin
  if my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para crear tarjetas de preferencia en este espacio';
  end if;

  select organization_id into v_organization_id from workspaces where id = p_workspace_id;
  if v_organization_id is null then
    raise exception 'Espacio no encontrado';
  end if;

  insert into preference_cards (organization_id, workspace_id, created_by)
  values (v_organization_id, p_workspace_id, auth.uid())
  returning id into v_card_id;

  insert into preference_card_versions (card_id, version_number, status, procedure_name, author_id)
  values (v_card_id, 1, 'draft', '', auth.uid())
  returning * into v_version;

  perform log_audit_event(
    v_organization_id, 'preference_card_created', 'preference_card', v_card_id, p_workspace_id, '{}'::jsonb
  );

  return v_version;
end;
$$;

create or replace function submit_preference_card_version_for_review(p_version_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_card_id uuid;
  v_workspace_id uuid;
  v_organization_id uuid;
begin
  select card_id into v_card_id
  from preference_card_versions
  where id = p_version_id and status = 'draft' and author_id = auth.uid();

  if v_card_id is null then
    raise exception 'No autorizado o version no valida para enviar a revision';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id from preference_cards where id = v_card_id;

  update preference_card_versions set status = 'in_review' where id = p_version_id;

  perform log_audit_event(
    v_organization_id, 'preference_card_version_submitted', 'preference_card_version', p_version_id, v_workspace_id,
    jsonb_build_object('card_id', v_card_id)
  );
end;
$$;

create or replace function approve_preference_card_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_card_id uuid;
  v_workspace_id uuid;
  v_organization_id uuid;
begin
  select card_id into v_card_id
  from preference_card_versions
  where id = p_version_id and status = 'in_review';

  if v_card_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id from preference_cards where id = v_card_id;

  if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'Solo quien aprueba en este espacio puede aprobar cambios';
  end if;

  update preference_card_versions
  set status = 'archived'
  where card_id = v_card_id and status = 'published';

  update preference_card_versions
  set status = 'published', approved_by = auth.uid(), approved_at = now(),
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  update preference_cards set published_version_id = p_version_id where id = v_card_id;

  perform log_audit_event(
    v_organization_id, 'preference_card_version_approved', 'preference_card_version', p_version_id, v_workspace_id,
    jsonb_build_object('card_id', v_card_id)
  );
end;
$$;

create or replace function reject_preference_card_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_card_id uuid;
  v_workspace_id uuid;
  v_organization_id uuid;
begin
  select card_id into v_card_id
  from preference_card_versions
  where id = p_version_id and status = 'in_review';

  if v_card_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id from preference_cards where id = v_card_id;

  if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'Solo quien aprueba en este espacio puede rechazar cambios';
  end if;

  update preference_card_versions
  set status = 'draft', comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  perform log_audit_event(
    v_organization_id, 'preference_card_version_rejected', 'preference_card_version', p_version_id, v_workspace_id,
    jsonb_build_object('card_id', v_card_id)
  );
end;
$$;

create or replace function restore_preference_card_version(p_version_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_card_id uuid;
  v_workspace_id uuid;
  v_organization_id uuid;
  v_next_version int;
  v_new_id uuid;
begin
  select card_id into v_card_id from preference_card_versions where id = p_version_id;
  if v_card_id is null then
    raise exception 'Version no encontrada';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id from preference_cards where id = v_card_id;

  if my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado';
  end if;

  select coalesce(max(version_number), 0) + 1 into v_next_version
  from preference_card_versions where card_id = v_card_id;

  insert into preference_card_versions (
    card_id, version_number, status, surgeon_id, procedure_name, items, general_notes,
    validated_by_surgeon, author_id, comment, based_on_version_id
  )
  select
    v_card_id, v_next_version, 'draft', surgeon_id, procedure_name, items, general_notes,
    validated_by_surgeon, auth.uid(), 'Restaurada desde una version anterior', p_version_id
  from preference_card_versions
  where id = p_version_id
  returning id into v_new_id;

  perform log_audit_event(
    v_organization_id, 'preference_card_version_submitted', 'preference_card_version', v_new_id, v_workspace_id,
    jsonb_build_object('card_id', v_card_id, 'restored_from', p_version_id)
  );

  return v_new_id;
end;
$$;
