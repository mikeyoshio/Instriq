-- EPIC 4 (Bandejas 2.0): posicion por item, sesiones reales de preparacion
-- con control de calidad/validacion, y duplicar bandeja. Checklist, fotos,
-- versionado e historial ya existian (schema_v15); esto anade lo que
-- faltaba, sin precedente previo en el codigo (ver docs/BACKLOG.md).

-- 1. Posicion fisica opcional por item del checklist (p.ej. "Bandeja
-- superior, fila 1"). Se guarda dentro del jsonb `items` ya existente en
-- tray_versions -- no hace falta ALTER TABLE, es un campo mas del objeto
-- TrayItem serializado. No hay nada que migrar aqui a nivel SQL.

-- 2. Sesiones de preparacion: registro de cada montaje fisico real de una
-- bandeja tras el lavado/esterilizacion, con lo que se encontro item a item
-- y el control de calidad/validacion de otra persona (o la misma).
create table if not exists tray_preparation_sessions (
  id uuid primary key default gen_random_uuid(),
  tray_id uuid not null references trays(id) on delete cascade,
  tray_version_id uuid not null references tray_versions(id),
  organization_id uuid not null references organizations(id) on delete cascade,
  workspace_id uuid not null references workspaces(id) on delete cascade,
  prepared_by uuid references auth.users(id),
  prepared_at timestamptz not null default now(),
  item_results jsonb not null default '[]'::jsonb,
  status text not null default 'prepared' check (status in ('prepared', 'qc_passed', 'qc_failed')),
  qc_by uuid references auth.users(id),
  qc_at timestamptz,
  qc_notes text,
  created_at timestamptz not null default now()
);

create index if not exists tray_preparation_sessions_tray_idx on tray_preparation_sessions (tray_id, prepared_at desc);
create index if not exists tray_preparation_sessions_organization_idx on tray_preparation_sessions (organization_id);
create index if not exists tray_preparation_sessions_workspace_idx on tray_preparation_sessions (workspace_id);
create index if not exists tray_preparation_sessions_version_idx on tray_preparation_sessions (tray_version_id);
create index if not exists tray_preparation_sessions_prepared_by_idx on tray_preparation_sessions (prepared_by);
create index if not exists tray_preparation_sessions_qc_by_idx on tray_preparation_sessions (qc_by);

alter table tray_preparation_sessions enable row level security;

drop policy if exists "tray_preparation_sessions_select" on tray_preparation_sessions;
create policy "tray_preparation_sessions_select" on tray_preparation_sessions for select using (
  my_workspace_role(workspace_id) is not null or my_is_hospital_admin()
);

-- Sin insert/update/delete directos para authenticated: se escribe solo via
-- las 2 RPC siguientes, mismo modelo de confianza que audit_log/knowledge_links.

create or replace function create_tray_preparation_session(p_tray_id uuid, p_item_results jsonb)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_workspace_id uuid;
  v_organization_id uuid;
  v_published_version_id uuid;
  v_session_id uuid;
begin
  select workspace_id, organization_id, published_version_id
    into v_workspace_id, v_organization_id, v_published_version_id
  from trays where id = p_tray_id;

  if v_workspace_id is null then
    raise exception 'Bandeja no encontrada';
  end if;

  if v_published_version_id is null then
    raise exception 'Esta bandeja todavia no tiene una version publicada que preparar';
  end if;

  if my_workspace_role(v_workspace_id) is null then
    raise exception 'No autorizado para registrar una preparacion en este espacio';
  end if;

  insert into tray_preparation_sessions (
    tray_id, tray_version_id, organization_id, workspace_id, prepared_by, item_results
  )
  values (p_tray_id, v_published_version_id, v_organization_id, v_workspace_id, auth.uid(), p_item_results)
  returning id into v_session_id;

  perform log_audit_event(
    v_organization_id,
    'tray_preparation_created',
    'tray_preparation_session',
    v_session_id,
    v_workspace_id,
    jsonb_build_object('tray_id', p_tray_id)
  );

  return v_session_id;
end;
$function$;

create or replace function qc_tray_preparation_session(p_session_id uuid, p_passed boolean, p_notes text default null)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_workspace_id uuid;
  v_organization_id uuid;
  v_tray_id uuid;
begin
  select workspace_id, organization_id, tray_id into v_workspace_id, v_organization_id, v_tray_id
  from tray_preparation_sessions where id = p_session_id;

  if v_workspace_id is null then
    raise exception 'Sesion de preparacion no encontrada';
  end if;

  if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'Solo quien aprueba en este espacio puede validar una preparacion';
  end if;

  update tray_preparation_sessions
  set status = case when p_passed then 'qc_passed' else 'qc_failed' end,
      qc_by = auth.uid(),
      qc_at = now(),
      qc_notes = p_notes
  where id = p_session_id;

  perform log_audit_event(
    v_organization_id,
    'tray_preparation_qc',
    'tray_preparation_session',
    p_session_id,
    v_workspace_id,
    jsonb_build_object('tray_id', v_tray_id, 'passed', p_passed)
  );
end;
$function$;

-- 3. Duplicar bandeja: copia la definicion (no las fotos, viven en Storage
-- atadas al tray_id original -- fuera de alcance de este tramo) de la
-- version publicada de origen a una bandeja nueva, con un primer borrador.
create or replace function duplicate_tray(p_tray_id uuid)
returns tray_versions
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_source_workspace_id uuid;
  v_source_organization_id uuid;
  v_source_version tray_versions;
  v_new_tray_id uuid;
  v_new_version tray_versions;
begin
  select workspace_id, organization_id into v_source_workspace_id, v_source_organization_id
  from trays where id = p_tray_id;

  if v_source_workspace_id is null then
    raise exception 'Bandeja no encontrada';
  end if;

  if my_workspace_role(v_source_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para duplicar bandejas en este espacio';
  end if;

  select tv.* into v_source_version
  from tray_versions tv
  join trays t on t.published_version_id = tv.id
  where t.id = p_tray_id;

  if v_source_version.id is null then
    raise exception 'Esta bandeja todavia no tiene una version publicada que duplicar';
  end if;

  insert into trays (organization_id, workspace_id, created_by)
  values (v_source_organization_id, v_source_workspace_id, auth.uid())
  returning id into v_new_tray_id;

  insert into tray_versions (
    tray_id, version_number, status, name, specialty, specialty_id, description, items, observations,
    author_id, comment
  )
  values (
    v_new_tray_id, 1, 'draft', v_source_version.name, v_source_version.specialty, v_source_version.specialty_id,
    v_source_version.description, v_source_version.items, v_source_version.observations,
    auth.uid(), 'Duplicada desde otra bandeja del espacio'
  )
  returning * into v_new_version;

  perform log_audit_event(
    v_source_organization_id,
    'tray_duplicated',
    'tray',
    v_new_tray_id,
    v_source_workspace_id,
    jsonb_build_object('source_tray_id', p_tray_id)
  );

  return v_new_version;
end;
$function$;
