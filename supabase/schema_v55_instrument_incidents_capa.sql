-- EPIC: ISO 9001 (8.7/10.2) -- convierte instrument_incidents en un flujo
-- CAPA real (causa raiz + accion correctiva + verificacion de efectividad,
-- separacion de funciones) y mueve todas sus escrituras a RPC, cerrando de
-- paso un bug real de RLS: la politica de update anterior exigia
-- approver/administrator de espacio solo cuando workspace_id no era nulo --
-- para una incidencia a nivel de organizacion (workspace_id nulo, el caso
-- mas comun: ni instrument_detail_screen.dart ni
-- custom_instrument_detail_screen.dart pasan workspace_id hoy) no habia
-- ningun chequeo de rol real, cualquier miembro de la organizacion podia
-- resolverla.

alter table instrument_incidents
  add column if not exists root_cause text,
  add column if not exists corrective_action text,
  add column if not exists verified_by uuid references auth.users(id),
  add column if not exists verified_at timestamptz,
  add column if not exists verification_notes text,
  add column if not exists tray_preparation_session_id uuid references tray_preparation_sessions(id) on delete set null;

create index if not exists instrument_incidents_tray_prep_session_idx
  on instrument_incidents (tray_preparation_session_id);

alter table instrument_incidents drop constraint if exists instrument_incidents_status_check;
alter table instrument_incidents add constraint instrument_incidents_status_check
  check (status in ('open', 'resolved', 'verified'));

-- Sin insert/update/delete directos para authenticated: se escribe solo via
-- RPC, mismo modelo que tray_preparation_sessions/audit_log. La politica de
-- select se mantiene intacta -- la transparencia de lectura (cualquier
-- miembro de la organizacion puede ver cualquier incidencia) es deliberada
-- y no cambia.
drop policy if exists instrument_incidents_insert on instrument_incidents;
drop policy if exists instrument_incidents_update on instrument_incidents;

create or replace function report_instrument_incident(
  p_instrument_ref_type text,
  p_instrument_ref_id text,
  p_severity text,
  p_description text,
  p_workspace_id uuid default null,
  p_tray_preparation_session_id uuid default null
)
returns instrument_incidents
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_row instrument_incidents;
begin
  v_organization_id := my_hospital_id();
  if v_organization_id is null then
    raise exception 'Tu usuario no pertenece a ningun grupo todavia';
  end if;

  -- Replica exactamente la antigua politica de insert: workspace_id nulo
  -- queda deliberadamente sin chequeo de rol (baja friccion para animar a
  -- reportar), workspace_id presente exige editor/approver/administrator en
  -- ese espacio.
  if p_workspace_id is not null and my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para reportar una incidencia en este espacio';
  end if;

  if p_tray_preparation_session_id is not null and not exists (
    select 1 from tray_preparation_sessions
    where id = p_tray_preparation_session_id and organization_id = v_organization_id
  ) then
    raise exception 'Sesion de preparacion no encontrada';
  end if;

  insert into instrument_incidents (
    instrument_ref_type, instrument_ref_id, organization_id, workspace_id,
    severity, status, description, reported_by, tray_preparation_session_id
  ) values (
    p_instrument_ref_type, p_instrument_ref_id, v_organization_id, p_workspace_id,
    p_severity, 'open', p_description, auth.uid(), p_tray_preparation_session_id
  ) returning * into v_row;

  perform log_audit_event(
    v_organization_id, 'instrument_incident_reported', 'instrument_incident',
    v_row.id, p_workspace_id, jsonb_build_object('severity', p_severity)
  );
  return v_row;
end;
$$;

create or replace function resolve_instrument_incident(
  p_incident_id uuid,
  p_root_cause text,
  p_corrective_action text,
  p_resolution_notes text default null
)
returns instrument_incidents
language plpgsql
security definer
set search_path = public
as $$
declare
  v_workspace_id uuid;
  v_organization_id uuid;
  v_status text;
  v_row instrument_incidents;
begin
  select workspace_id, organization_id, status into v_workspace_id, v_organization_id, v_status
  from instrument_incidents where id = p_incident_id;

  if v_organization_id is null or v_organization_id <> my_hospital_id() then
    raise exception 'Incidencia no encontrada';
  end if;
  if v_status <> 'open' then
    raise exception 'Solo se puede resolver una incidencia abierta';
  end if;

  -- El fix real del bug: workspace_id nulo ahora exige explicitamente
  -- my_is_hospital_admin(), no un chequeo vacio.
  if (v_workspace_id is null and not my_is_hospital_admin())
     or (v_workspace_id is not null and my_workspace_role(v_workspace_id) not in ('approver', 'administrator')) then
    raise exception 'No autorizado para resolver esta incidencia';
  end if;

  if coalesce(trim(p_root_cause), '') = '' or coalesce(trim(p_corrective_action), '') = '' then
    raise exception 'La causa raiz y la accion correctiva son obligatorias';
  end if;

  update instrument_incidents set
    status = 'resolved',
    root_cause = p_root_cause,
    corrective_action = p_corrective_action,
    resolution_notes = p_resolution_notes,
    resolved_by = auth.uid(),
    resolved_at = now()
  where id = p_incident_id
  returning * into v_row;

  perform log_audit_event(
    v_organization_id, 'instrument_incident_resolved', 'instrument_incident',
    p_incident_id, v_workspace_id, '{}'::jsonb
  );
  return v_row;
end;
$$;

create or replace function verify_instrument_incident(
  p_incident_id uuid,
  p_verification_notes text default null
)
returns instrument_incidents
language plpgsql
security definer
set search_path = public
as $$
declare
  v_workspace_id uuid;
  v_organization_id uuid;
  v_status text;
  v_resolved_by uuid;
  v_row instrument_incidents;
begin
  select workspace_id, organization_id, status, resolved_by
    into v_workspace_id, v_organization_id, v_status, v_resolved_by
  from instrument_incidents where id = p_incident_id;

  if v_organization_id is null or v_organization_id <> my_hospital_id() then
    raise exception 'Incidencia no encontrada';
  end if;
  if v_status <> 'resolved' then
    raise exception 'Solo se puede verificar una incidencia ya resuelta';
  end if;
  if (v_workspace_id is null and not my_is_hospital_admin())
     or (v_workspace_id is not null and my_workspace_role(v_workspace_id) not in ('approver', 'administrator')) then
    raise exception 'No autorizado para verificar esta incidencia';
  end if;

  -- Separacion de funciones: quien resolvio no puede verificar su propia
  -- resolucion -- exactamente lo que un auditor de ISO 9001 esperaria ver
  -- en el cierre de una no conformidad.
  if v_resolved_by = auth.uid() then
    raise exception 'Quien resuelve una incidencia no puede verificarla tambien';
  end if;

  update instrument_incidents set
    status = 'verified',
    verified_by = auth.uid(),
    verified_at = now(),
    verification_notes = p_verification_notes
  where id = p_incident_id
  returning * into v_row;

  perform log_audit_event(
    v_organization_id, 'instrument_incident_verified', 'instrument_incident',
    p_incident_id, v_workspace_id, '{}'::jsonb
  );
  return v_row;
end;
$$;

revoke all on function report_instrument_incident(text, text, text, text, uuid, uuid) from public, anon;
grant execute on function report_instrument_incident(text, text, text, text, uuid, uuid) to authenticated;

revoke all on function resolve_instrument_incident(uuid, text, text, text) from public, anon;
grant execute on function resolve_instrument_incident(uuid, text, text, text) to authenticated;

revoke all on function verify_instrument_incident(uuid, text) from public, anon;
grant execute on function verify_instrument_incident(uuid, text) to authenticated;
