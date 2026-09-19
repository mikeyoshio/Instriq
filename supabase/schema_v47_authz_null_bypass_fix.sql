-- Corrige un fallo de autorizacion critico y en produccion, encontrado en
-- una auditoria de seguridad completa (ver docs/SECURITY_AUDIT_2026-09.md,
-- hallazgos C-1/C-2/M-1). Resumen:
--
-- C-1: casi toda funcion `security definer` que crea/aprueba/rechaza/
-- restaura/duplica contenido de un espacio de trabajo usa un guard con la
-- forma `if my_workspace_role(p_workspace_id) not in (lista) then raise
-- exception`. `my_workspace_role()` devuelve SQL NULL (no lanza excepcion)
-- cuando quien llama no tiene ninguna relacion con ese espacio -- exactamente
-- el caso que el guard deberia bloquear con mas fuerza. `NULL not in (...)`
-- se evalua a NULL, y en PL/pgSQL un IF cuya condicion es NULL se trata igual
-- que `false`: la excepcion nunca salta y la escritura sigue adelante. Esto
-- existe desde schema_v7_roles.sql y se ha copiado literalmente en cada
-- entidad versionada desde entonces -- no es una regresion reciente, es un
-- defecto de origen que ninguna ronda de hardening previa detecto porque
-- todas se centraron en quien puede llamar a la funcion (grants), nunca en
-- la logica interna de autorizacion. El fix es sustituir cada guard por su
-- forma NULL-safe: `if my_workspace_role(x) is null or my_workspace_role(x)
-- not in (lista) then` -- mismo mensaje de error, mismo comportamiento en
-- todos los demas casos, cierra el unico camino que antes se colaba.
--
-- C-2: 12 de esas mismas funciones (schema_v39/v40/v42), mas 3 de invitacion
-- (schema_v41) y 2 de solo lectura (schema_v13/v15/v44), nunca revocaron el
-- EXECUTE a `anon` -- mismo gotcha ya corregido puntualmente en
-- schema_v45_catalog_content_reports.sql: `revoke all ... from public` NO
-- quita el EXECUTE que Supabase concede de forma directa a `anon` al crear
-- la funcion, al margen del pseudo-rol PUBLIC. Solo un `revoke ... from
-- anon` explicito lo cierra de verdad. Confirmado en produccion (consulta a
-- information_schema.role_routine_grants) que las 17 funciones de abajo
-- tenian hoy EXECUTE concedido a anon.
--
-- M-1: `create_sterilization_method`/`create_technical_info` (schema_v32)
-- aceptan un `p_organization_id` enteramente controlado por el cliente sin
-- comprobar que coincida con la organizacion real de `p_workspace_id` --
-- combinado con C-1, permitia insertar contenido con apariencia perfectamente
-- consistente en el catalogo de otra organizacion. Se anade la comprobacion
-- que le faltaba, igual que ya hacen el resto de funciones de creacion de
-- contenido de este mismo archivo.
--
-- Cada `create or replace function` de abajo es una copia literal de la
-- definicion vigente en su archivo de origen, con unicamente el guard (y,
-- en los dos casos de M-1, la comprobacion de organizacion) modificados --
-- ningun otro comportamiento cambia.

-- ============================================================
-- Documentos de grupo (tecnicas/protocolos) -- fuente: schema_v20, v38, v24
-- ============================================================

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

  if my_workspace_role(p_workspace_id) is null or my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
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

  if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
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

  if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
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

create or replace function approve_group_document_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_document_id uuid;
  v_workspace_id uuid;
  v_organization_id uuid;
  v_title text;
  v_related_instrument_ids jsonb;
  v_related_tray_ids jsonb;
  v_related_suture_ids jsonb;
begin
  select document_id, title, related_instrument_ids, related_tray_ids, related_suture_ids
    into v_document_id, v_title, v_related_instrument_ids, v_related_tray_ids, v_related_suture_ids
  from group_document_versions
  where id = p_version_id and status = 'in_review';

  if v_document_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id
  from group_documents where id = v_document_id;

  if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
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

  delete from knowledge_links where from_type = 'group_document' and from_id = v_document_id;

  insert into knowledge_links (organization_id, from_type, from_id, to_type, to_id)
  select
    v_organization_id, 'group_document', v_document_id,
    case when exists (select 1 from custom_instruments ci where ci.id::text = elem) then 'custom' else 'catalog' end,
    elem
  from jsonb_array_elements_text(coalesce(v_related_instrument_ids, '[]'::jsonb)) as elem
  on conflict do nothing;

  insert into knowledge_links (organization_id, from_type, from_id, to_type, to_id)
  select v_organization_id, 'group_document', v_document_id, 'tray', elem
  from jsonb_array_elements_text(coalesce(v_related_tray_ids, '[]'::jsonb)) as elem
  on conflict do nothing;

  insert into knowledge_links (organization_id, from_type, from_id, to_type, to_id)
  select v_organization_id, 'group_document', v_document_id, 'suture', elem
  from jsonb_array_elements_text(coalesce(v_related_suture_ids, '[]'::jsonb)) as elem
  on conflict do nothing;

  perform log_audit_event(
    v_organization_id,
    'document_version_approved',
    'group_document_version',
    p_version_id,
    v_workspace_id,
    jsonb_build_object('document_id', v_document_id, 'title', v_title)
  );
end;
$function$;

create or replace function restore_group_document_version(p_version_id uuid)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_document_id uuid;
  v_workspace_id uuid;
  v_next_version int;
  v_new_id uuid;
begin
  select document_id into v_document_id
  from group_document_versions
  where id = p_version_id;

  if v_document_id is null then
    raise exception 'Version no encontrada';
  end if;

  select workspace_id into v_workspace_id from group_documents where id = v_document_id;

  if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado';
  end if;

  select coalesce(max(version_number), 0) + 1 into v_next_version
  from group_document_versions
  where document_id = v_document_id;

  insert into group_document_versions (
    document_id, version_number, status, title, specialty, content,
    steps, related_instrument_ids, related_tray_ids, author_id, comment, based_on_version_id
  )
  select
    v_document_id, v_next_version, 'draft', title, specialty, content,
    steps, related_instrument_ids, related_tray_ids, auth.uid(),
    'Restaurada desde una version anterior', p_version_id
  from group_document_versions
  where id = p_version_id
  returning id into v_new_id;

  return v_new_id;
end;
$function$;

create or replace function duplicate_group_document(p_document_id uuid)
returns group_document_versions
language plpgsql
security definer
set search_path = 'public'
as $function$
declare
  v_source_workspace_id uuid;
  v_source_organization_id uuid;
  v_source_kind text;
  v_source_version group_document_versions;
  v_new_document_id uuid;
  v_new_version group_document_versions;
begin
  select workspace_id, organization_id, kind
    into v_source_workspace_id, v_source_organization_id, v_source_kind
  from group_documents where id = p_document_id;

  if v_source_workspace_id is null then
    raise exception 'Documento no encontrado';
  end if;

  if my_workspace_role(v_source_workspace_id) is null or my_workspace_role(v_source_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para duplicar documentos en este espacio';
  end if;

  select gv.* into v_source_version
  from group_document_versions gv
  join group_documents gd on gd.published_version_id = gv.id
  where gd.id = p_document_id;

  if v_source_version.id is null then
    raise exception 'Este documento todavia no tiene una version publicada que duplicar';
  end if;

  insert into group_documents (organization_id, workspace_id, kind, created_by)
  values (v_source_organization_id, v_source_workspace_id, v_source_kind, auth.uid())
  returning id into v_new_document_id;

  insert into group_document_versions (
    document_id, version_number, status, title, specialty, specialty_id, content, steps,
    related_instrument_ids, related_tray_ids, consumables, patient_positioning, anesthesia_notes,
    related_suture_ids, author_id, comment
  )
  values (
    v_new_document_id, 1, 'draft', v_source_version.title, v_source_version.specialty,
    v_source_version.specialty_id, v_source_version.content, v_source_version.steps,
    v_source_version.related_instrument_ids, v_source_version.related_tray_ids, v_source_version.consumables,
    v_source_version.patient_positioning, v_source_version.anesthesia_notes, v_source_version.related_suture_ids,
    auth.uid(), 'Duplicado desde otro documento del espacio'
  )
  returning * into v_new_version;

  perform log_audit_event(
    v_source_organization_id,
    'document_duplicated',
    'group_document',
    v_new_document_id,
    v_source_workspace_id,
    jsonb_build_object('source_document_id', p_document_id)
  );

  return v_new_version;
end;
$function$;

-- ============================================================
-- Bandejas -- fuente: schema_v20, v24, v25, v40, v42
-- ============================================================

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
  if my_workspace_role(p_workspace_id) is null or my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
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

  if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
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

  if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
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

create or replace function approve_tray_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_tray_id uuid;
  v_workspace_id uuid;
  v_organization_id uuid;
  v_items jsonb;
begin
  select tray_id, items into v_tray_id, v_items
  from tray_versions
  where id = p_version_id and status = 'in_review';

  if v_tray_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id from trays where id = v_tray_id;

  if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
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

  delete from knowledge_links where from_type = 'tray' and from_id = v_tray_id;

  insert into knowledge_links (organization_id, from_type, from_id, to_type, to_id)
  select v_organization_id, 'tray', v_tray_id, item->>'instrument_ref_type', item->>'instrument_ref_id'
  from jsonb_array_elements(coalesce(v_items, '[]'::jsonb)) as item
  on conflict do nothing;

  perform log_audit_event(
    v_organization_id,
    'tray_version_approved',
    'tray_version',
    p_version_id,
    v_workspace_id,
    jsonb_build_object('tray_id', v_tray_id)
  );
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

  if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
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

  if my_workspace_role(v_source_workspace_id) is null or my_workspace_role(v_source_workspace_id) not in ('editor', 'approver', 'administrator') then
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

create or replace function adopt_public_tray(p_public_tray_id uuid, p_workspace_id uuid)
returns tray_versions
language plpgsql
security definer
set search_path = 'public'
as $function$
declare
  v_organization_id uuid;
  v_source_version public_tray_versions;
  v_new_tray_id uuid;
  v_new_version tray_versions;
begin
  if my_workspace_role(p_workspace_id) is null or my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para adoptar contenido público en este espacio';
  end if;

  select organization_id into v_organization_id from workspaces where id = p_workspace_id;
  if v_organization_id is null then
    raise exception 'Espacio no encontrado';
  end if;

  select ptv.* into v_source_version
  from public_tray_versions ptv
  join public_trays pt on pt.published_version_id = ptv.id
  where pt.id = p_public_tray_id;

  if v_source_version.id is null then
    raise exception 'Esta bandeja pública todavía no tiene una versión publicada';
  end if;

  insert into trays (
    organization_id, workspace_id, created_by,
    upstream_public_tray_id, upstream_adopted_version_id, sync_status
  )
  values (
    v_organization_id, p_workspace_id, auth.uid(),
    p_public_tray_id, v_source_version.id, 'synced'
  )
  returning id into v_new_tray_id;

  insert into tray_versions (
    tray_id, version_number, status, name, specialty_id, description, items, observations,
    author_id, comment
  )
  values (
    v_new_tray_id, 1, 'draft', v_source_version.name, v_source_version.specialty_id,
    v_source_version.description, v_source_version.items, v_source_version.observations,
    auth.uid(), 'Adoptada desde la Biblioteca Pública'
  )
  returning * into v_new_version;

  perform log_audit_event(
    v_organization_id,
    'tray_adopted',
    'tray',
    v_new_tray_id,
    p_workspace_id,
    jsonb_build_object('source_public_tray_id', p_public_tray_id)
  );

  return v_new_version;
end;
$function$;

create or replace function stop_following_public_tray(p_tray_id uuid)
returns void
language plpgsql
security definer
set search_path = 'public'
as $function$
declare
  v_organization_id uuid;
  v_workspace_id uuid;
begin
  select organization_id, workspace_id into v_organization_id, v_workspace_id
  from trays where id = p_tray_id;

  if v_organization_id is null or v_organization_id <> my_hospital_id() then
    raise exception 'Bandeja no encontrada en tu organización';
  end if;
  if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado';
  end if;

  update trays set sync_status = 'independent'
  where id = p_tray_id and upstream_public_tray_id is not null and sync_status <> 'independent';

  perform log_audit_event(v_organization_id, 'tray_stopped_following_upstream', 'tray', p_tray_id, v_workspace_id, '{}'::jsonb);
end;
$function$;

create or replace function update_tray_from_upstream(p_tray_id uuid)
returns tray_versions
language plpgsql
security definer
set search_path = 'public'
as $function$
declare
  v_organization_id uuid;
  v_workspace_id uuid;
  v_upstream_id uuid;
  v_sync_status text;
  v_source_version public_tray_versions;
  v_existing_draft tray_versions;
  v_next_version_number int;
  v_result tray_versions;
begin
  select organization_id, workspace_id, upstream_public_tray_id, sync_status
    into v_organization_id, v_workspace_id, v_upstream_id, v_sync_status
  from trays where id = p_tray_id;

  if v_organization_id is null or v_organization_id <> my_hospital_id() then
    raise exception 'Bandeja no encontrada en tu organización';
  end if;
  if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado';
  end if;
  if v_upstream_id is null or v_sync_status <> 'synced' then
    raise exception 'Esta bandeja no sigue ningún origen público sincronizado';
  end if;

  select ptv.* into v_source_version
  from public_tray_versions ptv
  join public_trays pt on pt.published_version_id = ptv.id
  where pt.id = v_upstream_id;

  if v_source_version.id is null then
    raise exception 'El origen público ya no tiene una versión publicada';
  end if;

  select * into v_existing_draft
  from tray_versions
  where tray_id = p_tray_id and author_id = auth.uid() and status = 'draft'
  order by version_number desc
  limit 1;

  if v_existing_draft.id is not null then
    update tray_versions set
      name = v_source_version.name,
      specialty_id = v_source_version.specialty_id,
      description = v_source_version.description,
      items = v_source_version.items,
      observations = v_source_version.observations,
      comment = 'Actualizada desde la Biblioteca Pública'
    where id = v_existing_draft.id
    returning * into v_result;
  else
    select coalesce(max(version_number), 0) + 1 into v_next_version_number from tray_versions where tray_id = p_tray_id;
    insert into tray_versions (
      tray_id, version_number, status, name, specialty_id, description, items, observations,
      author_id, comment
    )
    values (
      p_tray_id, v_next_version_number, 'draft', v_source_version.name, v_source_version.specialty_id,
      v_source_version.description, v_source_version.items, v_source_version.observations,
      auth.uid(), 'Actualizada desde la Biblioteca Pública'
    )
    returning * into v_result;
  end if;

  -- El trigger de arriba ya habrá marcado la bandeja como 'customized' al
  -- cambiar el contenido de la fila -- se deshace aquí a propósito: esto es
  -- re-sincronizar con el origen, no divergir de él.
  update trays set upstream_adopted_version_id = v_source_version.id, sync_status = 'synced'
  where id = p_tray_id;

  perform log_audit_event(v_organization_id, 'tray_updated_from_upstream', 'tray', p_tray_id, v_workspace_id, '{}'::jsonb);

  return v_result;
end;
$function$;

-- ============================================================
-- Tarjetas de preferencia -- fuente: schema_v22, v40
-- ============================================================

create or replace function create_preference_card(p_workspace_id uuid)
returns preference_card_versions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_card_id uuid;
  v_version preference_card_versions;
begin
  if my_workspace_role(p_workspace_id) is null or my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para crear tarjetas de preferencia en este espacio';
  end if;

  select organization_id into v_organization_id from workspaces where id = p_workspace_id;
  if v_organization_id is null then
    raise exception 'Espacio no encontrado';
  end if;

  insert into preference_cards (organization_id, workspace_id, created_by)
  values (v_organization_id, p_workspace_id, auth.uid())
  returning id into v_card_id;

  insert into preference_card_versions (card_id, version_number, status, procedure_name, author_id)
  values (v_card_id, 1, 'draft', '', auth.uid())
  returning * into v_version;

  perform log_audit_event(
    v_organization_id, 'preference_card_created', 'preference_card', v_card_id, p_workspace_id, '{}'::jsonb
  );

  return v_version;
end;
$$;

create or replace function approve_preference_card_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_card_id uuid;
  v_workspace_id uuid;
  v_organization_id uuid;
begin
  select card_id into v_card_id
  from preference_card_versions
  where id = p_version_id and status = 'in_review';

  if v_card_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id from preference_cards where id = v_card_id;

  if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'Solo quien aprueba en este espacio puede aprobar cambios';
  end if;

  update preference_card_versions
  set status = 'archived'
  where card_id = v_card_id and status = 'published';

  update preference_card_versions
  set status = 'published', approved_by = auth.uid(), approved_at = now(),
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  update preference_cards set published_version_id = p_version_id where id = v_card_id;

  perform log_audit_event(
    v_organization_id, 'preference_card_version_approved', 'preference_card_version', p_version_id, v_workspace_id,
    jsonb_build_object('card_id', v_card_id)
  );
end;
$$;

create or replace function reject_preference_card_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_card_id uuid;
  v_workspace_id uuid;
  v_organization_id uuid;
begin
  select card_id into v_card_id
  from preference_card_versions
  where id = p_version_id and status = 'in_review';

  if v_card_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id from preference_cards where id = v_card_id;

  if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'Solo quien aprueba en este espacio puede rechazar cambios';
  end if;

  update preference_card_versions
  set status = 'draft', comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  perform log_audit_event(
    v_organization_id, 'preference_card_version_rejected', 'preference_card_version', p_version_id, v_workspace_id,
    jsonb_build_object('card_id', v_card_id)
  );
end;
$$;

create or replace function restore_preference_card_version(p_version_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_card_id uuid;
  v_workspace_id uuid;
  v_organization_id uuid;
  v_next_version int;
  v_new_id uuid;
begin
  select card_id into v_card_id from preference_card_versions where id = p_version_id;
  if v_card_id is null then
    raise exception 'Version no encontrada';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id from preference_cards where id = v_card_id;

  if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado';
  end if;

  select coalesce(max(version_number), 0) + 1 into v_next_version
  from preference_card_versions where card_id = v_card_id;

  insert into preference_card_versions (
    card_id, version_number, status, surgeon_id, procedure_name, items, general_notes,
    validated_by_surgeon, author_id, comment, based_on_version_id
  )
  select
    v_card_id, v_next_version, 'draft', surgeon_id, procedure_name, items, general_notes,
    validated_by_surgeon, auth.uid(), 'Restaurada desde una version anterior', p_version_id
  from preference_card_versions
  where id = p_version_id
  returning id into v_new_id;

  perform log_audit_event(
    v_organization_id, 'preference_card_version_submitted', 'preference_card_version', v_new_id, v_workspace_id,
    jsonb_build_object('card_id', v_card_id, 'restored_from', p_version_id)
  );

  return v_new_id;
end;
$$;

create or replace function duplicate_preference_card(p_card_id uuid)
returns preference_card_versions
language plpgsql
security definer
set search_path = 'public'
as $function$
declare
  v_source_workspace_id uuid;
  v_source_organization_id uuid;
  v_source_version preference_card_versions;
  v_new_card_id uuid;
  v_new_version preference_card_versions;
begin
  select workspace_id, organization_id into v_source_workspace_id, v_source_organization_id
  from preference_cards where id = p_card_id;

  if v_source_workspace_id is null then
    raise exception 'Tarjeta de preferencia no encontrada';
  end if;

  if my_workspace_role(v_source_workspace_id) is null or my_workspace_role(v_source_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para duplicar tarjetas de preferencia en este espacio';
  end if;

  select pv.* into v_source_version
  from preference_card_versions pv
  join preference_cards pc on pc.published_version_id = pv.id
  where pc.id = p_card_id;

  if v_source_version.id is null then
    raise exception 'Esta tarjeta todavia no tiene una version publicada que duplicar';
  end if;

  insert into preference_cards (organization_id, workspace_id, created_by)
  values (v_source_organization_id, v_source_workspace_id, auth.uid())
  returning id into v_new_card_id;

  insert into preference_card_versions (
    card_id, version_number, status, surgeon_id, procedure_name, items, general_notes,
    validated_by_surgeon, author_id, comment
  )
  values (
    v_new_card_id, 1, 'draft', v_source_version.surgeon_id, v_source_version.procedure_name,
    v_source_version.items, v_source_version.general_notes, false,
    auth.uid(), 'Duplicada desde otra tarjeta del espacio'
  )
  returning * into v_new_version;

  perform log_audit_event(
    v_source_organization_id,
    'preference_card_duplicated',
    'preference_card',
    v_new_card_id,
    v_source_workspace_id,
    jsonb_build_object('source_card_id', p_card_id)
  );

  return v_new_version;
end;
$function$;

-- ============================================================
-- Esterilizacion y ficha tecnica -- fuente: schema_v32
-- (create_sterilization_method y create_technical_info llevan ademas la
-- correccion M-1: comprobar que p_workspace_id pertenece de verdad a
-- p_organization_id antes de insertar)
-- ============================================================

create or replace function create_sterilization_method(
  p_instrument_ref_type text,
  p_instrument_ref_id text,
  p_organization_id uuid default null,
  p_workspace_id uuid default null,
  p_method text default 'vapor'
)
returns instrument_sterilization_method_versions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_method_id uuid;
  v_version instrument_sterilization_method_versions;
begin
  if p_organization_id is null then
    if not my_is_hospital_admin() then
      raise exception 'Només una administradora o administrador d''hospital pot proposar un mètode nou al catàleg global';
    end if;
  else
    if my_workspace_role(p_workspace_id) is null or my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
      raise exception 'No autoritzat per crear mètodes d''esterilització en aquest espai';
    end if;

    if not exists (select 1 from workspaces where id = p_workspace_id and organization_id = p_organization_id) then
      raise exception 'El espacio no pertenece a la organización indicada';
    end if;
  end if;

  insert into instrument_sterilization_methods (instrument_ref_type, instrument_ref_id, organization_id, workspace_id, created_by)
  values (p_instrument_ref_type, p_instrument_ref_id, p_organization_id, p_workspace_id, auth.uid())
  returning id into v_method_id;

  insert into instrument_sterilization_method_versions (method_id, version_number, status, method, author_id)
  values (v_method_id, 1, 'draft', p_method, auth.uid())
  returning * into v_version;

  perform log_audit_event(
    coalesce(p_organization_id, my_hospital_id()), 'sterilization_method_created', 'instrument_sterilization_method',
    v_method_id, p_workspace_id, '{}'::jsonb
  );

  return v_version;
end;
$$;

create or replace function approve_sterilization_method_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_method_id uuid;
  v_organization_id uuid;
  v_workspace_id uuid;
begin
  select method_id into v_method_id
  from instrument_sterilization_method_versions
  where id = p_version_id and status = 'in_review';

  if v_method_id is null then
    raise exception 'Versió no vàlida o no està en revisió';
  end if;

  select organization_id, workspace_id into v_organization_id, v_workspace_id from instrument_sterilization_methods where id = v_method_id;

  if v_organization_id is null then
    if not my_is_reviewer_or_above() then
      raise exception 'Només l''Editorial Board pot aprovar canvis al catàleg global';
    end if;
  else
    if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
      raise exception 'Només qui aprova en aquest espai pot aprovar canvis';
    end if;
  end if;

  update instrument_sterilization_method_versions set status = 'archived' where method_id = v_method_id and status = 'published';

  update instrument_sterilization_method_versions
  set status = 'published', approved_by = auth.uid(), approved_at = now(), comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  update instrument_sterilization_methods set published_version_id = p_version_id where id = v_method_id;

  perform log_audit_event(
    coalesce(v_organization_id, my_hospital_id()), 'sterilization_method_version_approved', 'instrument_sterilization_method_version',
    p_version_id, v_workspace_id, jsonb_build_object('method_id', v_method_id)
  );
end;
$$;

create or replace function reject_sterilization_method_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_method_id uuid;
  v_organization_id uuid;
  v_workspace_id uuid;
begin
  select method_id into v_method_id
  from instrument_sterilization_method_versions
  where id = p_version_id and status = 'in_review';

  if v_method_id is null then
    raise exception 'Versió no vàlida o no està en revisió';
  end if;

  select organization_id, workspace_id into v_organization_id, v_workspace_id from instrument_sterilization_methods where id = v_method_id;

  if v_organization_id is null then
    if not my_is_reviewer_or_above() then
      raise exception 'Només l''Editorial Board pot rebutjar canvis al catàleg global';
    end if;
  else
    if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
      raise exception 'Només qui aprova en aquest espai pot rebutjar canvis';
    end if;
  end if;

  update instrument_sterilization_method_versions
  set status = 'draft', comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  perform log_audit_event(
    coalesce(v_organization_id, my_hospital_id()), 'sterilization_method_version_rejected', 'instrument_sterilization_method_version',
    p_version_id, v_workspace_id, jsonb_build_object('method_id', v_method_id)
  );
end;
$$;

create or replace function restore_sterilization_method_version(p_version_id uuid)
returns instrument_sterilization_method_versions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_method_id uuid;
  v_organization_id uuid;
  v_workspace_id uuid;
  v_next_version int;
  v_source instrument_sterilization_method_versions;
  v_new instrument_sterilization_method_versions;
begin
  select * into v_source from instrument_sterilization_method_versions where id = p_version_id;
  if v_source is null then
    raise exception 'Versió no trobada';
  end if;
  v_method_id := v_source.method_id;

  select organization_id, workspace_id into v_organization_id, v_workspace_id from instrument_sterilization_methods where id = v_method_id;

  if v_organization_id is null then
    if not my_is_hospital_admin() then
      raise exception 'Només una administradora o administrador d''hospital pot restaurar una versió del catàleg global';
    end if;
  else
    if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
      raise exception 'No autoritzat per restaurar versions en aquest espai';
    end if;
  end if;

  select coalesce(max(version_number), 0) + 1 into v_next_version from instrument_sterilization_method_versions where method_id = v_method_id;

  insert into instrument_sterilization_method_versions (
    method_id, version_number, status, method, temperature, time_minutes, pressure, drying,
    recommended_cycle, compatibility_notes, restrictions, observations,
    lubrication_required, lubrication_type, lubrication_notes, author_id, based_on_version_id
  )
  values (
    v_method_id, v_next_version, 'draft', v_source.method, v_source.temperature, v_source.time_minutes, v_source.pressure, v_source.drying,
    v_source.recommended_cycle, v_source.compatibility_notes, v_source.restrictions, v_source.observations,
    v_source.lubrication_required, v_source.lubrication_type, v_source.lubrication_notes, auth.uid(), p_version_id
  )
  returning * into v_new;

  perform log_audit_event(
    coalesce(v_organization_id, my_hospital_id()), 'sterilization_method_version_restored', 'instrument_sterilization_method_version',
    v_new.id, v_workspace_id, jsonb_build_object('method_id', v_method_id, 'based_on_version_id', p_version_id)
  );

  return v_new;
end;
$$;

create or replace function create_technical_info(
  p_instrument_ref_type text,
  p_instrument_ref_id text,
  p_organization_id uuid default null,
  p_workspace_id uuid default null
)
returns instrument_technical_info_versions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_info_id uuid;
  v_version instrument_technical_info_versions;
begin
  if p_organization_id is null then
    if not my_is_hospital_admin() then
      raise exception 'Només una administradora o administrador d''hospital pot proposar fitxa tècnica nova al catàleg global';
    end if;
  else
    if my_workspace_role(p_workspace_id) is null or my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
      raise exception 'No autoritzat per crear fitxes tècniques en aquest espai';
    end if;

    if not exists (select 1 from workspaces where id = p_workspace_id and organization_id = p_organization_id) then
      raise exception 'El espacio no pertenece a la organización indicada';
    end if;
  end if;

  insert into instrument_technical_info (instrument_ref_type, instrument_ref_id, organization_id, workspace_id, created_by)
  values (p_instrument_ref_type, p_instrument_ref_id, p_organization_id, p_workspace_id, auth.uid())
  returning id into v_info_id;

  insert into instrument_technical_info_versions (info_id, version_number, status, author_id)
  values (v_info_id, 1, 'draft', auth.uid())
  returning * into v_version;

  perform log_audit_event(
    coalesce(p_organization_id, my_hospital_id()), 'technical_info_created', 'instrument_technical_info',
    v_info_id, p_workspace_id, '{}'::jsonb
  );

  return v_version;
end;
$$;

create or replace function approve_technical_info_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_info_id uuid;
  v_organization_id uuid;
  v_workspace_id uuid;
begin
  select info_id into v_info_id
  from instrument_technical_info_versions
  where id = p_version_id and status = 'in_review';

  if v_info_id is null then
    raise exception 'Versió no vàlida o no està en revisió';
  end if;

  select organization_id, workspace_id into v_organization_id, v_workspace_id from instrument_technical_info where id = v_info_id;

  if v_organization_id is null then
    if not my_is_reviewer_or_above() then
      raise exception 'Només l''Editorial Board pot aprovar canvis al catàleg global';
    end if;
  else
    if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
      raise exception 'Només qui aprova en aquest espai pot aprovar canvis';
    end if;
  end if;

  update instrument_technical_info_versions set status = 'archived' where info_id = v_info_id and status = 'published';

  update instrument_technical_info_versions
  set status = 'published', approved_by = auth.uid(), approved_at = now(), comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  update instrument_technical_info set published_version_id = p_version_id where id = v_info_id;

  perform log_audit_event(
    coalesce(v_organization_id, my_hospital_id()), 'technical_info_version_approved', 'instrument_technical_info_version',
    p_version_id, v_workspace_id, jsonb_build_object('info_id', v_info_id)
  );
end;
$$;

create or replace function reject_technical_info_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_info_id uuid;
  v_organization_id uuid;
  v_workspace_id uuid;
begin
  select info_id into v_info_id
  from instrument_technical_info_versions
  where id = p_version_id and status = 'in_review';

  if v_info_id is null then
    raise exception 'Versió no vàlida o no està en revisió';
  end if;

  select organization_id, workspace_id into v_organization_id, v_workspace_id from instrument_technical_info where id = v_info_id;

  if v_organization_id is null then
    if not my_is_reviewer_or_above() then
      raise exception 'Només l''Editorial Board pot rebutjar canvis al catàleg global';
    end if;
  else
    if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
      raise exception 'Només qui aprova en aquest espai pot rebutjar canvis';
    end if;
  end if;

  update instrument_technical_info_versions
  set status = 'draft', comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  perform log_audit_event(
    coalesce(v_organization_id, my_hospital_id()), 'technical_info_version_rejected', 'instrument_technical_info_version',
    p_version_id, v_workspace_id, jsonb_build_object('info_id', v_info_id)
  );
end;
$$;

create or replace function restore_technical_info_version(p_version_id uuid)
returns instrument_technical_info_versions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_info_id uuid;
  v_organization_id uuid;
  v_workspace_id uuid;
  v_next_version int;
  v_source instrument_technical_info_versions;
  v_new instrument_technical_info_versions;
begin
  select * into v_source from instrument_technical_info_versions where id = p_version_id;
  if v_source is null then
    raise exception 'Versió no trobada';
  end if;
  v_info_id := v_source.info_id;

  select organization_id, workspace_id into v_organization_id, v_workspace_id from instrument_technical_info where id = v_info_id;

  if v_organization_id is null then
    if not my_is_hospital_admin() then
      raise exception 'Només una administradora o administrador d''hospital pot restaurar una versió del catàleg global';
    end if;
  else
    if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
      raise exception 'No autoritzat per restaurar versions en aquest espai';
    end if;
  end if;

  select coalesce(max(version_number), 0) + 1 into v_next_version from instrument_technical_info_versions where info_id = v_info_id;

  insert into instrument_technical_info_versions (
    info_id, version_number, status, manufacturer_id, ifu_document_id,
    maintenance_notes, inspection_notes, useful_life_notes,
    maintenance_interval_days, last_maintenance_at, author_id, based_on_version_id
  )
  values (
    v_info_id, v_next_version, 'draft', v_source.manufacturer_id, v_source.ifu_document_id,
    v_source.maintenance_notes, v_source.inspection_notes, v_source.useful_life_notes,
    v_source.maintenance_interval_days, v_source.last_maintenance_at, auth.uid(), p_version_id
  )
  returning * into v_new;

  perform log_audit_event(
    coalesce(v_organization_id, my_hospital_id()), 'technical_info_version_restored', 'instrument_technical_info_version',
    v_new.id, v_workspace_id, jsonb_build_object('info_id', v_info_id, 'based_on_version_id', p_version_id)
  );

  return v_new;
end;
$$;

-- ============================================================
-- Instrumental personalizado -- fuente: schema_v39, v40
-- ============================================================

create or replace function create_custom_instrument(p_workspace_id uuid)
returns custom_instrument_versions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_instrument_id uuid;
  v_version custom_instrument_versions;
begin
  if my_workspace_role(p_workspace_id) is null or my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para crear instrumental personalizado en este espacio';
  end if;

  select organization_id into v_organization_id from workspaces where id = p_workspace_id;
  if v_organization_id is null then
    raise exception 'Espacio no encontrado';
  end if;

  insert into custom_instruments (organization_id, workspace_id, created_by)
  values (v_organization_id, p_workspace_id, auth.uid())
  returning id into v_instrument_id;

  insert into custom_instrument_versions (custom_instrument_id, version_number, status, name, author_id)
  values (v_instrument_id, 1, 'draft', '', auth.uid())
  returning * into v_version;

  perform log_audit_event(
    v_organization_id,
    'custom_instrument_created',
    'custom_instrument',
    v_instrument_id,
    p_workspace_id,
    '{}'::jsonb
  );

  return v_version;
end;
$$;

create or replace function approve_custom_instrument_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instrument_id uuid;
  v_workspace_id uuid;
  v_organization_id uuid;
begin
  select custom_instrument_id into v_instrument_id
  from custom_instrument_versions
  where id = p_version_id and status = 'in_review';

  if v_instrument_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id
  from custom_instruments where id = v_instrument_id;

  if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'Solo quien aprueba en este espacio puede aprobar cambios';
  end if;

  update custom_instrument_versions
  set status = 'archived'
  where custom_instrument_id = v_instrument_id and status = 'published';

  update custom_instrument_versions
  set status = 'published',
      approved_by = auth.uid(),
      approved_at = now(),
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  update custom_instruments
  set published_version_id = p_version_id
  where id = v_instrument_id;

  perform log_audit_event(
    v_organization_id,
    'custom_instrument_version_approved',
    'custom_instrument_version',
    p_version_id,
    v_workspace_id,
    jsonb_build_object('custom_instrument_id', v_instrument_id)
  );
end;
$$;

create or replace function reject_custom_instrument_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instrument_id uuid;
  v_workspace_id uuid;
  v_organization_id uuid;
begin
  select custom_instrument_id into v_instrument_id
  from custom_instrument_versions
  where id = p_version_id and status = 'in_review';

  if v_instrument_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id
  from custom_instruments where id = v_instrument_id;

  if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'Solo quien aprueba en este espacio puede rechazar cambios';
  end if;

  update custom_instrument_versions
  set status = 'draft',
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  perform log_audit_event(
    v_organization_id,
    'custom_instrument_version_rejected',
    'custom_instrument_version',
    p_version_id,
    v_workspace_id,
    jsonb_build_object('custom_instrument_id', v_instrument_id)
  );
end;
$$;

create or replace function restore_custom_instrument_version(p_version_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instrument_id uuid;
  v_workspace_id uuid;
  v_organization_id uuid;
  v_next_version int;
  v_new_id uuid;
begin
  select custom_instrument_id into v_instrument_id
  from custom_instrument_versions
  where id = p_version_id;

  if v_instrument_id is null then
    raise exception 'Version no encontrada';
  end if;

  select workspace_id, organization_id into v_workspace_id, v_organization_id
  from custom_instruments where id = v_instrument_id;

  if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado';
  end if;

  select coalesce(max(version_number), 0) + 1 into v_next_version
  from custom_instrument_versions
  where custom_instrument_id = v_instrument_id;

  insert into custom_instrument_versions (
    custom_instrument_id, version_number, status, name, category, specialty, specialty_id,
    description, use_text, tip, variants, author_id, comment, based_on_version_id
  )
  select
    v_instrument_id, v_next_version, 'draft', name, category, specialty, specialty_id,
    description, use_text, tip, variants, auth.uid(),
    'Restaurada desde una version anterior', p_version_id
  from custom_instrument_versions
  where id = p_version_id
  returning id into v_new_id;

  perform log_audit_event(
    v_organization_id,
    'custom_instrument_version_submitted',
    'custom_instrument_version',
    v_new_id,
    v_workspace_id,
    jsonb_build_object('custom_instrument_id', v_instrument_id, 'restored_from', p_version_id)
  );

  return v_new_id;
end;
$$;

create or replace function delete_custom_instrument(p_instrument_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_workspace_id uuid;
  v_name text;
begin
  select organization_id, workspace_id into v_organization_id, v_workspace_id
  from custom_instruments where id = p_instrument_id;

  if v_organization_id is null then
    raise exception 'Instrumento no encontrado';
  end if;

  if my_workspace_role(v_workspace_id) is null or my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'No autorizado para eliminar instrumental personalizado en este espacio';
  end if;

  select name into v_name
  from custom_instrument_versions
  where custom_instrument_id = p_instrument_id
  order by version_number desc
  limit 1;

  delete from custom_instruments where id = p_instrument_id;

  perform log_audit_event(
    v_organization_id,
    'custom_instrument_deleted',
    'custom_instrument',
    p_instrument_id,
    v_workspace_id,
    jsonb_build_object('name', v_name)
  );
end;
$$;

create or replace function duplicate_custom_instrument(p_instrument_id uuid)
returns custom_instrument_versions
language plpgsql
security definer
set search_path = 'public'
as $function$
declare
  v_source_workspace_id uuid;
  v_source_organization_id uuid;
  v_source_version custom_instrument_versions;
  v_new_variants jsonb;
  v_new_instrument_id uuid;
  v_new_version custom_instrument_versions;
begin
  select workspace_id, organization_id into v_source_workspace_id, v_source_organization_id
  from custom_instruments where id = p_instrument_id;

  if v_source_workspace_id is null then
    raise exception 'Instrumento no encontrado';
  end if;

  if my_workspace_role(v_source_workspace_id) is null or my_workspace_role(v_source_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para duplicar instrumental personalizado en este espacio';
  end if;

  select civ.* into v_source_version
  from custom_instrument_versions civ
  join custom_instruments ci on ci.published_version_id = civ.id
  where ci.id = p_instrument_id;

  if v_source_version.id is null then
    raise exception 'Este instrumento todavia no tiene una version publicada que duplicar';
  end if;

  -- Las variantes se copian (nombre/nota), pero nunca la foto: una variante
  -- duplicada es un punto de partida nuevo, no el mismo objeto físico
  -- fotografiado -- mismo criterio que duplicate_tray con photo_paths.
  select coalesce(jsonb_agg(elem || jsonb_build_object('photo_path', null)), '[]'::jsonb)
    into v_new_variants
  from jsonb_array_elements(v_source_version.variants) as elem;

  insert into custom_instruments (organization_id, workspace_id, created_by)
  values (v_source_organization_id, v_source_workspace_id, auth.uid())
  returning id into v_new_instrument_id;

  insert into custom_instrument_versions (
    custom_instrument_id, version_number, status, name, category, specialty_id, description, use_text, tip,
    variants, author_id, comment
  )
  values (
    v_new_instrument_id, 1, 'draft', v_source_version.name, v_source_version.category,
    v_source_version.specialty_id, v_source_version.description, v_source_version.use_text, v_source_version.tip,
    v_new_variants, auth.uid(), 'Duplicado desde otro instrumento del espacio'
  )
  returning * into v_new_version;

  perform log_audit_event(
    v_source_organization_id,
    'custom_instrument_duplicated',
    'custom_instrument',
    v_new_instrument_id,
    v_source_workspace_id,
    jsonb_build_object('source_instrument_id', p_instrument_id)
  );

  return v_new_version;
end;
$function$;

-- ============================================================
-- Cierre de C-2/M-3/L-2: EXECUTE nunca revocado a anon en estas 17
-- funciones. `revoke all ... from public` no basta -- Supabase concede
-- EXECUTE a anon de forma directa al crear la funcion, al margen del
-- pseudo-rol PUBLIC (mismo gotcha ya corregido puntualmente en
-- schema_v45_catalog_content_reports.sql). Confirmado en produccion que
-- las 17 tenian hoy EXECUTE concedido a anon.
-- ============================================================

revoke all on function create_custom_instrument(uuid) from anon;
revoke all on function submit_custom_instrument_version_for_review(uuid) from anon;
revoke all on function approve_custom_instrument_version(uuid, text) from anon;
revoke all on function reject_custom_instrument_version(uuid, text) from anon;
revoke all on function restore_custom_instrument_version(uuid) from anon;
revoke all on function delete_custom_instrument(uuid) from anon;
revoke all on function duplicate_group_document(uuid) from anon;
revoke all on function duplicate_preference_card(uuid) from anon;
revoke all on function duplicate_custom_instrument(uuid) from anon;
revoke all on function adopt_public_tray(uuid, uuid) from anon;
revoke all on function stop_following_public_tray(uuid) from anon;
revoke all on function update_tray_from_upstream(uuid) from anon;
revoke all on function create_invitation(uuid, text, text) from anon;
revoke all on function revoke_invitation(uuid) from anon;
revoke all on function accept_invitation(uuid, text) from anon;
revoke all on function can_access_tray_photo(text, boolean) from anon;
revoke all on function can_access_custom_instrument_photo(text, boolean) from anon;
