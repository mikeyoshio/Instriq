-- Fase F de la evolucion de Instriq: fotos de la comunidad para el catalogo
-- global (lib/data/instruments_data.dart). Ejecutar despues de
-- schema_v15_clinical_knowledge_model.sql.
--
-- Contexto: de los 110 instrumentos del catalogo global solo algunos tienen
-- foto real verificada de Wikimedia Commons (InstrumentImage). Para el resto,
-- cualquier usuaria/o registrada puede aportar una foto — pero antes de
-- hacerse visible para el resto de la app pasa por moderacion (queda en
-- estado 'pending', invisible para todo el mundo salvo quien la subio y un
-- admin). Referencia polimorfica identica al patron ya usado en
-- schema_v15 (instrument_ref_type/instrument_ref_id: 'catalog' -> id string
-- del catalogo Dart, 'custom' -> uuid de custom_instruments como texto, sin
-- FK real a ningun catalogo).
--
-- Por que el bucket es publico (a diferencia de tray-photos /
-- custom-instrument-photos, ambos privados): CatalogScreen e
-- InstrumentDetailScreen funcionan SIN cuenta (como ya pasa hoy con las
-- fotos de Wikimedia, servidas con Image.network directo a una URL publica,
-- sin createSignedUrl). Una persona anonima tiene que poder ver una foto ya
-- aprobada. Un bucket privado con URLs firmadas no serviria para usuarios
-- anonimos. La moderacion real no la hace el bucket (que es publico para
-- cualquier objeto que contenga), la hace el gating de la propia app: el
-- cliente Flutter solo pide/pinta una foto cuando status = 'approved' (ver
-- CatalogCommunityPhotoService.fetchApprovedPhoto), y las policies de la
-- tabla ya impiden leer filas 'pending'/'rejected' salvo para quien la subio
-- o un admin. No hay dato personal en la foto de un instrumento quirurgico,
-- asi que un bucket legible por cualquiera no supone un problema de
-- privacidad en si mismo.

-- 1. Tabla de fotos aportadas por la comunidad --------------------------------

create table if not exists catalog_community_photos (
  id uuid default gen_random_uuid() primary key,
  instrument_ref_type text not null check (instrument_ref_type in ('catalog', 'custom')),
  instrument_ref_id text not null,
  photo_path text not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  submitted_by uuid references auth.users(id) on delete set null,
  credit_name text,
  consent_accepted boolean not null default false check (consent_accepted = true),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  rejection_reason text,
  created_at timestamptz default now()
);

create index if not exists catalog_community_photos_ref_idx
  on catalog_community_photos (instrument_ref_type, instrument_ref_id);
create index if not exists catalog_community_photos_status_idx
  on catalog_community_photos (status);
create index if not exists catalog_community_photos_submitted_by_idx
  on catalog_community_photos (submitted_by);

alter table catalog_community_photos enable row level security;

-- 2. RLS ------------------------------------------------------------------------
-- Select: cualquiera (incluido anonimo, para que la app pueda mostrar la foto
-- aprobada sin sesion) puede ver filas aprobadas. Ademas, quien la subio
-- puede ver sus propias filas pendientes/rechazadas (para el aviso "ya tienes
-- una foto pendiente de revision"), y un admin puede ver todo para moderar.
-- No existe un rol "admin global de catalogo" todavia (ver nota de
-- schema_v15): se reutiliza profiles.is_admin (admin de hospital) tal cual,
-- igual que indica la ronda de trabajo — es una simplificacion deliberada.
drop policy if exists "catalog_community_photos_select" on catalog_community_photos;
create policy "catalog_community_photos_select" on catalog_community_photos
  for select using (
    status = 'approved'
    or submitted_by = auth.uid()
    or exists (select 1 from profiles where id = auth.uid() and is_admin = true)
  );

-- Insert: cualquier usuaria/o autenticada, siempre que declare el consentimiento
-- y se atribuya a si misma (submitted_by = auth.uid()). El check constraint
-- de la columna ya obliga consent_accepted = true a nivel de tabla; aqui se
-- repite en la policy para que quede explicito el requisito de producto.
drop policy if exists "catalog_community_photos_insert" on catalog_community_photos;
create policy "catalog_community_photos_insert" on catalog_community_photos
  for insert to authenticated
  with check (
    submitted_by = auth.uid()
    and consent_accepted = true
    and status = 'pending'
  );

-- Update: nadie desde el cliente directamente. Aprobar/rechazar pasa siempre
-- por review_community_photo (security definer, mas abajo), que ya comprueba
-- is_admin. Sin policy de update ni de delete: los datos se moderan, no se
-- editan ni se borran a mano.

-- 3. Moderacion (security definer) ----------------------------------------------
-- Aprueba o rechaza una foto pendiente. Si no se pasa p_credit_name al
-- aprobar, se usa el display_name del perfil de quien la subio (o null, que
-- el cliente interpreta como "Comunitat Instriq" / equivalente generico).
create or replace function review_community_photo(
  p_photo_id uuid,
  p_approve boolean,
  p_credit_name text default null,
  p_rejection_reason text default null
)
returns catalog_community_photos
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row catalog_community_photos;
  v_credit_name text;
begin
  if not exists (select 1 from profiles where id = auth.uid() and is_admin = true) then
    raise exception 'Solo un administrador puede revisar fotos de la comunidad';
  end if;

  select * into v_row from catalog_community_photos where id = p_photo_id and status = 'pending';
  if v_row.id is null then
    raise exception 'Foto no encontrada o ya revisada';
  end if;

  if p_approve then
    v_credit_name := p_credit_name;
    if v_credit_name is null or trim(v_credit_name) = '' then
      select display_name into v_credit_name from profiles where id = v_row.submitted_by;
    end if;

    update catalog_community_photos
    set status = 'approved',
        credit_name = v_credit_name,
        reviewed_by = auth.uid(),
        reviewed_at = now(),
        rejection_reason = null
    where id = p_photo_id
    returning * into v_row;

    -- log_audit_event exige hospital_id (columna nullable pero la funcion
    -- esta pensada para eventos de un hospital concreto); esto es moderacion
    -- GLOBAL de catalogo, sin hospital, asi que se inserta directo en
    -- audit_log replicando lo que hace log_audit_event (mismo esquema de
    -- columnas, actor_id = auth.uid(), hospital_id/workspace_id null).
    insert into audit_log (hospital_id, actor_id, action, entity_type, entity_id, workspace_id, metadata)
    values (
      null,
      auth.uid(),
      'community_photo_approved',
      'catalog_community_photo',
      p_photo_id,
      null,
      jsonb_build_object(
        'instrument_ref_type', v_row.instrument_ref_type,
        'instrument_ref_id', v_row.instrument_ref_id,
        'credit_name', v_credit_name
      )
    );
  else
    update catalog_community_photos
    set status = 'rejected',
        reviewed_by = auth.uid(),
        reviewed_at = now(),
        rejection_reason = p_rejection_reason
    where id = p_photo_id
    returning * into v_row;

    insert into audit_log (hospital_id, actor_id, action, entity_type, entity_id, workspace_id, metadata)
    values (
      null,
      auth.uid(),
      'community_photo_rejected',
      'catalog_community_photo',
      p_photo_id,
      null,
      jsonb_build_object(
        'instrument_ref_type', v_row.instrument_ref_type,
        'instrument_ref_id', v_row.instrument_ref_id,
        'rejection_reason', p_rejection_reason
      )
    );
  end if;

  return v_row;
end;
$$;

-- 4. Storage: bucket PUBLICO para las fotos aportadas por la comunidad --------
-- NOTA: en algunos proyectos Supabase la creacion de buckets via SQL puede no
-- tener efecto (segun la version del addon de Storage) — si tras aplicar esta
-- migracion el bucket no aparece en Storage > Buckets del dashboard, crealo a
-- mano ahi con el mismo id ('catalog-community-photos') y 'Public bucket'
-- ACTIVADO, las policies de abajo funcionan igual.

insert into storage.buckets (id, name, public)
values ('catalog-community-photos', 'catalog-community-photos', true)
on conflict do nothing;

-- Convencion de ruta de cada objeto dentro del bucket:
--   {instrument_ref_type}/{instrument_ref_id}/{uuid}.<ext>
-- No hace falta parsear ni comprobar rol por carpeta (a diferencia de
-- tray-photos / custom-instrument-photos): el bucket es publico para lectura,
-- y la moderacion real vive en la tabla, no en Storage.
drop policy if exists "catalog_community_photos_select" on storage.objects;
create policy "catalog_community_photos_select" on storage.objects
  for select using (bucket_id = 'catalog-community-photos');

drop policy if exists "catalog_community_photos_insert" on storage.objects;
create policy "catalog_community_photos_insert" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'catalog-community-photos');
