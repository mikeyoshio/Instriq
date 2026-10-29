-- Auditoria de maduresa (2026-10-29), hueco P1 de integridad: ni
-- set_content_source_reference ni mark_content_clinically_reviewed
-- (schema_v58) comprobaban el status de la version antes de escribir.
--
-- Alcance deliberado: solo mark_content_clinically_reviewed se restringe
-- aqui a versiones publicadas. Es la unica de las dos que hace una
-- afirmacion de confianza real ("esto lo ha revisado clinicamente un
-- profesional") -- permitir marcarla sobre un borrador en curso o una
-- version archivada rompe justo la distincion que motivo esta
-- funcionalidad (publicado != revisado por un profesional). La fuente de
-- informacion (set_content_source_reference) sigue sin restriccion de
-- status a proposito: documentar de donde sale un dato mientras se
-- redacta un borrador es un flujo de trabajo normal, no una afirmacion
-- de confianza, y exigir "publicado" ahi solo estorbaria sin cerrar
-- ningun riesgo real.

create or replace function _private_content_status(p_ref_type text, p_ref_id uuid)
returns text
language sql
security definer
stable
set search_path = public
as $$
  select case p_ref_type
    when 'group_document_version' then (select status from group_document_versions where id = p_ref_id)
    when 'tray_version' then (select status from tray_versions where id = p_ref_id)
    when 'preference_card_version' then (select status from preference_card_versions where id = p_ref_id)
    when 'custom_instrument_version' then (select status from custom_instrument_versions where id = p_ref_id)
    else null
  end
$$;

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

revoke all on function mark_content_clinically_reviewed(text, uuid, text) from public;
grant execute on function mark_content_clinically_reviewed(text, uuid, text) to authenticated;
