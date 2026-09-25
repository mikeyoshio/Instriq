-- Wizard de creacio de grup/espai (EPIC de creixement, "que tipus d'equip
-- sou" + safata inicial de contingut recomanat). Tres peces independents:
--
-- 1) `register_hospital` guanya un tercer parametre `p_org_type` -- la
--    columna `organizations.org_type` ja existia des de
--    `schema_v20_organizations_rename.sql` (check constraint amb els 6
--    valors de la landing "Per a qui") pero mai s'escrivia des del client:
--    tota organitzacio creada fins ara ha quedat amb el valor per defecte
--    'hospital' encara que en realitat fos un equip petit o una universitat.
--    Com que afegim un parametre nou (no nomes canviem el cos), cal
--    `drop function` abans de `create` -- una signatura diferent no
--    reemplaça la funcio existent, en crea una de sobrecarregada.
--
-- 2) `workspaces.specialty_id`: cada espai pot indicar amb quina
--    especialitat es correspon (reutilitza `specialties`, ja poblada des de
--    Fase C) -- avui no hi ha cap manera de saber-ho, es dedueix nomes del
--    nom que hagi triat qui l'ha creat.
--
-- 3) `starter_sets`: taula d'index (specialitat -> safates publiques
--    recomanades) curada pel Consell Editorial, mateix criteri d'accés que
--    la resta de contingut de la Biblioteca Publica (lectura oberta,
--    escriptura reservada a reviewer/editorial_board). Deliberadament NO hi
--    ha cap RPC nova d'adopcio en bloc: el client ja pot cridar
--    `adopt_public_tray` un cop per fila seleccionada (TrayService.
--    adoptPublicTray ja existeix, schema_v42), aixi que afegir-hi una
--    segona via en SQL nomes duplicaria logica sense necessitat real.

drop function if exists register_hospital(text, text);

create or replace function register_hospital(p_name text, p_display_name text default null, p_org_type text default 'hospital')
returns table (id uuid, name text, invite_code text, cif text, owner_id uuid, org_type text)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text;
  v_org_id uuid;
  v_attempt int := 0;
begin
  if v_user_id is null then
    raise exception 'Cal iniciar sessió per registrar un grup.';
  end if;
  if exists (select 1 from profiles where id = v_user_id and organization_id is not null) then
    raise exception 'Ja pertanys a un grup -- surt-ne abans de crear-ne un altre.';
  end if;

  loop
    v_attempt := v_attempt + 1;
    select string_agg(substr(v_alphabet, (get_byte(gen_random_bytes(8), i) % length(v_alphabet)) + 1, 1), '')
      into v_code
      from generate_series(0, 7) i;
    begin
      insert into organizations (name, invite_code, created_by, owner_id, org_type)
      values (trim(p_name), v_code, v_user_id, v_user_id, p_org_type)
      returning organizations.id into v_org_id;
      exit;
    exception when unique_violation then
      if v_attempt >= 5 then
        raise exception 'No s''ha pogut generar un codi d''invitació únic. Torna-ho a provar.';
      end if;
    end;
  end loop;

  perform set_config('app.bypass_profile_guard', 'on', true);
  insert into profiles (id, organization_id, is_admin, display_name)
  values (v_user_id, v_org_id, true, p_display_name)
  on conflict (id) do update set
    organization_id = excluded.organization_id,
    is_admin = excluded.is_admin,
    display_name = coalesce(excluded.display_name, profiles.display_name);

  return query select o.id, o.name, o.invite_code, o.cif, o.owner_id, o.org_type from organizations o where o.id = v_org_id;
end;
$$;

revoke all on function register_hospital(text, text, text) from public;
revoke all on function register_hospital(text, text, text) from anon;
grant execute on function register_hospital(text, text, text) to authenticated;

alter table workspaces add column if not exists specialty_id uuid references specialties(id);

create table if not exists starter_sets (
  specialty_id uuid not null references specialties(id) on delete cascade,
  public_tray_id uuid not null references public_trays(id) on delete cascade,
  sort_order int not null default 0,
  created_at timestamptz not null default now(),
  primary key (specialty_id, public_tray_id)
);

create index if not exists starter_sets_specialty_idx on starter_sets (specialty_id, sort_order);

alter table starter_sets enable row level security;

drop policy if exists "starter_sets_select" on starter_sets;
create policy "starter_sets_select" on starter_sets for select using (true);

drop policy if exists "starter_sets_insert" on starter_sets;
create policy "starter_sets_insert" on starter_sets for insert with check (my_is_reviewer_or_above());

drop policy if exists "starter_sets_update" on starter_sets;
create policy "starter_sets_update" on starter_sets for update
  using (my_is_reviewer_or_above()) with check (my_is_reviewer_or_above());

drop policy if exists "starter_sets_delete" on starter_sets;
create policy "starter_sets_delete" on starter_sets for delete using (my_is_reviewer_or_above());
