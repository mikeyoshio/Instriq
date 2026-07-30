-- Fase E de la evolucion de Instriq: modelo de conocimiento clinico por
-- instrumento (esterilizacion + ficha tecnica) y bandejas de instrumental,
-- mas la preferencia de "perfil profesional" que decide el orden de las
-- secciones en la ficha de un instrumento. Ejecutar despues de
-- schema_v14_security_hardening.sql.
--
-- Referencia polimorfica a un instrumento: no existe una tabla de catalogo
-- global en la base de datos (el catalogo curado vive en Dart, en
-- lib/data/instruments_data.dart, con id de tipo string p.ej. 'bisturi'), asi
-- que no se puede usar una FK real. Se sigue exactamente el mismo patron que
-- ya usa group_document_versions.related_instrument_ids hoy: cada fila lleva
--   instrument_ref_type text check (in ('catalog','custom'))
--   instrument_ref_id   text
-- Cuando instrument_ref_type = 'catalog', instrument_ref_id es el id string
-- del catalogo Dart. Cuando es 'custom', es el uuid (como texto) de
-- custom_instruments.id (schema_v13). Sin FK real a ningun catalogo.
--
-- Dos niveles de dato para catalogo/tecnica/ficha:
--   - hospital_id/workspace_id NULL: dato de catalogo global, curado,
--     visible para cualquier usuario autenticado de cualquier hospital.
--     Cualquier admin de cualquier hospital puede proponer/editar estos
--     datos (simplificacion deliberada: no hay todavia un equipo editorial
--     centralizado ni workflow de revision para el catalogo global).
--   - hospital_id/workspace_id NOT NULL: particularidad de un
--     custom_instrument de un workspace concreto (solo tiene sentido con
--     instrument_ref_type = 'custom'), con las mismas reglas de acceso que
--     ya usa custom_instruments (schema_v13) via my_workspace_role().
--
-- Bandejas (trays/tray_versions): calcado del patron de versionado con
-- aprobacion de group_documents/group_document_versions (schema_v5/v7/v10),
-- incluido el registro de auditoria (log_audit_event, schema_v10) y el
-- bucket de Storage privado con convencion de ruta propia (calcado de
-- custom-instrument-photos, schema_v13).
--
-- Queda fuera de esta ronda (rondas futuras):
--   - Relacionar instrumentos con las bandejas donde aparecen desde la
--     ficha del instrumento (mencionado en el perfil "instrumentista" del
--     selector de perfil profesional, pero no implementado todavia).
--   - Un catalogo global editorial con su propio workflow de revision
--     (hoy cualquier admin de hospital puede tocar los datos globales).

-- 0. Preferencia de perfil profesional (solo UI, no afecta a RLS) -------------

alter table profiles add column if not exists professional_profiles text[] not null default '{}';

-- 1. Metodos de esterilizacion por instrumento --------------------------------

create table if not exists instrument_sterilization_methods (
  id uuid default gen_random_uuid() primary key,
  instrument_ref_type text not null check (instrument_ref_type in ('catalog', 'custom')),
  instrument_ref_id text not null,
  hospital_id uuid references hospitals(id),
  workspace_id uuid references workspaces(id),
  method text not null check (method in ('vapor', 'plasma', 'oxido_etileno', 'baja_temperatura', 'desechable', 'no_esterilizable')),
  temperature text,
  time_minutes text,
  pressure text,
  drying text,
  recommended_cycle text,
  compatibility_notes text,
  restrictions text,
  observations text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (instrument_ref_type, instrument_ref_id, method, workspace_id)
);

-- workspace_id NULL no bloquea el unique constraint de arriba (NULL <> NULL
-- en Postgres), asi que hace falta un indice unico parcial aparte para
-- evitar duplicados en el catalogo global (workspace_id is null).
create unique index if not exists instrument_sterilization_methods_global_idx
  on instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, method)
  where workspace_id is null;

create index if not exists instrument_sterilization_methods_ref_idx
  on instrument_sterilization_methods (instrument_ref_type, instrument_ref_id);
create index if not exists instrument_sterilization_methods_workspace_idx
  on instrument_sterilization_methods (workspace_id);

alter table instrument_sterilization_methods enable row level security;

create or replace function set_instrument_sterilization_method_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists instrument_sterilization_methods_set_updated_at on instrument_sterilization_methods;
create trigger instrument_sterilization_methods_set_updated_at
  before update on instrument_sterilization_methods
  for each row execute function set_instrument_sterilization_method_updated_at();

drop policy if exists "instrument_sterilization_methods_select" on instrument_sterilization_methods;
create policy "instrument_sterilization_methods_select" on instrument_sterilization_methods
  for select using (
    (hospital_id is null and auth.role() = 'authenticated')
    or (hospital_id is not null and my_workspace_role(workspace_id) is not null)
  );

drop policy if exists "instrument_sterilization_methods_insert" on instrument_sterilization_methods;
create policy "instrument_sterilization_methods_insert" on instrument_sterilization_methods
  for insert with check (
    (hospital_id is null and my_is_hospital_admin())
    or (hospital_id is not null and my_workspace_role(workspace_id) in ('editor', 'approver', 'administrator'))
  );

drop policy if exists "instrument_sterilization_methods_update" on instrument_sterilization_methods;
create policy "instrument_sterilization_methods_update" on instrument_sterilization_methods
  for update using (
    (hospital_id is null and my_is_hospital_admin())
    or (hospital_id is not null and my_workspace_role(workspace_id) in ('editor', 'approver', 'administrator'))
  );

-- Sin policy de delete: los datos se actualizan, no se borran.

-- 2. Ficha tecnica por instrumento (uno-a-uno) ---------------------------------

create table if not exists instrument_technical_info (
  id uuid default gen_random_uuid() primary key,
  instrument_ref_type text not null check (instrument_ref_type in ('catalog', 'custom')),
  instrument_ref_id text not null,
  hospital_id uuid references hospitals(id),
  workspace_id uuid references workspaces(id),
  manufacturer text,
  ifu_url text,
  maintenance_notes text,
  inspection_notes text,
  useful_life_notes text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (instrument_ref_type, instrument_ref_id, workspace_id)
);

create unique index if not exists instrument_technical_info_global_idx
  on instrument_technical_info (instrument_ref_type, instrument_ref_id)
  where workspace_id is null;

create index if not exists instrument_technical_info_ref_idx
  on instrument_technical_info (instrument_ref_type, instrument_ref_id);
create index if not exists instrument_technical_info_workspace_idx
  on instrument_technical_info (workspace_id);

alter table instrument_technical_info enable row level security;

create or replace function set_instrument_technical_info_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists instrument_technical_info_set_updated_at on instrument_technical_info;
create trigger instrument_technical_info_set_updated_at
  before update on instrument_technical_info
  for each row execute function set_instrument_technical_info_updated_at();

drop policy if exists "instrument_technical_info_select" on instrument_technical_info;
create policy "instrument_technical_info_select" on instrument_technical_info
  for select using (
    (hospital_id is null and auth.role() = 'authenticated')
    or (hospital_id is not null and my_workspace_role(workspace_id) is not null)
  );

drop policy if exists "instrument_technical_info_insert" on instrument_technical_info;
create policy "instrument_technical_info_insert" on instrument_technical_info
  for insert with check (
    (hospital_id is null and my_is_hospital_admin())
    or (hospital_id is not null and my_workspace_role(workspace_id) in ('editor', 'approver', 'administrator'))
  );

drop policy if exists "instrument_technical_info_update" on instrument_technical_info;
create policy "instrument_technical_info_update" on instrument_technical_info
  for update using (
    (hospital_id is null and my_is_hospital_admin())
    or (hospital_id is not null and my_workspace_role(workspace_id) in ('editor', 'approver', 'administrator'))
  );

-- Sin policy de delete: los datos se actualizan, no se borran.

-- 3. Bandejas de instrumental ---------------------------------------------------
-- Mismo patron de cabecera + versiones con workflow de aprobacion que
-- group_documents/group_document_versions (schema_v5/v7/v10): la cabecera
-- solo guarda metadatos de pertenencia, el contenido (nombre, especialidad,
-- fotos, items, observaciones) vive en tray_versions.

create table if not exists trays (
  id uuid primary key default gen_random_uuid(),
  hospital_id uuid not null references hospitals(id),
  workspace_id uuid not null references workspaces(id),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  published_version_id uuid
);

create index if not exists trays_workspace_idx on trays (workspace_id);
create index if not exists trays_hospital_idx on trays (hospital_id);

create table if not exists tray_versions (
  id uuid primary key default gen_random_uuid(),
  tray_id uuid not null references trays(id) on delete cascade,
  version_number int not null,
  status text not null check (status in ('draft', 'in_review', 'published', 'archived')),
  name text,
  specialty text,
  description text,
  photo_paths jsonb not null default '[]'::jsonb,
  items jsonb not null default '[]'::jsonb,
  observations text,
  author_id uuid references auth.users(id) on delete set null,
  approved_by uuid references auth.users(id) on delete set null,
  approved_at timestamptz,
  comment text,
  based_on_version_id uuid references tray_versions(id),
  created_at timestamptz not null default now(),
  unique (tray_id, version_number)
);

create index if not exists tray_versions_tray_idx on tray_versions (tray_id);
create index if not exists tray_versions_author_idx on tray_versions (author_id);

-- Como mucho una version publicada por bandeja.
create unique index if not exists tray_versions_one_published_idx
  on tray_versions (tray_id)
  where status = 'published';

-- FK circular: trays.published_version_id -> tray_versions(id), creada
-- despues de tray_versions, igual que hace schema_v5 con
-- group_documents.published_version_id (columna nullable, se rellena
-- despues via UPDATE al aprobar una version, nunca en el insert inicial).
alter table trays
  add constraint trays_published_version_id_fkey
  foreign key (published_version_id) references tray_versions(id);

alter table trays enable row level security;
alter table tray_versions enable row level security;

drop trigger if exists trays_check_workspace on trays;
create trigger trays_check_workspace
  before insert or update on trays
  for each row execute function check_workspace_matches_hospital();

-- 3a. RLS: identica a group_documents/group_document_versions via
-- my_workspace_role (schema_v7).

drop policy if exists "trays_select_role" on trays;
create policy "trays_select_role" on trays
  for select using (my_workspace_role(workspace_id) is not null);

drop policy if exists "trays_insert_role" on trays;
create policy "trays_insert_role" on trays
  for insert with check (
    hospital_id = my_hospital_id()
    and my_workspace_role(workspace_id) in ('editor', 'approver', 'administrator')
  );

drop policy if exists "trays_update_role" on trays;
create policy "trays_update_role" on trays
  for update using (my_workspace_role(workspace_id) in ('approver', 'administrator'));

drop policy if exists "trays_delete_role" on trays;
create policy "trays_delete_role" on trays
  for delete using (my_workspace_role(workspace_id) in ('approver', 'administrator'));

drop policy if exists "tray_versions_select_role" on tray_versions;
create policy "tray_versions_select_role" on tray_versions
  for select using (
    my_workspace_role((select workspace_id from trays where id = tray_id)) is not null
    and (
      status = 'published'
      or author_id = auth.uid()
      or my_workspace_role((select workspace_id from trays where id = tray_id)) in ('approver', 'administrator')
    )
  );

drop policy if exists "tray_versions_insert_role" on tray_versions;
create policy "tray_versions_insert_role" on tray_versions
  for insert with check (
    status = 'draft'
    and author_id = auth.uid()
    and my_workspace_role((select workspace_id from trays where id = tray_id))
        in ('editor', 'approver', 'administrator')
  );

drop policy if exists "tray_versions_update_own_draft_role" on tray_versions;
create policy "tray_versions_update_own_draft_role" on tray_versions
  for update using (
    status = 'draft'
    and author_id = auth.uid()
    and my_workspace_role((select workspace_id from trays where id = tray_id))
        in ('editor', 'approver', 'administrator')
  );

-- 3b. Transiciones de workflow (security definer), mismo estilo que
-- create_group_document / submit_group_document_version_for_review /
-- approve_group_document_version / reject_group_document_version /
-- restore_group_document_version (schema_v5/v7/v10), con log_audit_event.

create or replace function create_tray(p_workspace_id uuid)
returns tray_versions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hospital_id uuid;
  v_tray_id uuid;
  v_version tray_versions;
begin
  if my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para crear bandejas en este espacio';
  end if;

  select hospital_id into v_hospital_id from workspaces where id = p_workspace_id;
  if v_hospital_id is null then
    raise exception 'Espacio no encontrado';
  end if;

  insert into trays (hospital_id, workspace_id, created_by)
  values (v_hospital_id, p_workspace_id, auth.uid())
  returning id into v_tray_id;

  insert into tray_versions (tray_id, version_number, status, name, author_id)
  values (v_tray_id, 1, 'draft', '', auth.uid())
  returning * into v_version;

  perform log_audit_event(
    v_hospital_id,
    'tray_created',
    'tray',
    v_tray_id,
    p_workspace_id,
    '{}'::jsonb
  );

  return v_version;
end;
$$;

create or replace function submit_tray_version_for_review(p_version_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tray_id uuid;
  v_workspace_id uuid;
  v_hospital_id uuid;
begin
  select tray_id into v_tray_id
  from tray_versions
  where id = p_version_id and status = 'draft' and author_id = auth.uid();

  if v_tray_id is null then
    raise exception 'No autorizado o version no valida para enviar a revision';
  end if;

  select workspace_id, hospital_id into v_workspace_id, v_hospital_id from trays where id = v_tray_id;

  update tray_versions
  set status = 'in_review'
  where id = p_version_id;

  perform log_audit_event(
    v_hospital_id,
    'tray_version_submitted',
    'tray_version',
    p_version_id,
    v_workspace_id,
    jsonb_build_object('tray_id', v_tray_id)
  );
end;
$$;

create or replace function approve_tray_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tray_id uuid;
  v_workspace_id uuid;
  v_hospital_id uuid;
begin
  select tray_id into v_tray_id
  from tray_versions
  where id = p_version_id and status = 'in_review';

  if v_tray_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, hospital_id into v_workspace_id, v_hospital_id from trays where id = v_tray_id;

  if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'Solo quien aprueba en este espacio puede aprobar cambios';
  end if;

  update tray_versions
  set status = 'archived'
  where tray_id = v_tray_id and status = 'published';

  update tray_versions
  set status = 'published',
      approved_by = auth.uid(),
      approved_at = now(),
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  update trays
  set published_version_id = p_version_id
  where id = v_tray_id;

  perform log_audit_event(
    v_hospital_id,
    'tray_version_approved',
    'tray_version',
    p_version_id,
    v_workspace_id,
    jsonb_build_object('tray_id', v_tray_id)
  );
end;
$$;

create or replace function reject_tray_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tray_id uuid;
  v_workspace_id uuid;
  v_hospital_id uuid;
begin
  select tray_id into v_tray_id
  from tray_versions
  where id = p_version_id and status = 'in_review';

  if v_tray_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, hospital_id into v_workspace_id, v_hospital_id from trays where id = v_tray_id;

  if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'Solo quien aprueba en este espacio puede rechazar cambios';
  end if;

  update tray_versions
  set status = 'draft',
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  perform log_audit_event(
    v_hospital_id,
    'tray_version_rejected',
    'tray_version',
    p_version_id,
    v_workspace_id,
    jsonb_build_object('tray_id', v_tray_id)
  );
end;
$$;

create or replace function restore_tray_version(p_version_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tray_id uuid;
  v_workspace_id uuid;
  v_hospital_id uuid;
  v_next_version int;
  v_new_id uuid;
begin
  select tray_id into v_tray_id
  from tray_versions
  where id = p_version_id;

  if v_tray_id is null then
    raise exception 'Version no encontrada';
  end if;

  select workspace_id, hospital_id into v_workspace_id, v_hospital_id from trays where id = v_tray_id;

  if my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado';
  end if;

  select coalesce(max(version_number), 0) + 1 into v_next_version
  from tray_versions
  where tray_id = v_tray_id;

  insert into tray_versions (
    tray_id, version_number, status, name, specialty, description,
    photo_paths, items, observations, author_id, comment, based_on_version_id
  )
  select
    v_tray_id, v_next_version, 'draft', name, specialty, description,
    photo_paths, items, observations, auth.uid(),
    'Restaurada desde una version anterior', p_version_id
  from tray_versions
  where id = p_version_id
  returning id into v_new_id;

  perform log_audit_event(
    v_hospital_id,
    'tray_version_submitted',
    'tray_version',
    v_new_id,
    v_workspace_id,
    jsonb_build_object('tray_id', v_tray_id, 'restored_from', p_version_id)
  );

  return v_new_id;
end;
$$;

-- 4. Storage: bucket privado para las fotos de bandejas ------------------------
-- NOTA: en algunos proyectos Supabase la creacion de buckets via SQL puede
-- no tener efecto (segun la version del addon de Storage) — si tras aplicar
-- esta migracion el bucket no aparece en Storage > Buckets del dashboard,
-- crealo a mano ahi con el mismo id ('tray-photos') y 'Public bucket'
-- DESACTIVADO, las policies de abajo funcionan igual.

insert into storage.buckets (id, name, public)
values ('tray-photos', 'tray-photos', false)
on conflict do nothing;

-- Convencion de ruta de cada objeto dentro del bucket:
--   {hospital_id}/{workspace_id}/{tray_id}/{filename}
-- Calcada de can_access_custom_instrument_photo (schema_v13): v_segments[1]
-- es hospital_id, v_segments[2] es workspace_id, v_segments[3] es tray_id.
create or replace function can_access_tray_photo(object_name text, need_write boolean)
returns boolean
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_segments text[];
  v_workspace_id uuid;
  v_role text;
begin
  v_segments := storage.foldername(object_name);
  if array_length(v_segments, 1) is null or array_length(v_segments, 1) < 2 then
    return false;
  end if;

  begin
    v_workspace_id := v_segments[2]::uuid;
  exception when invalid_text_representation then
    return false;
  end;

  v_role := my_workspace_role(v_workspace_id);

  if need_write then
    return v_role in ('editor', 'approver', 'administrator');
  end if;

  return v_role is not null;
end;
$$;

drop policy if exists "tray_photos_select" on storage.objects;
create policy "tray_photos_select" on storage.objects
  for select using (
    bucket_id = 'tray-photos'
    and can_access_tray_photo(name, false)
  );

drop policy if exists "tray_photos_insert" on storage.objects;
create policy "tray_photos_insert" on storage.objects
  for insert with check (
    bucket_id = 'tray-photos'
    and can_access_tray_photo(name, true)
  );

drop policy if exists "tray_photos_update" on storage.objects;
create policy "tray_photos_update" on storage.objects
  for update using (
    bucket_id = 'tray-photos'
    and can_access_tray_photo(name, true)
  );

drop policy if exists "tray_photos_delete" on storage.objects;
create policy "tray_photos_delete" on storage.objects
  for delete using (
    bucket_id = 'tray-photos'
    and can_access_tray_photo(name, true)
  );
