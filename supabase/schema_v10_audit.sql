-- Fase D de la evolucion de Instriq: registro de auditoria. Quien hizo que
-- y cuando sobre las acciones sensibles (aprobar/rechazar tecnicas y
-- protocolos, crear/borrar documentos, cambios de rol de miembros,
-- transferencia de propiedad del hospital). Ejecutar DESPUES de
-- schema_v9_gdpr.sql.
--
-- actor_id sigue el mismo patron que el resto del esquema
-- ("references auth.users(id) on delete set null"): si la cuenta se borra
-- (Fase GDPR), el log no se pierde ni bloquea el borrado, solo pierde la
-- referencia a quien hizo la accion (se muestra como "Usuario eliminado" en
-- el cliente, igual que ya se hace con documentos/tarjetas).

-- 1. Tabla de auditoria -------------------------------------------------------

create table if not exists audit_log (
  id uuid primary key default gen_random_uuid(),
  hospital_id uuid references hospitals(id),
  actor_id uuid references auth.users(id) on delete set null,
  action text not null,
  entity_type text,
  entity_id uuid,
  workspace_id uuid references workspaces(id),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists audit_log_hospital_idx on audit_log (hospital_id, created_at desc);
create index if not exists audit_log_workspace_idx on audit_log (workspace_id);
create index if not exists audit_log_actor_idx on audit_log (actor_id);

alter table audit_log enable row level security;

-- Solo admin/owner del hospital correspondiente puede leer el log. Sin
-- policies de insert/update/delete para "authenticated": los inserts solo
-- pasan por log_audit_event() (security definer), y nadie puede editar ni
-- borrar filas desde el cliente.
drop policy if exists "audit_log_select_admin" on audit_log;
create policy "audit_log_select_admin" on audit_log
  for select using (
    hospital_id = my_hospital_id()
    and my_is_hospital_admin()
  );

-- 2. Helper de insercion (security definer) -----------------------------------

create or replace function log_audit_event(
  p_hospital_id uuid,
  p_action text,
  p_entity_type text,
  p_entity_id uuid,
  p_workspace_id uuid,
  p_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into audit_log (hospital_id, actor_id, action, entity_type, entity_id, workspace_id, metadata)
  values (p_hospital_id, auth.uid(), p_action, p_entity_type, p_entity_id, p_workspace_id, coalesce(p_metadata, '{}'::jsonb));
end;
$$;

-- 3. Funciones ya existentes: se añade el log al final ------------------------
--    (mismo cuerpo que la version vigente en schema_v7, solo se añade la
--    llamada a log_audit_event antes de retornar).

create or replace function approve_group_document_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_document_id uuid;
  v_workspace_id uuid;
  v_hospital_id uuid;
  v_title text;
begin
  select document_id, title into v_document_id, v_title
  from group_document_versions
  where id = p_version_id and status = 'in_review';

  if v_document_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, hospital_id into v_workspace_id, v_hospital_id
  from group_documents where id = v_document_id;

  if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'Solo quien aprueba en este espacio puede aprobar cambios';
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

  perform log_audit_event(
    v_hospital_id,
    'document_version_approved',
    'group_document_version',
    p_version_id,
    v_workspace_id,
    jsonb_build_object('document_id', v_document_id, 'title', v_title)
  );
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
  v_workspace_id uuid;
  v_hospital_id uuid;
  v_title text;
begin
  select document_id, title into v_document_id, v_title
  from group_document_versions
  where id = p_version_id and status = 'in_review';

  if v_document_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, hospital_id into v_workspace_id, v_hospital_id
  from group_documents where id = v_document_id;

  if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'Solo quien aprueba en este espacio puede rechazar cambios';
  end if;

  update group_document_versions
  set status = 'draft',
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  perform log_audit_event(
    v_hospital_id,
    'document_version_rejected',
    'group_document_version',
    p_version_id,
    v_workspace_id,
    jsonb_build_object('document_id', v_document_id, 'title', v_title)
  );
end;
$$;

create or replace function transfer_hospital_ownership(new_owner_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hospital_id uuid;
  v_previous_owner_id uuid;
begin
  if not my_is_hospital_owner() then
    raise exception 'Solo la propietaria o el propietario actual puede transferir la propiedad';
  end if;

  if not exists (
    select 1 from profiles where id = new_owner_id and hospital_id = my_hospital_id()
  ) then
    raise exception 'La persona indicada no pertenece a este grupo';
  end if;

  v_hospital_id := my_hospital_id();
  v_previous_owner_id := auth.uid();

  update hospitals set owner_id = new_owner_id where id = v_hospital_id;

  perform log_audit_event(
    v_hospital_id,
    'hospital_ownership_transferred',
    'hospital',
    v_hospital_id,
    null,
    jsonb_build_object('previous_owner_id', v_previous_owner_id, 'new_owner_id', new_owner_id)
  );
end;
$$;

-- 4. Acciones que hoy se hacen directo desde el cliente (RLS pero sin
--    funcion intermedia): se envuelven en una funcion security definer que
--    replica el permiso de la policy existente + el log. El cliente Flutter
--    pasa a usar estas funciones en vez del insert/update/delete directo.

-- 4a. Cambio de rol de un miembro en un espacio (antes: upsert directo a
--     workspace_members, permitido por la policy "workspace_members_insert_admin"
--     / "workspace_members_update_admin").
create or replace function set_workspace_member_role(p_workspace_id uuid, p_user_id uuid, p_role text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hospital_id uuid;
  v_previous_role text;
begin
  if p_role not in ('reader', 'editor', 'approver') then
    raise exception 'Rol no valido';
  end if;

  if not my_is_hospital_admin() then
    raise exception 'Solo un administrador del grupo puede cambiar roles';
  end if;

  select hospital_id into v_hospital_id from workspaces where id = p_workspace_id;
  if v_hospital_id is null or v_hospital_id <> my_hospital_id() then
    raise exception 'No autorizado';
  end if;

  select role into v_previous_role
  from workspace_members
  where workspace_id = p_workspace_id and user_id = p_user_id;

  insert into workspace_members (workspace_id, user_id, role)
  values (p_workspace_id, p_user_id, p_role)
  on conflict (workspace_id, user_id) do update set role = excluded.role;

  perform log_audit_event(
    v_hospital_id,
    'workspace_member_role_changed',
    'workspace_member',
    p_user_id,
    p_workspace_id,
    jsonb_build_object('previous_role', v_previous_role, 'new_role', p_role)
  );
end;
$$;

-- 4b. Quitar el acceso de un miembro a un espacio (antes: delete directo,
--     permitido por "workspace_members_delete_admin"). Tambien es un cambio
--     de rol (a "ninguno"), asi que se registra con la misma accion.
create or replace function remove_workspace_member_role(p_workspace_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hospital_id uuid;
  v_previous_role text;
begin
  if not my_is_hospital_admin() then
    raise exception 'Solo un administrador del grupo puede quitar roles';
  end if;

  select hospital_id into v_hospital_id from workspaces where id = p_workspace_id;
  if v_hospital_id is null or v_hospital_id <> my_hospital_id() then
    raise exception 'No autorizado';
  end if;

  select role into v_previous_role
  from workspace_members
  where workspace_id = p_workspace_id and user_id = p_user_id;

  delete from workspace_members where workspace_id = p_workspace_id and user_id = p_user_id;

  if v_previous_role is not null then
    perform log_audit_event(
      v_hospital_id,
      'workspace_member_role_changed',
      'workspace_member',
      p_user_id,
      p_workspace_id,
      jsonb_build_object('previous_role', v_previous_role, 'new_role', null)
    );
  end if;
end;
$$;

-- 4c. Crear un documento (antes: dos inserts directos desde el cliente,
--     permitidos por "group_documents_insert_role" /
--     "group_document_versions_insert_role"). Devuelve la primera version en
--     borrador (con document_id ya dentro), igual forma que ya esperaba el
--     cliente al hacer los dos inserts por separado.
create or replace function create_group_document(p_kind text, p_workspace_id uuid)
returns group_document_versions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hospital_id uuid;
  v_document_id uuid;
  v_version group_document_versions;
begin
  if p_kind not in ('technique', 'protocol') then
    raise exception 'Tipo de documento no valido';
  end if;

  if my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para crear documentos en este espacio';
  end if;

  select hospital_id into v_hospital_id from workspaces where id = p_workspace_id;
  if v_hospital_id is null then
    raise exception 'Espacio no encontrado';
  end if;

  insert into group_documents (hospital_id, workspace_id, kind, created_by)
  values (v_hospital_id, p_workspace_id, p_kind, auth.uid())
  returning id into v_document_id;

  insert into group_document_versions (document_id, version_number, status, title, author_id)
  values (v_document_id, 1, 'draft', '', auth.uid())
  returning * into v_version;

  perform log_audit_event(
    v_hospital_id,
    'document_created',
    'group_document',
    v_document_id,
    p_workspace_id,
    jsonb_build_object('kind', p_kind)
  );

  return v_version;
end;
$$;

-- 4d. Borrar un documento (antes: delete directo, permitido por
--     "group_documents_delete_role").
create or replace function delete_group_document(p_document_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_hospital_id uuid;
  v_workspace_id uuid;
  v_title text;
begin
  select hospital_id, workspace_id into v_hospital_id, v_workspace_id
  from group_documents where id = p_document_id;

  if v_hospital_id is null then
    raise exception 'Documento no encontrado';
  end if;

  if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'No autorizado para eliminar documentos en este espacio';
  end if;

  select title into v_title
  from group_document_versions
  where document_id = p_document_id
  order by version_number desc
  limit 1;

  delete from group_documents where id = p_document_id;

  perform log_audit_event(
    v_hospital_id,
    'document_deleted',
    'group_document',
    p_document_id,
    v_workspace_id,
    jsonb_build_object('title', v_title)
  );
end;
$$;
