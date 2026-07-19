-- Fase C de la evolucion de Instriq: espacios de trabajo (Organizacion ->
-- Espacios -> Colecciones -> Contenido). Un hospital (Organizacion) puede
-- tener varios espacios (Traumatologia, Neurocirugia, Formacion...); las
-- tecnicas/protocolos y tarjetas de preferencia pasan a colgar de un
-- espacio, no solo del hospital. Ejecutar despues de
-- schema_v5_group_document_versions.sql. Ya existen filas reales en
-- group_documents y preference_cards, asi que este script crea un espacio
-- "General" por hospital y migra el contenido existente ahi.

-- 1. Tabla de espacios --------------------------------------------------------

create table if not exists workspaces (
  id uuid primary key default gen_random_uuid(),
  hospital_id uuid not null references hospitals(id) on delete cascade,
  name text not null,
  description text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists workspaces_hospital_idx on workspaces (hospital_id);

alter table workspaces enable row level security;

drop policy if exists "workspaces_select_same_hospital" on workspaces;
create policy "workspaces_select_same_hospital" on workspaces
  for select using (hospital_id = my_hospital_id());

drop policy if exists "workspaces_insert_admin" on workspaces;
create policy "workspaces_insert_admin" on workspaces
  for insert with check (hospital_id = my_hospital_id() and my_is_hospital_admin());

drop policy if exists "workspaces_update_admin" on workspaces;
create policy "workspaces_update_admin" on workspaces
  for update using (hospital_id = my_hospital_id() and my_is_hospital_admin());

drop policy if exists "workspaces_delete_admin" on workspaces;
create policy "workspaces_delete_admin" on workspaces
  for delete using (hospital_id = my_hospital_id() and my_is_hospital_admin());

-- 2. Backfill: un espacio "General" por hospital existente --------------------

insert into workspaces (hospital_id, name, created_by)
select id, 'General', created_by
from hospitals h
where not exists (select 1 from workspaces w where w.hospital_id = h.id);

-- 3. workspace_id en group_documents y preference_cards -----------------------

alter table group_documents add column if not exists workspace_id uuid references workspaces(id);
alter table preference_cards add column if not exists workspace_id uuid references workspaces(id);

update group_documents gd
set workspace_id = w.id
from workspaces w
where w.hospital_id = gd.hospital_id
  and w.name = 'General'
  and gd.workspace_id is null;

update preference_cards pc
set workspace_id = w.id
from workspaces w
where w.hospital_id = pc.hospital_id
  and w.name = 'General'
  and pc.workspace_id is null;

alter table group_documents alter column workspace_id set not null;
alter table preference_cards alter column workspace_id set not null;

create index if not exists group_documents_workspace_idx on group_documents (workspace_id);
create index if not exists preference_cards_workspace_idx on preference_cards (workspace_id);

-- 4. Integridad: workspace_id debe pertenecer al mismo hospital_id de la fila -

create or replace function check_workspace_matches_hospital()
returns trigger
language plpgsql
as $$
begin
  if not exists (
    select 1 from workspaces
    where id = new.workspace_id and hospital_id = new.hospital_id
  ) then
    raise exception 'El espacio no pertenece al mismo grupo que el contenido';
  end if;
  return new;
end;
$$;

drop trigger if exists group_documents_check_workspace on group_documents;
create trigger group_documents_check_workspace
  before insert or update on group_documents
  for each row execute function check_workspace_matches_hospital();

drop trigger if exists preference_cards_check_workspace on preference_cards;
create trigger preference_cards_check_workspace
  before insert or update on preference_cards
  for each row execute function check_workspace_matches_hospital();
