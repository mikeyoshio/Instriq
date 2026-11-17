-- schema_v69: hotfix d'autorització (auditories 2026-11-17). Dues classes
-- d'error, totes dues trobades en implementar la 2.0-alfa:
--
-- 1) Bypass cross-organització via my_is_hospital_admin(). La funció només
--    mira profiles.is_admin del cridant, NO de quina organització és admin.
--    I register_hospital fa admin de la seva pròpia organització qualsevol
--    usuari que se'n crea una -- així que "admin" == qualsevol usuari
--    autenticat. Tota política amb `... or my_is_hospital_admin()` sense
--    acotar organization_id = my_hospital_id() obria la taula sencera, i les
--    branques de contingut global (`organization_id is null and
--    my_is_hospital_admin()`) permetien a qualsevol reescriure/publicar
--    contingut global d'esterilització i fitxes tècniques sense revisió.
--    Mateixa classe que l'.ics corregit a v67.
--
-- 2) Bypass per NULL: my_workspace_role() retorna NULL per a qui no és
--    membre, i `NULL not in (...)` no és cert, així que el guard
--    `if my_workspace_role(x) not in (...) then raise` NO salta. v47 ho va
--    corregir a 35 funcions; v55/v58/v62/v64/v65 ho van tornar a introduir.
--    create/update_surgical_slot ja queden corregides a v68.
--
-- Columnes: després del rename de v20 la columna és organization_id (mai
-- hospital_id) a totes aquestes taules.

-- ===========================================================================
-- Polítiques
-- ===========================================================================

drop policy if exists "surgical_slots_select" on surgical_slots;
create policy "surgical_slots_select" on surgical_slots for select using (
  my_workspace_role(workspace_id) is not null
  or (my_is_hospital_admin() and organization_id = my_hospital_id())
);

drop policy if exists "tray_preparation_sessions_select" on tray_preparation_sessions;
create policy "tray_preparation_sessions_select" on tray_preparation_sessions for select using (
  my_workspace_role(workspace_id) is not null
  or (my_is_hospital_admin() and organization_id = my_hospital_id())
);

drop policy if exists "team_quizzes_delete" on team_quizzes;
create policy "team_quizzes_delete" on team_quizzes
  for delete using (
    (
      my_is_hospital_admin()
      or exists (select 1 from workspace_members where user_id = auth.uid() and role = 'approver')
    )
    and exists (select 1 from teams t where t.id = team_quizzes.team_id and t.organization_id = my_hospital_id())
  );

-- Capçaleres globals: el client no les escriu mai directament (tot via
-- RPC security definer, que no passa per RLS); la branca global queda
-- reservada al Consell Editorial.
drop policy if exists "instrument_sterilization_methods_insert" on instrument_sterilization_methods;
create policy "instrument_sterilization_methods_insert" on instrument_sterilization_methods
  for insert with check (
    (organization_id is null and my_is_reviewer_or_above())
    or (organization_id is not null and my_workspace_role(workspace_id) in ('editor', 'approver', 'administrator'))
  );

drop policy if exists "instrument_sterilization_methods_update" on instrument_sterilization_methods;
create policy "instrument_sterilization_methods_update" on instrument_sterilization_methods
  for update using (
    (organization_id is null and my_is_reviewer_or_above())
    or (organization_id is not null and my_workspace_role(workspace_id) in ('editor', 'approver', 'administrator'))
  );

drop policy if exists "instrument_technical_info_insert" on instrument_technical_info;
create policy "instrument_technical_info_insert" on instrument_technical_info
  for insert with check (
    (organization_id is null and my_is_reviewer_or_above())
    or (organization_id is not null and my_workspace_role(workspace_id) in ('editor', 'approver', 'administrator'))
  );

drop policy if exists "instrument_technical_info_update" on instrument_technical_info;
create policy "instrument_technical_info_update" on instrument_technical_info
  for update using (
    (organization_id is null and my_is_reviewer_or_above())
    or (organization_id is not null and my_workspace_role(workspace_id) in ('editor', 'approver', 'administrator'))
  );

-- Versions: escriptura directa del client només per a esborranys propis
-- (sterilization_service.dart insereix status='draft' + author_id = l'usuari
-- i actualitza només els seus esborranys); els canvis d'estat van per RPC.
-- El `with check` explícit impedeix convertir un esborrany en publicat.
drop policy if exists instrument_sterilization_method_versions_insert on instrument_sterilization_method_versions;
create policy instrument_sterilization_method_versions_insert on instrument_sterilization_method_versions
  for insert with check (
    instrument_sterilization_method_versions.status = 'draft'
    and exists (
      select 1 from instrument_sterilization_methods h
      where h.id = instrument_sterilization_method_versions.method_id
      and (
        (h.organization_id is null and instrument_sterilization_method_versions.author_id = auth.uid())
        or (h.organization_id is not null and my_workspace_role(h.workspace_id) in ('editor', 'approver', 'administrator'))
      )
    )
  );

drop policy if exists instrument_sterilization_method_versions_update on instrument_sterilization_method_versions;
create policy instrument_sterilization_method_versions_update on instrument_sterilization_method_versions
  for update
  using (
    instrument_sterilization_method_versions.status = 'draft'
    and exists (
      select 1 from instrument_sterilization_methods h
      where h.id = instrument_sterilization_method_versions.method_id
      and (
        (h.organization_id is null and instrument_sterilization_method_versions.author_id = auth.uid())
        or (h.organization_id is not null and my_workspace_role(h.workspace_id) in ('editor', 'approver', 'administrator'))
      )
    )
  )
  with check (
    instrument_sterilization_method_versions.status = 'draft'
    and exists (
      select 1 from instrument_sterilization_methods h
      where h.id = instrument_sterilization_method_versions.method_id
      and (
        (h.organization_id is null and instrument_sterilization_method_versions.author_id = auth.uid())
        or (h.organization_id is not null and my_workspace_role(h.workspace_id) in ('editor', 'approver', 'administrator'))
      )
    )
  );

drop policy if exists instrument_technical_info_versions_insert on instrument_technical_info_versions;
create policy instrument_technical_info_versions_insert on instrument_technical_info_versions
  for insert with check (
    instrument_technical_info_versions.status = 'draft'
    and exists (
      select 1 from instrument_technical_info h
      where h.id = instrument_technical_info_versions.info_id
      and (
        (h.organization_id is null and instrument_technical_info_versions.author_id = auth.uid())
        or (h.organization_id is not null and my_workspace_role(h.workspace_id) in ('editor', 'approver', 'administrator'))
      )
    )
  );

drop policy if exists instrument_technical_info_versions_update on instrument_technical_info_versions;
create policy instrument_technical_info_versions_update on instrument_technical_info_versions
  for update
  using (
    instrument_technical_info_versions.status = 'draft'
    and exists (
      select 1 from instrument_technical_info h
      where h.id = instrument_technical_info_versions.info_id
      and (
        (h.organization_id is null and instrument_technical_info_versions.author_id = auth.uid())
        or (h.organization_id is not null and my_workspace_role(h.workspace_id) in ('editor', 'approver', 'administrator'))
      )
    )
  )
  with check (
    instrument_technical_info_versions.status = 'draft'
    and exists (
      select 1 from instrument_technical_info h
      where h.id = instrument_technical_info_versions.info_id
      and (
        (h.organization_id is null and instrument_technical_info_versions.author_id = auth.uid())
        or (h.organization_id is not null and my_workspace_role(h.workspace_id) in ('editor', 'approver', 'administrator'))
      )
    )
  );

-- IFU globals: només revisors. El client ja passa organizationId en fitxes
-- d'organització (clinical_data_form_sheet.dart), així que l'IFU queda privada.
drop policy if exists "reference_documents_insert" on reference_documents;
create policy "reference_documents_insert" on reference_documents
  for insert with check (
    (organization_id is null and my_is_reviewer_or_above())
    or (
      organization_id is not null
      and organization_id = (select organization_id from profiles where id = auth.uid())
    )
  );

-- ===========================================================================
-- Funcions (cos idèntic a la darrera definició; només canvien els guards)
-- ===========================================================================

-- De v64:231
create or replace function cancel_surgical_slot(p_slot_id uuid, p_reason text default null)
returns void
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_workspace_id uuid;
  v_organization_id uuid;
  v_status text;
begin
  select workspace_id, organization_id, status into v_workspace_id, v_organization_id, v_status
  from surgical_slots where id = p_slot_id;

  if v_workspace_id is null then
    raise exception 'Slot de agenda no encontrado';
  end if;
  if v_status = 'cancelled' then
    raise exception 'Este slot ya esta cancelado';
  end if;
  if coalesce(my_workspace_role(v_workspace_id), '') not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para cancelar slots de agenda en este espacio';
  end if;

  update surgical_slots set
    status = 'cancelled', cancelled_by = auth.uid(), cancelled_at = now(), cancellation_reason = p_reason
  where id = p_slot_id;

  perform log_audit_event(
    v_organization_id, 'surgical_slot_cancelled', 'surgical_slot', p_slot_id, v_workspace_id, '{}'::jsonb
  );
end;
$function$;

-- De v65:220
create or replace function adopt_group_tray(p_source_tray_id uuid, p_target_workspace_id uuid)
returns tray_versions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_target_org uuid;
  v_target_group uuid;
  v_source_org uuid;
  v_source_group uuid;
  v_source_version_id uuid;
  v_source_version tray_versions;
  v_new_tray_id uuid;
  v_new_version tray_versions;
begin
  if coalesce(my_workspace_role(p_target_workspace_id), '') not in ('editor', 'approver', 'administrator') then
    raise exception 'No autoritzat per adoptar contingut en aquest espai';
  end if;

  select organization_id into v_target_org from workspaces where id = p_target_workspace_id;
  if v_target_org is null then
    raise exception 'Espai no trobat';
  end if;
  select group_id into v_target_group from organizations where id = v_target_org;

  select organization_id, published_version_id into v_source_org, v_source_version_id
    from trays where id = p_source_tray_id;
  if v_source_org is null then
    raise exception 'Bandeja d''origen no trobada';
  end if;
  select group_id into v_source_group from organizations where id = v_source_org;

  if v_target_group is null or v_source_group is null or v_target_group <> v_source_group then
    raise exception 'Aquesta safata no pertany al mateix grup.';
  end if;
  if v_source_version_id is null then
    raise exception 'Aquesta safata encara no té cap versió publicada.';
  end if;

  select * into v_source_version from tray_versions where id = v_source_version_id;

  insert into trays (organization_id, workspace_id, created_by)
  values (v_target_org, p_target_workspace_id, auth.uid())
  returning id into v_new_tray_id;

  insert into tray_versions (
    tray_id, version_number, status, name, specialty_id, description, items, observations,
    author_id, comment
  )
  values (
    v_new_tray_id, 1, 'draft', v_source_version.name, v_source_version.specialty_id,
    v_source_version.description, v_source_version.items, v_source_version.observations,
    auth.uid(), 'Importada des d''un altre centre del grup'
  )
  returning * into v_new_version;

  perform log_audit_event(
    v_target_org,
    'tray_adopted_from_group',
    'tray',
    v_new_tray_id,
    p_target_workspace_id,
    jsonb_build_object('source_tray_id', p_source_tray_id, 'source_organization_id', v_source_org)
  );

  return v_new_version;
end;
$$;

-- De v58:44
create or replace function set_content_source_reference(
  p_ref_type text,
  p_ref_id uuid,
  p_source_reference text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_workspace_id uuid;
begin
  if p_ref_type not in ('group_document_version', 'tray_version', 'preference_card_version', 'custom_instrument_version') then
    raise exception 'Tipo de contenido no valido';
  end if;

  v_workspace_id := _private_content_comment_workspace_id(p_ref_type, p_ref_id);
  if v_workspace_id is null or coalesce(my_workspace_role(v_workspace_id), '') not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para editar este contenido';
  end if;

  case p_ref_type
    when 'group_document_version' then
      update group_document_versions set source_reference = p_source_reference where id = p_ref_id;
    when 'tray_version' then
      update tray_versions set source_reference = p_source_reference where id = p_ref_id;
    when 'preference_card_version' then
      update preference_card_versions set source_reference = p_source_reference where id = p_ref_id;
    when 'custom_instrument_version' then
      update custom_instrument_versions set source_reference = p_source_reference where id = p_ref_id;
  end case;
end;
$$;

-- De v62:33
create or replace function mark_content_clinically_reviewed(
  p_ref_type text,
  p_ref_id uuid,
  p_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_workspace_id uuid;
begin
  if p_ref_type not in ('group_document_version', 'tray_version', 'preference_card_version', 'custom_instrument_version') then
    raise exception 'Tipo de contenido no valido';
  end if;

  v_workspace_id := _private_content_comment_workspace_id(p_ref_type, p_ref_id);
  if v_workspace_id is null or coalesce(my_workspace_role(v_workspace_id), '') not in ('approver', 'administrator') then
    raise exception 'No autorizado para marcar este contenido como revisado clinicamente';
  end if;

  if _private_content_status(p_ref_type, p_ref_id) is distinct from 'published' then
    raise exception 'Solo se puede marcar como revisado clinicamente el contenido ya publicado';
  end if;

  case p_ref_type
    when 'group_document_version' then
      update group_document_versions
        set clinically_reviewed_by = auth.uid(), clinically_reviewed_at = now(), clinical_review_notes = p_notes
        where id = p_ref_id;
    when 'tray_version' then
      update tray_versions
        set clinically_reviewed_by = auth.uid(), clinically_reviewed_at = now(), clinical_review_notes = p_notes
        where id = p_ref_id;
    when 'preference_card_version' then
      update preference_card_versions
        set clinically_reviewed_by = auth.uid(), clinically_reviewed_at = now(), clinical_review_notes = p_notes
        where id = p_ref_id;
    when 'custom_instrument_version' then
      update custom_instrument_versions
        set clinically_reviewed_by = auth.uid(), clinically_reviewed_at = now(), clinical_review_notes = p_notes
        where id = p_ref_id;
  end case;

  perform log_audit_event(
    (select organization_id from workspaces where id = v_workspace_id),
    'content_clinically_reviewed',
    p_ref_type,
    p_ref_id,
    v_workspace_id,
    jsonb_build_object('notes', p_notes)
  );
end;
$$;

-- De v55:35. Afegit: el workspace ha de ser de la pròpia organització.
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

  if p_workspace_id is not null and not exists (
    select 1 from workspaces where id = p_workspace_id and organization_id = v_organization_id
  ) then
    raise exception 'Espacio no encontrado en tu grupo';
  end if;

  -- workspace_id nulo queda deliberadamente sin chequeo de rol (baja
  -- friccion para animar a reportar); presente exige editor+ en ese espacio.
  if p_workspace_id is not null and coalesce(my_workspace_role(p_workspace_id), '') not in ('editor', 'approver', 'administrator') then
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

-- De v55:88
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

  if (v_workspace_id is null and not my_is_hospital_admin())
     or (v_workspace_id is not null and coalesce(my_workspace_role(v_workspace_id), '') not in ('approver', 'administrator')) then
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

-- De v55:144
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
     or (v_workspace_id is not null and coalesce(my_workspace_role(v_workspace_id), '') not in ('approver', 'administrator')) then
    raise exception 'No autorizado para verificar esta incidencia';
  end if;

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

revoke all on function cancel_surgical_slot(uuid, text) from public, anon;
grant execute on function cancel_surgical_slot(uuid, text) to authenticated;
revoke all on function adopt_group_tray(uuid, uuid) from public, anon;
grant execute on function adopt_group_tray(uuid, uuid) to authenticated;
revoke all on function set_content_source_reference(text, uuid, text) from public, anon;
grant execute on function set_content_source_reference(text, uuid, text) to authenticated;
revoke all on function mark_content_clinically_reviewed(text, uuid, text) from public, anon;
grant execute on function mark_content_clinically_reviewed(text, uuid, text) to authenticated;
revoke all on function report_instrument_incident(text, text, text, text, uuid, uuid) from public, anon;
grant execute on function report_instrument_incident(text, text, text, text, uuid, uuid) to authenticated;
revoke all on function resolve_instrument_incident(uuid, text, text, text) from public, anon;
grant execute on function resolve_instrument_incident(uuid, text, text, text) to authenticated;
revoke all on function verify_instrument_incident(uuid, text) from public, anon;
grant execute on function verify_instrument_incident(uuid, text) to authenticated;

-- Verificació (executar després d'aplicar, amb dos comptes de proves A i B
-- d'organitzacions diferents):
--   -- Com a admin de l'org A: les cites de l'org B han de ser 0.
--   select count(*) from surgical_slots where organization_id = '<org_B>';
--   select count(*) from tray_preparation_sessions where organization_id = '<org_B>';
--   -- Com a usuari sense rol a l'espai de la cita: ha de fallar.
--   select cancel_surgical_slot('<slot_de_B>');
--   -- Com a no-revisor: ha de fallar.
--   insert into reference_documents (title, url, doc_type) values ('x', 'https://x', 'ifu');
--   -- Cap d'aquestes ha de tenir EXECUTE per a anon:
--   select proname, proacl from pg_proc where proname in (
--     'cancel_surgical_slot', 'adopt_group_tray', 'set_content_source_reference',
--     'mark_content_clinically_reviewed', 'report_instrument_incident',
--     'resolve_instrument_incident', 'verify_instrument_incident');
