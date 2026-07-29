-- Fase D de la evolucion de Instriq: instrumental personalizado por equipo.
-- Ademas del catalogo global curado (lib/data/instruments_data.dart, con
-- fotos reales de licencia libre verificada de Wikimedia Commons), cada
-- equipo (hospital/workspace) puede dar de alta SU PROPIO instrumental:
-- cosas especificas de ese quirofano, de un cirujano concreto, con
-- variantes propias y su propia foto.
--
-- Reglas de producto, explicitas y no negociables:
--   1. El instrumental personalizado NUNCA se mezcla con el catalogo
--      global ni se hace publico entre hospitales: es privado del
--      workspace/hospital que lo crea. Puede ser instrumental muy
--      especifico, potencialmente patentado por un medico concreto, y
--      mezclarlo o hacerlo publico seria un problema legal. No aparece en
--      CatalogScreen, no se busca junto al catalogo global, vive en su
--      propia seccion separada y en su propio bucket de Storage privado.
--   2. Las fotos son responsabilidad de quien las sube (el equipo), no
--      vienen con licencia verificada como las del catalogo global
--      (CC0/CC-BY de Wikimedia) — la UI debe dejarlo claro con un aviso
--      visible junto a cada foto.
--   3. Un instrumento personalizado puede tener varias variantes, cada
--      una con su propio nombre y su propia foto.
--
-- Sigue el mismo patron que preference_cards (schema.sql + schema_v6:
-- hospital_id + workspace_id, ambos obligatorios) y que group_documents /
-- roles (schema_v7: my_workspace_role(workspace_id) decide quien puede
-- leer/crear/editar/borrar). Ejecutar despues de schema_v7_roles.sql.

-- 1. Tabla de instrumentos personalizados ------------------------------------

create table if not exists custom_instruments (
  id uuid default gen_random_uuid() primary key,
  hospital_id uuid not null references hospitals(id),
  workspace_id uuid not null references workspaces(id),
  name text not null,
  category text,
  specialty text,
  description text,
  use_text text,
  tip text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create index if not exists custom_instruments_workspace_idx on custom_instruments (workspace_id);
create index if not exists custom_instruments_hospital_idx on custom_instruments (hospital_id);

alter table custom_instruments enable row level security;

drop trigger if exists custom_instruments_check_workspace on custom_instruments;
create trigger custom_instruments_check_workspace
  before insert or update on custom_instruments
  for each row execute function check_workspace_matches_hospital();

drop policy if exists "custom_instruments_select_role" on custom_instruments;
create policy "custom_instruments_select_role" on custom_instruments
  for select using (my_workspace_role(workspace_id) is not null);

drop policy if exists "custom_instruments_insert_role" on custom_instruments;
create policy "custom_instruments_insert_role" on custom_instruments
  for insert with check (
    hospital_id = my_hospital_id()
    and my_workspace_role(workspace_id) in ('editor', 'approver', 'administrator')
  );

drop policy if exists "custom_instruments_update_role" on custom_instruments;
create policy "custom_instruments_update_role" on custom_instruments
  for update using (my_workspace_role(workspace_id) in ('editor', 'approver', 'administrator'));

drop policy if exists "custom_instruments_delete_role" on custom_instruments;
create policy "custom_instruments_delete_role" on custom_instruments
  for delete using (my_workspace_role(workspace_id) in ('approver', 'administrator'));

-- updated_at automatico en cada cambio.
create or replace function set_custom_instrument_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists custom_instruments_set_updated_at on custom_instruments;
create trigger custom_instruments_set_updated_at
  before update on custom_instruments
  for each row execute function set_custom_instrument_updated_at();

-- 2. Variantes ----------------------------------------------------------------
-- No tiene workspace_id propio: las policies comprueban el rol a traves del
-- custom_instrument padre.

create table if not exists custom_instrument_variants (
  id uuid default gen_random_uuid() primary key,
  custom_instrument_id uuid not null references custom_instruments(id) on delete cascade,
  name text not null,
  photo_path text,
  note text,
  created_at timestamptz default now()
);

create index if not exists custom_instrument_variants_instrument_idx
  on custom_instrument_variants (custom_instrument_id);

alter table custom_instrument_variants enable row level security;

drop policy if exists "custom_instrument_variants_select_role" on custom_instrument_variants;
create policy "custom_instrument_variants_select_role" on custom_instrument_variants
  for select using (
    exists (
      select 1 from custom_instruments ci
      where ci.id = custom_instrument_variants.custom_instrument_id
        and my_workspace_role(ci.workspace_id) is not null
    )
  );

drop policy if exists "custom_instrument_variants_insert_role" on custom_instrument_variants;
create policy "custom_instrument_variants_insert_role" on custom_instrument_variants
  for insert with check (
    exists (
      select 1 from custom_instruments ci
      where ci.id = custom_instrument_variants.custom_instrument_id
        and my_workspace_role(ci.workspace_id) in ('editor', 'approver', 'administrator')
    )
  );

drop policy if exists "custom_instrument_variants_update_role" on custom_instrument_variants;
create policy "custom_instrument_variants_update_role" on custom_instrument_variants
  for update using (
    exists (
      select 1 from custom_instruments ci
      where ci.id = custom_instrument_variants.custom_instrument_id
        and my_workspace_role(ci.workspace_id) in ('editor', 'approver', 'administrator')
    )
  );

drop policy if exists "custom_instrument_variants_delete_role" on custom_instrument_variants;
create policy "custom_instrument_variants_delete_role" on custom_instrument_variants
  for delete using (
    exists (
      select 1 from custom_instruments ci
      where ci.id = custom_instrument_variants.custom_instrument_id
        and my_workspace_role(ci.workspace_id) in ('approver', 'administrator')
    )
  );

-- 3. Storage: bucket privado para las fotos subidas por cada equipo -----------
-- NOTA: en algunos proyectos Supabase la creacion de buckets via SQL puede
-- no tener efecto (segun la version del addon de Storage) — si tras aplicar
-- esta migracion el bucket no aparece en Storage > Buckets del dashboard,
-- crealo a mano ahi con el mismo id ('custom-instrument-photos') y
-- 'Public bucket' DESACTIVADO, las policies de abajo funcionan igual.

insert into storage.buckets (id, name, public)
values ('custom-instrument-photos', 'custom-instrument-photos', false)
on conflict do nothing;

-- Convencion de ruta de cada objeto dentro del bucket:
--   {hospital_id}/{workspace_id}/{custom_instrument_id}/{variant_id}.jpg
-- storage.foldername(name) devuelve los segmentos de carpeta como text[];
-- esta funcion hace el parseo y la comprobacion de rol en un unico sitio,
-- security definer para poder leer workspace_members/hospitals igual que
-- my_workspace_role, y mas facil de depurar que repetir la logica en cada
-- policy de storage.objects.
create or replace function can_access_custom_instrument_photo(object_name text, need_write boolean)
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
  -- v_segments[1] = hospital_id, v_segments[2] = workspace_id,
  -- v_segments[3] = custom_instrument_id. El hospital_id del path no hace
  -- falta comprobarlo aparte: my_workspace_role ya valida que el workspace
  -- pertenezca al hospital del usuario autenticado.
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

drop policy if exists "custom_instrument_photos_select" on storage.objects;
create policy "custom_instrument_photos_select" on storage.objects
  for select using (
    bucket_id = 'custom-instrument-photos'
    and can_access_custom_instrument_photo(name, false)
  );

drop policy if exists "custom_instrument_photos_insert" on storage.objects;
create policy "custom_instrument_photos_insert" on storage.objects
  for insert with check (
    bucket_id = 'custom-instrument-photos'
    and can_access_custom_instrument_photo(name, true)
  );

drop policy if exists "custom_instrument_photos_update" on storage.objects;
create policy "custom_instrument_photos_update" on storage.objects
  for update using (
    bucket_id = 'custom-instrument-photos'
    and can_access_custom_instrument_photo(name, true)
  );

drop policy if exists "custom_instrument_photos_delete" on storage.objects;
create policy "custom_instrument_photos_delete" on storage.objects
  for delete using (
    bucket_id = 'custom-instrument-photos'
    and can_access_custom_instrument_photo(name, true)
  );
