-- Tercer tipus de contingut de la Biblioteca Publica (EPIC 9): instrumental
-- concret proposat per la comunitat -- mateix patro exacte que
-- public_documents/public_trays (schema_v29_public_library.sql), adaptat
-- amb els camps de contingut de custom_instrument_versions (schema_v13/v39)
-- en comptes dels propis de tecnica/protocol o safata.
--
-- Decisio de producte (confirmada explicitament, no per defecte): la foto
-- es la que puja el propi col·laborador, amb un avis de "no verificada per
-- Instriq" -- mateix criteri que l'instrumental privat de cada equip
-- (custom_instrument_versions), NO el nivell d'exigencia del cataleg
-- global (llicencia Wikimedia Commons verificada). Categoria reutilitza
-- l'enum InstrumentCategory del cataleg (les mateixes 7 categories, ja
-- traduides als 3 idiomes); especialitat reutilitza `specialties`, la
-- mateixa taula relacional que ja fan servir public_document_versions/
-- public_tray_versions -- no l'enum Specialty del cataleg (que es propi
-- del dataset estatic de 110 instruments, sense equivalent relacional).

create table if not exists public_instruments (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  published_version_id uuid
);

create table if not exists public_instrument_versions (
  id uuid primary key default gen_random_uuid(),
  instrument_id uuid not null references public_instruments(id) on delete cascade,
  version_number int not null,
  status text not null check (status in ('draft', 'in_review', 'published', 'archived')),
  name text,
  category text check (category in ('corte', 'diseccion', 'sutura', 'separacion', 'succion', 'especiales', 'equipos')),
  specialty_id uuid references specialties(id) on delete set null,
  description text,
  use_text text,
  tip text,
  photo_path text,
  author_id uuid references auth.users(id) on delete set null,
  comment text,
  based_on_version_id uuid references public_instrument_versions(id) on delete set null,
  approved_by uuid references auth.users(id) on delete set null,
  approved_at timestamptz,
  created_at timestamptz not null default now(),
  unique (instrument_id, version_number)
);

alter table public_instruments
  add constraint public_instruments_published_version_fkey
  foreign key (published_version_id) references public_instrument_versions(id) on delete set null;

create index if not exists public_instrument_versions_instrument_idx on public_instrument_versions (instrument_id);
create index if not exists public_instrument_versions_author_idx on public_instrument_versions (author_id);
create unique index if not exists public_instrument_versions_one_published_idx
  on public_instrument_versions (instrument_id) where status = 'published';

-- RLS -- identic al criteri de public_documents/public_trays.

alter table public_instruments enable row level security;
alter table public_instrument_versions enable row level security;

create policy "public_instruments_select" on public_instruments for select using (true);

create policy "public_instruments_insert" on public_instruments
  for insert with check (my_is_active_contributor() and created_by = auth.uid());

create policy "public_instrument_versions_select" on public_instrument_versions
  for select using (status = 'published' or author_id = auth.uid() or my_is_reviewer_or_above());

create policy "public_instrument_versions_insert" on public_instrument_versions
  for insert with check (status = 'draft' and author_id = auth.uid() and my_is_active_contributor());

create policy "public_instrument_versions_update_own_draft" on public_instrument_versions
  for update using (status = 'draft' and author_id = auth.uid());

-- editorial_comments (schema_v29) ja es generic per ref_type/ref_id -- nomes
-- cal ampliar el check i les 2 policies que enumeraven explicitament els
-- 2 tipus anteriors.

alter table editorial_comments drop constraint if exists editorial_comments_ref_type_check;
alter table editorial_comments add constraint editorial_comments_ref_type_check check (ref_type in (
  'public_document_version', 'public_tray_version', 'public_instrument_version'
));

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
    or exists (
      select 1 from public_instrument_versions v
      where v.id = ref_id and ref_type = 'public_instrument_version' and v.author_id = auth.uid()
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
      or exists (
        select 1 from public_instrument_versions v
        where v.id = ref_id and ref_type = 'public_instrument_version' and v.author_id = auth.uid()
      )
    )
  );

-- RPC de flux editorial -- mateix patro exacte que create_public_tray/
-- approve_public_tray_version (schema_v29). my_is_active_contributor()/
-- my_is_reviewer_or_above() ja son coalesced a boolean (mai NULL), aixi que
-- `if not <helper>() then` es segur per disseny -- no reincideix en el
-- bypass de NULL corregit a schema_v47_authz_null_bypass_fix.sql (aquell
-- nomes afectava el patro `my_workspace_role(x) not in (llista)`, que aqui
-- no es fa servir).

create or replace function create_public_instrument()
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instrument_id uuid;
begin
  if not my_is_active_contributor() then
    raise exception 'Nomes un col·laborador actiu pot proposar contingut';
  end if;

  insert into public_instruments (created_by) values (auth.uid()) returning id into v_instrument_id;

  insert into public_instrument_versions (instrument_id, version_number, status, author_id)
  values (v_instrument_id, 1, 'draft', auth.uid());

  return v_instrument_id;
end;
$$;

create or replace function submit_public_instrument_version_for_review(p_version_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public_instrument_versions
  set status = 'in_review'
  where id = p_version_id and status = 'draft' and author_id = auth.uid();

  if not found then
    raise exception 'Version no valida per enviar a revisio';
  end if;
end;
$$;

create or replace function approve_public_instrument_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_instrument_id uuid;
begin
  if not my_is_reviewer_or_above() then
    raise exception 'Nomes qui revisa pot aprovar';
  end if;

  select instrument_id into v_instrument_id from public_instrument_versions
  where id = p_version_id and status = 'in_review';

  if v_instrument_id is null then
    raise exception 'Version no valida o no esta en revisio';
  end if;

  update public_instrument_versions set status = 'archived'
  where instrument_id = v_instrument_id and status = 'published';

  update public_instrument_versions
  set status = 'published', approved_by = auth.uid(), approved_at = now(),
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  update public_instruments set published_version_id = p_version_id where id = v_instrument_id;
end;
$$;

create or replace function reject_public_instrument_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not my_is_reviewer_or_above() then
    raise exception 'Nomes qui revisa pot rebutjar';
  end if;

  update public_instrument_versions
  set status = 'draft', comment = coalesce(p_review_comment, comment)
  where id = p_version_id and status = 'in_review';

  if not found then
    raise exception 'Version no valida o no esta en revisio';
  end if;
end;
$$;

-- Grants: revoke explicit de anon des del principi (no nomes de public) --
-- aplicant ja la lliço de schema_v47: Supabase concedeix EXECUTE a anon
-- directament en crear la funcio, al marge del pseudo-rol PUBLIC.

revoke all on function create_public_instrument() from public;
revoke all on function create_public_instrument() from anon;
grant execute on function create_public_instrument() to authenticated;

revoke all on function submit_public_instrument_version_for_review(uuid) from public;
revoke all on function submit_public_instrument_version_for_review(uuid) from anon;
grant execute on function submit_public_instrument_version_for_review(uuid) to authenticated;

revoke all on function approve_public_instrument_version(uuid, text) from public;
revoke all on function approve_public_instrument_version(uuid, text) from anon;
grant execute on function approve_public_instrument_version(uuid, text) to authenticated;

revoke all on function reject_public_instrument_version(uuid, text) from public;
revoke all on function reject_public_instrument_version(uuid, text) from anon;
grant execute on function reject_public_instrument_version(uuid, text) to authenticated;

-- Storage: bucket public (a diferencia de custom-instrument-photos, que es
-- privat) -- coherent amb la decisio de foto "pujada amb avis" en comptes
-- de llicencia verificada: no cal restringir la lectura a cap organitzacio,
-- es contingut destinat a ser public des del principi.

insert into storage.buckets (id, name, public)
values ('public-instrument-photos', 'public-instrument-photos', true)
on conflict do nothing;

-- Convencio de ruta: {user_id}/{fitxer} -- nomes cal saber qui n'es l'autor
-- per protegir l'escriptura; la lectura ja es publica (bucket public=true).

drop policy if exists "public_instrument_photos_select" on storage.objects;
create policy "public_instrument_photos_select" on storage.objects
  for select using (bucket_id = 'public-instrument-photos');

drop policy if exists "public_instrument_photos_insert" on storage.objects;
create policy "public_instrument_photos_insert" on storage.objects
  for insert with check (
    bucket_id = 'public-instrument-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
    and my_is_active_contributor()
  );

drop policy if exists "public_instrument_photos_update" on storage.objects;
create policy "public_instrument_photos_update" on storage.objects
  for update using (
    bucket_id = 'public-instrument-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

drop policy if exists "public_instrument_photos_delete" on storage.objects;
create policy "public_instrument_photos_delete" on storage.objects
  for delete using (
    bucket_id = 'public-instrument-photos'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
