-- Traduccions de contingut de la Biblioteca Publica (decisio explicita amb
-- el propietari: "opcio 2" -- mai traduccio automatica). Cada idioma es un
-- document/safata/instrument propi (la seva propia capçalera, el seu propi
-- cicle borrany->revisio->aprovacio pel Consell Editorial), no una versio
-- mes de l'original -- una capçalera nomes te un `published_version_id`,
-- aixi que dos idiomes publicats simultaniament NOMES poden ser dues
-- capçaleres diferents. Mateix criteri que les edicions per idioma de
-- Wikipedia (cada article es independent, enllaçat), i coherent amb "mai
-- enviar dades cliniques a un tercer" ja decidit per a l'assistent d'IA
-- (ADR-002): cap traduccio automatica via API externa.
--
-- `translation_group_id` agrupa totes les variants d'idioma d'"el mateix
-- contingut"; `locale` diu quin idioma es aquesta capçalera concreta.

alter table public_documents add column if not exists locale text not null default 'ca' check (locale in ('ca','es','en'));
alter table public_documents add column if not exists translation_group_id uuid;
alter table public_trays add column if not exists locale text not null default 'ca' check (locale in ('ca','es','en'));
alter table public_trays add column if not exists translation_group_id uuid;
alter table public_instruments add column if not exists locale text not null default 'ca' check (locale in ('ca','es','en'));
alter table public_instruments add column if not exists translation_group_id uuid;

-- Backfill: el contingut ja existent esdevé l'ancora del seu propi grup
-- (encara no te cap traduccio), mateix criteri que aplicara el trigger a
-- qualsevol fila nova creada sense translation_group_id explicit.
update public_documents set translation_group_id = id where translation_group_id is null;
update public_trays set translation_group_id = id where translation_group_id is null;
update public_instruments set translation_group_id = id where translation_group_id is null;

create or replace function set_own_translation_group()
returns trigger
language plpgsql
as $$
begin
  if new.translation_group_id is null then
    new.translation_group_id := new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists public_documents_translation_group on public_documents;
create trigger public_documents_translation_group
  before insert on public_documents
  for each row execute function set_own_translation_group();

drop trigger if exists public_trays_translation_group on public_trays;
create trigger public_trays_translation_group
  before insert on public_trays
  for each row execute function set_own_translation_group();

drop trigger if exists public_instruments_translation_group on public_instruments;
create trigger public_instruments_translation_group
  before insert on public_instruments
  for each row execute function set_own_translation_group();

alter table public_documents alter column translation_group_id set not null;
alter table public_trays alter column translation_group_id set not null;
alter table public_instruments alter column translation_group_id set not null;

create index if not exists public_documents_translation_group_idx on public_documents (translation_group_id);
create index if not exists public_trays_translation_group_idx on public_trays (translation_group_id);
create index if not exists public_instruments_translation_group_idx on public_instruments (translation_group_id);

-- RPC de proposta de traduccio -- 3 versions paral·leles (mateixa recepta
-- exacta que create_public_document/tray/instrument), no una de generica:
-- mateix criteri ja aplicat a ADR-004 (preferir N implementacions tipades
-- a una de dinamica que sacrifiqui integritat referencial i claredat de
-- RLS). Clona el contingut de la versio PUBLICADA d'origen com a punt de
-- partida per traduir (mai un esborrany aliè en curs), mai publica sola --
-- passa igual pel cicle draft->in_review->approved que qualsevol altra
-- proposta.

create or replace function propose_document_translation(p_source_document_id uuid, p_locale text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_source public_documents;
  v_source_version public_document_versions;
  v_new_document_id uuid;
begin
  if not my_is_active_contributor() then
    raise exception 'Nomes un col·laborador actiu pot proposar contingut';
  end if;
  if p_locale is null or p_locale not in ('ca', 'es', 'en') then
    raise exception 'Idioma no valid: %', p_locale;
  end if;

  select * into v_source from public_documents where id = p_source_document_id;
  if v_source.id is null then
    raise exception 'Document font no trobat';
  end if;
  if v_source.published_version_id is null then
    raise exception 'Nomes es pot traduir contingut ja publicat';
  end if;
  if v_source.locale = p_locale then
    raise exception 'Aquest document ja esta en aquest idioma';
  end if;
  if exists (
    select 1 from public_documents pd
    where pd.translation_group_id = v_source.translation_group_id
      and pd.locale = p_locale
      and pd.published_version_id is not null
  ) then
    raise exception 'Ja hi ha una traduccio publicada en aquest idioma';
  end if;

  select * into v_source_version from public_document_versions where id = v_source.published_version_id;

  insert into public_documents (kind, created_by, locale, translation_group_id)
  values (v_source.kind, auth.uid(), p_locale, v_source.translation_group_id)
  returning id into v_new_document_id;

  insert into public_document_versions (
    document_id, version_number, status, title, specialty_id, content, steps,
    author_id, based_on_version_id
  )
  values (
    v_new_document_id, 1, 'draft', v_source_version.title, v_source_version.specialty_id,
    v_source_version.content, v_source_version.steps,
    auth.uid(), v_source_version.id
  );

  return v_new_document_id;
end;
$$;

revoke all on function propose_document_translation(uuid, text) from public;
revoke all on function propose_document_translation(uuid, text) from anon;
grant execute on function propose_document_translation(uuid, text) to authenticated;

create or replace function propose_tray_translation(p_source_tray_id uuid, p_locale text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_source public_trays;
  v_source_version public_tray_versions;
  v_new_tray_id uuid;
begin
  if not my_is_active_contributor() then
    raise exception 'Nomes un col·laborador actiu pot proposar contingut';
  end if;
  if p_locale is null or p_locale not in ('ca', 'es', 'en') then
    raise exception 'Idioma no valid: %', p_locale;
  end if;

  select * into v_source from public_trays where id = p_source_tray_id;
  if v_source.id is null then
    raise exception 'Safata font no trobada';
  end if;
  if v_source.published_version_id is null then
    raise exception 'Nomes es pot traduir contingut ja publicat';
  end if;
  if v_source.locale = p_locale then
    raise exception 'Aquesta safata ja esta en aquest idioma';
  end if;
  if exists (
    select 1 from public_trays pt
    where pt.translation_group_id = v_source.translation_group_id
      and pt.locale = p_locale
      and pt.published_version_id is not null
  ) then
    raise exception 'Ja hi ha una traduccio publicada en aquest idioma';
  end if;

  select * into v_source_version from public_tray_versions where id = v_source.published_version_id;

  insert into public_trays (created_by, locale, translation_group_id)
  values (auth.uid(), p_locale, v_source.translation_group_id)
  returning id into v_new_tray_id;

  insert into public_tray_versions (
    tray_id, version_number, status, name, specialty_id, description, items, observations,
    author_id, based_on_version_id
  )
  values (
    v_new_tray_id, 1, 'draft', v_source_version.name, v_source_version.specialty_id,
    v_source_version.description, v_source_version.items, v_source_version.observations,
    auth.uid(), v_source_version.id
  );

  return v_new_tray_id;
end;
$$;

revoke all on function propose_tray_translation(uuid, text) from public;
revoke all on function propose_tray_translation(uuid, text) from anon;
grant execute on function propose_tray_translation(uuid, text) to authenticated;

create or replace function propose_instrument_translation(p_source_instrument_id uuid, p_locale text)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_source public_instruments;
  v_source_version public_instrument_versions;
  v_new_instrument_id uuid;
begin
  if not my_is_active_contributor() then
    raise exception 'Nomes un col·laborador actiu pot proposar contingut';
  end if;
  if p_locale is null or p_locale not in ('ca', 'es', 'en') then
    raise exception 'Idioma no valid: %', p_locale;
  end if;

  select * into v_source from public_instruments where id = p_source_instrument_id;
  if v_source.id is null then
    raise exception 'Instrument font no trobat';
  end if;
  if v_source.published_version_id is null then
    raise exception 'Nomes es pot traduir contingut ja publicat';
  end if;
  if v_source.locale = p_locale then
    raise exception 'Aquest instrument ja esta en aquest idioma';
  end if;
  if exists (
    select 1 from public_instruments pi
    where pi.translation_group_id = v_source.translation_group_id
      and pi.locale = p_locale
      and pi.published_version_id is not null
  ) then
    raise exception 'Ja hi ha una traduccio publicada en aquest idioma';
  end if;

  select * into v_source_version from public_instrument_versions where id = v_source.published_version_id;

  insert into public_instruments (created_by, locale, translation_group_id)
  values (auth.uid(), p_locale, v_source.translation_group_id)
  returning id into v_new_instrument_id;

  insert into public_instrument_versions (
    instrument_id, version_number, status, name, category, specialty_id, description, use_text, tip, photo_path,
    author_id, based_on_version_id
  )
  values (
    v_new_instrument_id, 1, 'draft', v_source_version.name, v_source_version.category, v_source_version.specialty_id,
    v_source_version.description, v_source_version.use_text, v_source_version.tip, v_source_version.photo_path,
    auth.uid(), v_source_version.id
  );

  return v_new_instrument_id;
end;
$$;

revoke all on function propose_instrument_translation(uuid, text) from public;
revoke all on function propose_instrument_translation(uuid, text) from anon;
grant execute on function propose_instrument_translation(uuid, text) to authenticated;

-- Reforç trobat en revisió adversarial abans d'aplicar a producció:
--
-- 1) L'EXISTS de "ja hi ha una traduccio publicada en aquest idioma" de cada
--    RPC de dalt nomes es comprova en el moment de PROPOSAR, mai en el
--    moment d'APROVAR -- dues persones podrien proposar independentment una
--    traduccio al mateix idioma abans que la primera s'aprovi, i totes dues
--    acabar publicades (`approve_public_document_version`/`_tray_/
--    `_instrument_version`, schema_v29/v48, nomes miren la seva propia
--    capçalera, mai les germanes del mateix `translation_group_id`). Índex
--    únic parcial: fa la invariant del propi capçalera d'aquest fitxer
--    ("dos idiomes publicats simultaniament nomes poden ser dues
--    capçaleres diferents") impossible de violar per construcció, en lloc
--    de confiar nomes en una comprovació d'aplicació que te una finestra de
--    carrera.
create unique index if not exists public_documents_one_published_per_locale
  on public_documents (translation_group_id, locale) where published_version_id is not null;
create unique index if not exists public_trays_one_published_per_locale
  on public_trays (translation_group_id, locale) where published_version_id is not null;
create unique index if not exists public_instruments_one_published_per_locale
  on public_instruments (translation_group_id, locale) where published_version_id is not null;

-- 2) Les policies d'INSERT de `public_documents`/`public_trays`/
--    `public_instruments` (schema_v29/v48) exigien nomes ser col·laborador
--    actiu i `created_by = auth.uid()` -- no deien res sobre
--    `translation_group_id`, així que un contribuidor actiu podia fer un
--    insert directe (sense passar per `propose_*_translation`) fixant
--    `translation_group_id` a qualsevol valor, saltant-se totes les
--    comprovacions de la RPC (origen publicat, idioma no ja cobert,
--    contingut clonat de l'origen real) i enllaçant contingut arbitrari a
--    un grup de traduccio que no és seu. Com que `propose_*_translation`
--    son `security definer` (s'executen amb els privilegis de qui les ha
--    creat, no de qui les crida), no depenen d'aquesta policy per
--    funcionar -- exigir `translation_group_id = id` nomes tanca la via
--    d'insert directe, sense afectar la via normal (el trigger
--    `set_own_translation_group` ja fixa `translation_group_id = id` quan
--    un client no l'especifica, que és sempre el cas fora d'aquestes RPC).
drop policy if exists "public_documents_insert" on public_documents;
create policy "public_documents_insert" on public_documents
  for insert with check (my_is_active_contributor() and created_by = auth.uid() and translation_group_id = id);

drop policy if exists "public_trays_insert" on public_trays;
create policy "public_trays_insert" on public_trays
  for insert with check (my_is_active_contributor() and created_by = auth.uid() and translation_group_id = id);

drop policy if exists "public_instruments_insert" on public_instruments;
create policy "public_instruments_insert" on public_instruments
  for insert with check (my_is_active_contributor() and created_by = auth.uid() and translation_group_id = id);
