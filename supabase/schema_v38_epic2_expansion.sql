-- EPIC 2 ampliat (2026-08): Material fungible, Posicionament del pacient,
-- Anestèsia i Sutures relacionades a tècniques/protocols, més Vídeos
-- explicatius -- forats documentats a docs/BACKLOG.md des d'EPIC 2
-- ("no existeixen com a entitat enlloc") i confirmats per una comparativa
-- amb apps competidores (procedimientosenquirofano.es i similars).

-- ============================================================
-- 1) group_document_versions -- 4 columnes noves. Mateix criteri que
--    `content`/`steps`/`related_instrument_ids` ja existents: no són
--    entitats independents amb flux propi (ADR-004 §2), són més contingut
--    de la mateixa fitxa versionada. Editables només en draft per la RLS
--    ja existent (status='draft' and author_id=auth.uid()), sense RPC nova.
-- ============================================================

alter table group_document_versions
  add column if not exists consumables jsonb not null default '[]'::jsonb,
  add column if not exists patient_positioning text,
  add column if not exists anesthesia_notes text,
  add column if not exists related_suture_ids jsonb not null default '[]'::jsonb;

-- ============================================================
-- 2) knowledge_links -- amplia to_type amb 'suture', calcat de com ja s'hi
--    va afegir 'public_tray' (schema_v33). cleanup_knowledge_links() només
--    neteja from_type, mai to_type, així que no cal tocar el trigger.
-- ============================================================

alter table knowledge_links drop constraint if exists knowledge_links_to_type_check;
alter table knowledge_links add constraint knowledge_links_to_type_check
  check (to_type in ('catalog', 'custom', 'tray', 'public_tray', 'suture'));

-- ============================================================
-- 3) approve_group_document_version -- sincronitza related_suture_ids a
--    knowledge_links igual que ja fa amb related_tray_ids. Mateix cos
--    vigent (verificat contra la funció real abans d'escriure això), amb
--    la lectura/inserció de sutures afegida.
-- ============================================================

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

-- ============================================================
-- 4) Especialitat nova -- "Anestesiología y Reanimación". Llista tancada,
--    la sembra la migració, no el client (mateix criteri que les 16 files
--    ja existents, schema_v24).
-- ============================================================

insert into specialties (slug, label)
values ('anestesiologiaReanimacio', 'Anestesiología y Reanimación')
on conflict (slug) do nothing;

-- ============================================================
-- 5) group_document_videos -- taula plana moderada, calcada
--    d'instrument_incidents (schema_v32): "no és contingut que calgui
--    aprovar abans d'existir [com a veritat publicada], és més proper a
--    una anotació operativa" -- però a diferència d'incidències, aquí
--    l'estat per defecte SÍ bloqueja la visibilitat pública fins que
--    s'aprova (com catalog_community_photos), perquè és contingut
--    submergit per qualsevol editor i mostrat a tothom amb accés al
--    document, no un registre operatiu intern.
-- ============================================================

create table if not exists group_document_videos (
  id uuid primary key default gen_random_uuid(),
  group_document_id uuid not null references group_documents(id) on delete cascade,
  organization_id uuid not null references organizations(id) on delete cascade,
  workspace_id uuid not null references workspaces(id),
  title text not null,
  url text not null,
  submitted_by uuid references auth.users(id),
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists group_document_videos_document_idx on group_document_videos (group_document_id);
create index if not exists group_document_videos_organization_idx on group_document_videos (organization_id);

alter table group_document_videos enable row level security;

create policy group_document_videos_select on group_document_videos
  for select using (organization_id = my_hospital_id());

create policy group_document_videos_insert on group_document_videos
  for insert with check (
    organization_id = my_hospital_id()
    and submitted_by = auth.uid()
    and my_workspace_role(workspace_id) in ('editor', 'approver', 'administrator')
  );

-- Aprovar/rebutjar un vídeo és una decisió (igual pes que aprovar un canvi
-- de contingut), no una simple edició -- exigeix approver/administrator.
create policy group_document_videos_update on group_document_videos
  for update using (
    organization_id = my_hospital_id()
    and my_workspace_role(workspace_id) in ('approver', 'administrator')
  );

revoke all on function approve_group_document_version(uuid, text) from public;
grant execute on function approve_group_document_version(uuid, text) to authenticated;
