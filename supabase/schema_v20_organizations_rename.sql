-- Fase C (continuacion): renombrar "hospital" a "organizacion" en todo el
-- esquema. El vocabulario de la app ya no encaja: no todos los grupos que
-- usan Instriq son hospitales (universidades, centros de simulacion,
-- fabricantes formando a su propia gente, equipos privados...). Este script
-- renombra la tabla y toda columna hospital_id existente a organization_id,
-- y anade el tipo de organizacion. Ejecutar DESPUES de
-- schema_v19_core_domain_model.sql (surgeons/taggings/reference_documents se
-- crean alli con columna hospital_id; este script las alcanza tambien).
--
-- Lista de tablas con columna hospital_id, confirmada con
-- grep -r "hospital_id uuid" supabase/schema_v*.sql (12 tablas, sin contar la
-- propia tabla "hospitals" que se renombra aparte):
--   profiles, preference_cards, group_documents, workspaces, audit_log,
--   custom_instruments, instrument_sterilization_methods,
--   instrument_technical_info, trays, surgeons, taggings, reference_documents
--
-- Postgres preserva FKs, indices y RLS automaticamente en un rename de
-- columna/tabla (las policies guardan la expresion ya parseada, por
-- attnum/oid, no como texto con el nombre de la columna) -- pero aun asi,
-- comprobar a mano tras aplicar:
--   select policyname, qual, with_check from pg_policies where tablename = 'organizations';
-- (y de paso en el resto de tablas de la lista de arriba) para confirmar que
-- ninguna policy quedo con una referencia rota.

alter table hospitals rename to organizations;

alter table profiles rename column hospital_id to organization_id;
alter table preference_cards rename column hospital_id to organization_id;
alter table group_documents rename column hospital_id to organization_id;
alter table workspaces rename column hospital_id to organization_id;
alter table audit_log rename column hospital_id to organization_id;
alter table custom_instruments rename column hospital_id to organization_id;
alter table instrument_sterilization_methods rename column hospital_id to organization_id;
alter table instrument_technical_info rename column hospital_id to organization_id;
alter table trays rename column hospital_id to organization_id;
alter table surgeons rename column hospital_id to organization_id;
alter table taggings rename column hospital_id to organization_id;
alter table reference_documents rename column hospital_id to organization_id;

-- Tipo de organizacion. Default 'hospital' para no romper ninguna fila
-- existente (todas las organizaciones de hoy son, de hecho, hospitales).
alter table organizations
  add column if not exists org_type text not null default 'hospital'
  check (org_type in ('hospital', 'clinica', 'universidad', 'centro_simulacion', 'fabricante', 'equipo_privado'));

-- AVISO IMPORTANTE, fuera del alcance literal de este script pero critico
-- antes de dar esto por terminado: a diferencia de las RLS policies (que
-- Postgres actualiza solas, ver nota de arriba), el CUERPO de las funciones
-- SQL/plpgsql se guarda como texto (prosrc) y NO se reescribe con el rename.
-- Toda funcion de abajo tiene "hospital_id" escrito literalmente como nombre
-- de columna/tabla en su cuerpo (no como variable local v_hospital_id/
-- p_hospital_id, esas no dependen del nombre real de la columna) y se
-- ROMPERA en tiempo de ejecucion tras este script, hasta que se recreen
-- (create or replace function) con "organization_id"/"organizations":
--   my_hospital_id, my_is_hospital_owner, transfer_hospital_ownership,
--   check_workspace_matches_hospital, my_workspace_role, log_audit_event,
--   set_workspace_member_role, remove_workspace_member_role,
--   create_group_document, delete_group_document,
--   approve_group_document_version, reject_group_document_version,
--   submit_group_document_version_for_review, create_tray,
--   submit_tray_version_for_review, approve_tray_version,
--   reject_tray_version, restore_tray_version, delete_my_account,
--   export_my_account_data, hospital_content_stats, review_community_photo
-- (my_is_hospital_admin no esta en la lista: solo lee profiles.is_admin, no
-- referencia hospital_id, no se ve afectada). Practicamente toda policy de
-- RLS de la app depende de my_hospital_id()/my_workspace_role(), asi que la
-- app quedaria rota de punta a punta hasta recrear estas funciones -- se
-- deja fuera de este archivo porque no estaba en el encargo de esta ronda,
-- pero debe ser la primera cosa a resolver (siguiente migracion, p.ej.
-- schema_v21) antes de considerar esto desplegable.

-- =============================================================================
-- Recreacion de las funciones de arriba (cuerpo corregido: "organization_id"/
-- "organizations" en vez de "hospital_id"/"hospitals"). Van en este mismo
-- archivo porque son la contraparte obligatoria del rename de arriba, no una
-- ronda nueva: sin esto, este script deja el esquema en un estado a medias
-- (tabla y columnas renombradas, funciones que las usan todavia rotas).
--
-- DECISION DE DISEÑO IMPORTANTE: se mantiene el NOMBRE de cada funcion (y el
-- de cada parametro) EXACTAMENTE IGUAL. Solo se corrige el CUERPO. Motivo:
--   1. "create or replace function" conserva el OID de la funcion cuando el
--      nombre y la firma (tipos de los parametros) no cambian. Todo lo que ya
--      la invoca por ese OID -- policies de RLS creadas en schema_v3/v6/v7/
--      v9/v10/v11/v13/v14/v15/v16, y otras funciones de este mismo grupo --
--      sigue funcionando sin tocar ni una linea mas en ningun otro archivo.
--   2. Si en cambio se creara una funcion NUEVA con nombre distinto (p.ej.
--      my_organization_id en vez de my_hospital_id), la funcion VIEJA se
--      quedaria huerfana con su cuerpo roto (sigue mencionando hospital_id/
--      hospitals, que ya no existen) y CUALQUIER policy o funcion creada en
--      un archivo anterior que la invoque por su nombre de siempre seguiria
--      llamando a esa version vieja y rota -- rebautizar de verdad exigiria
--      "alter function ... rename to ..." + tocar cada CREATE POLICY antigua,
--      muy por encima del encargo de esta ronda.
--   3. grep -rn ".rpc(" lib/ confirma que transfer_hospital_ownership y
--      hospital_content_stats (con su parametro p_hospital_id, ver
--      lib/services/analytics_service.dart) se llaman por nombre literal
--      desde Flutter (supabase_flutter arma el POST a /rpc/<nombre> con las
--      claves del "params" igual al nombre de cada parametro SQL). Renombrar
--      cualquiera de los dos rompe la app sin cambios coordinados en Dart.
--      Por consistencia se aplica el mismo criterio a las 22 funciones: cero
--      cambios de firma, todo el rename vive dentro del cuerpo (columnas,
--      tablas, variables locales, comentarios).
--
-- Con esto, funciones como my_hospital_id(), transfer_hospital_ownership() o
-- hospital_content_stats() SIGUEN llamandose asi a proposito (deuda tecnica
-- de nomenclatura conocida y aceptada); lo unico que se arregla aqui es que
-- vuelvan a leer/escribir las columnas y la tabla con su nombre real.

create or replace function my_hospital_id()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select organization_id from profiles where id = auth.uid()
$$;

create or replace function my_is_hospital_owner()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(
    (select owner_id = auth.uid() from organizations where id = my_hospital_id()),
    false
  )
$$;

create or replace function transfer_hospital_ownership(new_owner_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_previous_owner_id uuid;
begin
  if not my_is_hospital_owner() then
    raise exception 'Solo la propietaria o el propietario actual puede transferir la propiedad';
  end if;

  if not exists (
    select 1 from profiles where id = new_owner_id and organization_id = my_hospital_id()
  ) then
    raise exception 'La persona indicada no pertenece a este grupo';
  end if;

  v_organization_id := my_hospital_id();
  v_previous_owner_id := auth.uid();

  update organizations set owner_id = new_owner_id where id = v_organization_id;

  -- 'hospital_ownership_transferred'/'hospital' son valores de datos (accion
  -- y entity_type del log de auditoria), no identificadores de esquema: se
  -- dejan tal cual para no alterar la taxonomia ya usada por filas existentes
  -- de audit_log ni por el mapeo de la Edge Function send-push.
  perform log_audit_event(
    v_organization_id,
    'hospital_ownership_transferred',
    'hospital',
    v_organization_id,
    null,
    jsonb_build_object('previous_owner_id', v_previous_owner_id, 'new_owner_id', new_owner_id)
  );
end;
$$;

-- Trigger de integridad: workspace_id debe pertenecer a la misma organizacion
-- que la fila (group_documents, preference_cards, trays).
create or replace function check_workspace_matches_hospital()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not exists (
    select 1 from workspaces
    where id = new.workspace_id and organization_id = new.organization_id
  ) then
    raise exception 'El espacio no pertenece al mismo grupo que el contenido';
  end if;
  return new;
end;
$$;

create or replace function my_workspace_role(p_workspace_id uuid)
returns text
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_role text;
begin
  select organization_id into v_organization_id from workspaces where id = p_workspace_id;
  if v_organization_id is null or v_organization_id <> my_hospital_id() then
    return null;
  end if;
  if my_is_hospital_admin() then
    return 'administrator';
  end if;
  select role into v_role from workspace_members
    where workspace_id = p_workspace_id and user_id = auth.uid();
  return v_role;
end;
$$;

-- log_audit_event: aqui SI se renombra el parametro (p_hospital_id ->
-- p_organization_id) porque nadie lo llama por nombre desde fuera de SQL
-- (grep ".rpc(" en lib/ y supabase/functions/ no encuentra ninguna llamada a
-- "log_audit_event"; todas las invocaciones son "perform log_audit_event(...)"
-- posicionales dentro de otras funciones de este mismo archivo). Postgres no
-- permite "create or replace" cuando cambia el nombre de un parametro -- hay
-- que borrarla primero. Las funciones que ya se recrearon arriba y la llaman
-- de forma posicional (transfer_hospital_ownership) no se ven afectadas por
-- este drop+create intermedio: PL/pgSQL no resuelve llamadas a otras
-- funciones hasta el momento de ejecutarse, no al crearse.
drop function if exists log_audit_event(uuid, text, text, uuid, uuid, jsonb);
create or replace function log_audit_event(
  p_organization_id uuid,
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
  insert into audit_log (organization_id, actor_id, action, entity_type, entity_id, workspace_id, metadata)
  values (p_organization_id, auth.uid(), p_action, p_entity_type, p_entity_id, p_workspace_id, coalesce(p_metadata, '{}'::jsonb));
end;
$$;

create or replace function set_workspace_member_role(p_workspace_id uuid, p_user_id uuid, p_role text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_previous_role text;
begin
  if p_role not in ('reader', 'editor', 'approver') then
    raise exception 'Rol no valido';
  end if;

  if not my_is_hospital_admin() then
    raise exception 'Solo un administrador del grupo puede cambiar roles';
  end if;

  select organization_id into v_organization_id from workspaces where id = p_workspace_id;
  if v_organization_id is null or v_organization_id <> my_hospital_id() then
    raise exception 'No autorizado';
  end if;

  select role into v_previous_role
  from workspace_members
  where workspace_id = p_workspace_id and user_id = p_user_id;

  insert into workspace_members (workspace_id, user_id, role)
  values (p_workspace_id, p_user_id, p_role)
  on conflict (workspace_id, user_id) do update set role = excluded.role;

  perform log_audit_event(
    v_organization_id,
    'workspace_member_role_changed',
    'workspace_member',
    p_user_id,
    p_workspace_id,
    jsonb_build_object('previous_role', v_previous_role, 'new_role', p_role)
  );
end;
$$;

create or replace function remove_workspace_member_role(p_workspace_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_previous_role text;
begin
  if not my_is_hospital_admin() then
    raise exception 'Solo un administrador del grupo puede quitar roles';
  end if;

  select organization_id into v_organization_id from workspaces where id = p_workspace_id;
  if v_organization_id is null or v_organization_id <> my_hospital_id() then
    raise exception 'No autorizado';
  end if;

  select role into v_previous_role
  from workspace_members
  where workspace_id = p_workspace_id and user_id = p_user_id;

  delete from workspace_members where workspace_id = p_workspace_id and user_id = p_user_id;

  if v_previous_role is not null then
    perform log_audit_event(
      v_organization_id,
      'workspace_member_role_changed',
      'workspace_member',
      p_user_id,
      p_workspace_id,
      jsonb_build_object('previous_role', v_previous_role, 'new_role', null)
    );
  end if;
end;
$$;

create or replace function create_group_document(p_kind text, p_workspace_id uuid)
returns group_document_versions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_document_id uuid;
  v_version group_document_versions;
begin
  if p_kind not in ('technique', 'protocol') then
    raise exception 'Tipo de documento no valido';
  end if;

  if my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para crear documentos en este espacio';
  end if;

  select organization_id into v_organization_id from workspaces where id = p_workspace_id;
  if v_organization_id is null then
    raise exception 'Espacio no encontrado';
  end if;

  insert into group_documents (organization_id, workspace_id, kind, created_by)
  values (v_organization_id, p_workspace_id, p_kind, auth.uid())
  returning id into v_document_id;

  insert into group_document_versions (document_id, version_number, status, title, author_id)
  values (v_document_id, 1, 'draft', '', auth.uid())
  returning * into v_version;

  perform log_audit_event(
    v_organization_id,
    'document_created',
    'group_document',
    v_document_id,
    p_workspace_id,
    jsonb_build_object('kind', p_kind)
  );

  return v_version;
end;
$$;

create or replace function delete_group_document(p_document_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_workspace_id uuid;
  v_title text;
begin
  select organization_id, workspace_id into v_organization_id, v_workspace_id
  from group_documents where id = p_document_id;

  if v_organization_id is null then
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
    v_organization_id,
    'document_deleted',
    'group_document',
    p_document_id,
    v_workspace_id,
    jsonb_build_object('title', v_title)
  );
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
  v_workspace_id uuid;
  v_organization_id uuid;
  v_title text;
begin
  select document_id, title into v_document_id, v_title
  from group_document_versions
  where id = p_version_id and status = 'in_review';

  if v_document_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id
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
    v_organization_id,
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
  v_organization_id uuid;
  v_title text;
begin
  select document_id, title into v_document_id, v_title
  from group_document_versions
  where id = p_version_id and status = 'in_review';

  if v_document_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id
  from group_documents where id = v_document_id;

  if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'Solo quien aprueba en este espacio puede rechazar cambios';
  end if;

  update group_document_versions
  set status = 'draft',
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  perform log_audit_event(
    v_organization_id,
    'document_version_rejected',
    'group_document_version',
    p_version_id,
    v_workspace_id,
    jsonb_build_object('document_id', v_document_id, 'title', v_title)
  );
end;
$$;

create or replace function submit_group_document_version_for_review(p_version_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_document_id uuid;
  v_workspace_id uuid;
  v_organization_id uuid;
  v_title text;
begin
  update group_document_versions
  set status = 'in_review'
  where id = p_version_id
    and status = 'draft'
    and author_id = auth.uid();

  if not found then
    raise exception 'No autorizado o version no valida para enviar a revision';
  end if;

  select document_id, title into v_document_id, v_title
  from group_document_versions
  where id = p_version_id;

  select workspace_id, organization_id into v_workspace_id, v_organization_id
  from group_documents where id = v_document_id;

  perform log_audit_event(
    v_organization_id,
    'document_version_submitted',
    'group_document_version',
    p_version_id,
    v_workspace_id,
    jsonb_build_object('document_id', v_document_id, 'title', v_title)
  );
end;
$$;

create or replace function create_tray(p_workspace_id uuid)
returns tray_versions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_tray_id uuid;
  v_version tray_versions;
begin
  if my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para crear bandejas en este espacio';
  end if;

  select organization_id into v_organization_id from workspaces where id = p_workspace_id;
  if v_organization_id is null then
    raise exception 'Espacio no encontrado';
  end if;

  insert into trays (organization_id, workspace_id, created_by)
  values (v_organization_id, p_workspace_id, auth.uid())
  returning id into v_tray_id;

  insert into tray_versions (tray_id, version_number, status, name, author_id)
  values (v_tray_id, 1, 'draft', '', auth.uid())
  returning * into v_version;

  perform log_audit_event(
    v_organization_id,
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
  v_organization_id uuid;
begin
  select tray_id into v_tray_id
  from tray_versions
  where id = p_version_id and status = 'draft' and author_id = auth.uid();

  if v_tray_id is null then
    raise exception 'No autorizado o version no valida para enviar a revision';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id from trays where id = v_tray_id;

  update tray_versions
  set status = 'in_review'
  where id = p_version_id;

  perform log_audit_event(
    v_organization_id,
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
  v_organization_id uuid;
begin
  select tray_id into v_tray_id
  from tray_versions
  where id = p_version_id and status = 'in_review';

  if v_tray_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id from trays where id = v_tray_id;

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
    v_organization_id,
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
  v_organization_id uuid;
begin
  select tray_id into v_tray_id
  from tray_versions
  where id = p_version_id and status = 'in_review';

  if v_tray_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id from trays where id = v_tray_id;

  if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'Solo quien aprueba en este espacio puede rechazar cambios';
  end if;

  update tray_versions
  set status = 'draft',
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  perform log_audit_event(
    v_organization_id,
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
  v_organization_id uuid;
  v_next_version int;
  v_new_id uuid;
begin
  select tray_id into v_tray_id
  from tray_versions
  where id = p_version_id;

  if v_tray_id is null then
    raise exception 'Version no encontrada';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id from trays where id = v_tray_id;

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
    v_organization_id,
    'tray_version_submitted',
    'tray_version',
    v_new_id,
    v_workspace_id,
    jsonb_build_object('tray_id', v_tray_id, 'restored_from', p_version_id)
  );

  return v_new_id;
end;
$$;

create or replace function delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owned_organization_id uuid;
  v_has_other_members boolean;
begin
  select id into v_owned_organization_id from organizations where owner_id = auth.uid();

  if v_owned_organization_id is not null then
    select exists (
      select 1 from profiles
      where organization_id = v_owned_organization_id and id <> auth.uid()
    ) into v_has_other_members;

    if v_has_other_members then
      raise exception 'Eres propietaria/o de un grupo con más miembros. Transfiere la propiedad antes de eliminar tu cuenta.';
    end if;

    -- Propietaria/o sin nadie mas en el grupo: se borra tambien el grupo
    -- (la cascada existente se lleva espacios, roles, tecnicas/protocolos,
    -- versiones y tarjetas de ese grupo).
    delete from organizations where id = v_owned_organization_id;
  end if;

  delete from auth.users where id = auth.uid();
end;
$$;

create or replace function export_my_account_data()
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result json;
begin
  select json_build_object(
    'profile', (
      select json_build_object(
        'display_name', p.display_name,
        -- Clave renombrada de 'hospital_name' a 'organization_name': es un
        -- JSON devuelto tal cual al cliente (AccountPrivacyScreen lo vuelca
        -- con JsonEncoder sin leer claves concretas, ver
        -- lib/screens/account_privacy_screen.dart), no hay ningun .rpc/parse
        -- en Dart que dependa del nombre exacto de esta clave.
        'organization_name', o.name,
        'is_admin', p.is_admin,
        'is_owner', o.owner_id = p.id,
        'created_at', p.created_at
      )
      from profiles p
      left join organizations o on o.id = p.organization_id
      where p.id = auth.uid()
    ),
    'workspace_roles', (
      select coalesce(json_agg(json_build_object(
        'workspace', w.name,
        'role', wm.role
      )), '[]'::json)
      from workspace_members wm
      join workspaces w on w.id = wm.workspace_id
      where wm.user_id = auth.uid()
    ),
    'documents_authored', (
      select coalesce(json_agg(json_build_object(
        'kind', gd.kind,
        'workspace', w.name,
        'title', gdv.title,
        'status', gdv.status,
        'version_number', gdv.version_number,
        'created_at', gdv.created_at
      )), '[]'::json)
      from group_document_versions gdv
      join group_documents gd on gd.id = gdv.document_id
      join workspaces w on w.id = gd.workspace_id
      where gdv.author_id = auth.uid()
    ),
    'documents_approved', (
      select coalesce(json_agg(json_build_object(
        'kind', gd.kind,
        'workspace', w.name,
        'title', gdv.title,
        'version_number', gdv.version_number,
        'approved_at', gdv.approved_at
      )), '[]'::json)
      from group_document_versions gdv
      join group_documents gd on gd.id = gdv.document_id
      join workspaces w on w.id = gd.workspace_id
      where gdv.approved_by = auth.uid()
    ),
    'preference_cards_created', (
      -- surgeon_name era texto libre en preference_cards; schema_v19 lo migro
      -- a surgeon_id (FK a surgeons) y borro la columna vieja, asi que aqui
      -- se resuelve el nombre via left join en vez de leer la columna
      -- original (left join por si algun surgeon_id quedo null tras el
      -- backfill conservador de schema_v19).
      select coalesce(json_agg(json_build_object(
        'workspace', w.name,
        'surgeon_name', s.name,
        'procedure_name', pc.procedure_name,
        'created_at', pc.created_at
      )), '[]'::json)
      from preference_cards pc
      join workspaces w on w.id = pc.workspace_id
      left join surgeons s on s.id = pc.surgeon_id
      where pc.created_by = auth.uid()
    )
  ) into v_result;

  return v_result;
end;
$$;

-- hospital_content_stats: nombre de funcion Y de parametro (p_hospital_id) se
-- mantienen sin cambios a proposito -- lib/services/analytics_service.dart
-- llama ".rpc('hospital_content_stats', params: {'p_hospital_id': hospitalId})"
-- por nombre literal en ambos casos. Solo se corrige el cuerpo: toda columna
-- "hospital_id" leida de profiles/workspaces/preference_cards/group_documents
-- pasa a ser "organization_id" (comparada contra el mismo p_hospital_id de
-- siempre, que ahora representa un organization_id aunque conserve ese
-- nombre de parametro).
create or replace function hospital_content_stats(p_hospital_id uuid)
returns json
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_result json;
begin
  -- Solo un miembro de la propia organizacion puede pedir sus estadisticas.
  if p_hospital_id is null or p_hospital_id <> my_hospital_id() then
    raise exception 'No autorizado';
  end if;

  select json_build_object(
    -- Cobertura de contenido por especialidad. La especialidad es el campo
    -- de texto libre historico en group_document_versions.specialty (la
    -- lista cerrada real vive en la tabla `specialties`, 1:1 con el enum
    -- Specialty de lib/models/instrument.dart, ver schema_v19). Se
    -- agrupa por el valor tal cual esta guardado (incluye null como "Sin
    -- especialidad" para no perder documentos antiguos sin clasificar).
    'by_specialty', (
      select coalesce(json_agg(row_to_json(t) order by t.published_count desc, t.specialty), '[]'::json)
      from (
        select
          coalesce(specialty_key, 'Sin especialidad') as specialty,
          count(*) filter (where kind_flag = 'published') as published_count,
          count(*) filter (where kind_flag = 'draft_review') as draft_review_count
        from (
          -- Una fila por documento publicado (version aprobada vigente).
          select gd.id as doc_id, gdv.specialty as specialty_key, 'published' as kind_flag
          from group_documents gd
          join group_document_versions gdv on gdv.id = gd.published_version_id
          where gd.organization_id = p_hospital_id

          union all

          -- Una fila por documento con contenido pendiente (borrador o en
          -- revision). Se toma la version pendiente mas reciente de cada
          -- documento para no contar el mismo documento varias veces.
          select doc_id, specialty_key, 'draft_review' as kind_flag
          from (
            select distinct on (gd.id) gd.id as doc_id, gdv.specialty as specialty_key
            from group_documents gd
            join group_document_versions gdv on gdv.document_id = gd.id
            where gd.organization_id = p_hospital_id
              and gdv.status in ('draft', 'in_review')
            order by gd.id, gdv.version_number desc
          ) latest_pending
        ) x
        group by specialty_key
      ) t
    ),
    'totals', json_build_object(
      'workspaces_count', (
        select count(*) from workspaces where organization_id = p_hospital_id
      ),
      'preference_cards_count', (
        select count(*) from preference_cards where organization_id = p_hospital_id
      ),
      'members_by_role', json_build_object(
        -- El rol "administrator" es a nivel de organizacion (profiles.is_admin),
        -- no por espacio: coincide con el criterio de my_workspace_role().
        'administrator', (
          select count(*) from profiles
          where organization_id = p_hospital_id and is_admin = true
        ),
        'reader', (
          select count(distinct wm.user_id)
          from workspace_members wm
          join workspaces w on w.id = wm.workspace_id
          where w.organization_id = p_hospital_id and wm.role = 'reader'
        ),
        'editor', (
          select count(distinct wm.user_id)
          from workspace_members wm
          join workspaces w on w.id = wm.workspace_id
          where w.organization_id = p_hospital_id and wm.role = 'editor'
        ),
        'approver', (
          select count(distinct wm.user_id)
          from workspace_members wm
          join workspaces w on w.id = wm.workspace_id
          where w.organization_id = p_hospital_id and wm.role = 'approver'
        )
      )
    )
  ) into v_result;

  return v_result;
end;
$$;

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

    -- log_audit_event ya no exige "hospital_id": el nombre de columna real es
    -- ahora "organization_id" (nullable, moderacion global de catalogo sin
    -- organizacion concreta) -- se sigue insertando directo en audit_log en
    -- vez de llamar a log_audit_event, igual que en la version anterior.
    insert into audit_log (organization_id, actor_id, action, entity_type, entity_id, workspace_id, metadata)
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

    insert into audit_log (organization_id, actor_id, action, entity_type, entity_id, workspace_id, metadata)
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

-- =============================================================================
-- Funcion huerfana encontrada fuera de la lista de 22 al recorrer
-- supabase/schema_v*.sql en busca de referencias a "hospital_id":
--
--   my_group_document_version_hospital(check_document_id uuid)
--   (definida en schema_v5_group_document_versions.sql: "select hospital_id
--   from group_documents where id = check_document_id")
--
-- Esta huerfana: existe como funcion en la base de datos, pero ninguna
-- funcion NI policy vigente la llama ya -- schema_v5 la usaba desde
-- approve_group_document_version/reject_group_document_version/
-- restore_group_document_version, pero schema_v7 y schema_v10 reemplazaron
-- esas tres (mismo nombre, "create or replace") con cuerpos que usan
-- my_workspace_role() en su lugar y ya no la invocan. Decision: se elimina
-- (nadie la llama, confirmado por grep; dejarla viva y rota es peor que no
-- tenerla) en vez de recrearla con "organization_id" sin ningun uso real.
drop function if exists my_group_document_version_hospital(uuid);
