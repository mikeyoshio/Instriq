-- EPIC 9 (primer tram): candidatura de col·laborador + perfil de comunitat.
-- Segons docs/EPIC_COMMUNITY_GOVERNANCE.md i la decisio confirmada a
-- docs/ADR_001_KNOWLEDGE_GOVERNANCE.md (2026-08). No toca contingut
-- versionat -- la Biblioteca Publica (public_documents/public_trays o la
-- seva alternativa unificada amb `visibility`) queda per a un tram futur.
--
-- Els nivells de col·laborador son un eix de permisos nou i paral·lel a
-- WorkspaceRole (mai una extensio d'aquest) -- coexisteixen sense tocar-lo.

create table if not exists contributor_applications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  full_name text not null,
  email text not null,
  country text,
  organization_name text,
  professional_role text,
  years_experience int,
  linkedin_url text,
  certifications text,
  publications_or_teaching text,
  motivation_letter text not null,
  status text not null default 'pending' check (status in ('pending', 'approved', 'rejected')),
  reviewed_by uuid references auth.users(id) on delete set null,
  reviewed_at timestamptz,
  review_notes text,
  created_at timestamptz not null default now()
);

create index if not exists contributor_applications_user_idx on contributor_applications (user_id);
create index if not exists contributor_applications_status_idx on contributor_applications (status);

-- Nomes una candidatura pendent alhora per usuari -- no impedeix tornar a
-- sol·licitar despres d'un rebuig.
create unique index if not exists contributor_applications_one_pending_per_user
  on contributor_applications (user_id) where status = 'pending';

alter table contributor_applications enable row level security;

create table if not exists contributor_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users(id) on delete cascade,
  level text not null default 'contributor' check (level in ('contributor', 'reviewer', 'editorial_board')),
  public_display_name text,
  public_bio text,
  show_organization boolean not null default false,
  is_public boolean not null default false,
  status text not null default 'active' check (status in ('active', 'suspended', 'retired')),
  approved_by uuid references auth.users(id) on delete set null,
  approved_at timestamptz not null default now()
);

create index if not exists contributor_profiles_level_idx on contributor_profiles (level);

alter table contributor_profiles enable row level security;

-- Sense policy d'update per a "authenticated": ni tan sols per a la propia
-- fila -- `level`/`status` son columnes de privilegi i no es poden separar
-- amb RLS a nivell de columna. Tota escriptura (perfil public propi o canvi
-- de nivell per l'Editorial Board) passa per les RPC de mes avall.

-- Amplia taggings.ref_type per a etiquetar arees de col·laboracio d'un
-- col·laborador (ref_id = user_id) -- reutilitza el cataleg `tags` ja
-- existent, no en crea un de nou (docs/EPIC_COMMUNITY_GOVERNANCE.md §2.2).
alter table taggings drop constraint if exists taggings_ref_type_check;
alter table taggings add constraint taggings_ref_type_check check (ref_type in (
  'catalog', 'custom', 'group_document', 'tray', 'preference_card',
  'surgeon', 'manufacturer', 'specialty', 'contributor'
));

-- Helper security definer -- mateix patro que my_is_hospital_admin().
create or replace function my_is_editorial_board()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(
    (select level = 'editorial_board' and status = 'active'
     from contributor_profiles where user_id = auth.uid()),
    false
  )
$$;

-- Policies que depenen de my_is_editorial_board() -- definides ara que la
-- funcio ja existeix.
drop policy if exists "contributor_applications_select" on contributor_applications;
create policy "contributor_applications_select" on contributor_applications
  for select using (auth.uid() = user_id or my_is_editorial_board());

drop policy if exists "contributor_applications_insert" on contributor_applications;
create policy "contributor_applications_insert" on contributor_applications
  for insert with check (auth.uid() = user_id);

-- Sense policy d'update ni de delete per a "authenticated": la revisio
-- nomes es fa via review_contributor_application() (security definer),
-- mai un update directe des del client -- evita que algu es canviï el seu
-- propi estat.

drop policy if exists "contributor_profiles_select" on contributor_profiles;
create policy "contributor_profiles_select" on contributor_profiles
  for select using (is_public = true or auth.uid() = user_id or my_is_editorial_board());

-- RPC: revisar una candidatura (Editorial Board). Aprovar crea el perfil.
create or replace function review_contributor_application(
  p_application_id uuid,
  p_approved boolean,
  p_notes text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  if not my_is_editorial_board() then
    raise exception 'Nomes l''Editorial Board pot revisar candidatures';
  end if;

  select user_id into v_user_id from contributor_applications
  where id = p_application_id and status = 'pending';

  if v_user_id is null then
    raise exception 'Candidatura no valida o ja revisada';
  end if;

  update contributor_applications
  set status = case when p_approved then 'approved' else 'rejected' end,
      reviewed_by = auth.uid(),
      reviewed_at = now(),
      review_notes = p_notes
  where id = p_application_id;

  if p_approved then
    insert into contributor_profiles (user_id, level, approved_by)
    values (v_user_id, 'contributor', auth.uid())
    on conflict (user_id) do nothing;
  end if;

  perform log_audit_event(
    null,
    case when p_approved then 'contributor_application_approved' else 'contributor_application_rejected' end,
    'contributor_application',
    p_application_id,
    null,
    jsonb_build_object('applicant_user_id', v_user_id)
  );
end;
$$;

-- RPC: el propi col·laborador edita nomes els camps del seu perfil public
-- (mai level/status -- veure comentari de la policy de select mes amunt).
create or replace function update_my_contributor_profile(
  p_public_display_name text default null,
  p_public_bio text default null,
  p_show_organization boolean default null,
  p_is_public boolean default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update contributor_profiles
  set public_display_name = coalesce(p_public_display_name, public_display_name),
      public_bio = coalesce(p_public_bio, public_bio),
      show_organization = coalesce(p_show_organization, show_organization),
      is_public = coalesce(p_is_public, is_public)
  where user_id = auth.uid();
end;
$$;

-- RPC: promocionar/degradar un col·laborador (Editorial Board).
create or replace function set_contributor_level(p_user_id uuid, p_new_level text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not my_is_editorial_board() then
    raise exception 'Nomes l''Editorial Board pot canviar nivells de col·laborador';
  end if;
  if p_new_level not in ('contributor', 'reviewer', 'editorial_board') then
    raise exception 'Nivell no valid: %', p_new_level;
  end if;

  update contributor_profiles set level = p_new_level where user_id = p_user_id;

  perform log_audit_event(
    null, 'contributor_level_changed', 'contributor_profile', p_user_id, null,
    jsonb_build_object('new_level', p_new_level)
  );
end;
$$;
