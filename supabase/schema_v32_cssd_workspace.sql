-- EPIC 3 · CSSD Workspace. Converteix instrument_sterilization_methods /
-- instrument_technical_info -- avui escriptura directa, sense esborrany ni
-- aprovació -- en parelles capçalera+versions, seguint la mateixa recepta
-- d'ADR-004 que ja fan servir trays/group_documents/preference_cards
-- (schema_v22_preference_card_versioning.sql és la plantilla literal). De
-- pas s'afegeixen camps estructurats de lubricació i manteniment (eren text
-- lliure) i una taula nova d'incidències.
--
-- Decisió confirmada pel propietari (2026-08): "qui aprova un canvi al
-- catàleg global" -- l'única pregunta que deixava ADR-004 sense resposta
-- per a aquest cas -- es resol reutilitzant el sistema de col·laboradors/
-- Editorial Board ja construït per a la Biblioteca Pública
-- (my_is_reviewer_or_above(), schema_v29_public_library.sql), en lloc
-- d'inventar un rol nou. Files d'organització (organization_id not null)
-- segueixen aprovant-se pel rol d'espai (approver/administrator), exactament
-- com la resta de contingut versionat.

-- ============================================================
-- 1) instrument_sterilization_methods -> capçalera + versions
-- ============================================================

create table if not exists instrument_sterilization_method_versions (
  id uuid primary key default gen_random_uuid(),
  method_id uuid not null references instrument_sterilization_methods(id) on delete cascade,
  version_number integer not null,
  status text not null check (status in ('draft', 'in_review', 'published', 'archived')),
  method text not null check (method in ('vapor', 'plasma', 'oxido_etileno', 'baja_temperatura', 'desechable', 'no_esterilizable')),
  temperature text,
  time_minutes text,
  pressure text,
  drying text,
  recommended_cycle text,
  compatibility_notes text,
  restrictions text,
  observations text,
  -- Lubricació: era inexistent (bullet propi d'EPIC 3, no un camp de text lliure més).
  lubrication_required boolean not null default false,
  lubrication_type text,
  lubrication_notes text,
  author_id uuid references auth.users(id),
  approved_by uuid references auth.users(id),
  approved_at timestamptz,
  comment text,
  based_on_version_id uuid references instrument_sterilization_method_versions(id),
  created_at timestamptz not null default now(),
  unique (method_id, version_number)
);

create unique index if not exists instrument_sterilization_method_versions_one_published_idx
  on instrument_sterilization_method_versions (method_id) where status = 'published';

-- Backfill: cada fila existent (71 files, totes globals avui) esdevé la seva
-- pròpia versió 1, ja publicada -- res es perd en passar d'edició directa a
-- capçalera+versió.
insert into instrument_sterilization_method_versions (
  method_id, version_number, status, method, temperature, time_minutes, pressure, drying,
  recommended_cycle, compatibility_notes, restrictions, observations, author_id, approved_by, approved_at, created_at
)
select
  id, 1, 'published', method, temperature, time_minutes, pressure, drying,
  recommended_cycle, compatibility_notes, restrictions, observations, created_by, created_by, created_at, created_at
from instrument_sterilization_methods;

alter table instrument_sterilization_methods add column if not exists published_version_id uuid;

update instrument_sterilization_methods h
set published_version_id = v.id
from instrument_sterilization_method_versions v
where v.method_id = h.id and v.version_number = 1;

alter table instrument_sterilization_methods
  add constraint instrument_sterilization_methods_published_version_id_fkey
  foreign key (published_version_id) references instrument_sterilization_method_versions(id);

alter table instrument_sterilization_methods drop column if exists method;
alter table instrument_sterilization_methods drop column if exists temperature;
alter table instrument_sterilization_methods drop column if exists time_minutes;
alter table instrument_sterilization_methods drop column if exists pressure;
alter table instrument_sterilization_methods drop column if exists drying;
alter table instrument_sterilization_methods drop column if exists recommended_cycle;
alter table instrument_sterilization_methods drop column if exists compatibility_notes;
alter table instrument_sterilization_methods drop column if exists restrictions;
alter table instrument_sterilization_methods drop column if exists observations;
alter table instrument_sterilization_methods drop column if exists updated_at;

create index if not exists instrument_sterilization_method_versions_method_idx
  on instrument_sterilization_method_versions (method_id);

alter table instrument_sterilization_method_versions enable row level security;

-- Lectura: files globals publicades, visibles per tothom (anon inclòs --
-- mateix criteri que schema_v17, no regressionar el catàleg en mode
-- convidat); esborranys/en revisió globals només per l'autor o l'Editorial
-- Board. Files d'organització: qualsevol rol d'espai, igual que la resta de
-- contingut versionat.
create policy instrument_sterilization_method_versions_select on instrument_sterilization_method_versions
  for select using (
    exists (
      select 1 from instrument_sterilization_methods h
      where h.id = instrument_sterilization_method_versions.method_id
      and (
        (h.organization_id is null and (status = 'published' or author_id = auth.uid() or my_is_reviewer_or_above()))
        or (h.organization_id is not null and my_workspace_role(h.workspace_id) is not null)
      )
    )
  );

create policy instrument_sterilization_method_versions_insert on instrument_sterilization_method_versions
  for insert with check (
    exists (
      select 1 from instrument_sterilization_methods h
      where h.id = instrument_sterilization_method_versions.method_id
      and (
        (h.organization_id is null and my_is_hospital_admin())
        or (h.organization_id is not null and my_workspace_role(h.workspace_id) in ('editor', 'approver', 'administrator'))
      )
    )
  );

create policy instrument_sterilization_method_versions_update on instrument_sterilization_method_versions
  for update using (
    exists (
      select 1 from instrument_sterilization_methods h
      where h.id = instrument_sterilization_method_versions.method_id
      and (
        (h.organization_id is null and my_is_hospital_admin())
        or (h.organization_id is not null and my_workspace_role(h.workspace_id) in ('editor', 'approver', 'administrator'))
      )
    )
  );

-- ============================================================
-- 2) instrument_technical_info -> capçalera + versions
-- ============================================================

create table if not exists instrument_technical_info_versions (
  id uuid primary key default gen_random_uuid(),
  info_id uuid not null references instrument_technical_info(id) on delete cascade,
  version_number integer not null,
  status text not null check (status in ('draft', 'in_review', 'published', 'archived')),
  manufacturer_id uuid references manufacturers(id),
  ifu_document_id uuid references reference_documents(id),
  maintenance_notes text,
  inspection_notes text,
  useful_life_notes text,
  -- Manteniment estructurat: abans només text lliure.
  maintenance_interval_days integer,
  last_maintenance_at date,
  author_id uuid references auth.users(id),
  approved_by uuid references auth.users(id),
  approved_at timestamptz,
  comment text,
  based_on_version_id uuid references instrument_technical_info_versions(id),
  created_at timestamptz not null default now(),
  unique (info_id, version_number)
);

create unique index if not exists instrument_technical_info_versions_one_published_idx
  on instrument_technical_info_versions (info_id) where status = 'published';

-- Backfill: la taula no té cap fila avui (confirmat abans d'aplicar aquesta
-- migració), així que aquest insert no mou cap dada real -- es deixa igualment
-- pel mateix motiu que preference_cards: consistència de patró, no perquè
-- calgui aquí.
insert into instrument_technical_info_versions (
  info_id, version_number, status, manufacturer_id, ifu_document_id,
  maintenance_notes, inspection_notes, useful_life_notes, author_id, approved_by, approved_at, created_at
)
select
  id, 1, 'published', manufacturer_id, ifu_document_id,
  maintenance_notes, inspection_notes, useful_life_notes, created_by, created_by, created_at, created_at
from instrument_technical_info;

alter table instrument_technical_info add column if not exists published_version_id uuid;

update instrument_technical_info h
set published_version_id = v.id
from instrument_technical_info_versions v
where v.info_id = h.id and v.version_number = 1;

alter table instrument_technical_info
  add constraint instrument_technical_info_published_version_id_fkey
  foreign key (published_version_id) references instrument_technical_info_versions(id);

alter table instrument_technical_info drop column if exists manufacturer_id;
alter table instrument_technical_info drop column if exists ifu_document_id;
alter table instrument_technical_info drop column if exists maintenance_notes;
alter table instrument_technical_info drop column if exists inspection_notes;
alter table instrument_technical_info drop column if exists useful_life_notes;
alter table instrument_technical_info drop column if exists updated_at;

create index if not exists instrument_technical_info_versions_info_idx
  on instrument_technical_info_versions (info_id);

alter table instrument_technical_info_versions enable row level security;

create policy instrument_technical_info_versions_select on instrument_technical_info_versions
  for select using (
    exists (
      select 1 from instrument_technical_info h
      where h.id = instrument_technical_info_versions.info_id
      and (
        (h.organization_id is null and (status = 'published' or author_id = auth.uid() or my_is_reviewer_or_above()))
        or (h.organization_id is not null and my_workspace_role(h.workspace_id) is not null)
      )
    )
  );

create policy instrument_technical_info_versions_insert on instrument_technical_info_versions
  for insert with check (
    exists (
      select 1 from instrument_technical_info h
      where h.id = instrument_technical_info_versions.info_id
      and (
        (h.organization_id is null and my_is_hospital_admin())
        or (h.organization_id is not null and my_workspace_role(h.workspace_id) in ('editor', 'approver', 'administrator'))
      )
    )
  );

create policy instrument_technical_info_versions_update on instrument_technical_info_versions
  for update using (
    exists (
      select 1 from instrument_technical_info h
      where h.id = instrument_technical_info_versions.info_id
      and (
        (h.organization_id is null and my_is_hospital_admin())
        or (h.organization_id is not null and my_workspace_role(h.workspace_id) in ('editor', 'approver', 'administrator'))
      )
    )
  );

-- ============================================================
-- 3) Incidències -- taula nova, sense versionat (registre operatiu, no
--    contingut que calgui aprovar abans d'existir). Amb estat i gravetat,
--    decisió confirmada pel propietari.
-- ============================================================

create table if not exists instrument_incidents (
  id uuid primary key default gen_random_uuid(),
  instrument_ref_type text not null check (instrument_ref_type in ('catalog', 'custom')),
  instrument_ref_id text not null,
  organization_id uuid not null references organizations(id) on delete cascade,
  workspace_id uuid references workspaces(id),
  severity text not null check (severity in ('low', 'medium', 'high')),
  status text not null default 'open' check (status in ('open', 'resolved')),
  description text not null,
  resolution_notes text,
  reported_by uuid references auth.users(id),
  resolved_by uuid references auth.users(id),
  resolved_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists instrument_incidents_ref_idx on instrument_incidents (instrument_ref_type, instrument_ref_id);
create index if not exists instrument_incidents_organization_idx on instrument_incidents (organization_id);

alter table instrument_incidents enable row level security;

-- Transparència de seguretat: qualsevol rol d'espai de l'organització pot
-- llegir-les (fins i tot reader), no només qui les crea.
create policy instrument_incidents_select on instrument_incidents
  for select using (organization_id = my_hospital_id());

create policy instrument_incidents_insert on instrument_incidents
  for insert with check (
    organization_id = my_hospital_id()
    and reported_by = auth.uid()
    and (workspace_id is null or my_workspace_role(workspace_id) in ('editor', 'approver', 'administrator'))
  );

-- Resoldre una incidència és una decisió (igual pes que aprovar un canvi),
-- no una simple edició -- exigeix approver/administrator, no editor.
create policy instrument_incidents_update on instrument_incidents
  for update using (
    organization_id = my_hospital_id()
    and (workspace_id is null or my_workspace_role(workspace_id) in ('approver', 'administrator'))
  );

-- ============================================================
-- 4) RPCs -- instrument_sterilization_method_versions
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
    if my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
      raise exception 'No autoritzat per crear mètodes d''esterilització en aquest espai';
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

create or replace function submit_sterilization_method_version_for_review(p_version_id uuid)
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
  where id = p_version_id and status = 'draft' and author_id = auth.uid();

  if v_method_id is null then
    raise exception 'No autoritzat o versió no vàlida per enviar a revisió';
  end if;

  select organization_id, workspace_id into v_organization_id, v_workspace_id from instrument_sterilization_methods where id = v_method_id;

  update instrument_sterilization_method_versions set status = 'in_review' where id = p_version_id;

  perform log_audit_event(
    coalesce(v_organization_id, my_hospital_id()), 'sterilization_method_version_submitted', 'instrument_sterilization_method_version',
    p_version_id, v_workspace_id, jsonb_build_object('method_id', v_method_id)
  );
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
    if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
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
    if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
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
    if my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
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

-- ============================================================
-- 5) RPCs -- instrument_technical_info_versions (mateix patró exacte)
-- ============================================================

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
    if my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
      raise exception 'No autoritzat per crear fitxes tècniques en aquest espai';
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

create or replace function submit_technical_info_version_for_review(p_version_id uuid)
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
  where id = p_version_id and status = 'draft' and author_id = auth.uid();

  if v_info_id is null then
    raise exception 'No autoritzat o versió no vàlida per enviar a revisió';
  end if;

  select organization_id, workspace_id into v_organization_id, v_workspace_id from instrument_technical_info where id = v_info_id;

  update instrument_technical_info_versions set status = 'in_review' where id = p_version_id;

  perform log_audit_event(
    coalesce(v_organization_id, my_hospital_id()), 'technical_info_version_submitted', 'instrument_technical_info_version',
    p_version_id, v_workspace_id, jsonb_build_object('info_id', v_info_id)
  );
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
    if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
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
    if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
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
    if my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
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
