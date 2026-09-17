-- Reportar un error de contenido en el catalogo global (lib/data/instruments_data.dart).
-- Ejecutar despues de schema_v27_contributors.sql (usa my_is_editorial_board()).
--
-- Por que una tabla nueva y no instrument_incidents (schema_v32): esa tabla
-- es para incidencias operativas de un instrumento fisico de UNA organizacion
-- concreta (roto, perdido) -- organization_id es obligatorio ahi. Un error de
-- contenido en una ficha del catalogo global ("la descripcion confunde Kelly
-- con Pean", "la foto no es la correcta") no pertenece a ninguna
-- organizacion, es sobre el catalogo compartido por todas. El precedente que
-- si encaja es catalog_community_photos (schema_v16): mismo catalogo global,
-- mismo patron instrument_ref_type/instrument_ref_id, sin organization_id,
-- moderacion antes de tener efecto.
--
-- Por que el gate de moderacion es my_is_editorial_board() y no
-- profiles.is_admin (a diferencia de catalog_community_photos, que usa
-- is_admin): juzgar si una descripcion clinica es erronea es una decision
-- editorial de conocimiento, no de administracion de cuenta -- mismo criterio
-- que ya usa GlobalCatalogReviewQueueScreen para esterilizacion/ficha
-- tecnica (ver docs/EPIC_COMMUNITY_GOVERNANCE.md).
--
-- Nota: el catalogo (kInstruments) es una lista Dart compilada en la app, no
-- contenido vivo en base de datos -- resolver un reporte no reescribe el
-- catalogo por si solo, es una senal para quien mantiene ese fichero de que
-- hay que corregirlo en una proxima version de la app.

create table if not exists catalog_content_reports (
  id uuid primary key default gen_random_uuid(),
  instrument_ref_type text not null check (instrument_ref_type in ('catalog', 'custom')),
  instrument_ref_id text not null,
  description text not null,
  status text not null default 'open' check (status in ('open', 'resolved')),
  reported_by uuid references auth.users(id) on delete set null,
  resolved_by uuid references auth.users(id) on delete set null,
  resolved_at timestamptz,
  resolution_notes text,
  created_at timestamptz not null default now()
);

create index if not exists catalog_content_reports_ref_idx
  on catalog_content_reports (instrument_ref_type, instrument_ref_id);
create index if not exists catalog_content_reports_status_idx
  on catalog_content_reports (status);
create index if not exists catalog_content_reports_reported_by_idx
  on catalog_content_reports (reported_by);

alter table catalog_content_reports enable row level security;

-- Select: quien lo reporto (para poder ver el estado de lo suyo), o el
-- Editorial Board (para moderar). Nadie mas -- a diferencia de
-- instrument_incidents, esto no es transparente a nivel de organizacion
-- porque no hay organizacion involucrada.
drop policy if exists "catalog_content_reports_select" on catalog_content_reports;
create policy "catalog_content_reports_select" on catalog_content_reports
  for select using (
    reported_by = auth.uid()
    or my_is_editorial_board()
  );

-- Insert: cualquier usuaria/o autenticada, siempre auto-atribuida.
drop policy if exists "catalog_content_reports_insert" on catalog_content_reports;
create policy "catalog_content_reports_insert" on catalog_content_reports
  for insert to authenticated
  with check (
    reported_by = auth.uid()
    and status = 'open'
  );

-- Update: nadie desde el cliente directamente. Resolver pasa siempre por
-- resolve_catalog_content_report (security definer, mas abajo), que ya
-- comprueba my_is_editorial_board() -- mismo criterio que
-- review_community_photo.

create or replace function resolve_catalog_content_report(
  p_report_id uuid,
  p_resolution_notes text default null
)
returns catalog_content_reports
language plpgsql
security definer
set search_path = public
as $$
declare
  v_row catalog_content_reports;
begin
  if not my_is_editorial_board() then
    raise exception 'Solo el Editorial Board puede resolver un reporte de contenido';
  end if;

  select * into v_row from catalog_content_reports where id = p_report_id and status = 'open';
  if v_row.id is null then
    raise exception 'Reporte no encontrado o ya resuelto';
  end if;

  update catalog_content_reports
  set status = 'resolved',
      resolved_by = auth.uid(),
      resolved_at = now(),
      resolution_notes = p_resolution_notes
  where id = p_report_id
  returning * into v_row;

  -- Mismo criterio que review_community_photo: moderacion GLOBAL de
  -- catalogo, sin organizacion, se inserta directo en audit_log replicando el
  -- esquema de log_audit_event (organization_id/workspace_id null).
  insert into audit_log (organization_id, actor_id, action, entity_type, entity_id, workspace_id, metadata)
  values (
    null,
    auth.uid(),
    'catalog_content_report_resolved',
    'catalog_content_report',
    p_report_id,
    null,
    jsonb_build_object(
      'instrument_ref_type', v_row.instrument_ref_type,
      'instrument_ref_id', v_row.instrument_ref_id,
      'resolution_notes', p_resolution_notes
    )
  );

  return v_row;
end;
$$;

-- revoke from public no basta: Supabase concede EXECUTE directamente a
-- anon/authenticated/service_role al crear la funcion (no via PUBLIC), asi
-- que hay que revocarselo explicitamente a anon tambien.
revoke all on function resolve_catalog_content_report(uuid, text) from public;
revoke all on function resolve_catalog_content_report(uuid, text) from anon;
grant execute on function resolve_catalog_content_report(uuid, text) to authenticated;
