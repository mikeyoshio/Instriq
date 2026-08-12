-- EPIC 9, tram de tancament de forats documentats a
-- docs/EPIC_COMMUNITY_GOVERNANCE.md §12 i docs/ADR_001_KNOWLEDGE_GOVERNANCE.md §6:
--
-- 1) knowledge_links per a contingut públic: fins ara només group_document/tray
--    (privats) podien ser from_type, i només catalog/custom/tray com a to_type.
--    S'ampliïn els dos checks per admetre public_document/public_tray, i
--    approve_public_document_version/approve_public_tray_version es
--    reescriuen amb el mateix bloc de sincronització que ja tenen les seves
--    bessones privades (schema_v24_knowledge_links.sql) -- organization_id
--    sempre null per a contingut públic, mateix criteri que la resta de
--    columnes d'aquestes taules.
-- 2) RPC per revelar l'organització d'un col·laborador al seu perfil públic
--    NOMÉS quan ell mateix ho ha triat (show_organization = true) -- profiles/
--    organizations no són llegibles entre organitzacions diferents per RLS,
--    així que cal una funció security definer que faci la comprovació abans
--    de saltar-se-la, no relaxar la RLS de profiles/organizations en general.

alter table knowledge_links drop constraint if exists knowledge_links_from_type_check;
alter table knowledge_links add constraint knowledge_links_from_type_check
  check (from_type in ('group_document', 'tray', 'public_document', 'public_tray'));

alter table knowledge_links drop constraint if exists knowledge_links_to_type_check;
alter table knowledge_links add constraint knowledge_links_to_type_check
  check (to_type in ('catalog', 'custom', 'tray', 'public_tray'));

create or replace function approve_public_document_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_document_id uuid;
  v_related_instrument_ids jsonb;
  v_related_tray_ids jsonb;
begin
  if not my_is_reviewer_or_above() then
    raise exception 'Nomes qui revisa pot aprovar';
  end if;

  select document_id, related_instrument_ids, related_tray_ids
    into v_document_id, v_related_instrument_ids, v_related_tray_ids
  from public_document_versions
  where id = p_version_id and status = 'in_review';

  if v_document_id is null then
    raise exception 'Version no valida o no esta en revisio';
  end if;

  update public_document_versions set status = 'archived'
  where document_id = v_document_id and status = 'published';

  update public_document_versions
  set status = 'published', approved_by = auth.uid(), approved_at = now(),
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  update public_documents set published_version_id = p_version_id where id = v_document_id;

  delete from knowledge_links where from_type = 'public_document' and from_id = v_document_id;

  insert into knowledge_links (organization_id, from_type, from_id, to_type, to_id)
  select
    null, 'public_document', v_document_id,
    case when exists (select 1 from custom_instruments ci where ci.id::text = elem) then 'custom' else 'catalog' end,
    elem
  from jsonb_array_elements_text(coalesce(v_related_instrument_ids, '[]'::jsonb)) as elem
  on conflict do nothing;

  insert into knowledge_links (organization_id, from_type, from_id, to_type, to_id)
  select null, 'public_document', v_document_id, 'public_tray', elem
  from jsonb_array_elements_text(coalesce(v_related_tray_ids, '[]'::jsonb)) as elem
  on conflict do nothing;
end;
$$;

create or replace function approve_public_tray_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tray_id uuid;
  v_items jsonb;
begin
  if not my_is_reviewer_or_above() then
    raise exception 'Nomes qui revisa pot aprovar';
  end if;

  select tray_id, items into v_tray_id, v_items from public_tray_versions
  where id = p_version_id and status = 'in_review';

  if v_tray_id is null then
    raise exception 'Version no valida o no esta en revisio';
  end if;

  update public_tray_versions set status = 'archived'
  where tray_id = v_tray_id and status = 'published';

  update public_tray_versions
  set status = 'published', approved_by = auth.uid(), approved_at = now(),
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  update public_trays set published_version_id = p_version_id where id = v_tray_id;

  delete from knowledge_links where from_type = 'public_tray' and from_id = v_tray_id;

  insert into knowledge_links (organization_id, from_type, from_id, to_type, to_id)
  select null, 'public_tray', v_tray_id, item->>'instrument_ref_type', item->>'instrument_ref_id'
  from jsonb_array_elements(coalesce(v_items, '[]'::jsonb)) as item
  on conflict do nothing;
end;
$$;

-- Neteja en esborrar contingut públic -- mateix criteri que
-- group_documents/trays (schema_v24), cleanup_knowledge_links() ja tenia
-- l'estructura preparada per afegir-hi mes taules.
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
  elsif TG_TABLE_NAME = 'public_documents' then
    delete from knowledge_links where from_type = 'public_document' and from_id = OLD.id;
  elsif TG_TABLE_NAME = 'public_trays' then
    delete from knowledge_links where from_type = 'public_tray' and from_id = OLD.id;
  end if;
  return OLD;
end;
$function$;

drop trigger if exists public_documents_cleanup_knowledge_links on public_documents;
create trigger public_documents_cleanup_knowledge_links
  before delete on public_documents
  for each row execute function cleanup_knowledge_links();

drop trigger if exists public_trays_cleanup_knowledge_links on public_trays;
create trigger public_trays_cleanup_knowledge_links
  before delete on public_trays
  for each row execute function cleanup_knowledge_links();

-- Perfil públic d'un col·laborador (docs/EPIC_COMMUNITY_GOVERNANCE.md §8):
-- l'organització només es mostra si el propi col·laborador ho ha triat
-- (show_organization = true). profiles/organizations no són llegibles entre
-- organitzacions diferents per RLS -- aquesta funció comprova el consentiment
-- i, només si es compleix, es salta aquesta restricció per a aquesta única
-- dada concreta (mai per a res més de profiles/organizations).
create or replace function get_public_contributor_organization(p_user_id uuid)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  v_show_organization boolean;
  v_org_name text;
begin
  select show_organization into v_show_organization
  from contributor_profiles
  where user_id = p_user_id and is_public = true;

  if v_show_organization is not true then
    return null;
  end if;

  select o.name into v_org_name
  from profiles p
  join organizations o on o.id = p.organization_id
  where p.id = p_user_id;

  return v_org_name;
end;
$$;

revoke all on function get_public_contributor_organization(uuid) from public;
grant execute on function get_public_contributor_organization(uuid) to authenticated, anon;
