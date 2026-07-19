-- Fase A de la evolucion de Instriq: versionado y workflow de aprobacion
-- para tecnicas quirurgicas y protocolos (group_documents). Ejecutar
-- DESPUES de schema_v4_group_documents.sql. Ya existen filas reales en
-- group_documents, asi que este script hace backfill antes de eliminar
-- las columnas de contenido de esa tabla.

-- 1. Nueva tabla de versiones -------------------------------------------------

create table if not exists group_document_versions (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references group_documents(id) on delete cascade,
  version_number int not null,
  status text not null check (status in ('draft', 'in_review', 'published', 'archived')),
  title text not null,
  specialty text,
  content text,
  steps jsonb not null default '[]'::jsonb,
  related_instrument_ids jsonb not null default '[]'::jsonb,
  author_id uuid references auth.users(id) on delete set null,
  comment text,
  based_on_version_id uuid references group_document_versions(id) on delete set null,
  approved_by uuid references auth.users(id) on delete set null,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  unique (document_id, version_number)
);

create index if not exists group_document_versions_document_idx
  on group_document_versions (document_id);

create index if not exists group_document_versions_author_idx
  on group_document_versions (author_id);

-- Como mucho una version publicada por documento.
create unique index if not exists group_document_versions_one_published_idx
  on group_document_versions (document_id)
  where status = 'published';

-- 2. group_documents pasa a ser solo cabecera --------------------------------

alter table group_documents
  add column if not exists published_version_id uuid references group_document_versions(id);

-- 3. Backfill: cada fila existente de group_documents se convierte en su
--    version 1, publicada, con el contenido que ya tenia.
insert into group_document_versions (
  document_id, version_number, status, title, specialty, content,
  steps, related_instrument_ids, author_id, approved_by, approved_at, created_at
)
select
  id, 1, 'published', title, specialty, content,
  steps, related_instrument_ids, created_by, created_by, created_at, created_at
from group_documents
where published_version_id is null;

update group_documents gd
set published_version_id = v.id
from group_document_versions v
where v.document_id = gd.id
  and v.version_number = 1
  and gd.published_version_id is null;

-- 4. El contenido ya vive solo en las versiones: se eliminan las columnas
--    duplicadas de group_documents.
alter table group_documents drop column if exists title;
alter table group_documents drop column if exists specialty;
alter table group_documents drop column if exists content;
alter table group_documents drop column if exists steps;
alter table group_documents drop column if exists related_instrument_ids;
alter table group_documents drop column if exists updated_at;

-- El trigger de updated_at ya no aplica (esa columna no existe en group_documents).
drop trigger if exists group_documents_set_updated_at on group_documents;

-- 5. RLS de group_document_versions -------------------------------------------

alter table group_document_versions enable row level security;

-- Ayuda a comprobar que una version pertenece al hospital del usuario actual.
create or replace function my_group_document_version_hospital(check_document_id uuid)
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select hospital_id from group_documents where id = check_document_id
$$;

drop policy if exists "group_document_versions_select" on group_document_versions;
create policy "group_document_versions_select" on group_document_versions
  for select using (
    my_group_document_version_hospital(document_id) = my_hospital_id()
    and (
      status = 'published'
      or author_id = auth.uid()
      or my_is_hospital_admin()
    )
  );

drop policy if exists "group_document_versions_insert" on group_document_versions;
create policy "group_document_versions_insert" on group_document_versions
  for insert with check (
    status = 'draft'
    and author_id = auth.uid()
    and my_group_document_version_hospital(document_id) = my_hospital_id()
  );

drop policy if exists "group_document_versions_update_own_draft" on group_document_versions;
create policy "group_document_versions_update_own_draft" on group_document_versions
  for update using (
    status = 'draft'
    and author_id = auth.uid()
    and my_group_document_version_hospital(document_id) = my_hospital_id()
  );

-- group_documents: cualquier miembro del hospital puede crear cabeceras
-- (ya cubierto por la policy de insert de schema_v4). El update de
-- published_version_id solo lo hacen las funciones security definer de abajo.

-- 6. Transiciones de estado (security definer) --------------------------------

create or replace function submit_group_document_version_for_review(p_version_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update group_document_versions
  set status = 'in_review'
  where id = p_version_id
    and status = 'draft'
    and author_id = auth.uid();

  if not found then
    raise exception 'No autorizado o version no valida para enviar a revision';
  end if;
end;
$$;

create or replace function approve_group_document_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_document_id uuid;
begin
  if not my_is_hospital_admin() then
    raise exception 'Solo un administrador del grupo puede aprobar cambios';
  end if;

  select document_id into v_document_id
  from group_document_versions
  where id = p_version_id and status = 'in_review';

  if v_document_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  if my_group_document_version_hospital(v_document_id) <> my_hospital_id() then
    raise exception 'No autorizado';
  end if;

  update group_document_versions
  set status = 'archived'
  where document_id = v_document_id and status = 'published';

  update group_document_versions
  set status = 'published',
      approved_by = auth.uid(),
      approved_at = now(),
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  update group_documents
  set published_version_id = p_version_id
  where id = v_document_id;
end;
$$;

create or replace function reject_group_document_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_document_id uuid;
begin
  if not my_is_hospital_admin() then
    raise exception 'Solo un administrador del grupo puede rechazar cambios';
  end if;

  select document_id into v_document_id
  from group_document_versions
  where id = p_version_id and status = 'in_review';

  if v_document_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  if my_group_document_version_hospital(v_document_id) <> my_hospital_id() then
    raise exception 'No autorizado';
  end if;

  update group_document_versions
  set status = 'draft',
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;
end;
$$;

create or replace function restore_group_document_version(p_version_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_document_id uuid;
  v_hospital_id uuid;
  v_next_version int;
  v_new_id uuid;
begin
  select document_id into v_document_id
  from group_document_versions
  where id = p_version_id;

  if v_document_id is null then
    raise exception 'Version no encontrada';
  end if;

  v_hospital_id := my_group_document_version_hospital(v_document_id);
  if v_hospital_id is null or v_hospital_id <> my_hospital_id() then
    raise exception 'No autorizado';
  end if;

  select coalesce(max(version_number), 0) + 1 into v_next_version
  from group_document_versions
  where document_id = v_document_id;

  insert into group_document_versions (
    document_id, version_number, status, title, specialty, content,
    steps, related_instrument_ids, author_id, comment, based_on_version_id
  )
  select
    v_document_id, v_next_version, 'draft', title, specialty, content,
    steps, related_instrument_ids, auth.uid(),
    'Restaurada desde una version anterior', p_version_id
  from group_document_versions
  where id = p_version_id
  returning id into v_new_id;

  return v_new_id;
end;
$$;
