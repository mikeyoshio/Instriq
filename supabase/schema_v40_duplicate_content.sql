-- Generaliza "duplicar" (hasta ahora solo bandejas, ver duplicate_tray en
-- schema_v25_tray_preparation.sql) a técnicas/protocolos, tarjetas de
-- preferencia e instrumental personalizado. Mismo patrón exacto que
-- duplicate_tray: crea una cabecera nueva + una versión 1 en borrador con el
-- contenido de la versión PUBLICADA de origen (nunca de un borrador ajeno en
-- curso), registra auditoría, exige rol editor/approver/administrator en el
-- espacio de destino.
--
-- Deliberadamente NO se copian: fotos (instrumental personalizado: cada
-- variante duplicada pierde su photo_path, igual que duplicate_tray ya
-- excluía photo_paths) ni el estado de validación (tarjetas de preferencia:
-- validated_by_surgeon vuelve a false, es una copia nueva sin validar).

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

  if my_workspace_role(v_source_workspace_id) not in ('editor', 'approver', 'administrator') then
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

  if my_workspace_role(v_source_workspace_id) not in ('editor', 'approver', 'administrator') then
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

  if my_workspace_role(v_source_workspace_id) not in ('editor', 'approver', 'administrator') then
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

-- Refuerzo de permisos (mismo criterio que schema_v34_rpc_grants_hardening):
-- revoke a PUBLIC + grant explicito solo a authenticated. Aprovecha para
-- cerrar también las 6 RPC de schema_v39_custom_instrument_versioning.sql,
-- que quedaron sin este refuerzo por error -- hallazgo real de esta sesión,
-- no solo las 3 funciones nuevas de este archivo. El riesgo práctico ya era
-- bajo (las 9 se protegen igualmente por dentro con auth.uid()/rol), pero
-- había que cerrarlo igual, mismo razonamiento que schema_v34.
revoke all on function duplicate_group_document(p_document_id uuid) from public;
grant execute on function duplicate_group_document(p_document_id uuid) to authenticated;
revoke all on function duplicate_preference_card(p_card_id uuid) from public;
grant execute on function duplicate_preference_card(p_card_id uuid) to authenticated;
revoke all on function duplicate_custom_instrument(p_instrument_id uuid) from public;
grant execute on function duplicate_custom_instrument(p_instrument_id uuid) to authenticated;

revoke all on function create_custom_instrument(p_workspace_id uuid) from public;
grant execute on function create_custom_instrument(p_workspace_id uuid) to authenticated;
revoke all on function submit_custom_instrument_version_for_review(p_version_id uuid) from public;
grant execute on function submit_custom_instrument_version_for_review(p_version_id uuid) to authenticated;
revoke all on function approve_custom_instrument_version(p_version_id uuid, p_review_comment text) from public;
grant execute on function approve_custom_instrument_version(p_version_id uuid, p_review_comment text) to authenticated;
revoke all on function reject_custom_instrument_version(p_version_id uuid, p_review_comment text) from public;
grant execute on function reject_custom_instrument_version(p_version_id uuid, p_review_comment text) to authenticated;
revoke all on function restore_custom_instrument_version(p_version_id uuid) from public;
grant execute on function restore_custom_instrument_version(p_version_id uuid) to authenticated;
revoke all on function delete_custom_instrument(p_instrument_id uuid) from public;
grant execute on function delete_custom_instrument(p_instrument_id uuid) to authenticated;
