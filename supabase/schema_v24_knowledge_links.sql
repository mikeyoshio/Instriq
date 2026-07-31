-- EPIC 1 (Knowledge Graph), primer tramo: indice derivado de relaciones
-- tecnica/protocolo <-> instrumental/safata, y safata <-> instrumental.
--
-- No se migra nada: related_instrument_ids (group_document_versions) y
-- tray_versions.items siguen siendo la fuente de verdad. knowledge_links es
-- un indice sincronizado solo al publicar (approve_group_document_version /
-- approve_tray_version), igual que audit_log solo se escribe desde
-- log_audit_event: sin insert/update/delete directo para clientes.
--
-- related_tray_ids es la relacion que faltaba (tecnica/protocolo -> safata),
-- calcada de related_instrument_ids.

create table if not exists knowledge_links (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid references organizations(id) on delete cascade,
  from_type text not null check (from_type in ('group_document', 'tray')),
  from_id uuid not null,
  to_type text not null check (to_type in ('catalog', 'custom', 'tray')),
  to_id text not null,
  created_at timestamptz not null default now(),
  unique (from_type, from_id, to_type, to_id)
);

create index if not exists knowledge_links_to_idx on knowledge_links (to_type, to_id);
create index if not exists knowledge_links_from_idx on knowledge_links (from_type, from_id);
create index if not exists knowledge_links_organization_idx on knowledge_links (organization_id);

alter table knowledge_links enable row level security;

drop policy if exists "knowledge_links_select" on knowledge_links;
create policy "knowledge_links_select" on knowledge_links for select using (
  organization_id is null or organization_id = my_hospital_id()
);

alter table group_document_versions add column if not exists related_tray_ids jsonb not null default '[]'::jsonb;

-- approve_group_document_version: mismo cuerpo vigente + sync de knowledge_links.
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
begin
  select document_id, title, related_instrument_ids, related_tray_ids
    into v_document_id, v_title, v_related_instrument_ids, v_related_tray_ids
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

-- approve_tray_version: mismo cuerpo vigente + sync de knowledge_links.
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

-- Al borrar una tecnica/protocolo o una safata, sus propias filas de
-- knowledge_links (from_type/from_id) ya no significan nada: se limpian con
-- un trigger (no hay FK real posible en from_id, es polimorfico entre dos
-- tablas). Las referencias inversas (otro contenido que apuntaba a lo
-- borrado via to_type/to_id) se toleran igual que ya se tolera hoy un
-- related_instrument_ids con un id de un instrumento personalizado borrado:
-- el cliente resuelve a null y omite la fila, sin romper la ficha.
create or replace function cleanup_knowledge_links()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
begin
  if TG_TABLE_NAME = 'group_documents' then
    delete from knowledge_links where from_type = 'group_document' and from_id = OLD.id;
  elsif TG_TABLE_NAME = 'trays' then
    delete from knowledge_links where from_type = 'tray' and from_id = OLD.id;
  end if;
  return OLD;
end;
$function$;

drop trigger if exists group_documents_cleanup_knowledge_links on group_documents;
create trigger group_documents_cleanup_knowledge_links
  before delete on group_documents
  for each row execute function cleanup_knowledge_links();

drop trigger if exists trays_cleanup_knowledge_links on trays;
create trigger trays_cleanup_knowledge_links
  before delete on trays
  for each row execute function cleanup_knowledge_links();

-- restore_group_document_version: anade related_tray_ids a la lista restaurada
-- (mismo criterio que ya usaba related_instrument_ids; specialty_id no se
-- restauraba en la version original tampoco, no se cambia ese comportamiento).
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

  if my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
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
