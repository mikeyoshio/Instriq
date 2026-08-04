-- EPIC 9 (segon tram): Biblioteca Publica -- tecniques/protocols i safates
-- mantingudes per la comunitat, seguint la recepta d'ADR-004
-- (docs/ADR_004_VERSIONING.md §5) i el model de governanca d'ADR-001
-- (docs/ADR_001_KNOWLEDGE_GOVERNANCE.md). Taules NOVES i separades de
-- group_documents/trays (decisio revisada i confirmada a ADR-001 §0 --
-- reutilitzar les taules existents amb una columna `visibility` exigiria
-- treure NOT NULL d'organization_id/workspace_id i reescriure RLS+RPC+
-- consultes Dart de les 4 taules, comparable en esforc a taules noves,
-- amb mes risc perque son taules ja en produccio).
--
-- Cap fila d'aquestes taules te organization_id/workspace_id -- son
-- ortogonals al model multiorganitzacio, mateix criteri que
-- manufacturers/tags/specialties (schema_v19).

-- 1. Capcaleres + versions -----------------------------------------------

create table if not exists public_documents (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('technique', 'protocol')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  published_version_id uuid
);

create table if not exists public_document_versions (
  id uuid primary key default gen_random_uuid(),
  document_id uuid not null references public_documents(id) on delete cascade,
  version_number int not null,
  status text not null check (status in ('draft', 'in_review', 'published', 'archived')),
  title text,
  specialty_id uuid references specialties(id) on delete set null,
  content text,
  steps jsonb not null default '[]'::jsonb,
  related_instrument_ids jsonb not null default '[]'::jsonb,
  related_tray_ids jsonb not null default '[]'::jsonb,
  author_id uuid references auth.users(id) on delete set null,
  comment text,
  based_on_version_id uuid references public_document_versions(id) on delete set null,
  approved_by uuid references auth.users(id) on delete set null,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  unique (document_id, version_number)
);

alter table public_documents
  add constraint public_documents_published_version_fkey
  foreign key (published_version_id) references public_document_versions(id) on delete set null;

create index if not exists public_document_versions_document_idx on public_document_versions (document_id);
create index if not exists public_document_versions_author_idx on public_document_versions (author_id);
create unique index if not exists public_document_versions_one_published_idx
  on public_document_versions (document_id) where status = 'published';

create table if not exists public_trays (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  published_version_id uuid
);

create table if not exists public_tray_versions (
  id uuid primary key default gen_random_uuid(),
  tray_id uuid not null references public_trays(id) on delete cascade,
  version_number int not null,
  status text not null check (status in ('draft', 'in_review', 'published', 'archived')),
  name text,
  specialty_id uuid references specialties(id) on delete set null,
  description text,
  items jsonb not null default '[]'::jsonb,
  observations text,
  author_id uuid references auth.users(id) on delete set null,
  comment text,
  based_on_version_id uuid references public_tray_versions(id) on delete set null,
  approved_by uuid references auth.users(id) on delete set null,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  unique (tray_id, version_number)
);

alter table public_trays
  add constraint public_trays_published_version_fkey
  foreign key (published_version_id) references public_tray_versions(id) on delete set null;

create index if not exists public_tray_versions_tray_idx on public_tray_versions (tray_id);
create index if not exists public_tray_versions_author_idx on public_tray_versions (author_id);
create unique index if not exists public_tray_versions_one_published_idx
  on public_tray_versions (tray_id) where status = 'published';

-- 2. Comentaris de revisio multi-ronda (capacitat nova, cap dels 3 fluxos
--    privats existents en te -- nomes un camp `comment` sobreescrivible) --

create table if not exists editorial_comments (
  id uuid primary key default gen_random_uuid(),
  ref_type text not null check (ref_type in ('public_document_version', 'public_tray_version')),
  ref_id uuid not null,
  author_id uuid not null references auth.users(id) on delete cascade,
  body text not null,
  resolved boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists editorial_comments_ref_idx on editorial_comments (ref_type, ref_id);

-- 3. Helpers security definer ---------------------------------------------

create or replace function my_is_active_contributor()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select coalesce((select status = 'active' from contributor_profiles where user_id = auth.uid()), false)
$$;

create or replace function my_is_reviewer_or_above()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(
    (select level in ('reviewer', 'editorial_board') and status = 'active'
     from contributor_profiles where user_id = auth.uid()),
    false
  )
$$;

-- 4. RLS -------------------------------------------------------------------

alter table public_documents enable row level security;
alter table public_document_versions enable row level security;
alter table public_trays enable row level security;
alter table public_tray_versions enable row level security;
alter table editorial_comments enable row level security;

-- Capcaleres: lectura publica total (mateix criteri que manufacturers/tags/
-- specialties, schema_v19) -- nomes contingut, mai dades privades.
create policy "public_documents_select" on public_documents for select using (true);
create policy "public_trays_select" on public_trays for select using (true);

-- Nomes un col·laborador actiu pot proposar contingut nou.
create policy "public_documents_insert" on public_documents
  for insert with check (my_is_active_contributor() and created_by = auth.uid());
create policy "public_trays_insert" on public_trays
  for insert with check (my_is_active_contributor() and created_by = auth.uid());

-- Versions: publicat es visible per tothom (inclos anonim); esborrany/en
-- revisio nomes per l'autor i per qui revisa/aprova.
create policy "public_document_versions_select" on public_document_versions
  for select using (status = 'published' or author_id = auth.uid() or my_is_reviewer_or_above());
create policy "public_tray_versions_select" on public_tray_versions
  for select using (status = 'published' or author_id = auth.uid() or my_is_reviewer_or_above());

create policy "public_document_versions_insert" on public_document_versions
  for insert with check (status = 'draft' and author_id = auth.uid() and my_is_active_contributor());
create policy "public_tray_versions_insert" on public_tray_versions
  for insert with check (status = 'draft' and author_id = auth.uid() and my_is_active_contributor());

-- Nomes l'autor pot editar el seu propi esborrany (mateix criteri que
-- group_document_versions_update_own_draft_role) -- els canvis d'estat
-- (submit/approve/reject) van sempre per RPC, mai per update directe.
create policy "public_document_versions_update_own_draft" on public_document_versions
  for update using (status = 'draft' and author_id = auth.uid());
create policy "public_tray_versions_update_own_draft" on public_tray_versions
  for update using (status = 'draft' and author_id = auth.uid());

-- Comentaris: l'autor de la versio i qui revisa/aprova.
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
  );

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
    )
  );

-- Marcar un comentari com a resolt: qui revisa, o el propi autor del comentari.
create policy "editorial_comments_update" on editorial_comments
  for update using (my_is_reviewer_or_above() or author_id = auth.uid());

-- 5. RPC de flux editorial (mateix patro que create_group_document/
--    approve_group_document_version, adaptat: sense workspace_id/
--    organization_id, permisos via my_is_active_contributor()/
--    my_is_reviewer_or_above() en comptes de my_workspace_role()) --------

create or replace function create_public_document(p_kind text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_document_id uuid;
  v_version_id uuid;
begin
  if not my_is_active_contributor() then
    raise exception 'Nomes un col·laborador actiu pot proposar contingut';
  end if;
  if p_kind not in ('technique', 'protocol') then
    raise exception 'Tipus no valid: %', p_kind;
  end if;

  insert into public_documents (kind, created_by) values (p_kind, auth.uid())
  returning id into v_document_id;

  insert into public_document_versions (document_id, version_number, status, author_id)
  values (v_document_id, 1, 'draft', auth.uid())
  returning id into v_version_id;

  return v_document_id;
end;
$$;

create or replace function create_public_tray()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_tray_id uuid;
begin
  if not my_is_active_contributor() then
    raise exception 'Nomes un col·laborador actiu pot proposar contingut';
  end if;

  insert into public_trays (created_by) values (auth.uid()) returning id into v_tray_id;

  insert into public_tray_versions (tray_id, version_number, status, author_id)
  values (v_tray_id, 1, 'draft', auth.uid());

  return v_tray_id;
end;
$$;

create or replace function submit_public_document_version_for_review(p_version_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public_document_versions
  set status = 'in_review'
  where id = p_version_id and status = 'draft' and author_id = auth.uid();

  if not found then
    raise exception 'Version no valida per enviar a revisio';
  end if;
end;
$$;

create or replace function submit_public_tray_version_for_review(p_version_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public_tray_versions
  set status = 'in_review'
  where id = p_version_id and status = 'draft' and author_id = auth.uid();

  if not found then
    raise exception 'Version no valida per enviar a revisio';
  end if;
end;
$$;

create or replace function approve_public_document_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_document_id uuid;
begin
  if not my_is_reviewer_or_above() then
    raise exception 'Nomes qui revisa pot aprovar';
  end if;

  select document_id into v_document_id from public_document_versions
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
end;
$$;

create or replace function reject_public_document_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not my_is_reviewer_or_above() then
    raise exception 'Nomes qui revisa pot rebutjar';
  end if;

  update public_document_versions
  set status = 'draft', comment = coalesce(p_review_comment, comment)
  where id = p_version_id and status = 'in_review';

  if not found then
    raise exception 'Version no valida o no esta en revisio';
  end if;
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
begin
  if not my_is_reviewer_or_above() then
    raise exception 'Nomes qui revisa pot aprovar';
  end if;

  select tray_id into v_tray_id from public_tray_versions
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
end;
$$;

create or replace function reject_public_tray_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not my_is_reviewer_or_above() then
    raise exception 'Nomes qui revisa pot rebutjar';
  end if;

  update public_tray_versions
  set status = 'draft', comment = coalesce(p_review_comment, comment)
  where id = p_version_id and status = 'in_review';

  if not found then
    raise exception 'Version no valida o no esta en revisio';
  end if;
end;
$$;

-- 6. Knowledge Graph: additiu, cap canvi de forma (ja preparat a ADR-001).
--    Nomes s'amplia el check dels tipus permesos -- la sincronitzacio real
--    (com approve_group_document_version/approve_tray_version ja fan per
--    als seus tipus) es deixa explicitament fora d'aquest tram: decisio
--    conscient (recepta d'ADR-004 §5), no una omissio -- veure docs/BACKLOG.md.

alter table knowledge_links drop constraint if exists knowledge_links_from_type_check;
alter table knowledge_links add constraint knowledge_links_from_type_check check (from_type in (
  'group_document', 'tray', 'public_document', 'public_tray'
));

alter table knowledge_links drop constraint if exists knowledge_links_to_type_check;
alter table knowledge_links add constraint knowledge_links_to_type_check check (to_type in (
  'catalog', 'custom', 'tray', 'public_document', 'public_tray'
));
