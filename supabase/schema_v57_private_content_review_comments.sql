-- Revisión colaborativa extendida a contenido privado de grupo (propuesta de
-- producto auditada esta sesión): hoy `editorial_comments` (ver
-- schema_v29_public_library.sql) solo cubre la Biblioteca Pública -- un
-- miembro de un espacio privado no puede proponer una corrección sin editar
-- directamente el documento. Reutiliza la misma tabla y el mismo patrón
-- (RLS directa, sin RPC -- un comentario no es una escritura lo bastante
-- sensible como para necesitar auditoría, mismo criterio que el resto del
-- proyecto) en vez de crear una tabla paralela.
--
-- Alcance de este tramo: los 4 tipos de contenido privado más usados a
-- diario (técnica/protocolo, bandeja, tarjeta de preferencia, instrumental
-- personalizado). Fuera de alcance: esterilización/ficha técnica (ya tiene
-- su propio `reference_documents`/flujo con el Consejo Editorial global) y
-- el bloque de fecha de revisión/validación clínica/fuente por campo
-- (queda para una ronda posterior).

alter table editorial_comments drop constraint if exists editorial_comments_ref_type_check;
alter table editorial_comments add constraint editorial_comments_ref_type_check
  check (ref_type in (
    'public_document_version', 'public_tray_version',
    'group_document_version', 'tray_version', 'preference_card_version', 'custom_instrument_version'
  ));

-- Workspace del contenido privado que referencia una fila de
-- editorial_comments, o null si ref_type/ref_id no resuelve (fila huérfana o
-- de un tipo público, que no pasa por esta función). security definer +
-- stable: mismo criterio que my_workspace_role(), una sola fuente de verdad
-- reutilizada por las 3 policies de abajo en vez de repetir el mismo join 3
-- veces con riesgo de que diverjan.
create or replace function _private_content_comment_workspace_id(p_ref_type text, p_ref_id uuid)
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select case p_ref_type
    when 'group_document_version' then (
      select gd.workspace_id from group_document_versions gdv
      join group_documents gd on gd.id = gdv.document_id
      where gdv.id = p_ref_id
    )
    when 'tray_version' then (
      select t.workspace_id from tray_versions tv
      join trays t on t.id = tv.tray_id
      where tv.id = p_ref_id
    )
    when 'preference_card_version' then (
      select pc.workspace_id from preference_card_versions pcv
      join preference_cards pc on pc.id = pcv.card_id
      where pcv.id = p_ref_id
    )
    when 'custom_instrument_version' then (
      select ci.workspace_id from custom_instrument_versions civ
      join custom_instruments ci on ci.id = civ.custom_instrument_id
      where civ.id = p_ref_id
    )
    else null
  end
$$;

drop policy if exists "editorial_comments_select" on editorial_comments;
create policy "editorial_comments_select" on editorial_comments
  for select using (
    my_is_reviewer_or_above()
    or exists (
      select 1 from public_document_versions v
      where v.id = ref_id and ref_type = 'public_document_version' and v.author_id = auth.uid()
    )
    or exists (
      select 1 from public_tray_versions v
      where v.id = ref_id and ref_type = 'public_tray_version' and v.author_id = auth.uid()
    )
    or (
      ref_type in ('group_document_version', 'tray_version', 'preference_card_version', 'custom_instrument_version')
      and my_workspace_role(_private_content_comment_workspace_id(ref_type, ref_id)) is not null
    )
  );

drop policy if exists "editorial_comments_insert" on editorial_comments;
create policy "editorial_comments_insert" on editorial_comments
  for insert with check (
    author_id = auth.uid()
    and (
      my_is_reviewer_or_above()
      or exists (
        select 1 from public_document_versions v
        where v.id = ref_id and ref_type = 'public_document_version' and v.author_id = auth.uid()
      )
      or exists (
        select 1 from public_tray_versions v
        where v.id = ref_id and ref_type = 'public_tray_version' and v.author_id = auth.uid()
      )
      or (
        ref_type in ('group_document_version', 'tray_version', 'preference_card_version', 'custom_instrument_version')
        and my_workspace_role(_private_content_comment_workspace_id(ref_type, ref_id)) is not null
      )
    )
  );

-- Marcar como resuelto: quien revisa la Biblioteca Pública, el approver/
-- administrator del espacio para contenido privado, o el propio autor del
-- comentario en cualquier caso (mismo criterio que la policy pública).
drop policy if exists "editorial_comments_update" on editorial_comments;
create policy "editorial_comments_update" on editorial_comments
  for update using (
    my_is_reviewer_or_above()
    or author_id = auth.uid()
    or (
      ref_type in ('group_document_version', 'tray_version', 'preference_card_version', 'custom_instrument_version')
      and my_workspace_role(_private_content_comment_workspace_id(ref_type, ref_id)) in ('approver', 'administrator')
    )
  );
