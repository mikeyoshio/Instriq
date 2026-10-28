-- Resto del bloque de confianza/trazabilidad de contenido (propuesta de
-- producto auditada esta sesión, confirmada "no implementada"): fuente de
-- información por campo y fecha de revisión explícita, y "validación
-- clínica" separada del ciclo editorial draft->revisión->publicado->
-- archivado ya existente -- que publicado no implique "revisado por un
-- profesional" es justo la distinción que pedía evitar ambigüedad el propio
-- documento auditado.
--
-- Mismo alcance que schema_v57 (los 4 tipos de contenido privado de uso
-- diario: técnica/protocolo, bandeja, tarjeta de preferencia, instrumental
-- personalizado); esterilización/ficha técnica queda fuera, ya tiene su
-- propio `reference_documents`/flujo con el Consejo Editorial global.

alter table group_document_versions
  add column if not exists source_reference text,
  add column if not exists clinically_reviewed_by uuid references auth.users(id) on delete set null,
  add column if not exists clinically_reviewed_at timestamptz,
  add column if not exists clinical_review_notes text;

alter table tray_versions
  add column if not exists source_reference text,
  add column if not exists clinically_reviewed_by uuid references auth.users(id) on delete set null,
  add column if not exists clinically_reviewed_at timestamptz,
  add column if not exists clinical_review_notes text;

alter table preference_card_versions
  add column if not exists source_reference text,
  add column if not exists clinically_reviewed_by uuid references auth.users(id) on delete set null,
  add column if not exists clinically_reviewed_at timestamptz,
  add column if not exists clinical_review_notes text;

alter table custom_instrument_versions
  add column if not exists source_reference text,
  add column if not exists clinically_reviewed_by uuid references auth.users(id) on delete set null,
  add column if not exists clinically_reviewed_at timestamptz,
  add column if not exists clinical_review_notes text;

-- Documentar la fuente es de bajo riesgo (solo trazabilidad, no cambia el
-- contenido clínico en sí) -- mismo umbral de permiso que editar un borrador
-- (editor/approver/administrator), vía la misma _private_content_comment_workspace_id
-- añadida en schema_v57 (reutilizada aquí: resuelve el workspace_id de
-- cualquier ref_type/ref_id de contenido privado, no es exclusiva de
-- comentarios pese al nombre).
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
  if v_workspace_id is null or my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
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

revoke all on function set_content_source_reference(text, uuid, text) from public;
grant execute on function set_content_source_reference(text, uuid, text) to authenticated;

-- Validacion clinica: exige approver/administrator (el mismo umbral ya
-- confiado para aprobar el contenido en si), nunca solo editor. Re-llamable
-- (un contenido se puede re-revisar tras un cambio real sin crear una fila
-- nueva de por si -- el cambio de contenido ya genera una version nueva,
-- cuyas columnas de revision clinica nacen limpias).
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
  if v_workspace_id is null or my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'No autorizado para marcar este contenido como revisado clinicamente';
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

revoke all on function mark_content_clinically_reviewed(text, uuid, text) from public;
grant execute on function mark_content_clinically_reviewed(text, uuid, text) to authenticated;
