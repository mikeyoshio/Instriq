-- Grups d'hospitals (cadenes amb multiples seus): una organitzacio pot
-- pertanyer opcionalment a un "hospital_groups" compartit amb organitzacions
-- germanes (p. ex. Quiron Teknon i Quiron Barcelona), que desbloqueja
-- visibilitat de NOMES LECTURA de les seves bandeixes i tecniques/protocols
-- PUBLICATS entre seus -- mai targetes de preferencia, mai instrumental
-- personalitzat (schema_v13, regla de producte/legal no negociable), mai
-- pertinenca compartida (un perfil segueix lligat a exactament una
-- organitzacio, com sempre). Disseny complet discutit i aprovat amb
-- l'usuari -- veure el pla a .claude/plans/kind-spinning-comet.md.

create table if not exists hospital_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  group_code text not null unique,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

alter table hospital_groups enable row level security;

alter table organizations
  add column if not exists group_id uuid references hospital_groups(id) on delete set null;

create or replace function my_group_id()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select group_id from organizations where id = my_hospital_id()
$$;

revoke all on function my_group_id() from public, anon;
grant execute on function my_group_id() to authenticated;

create policy "hospital_groups_select_member" on hospital_groups
  for select using (id = my_group_id());

-- register_hospital guanya 2 parametres opcionals nous, mutuament
-- excloents: p_new_group_name (ets la primera seu d'una cadena nova,
-- es crea hospital_groups + es genera un group_code nou) i p_group_code
-- (t'unexis a una cadena existent, es valida el codi i es reusa el seu
-- group_id). Amb tots dos null, comportament identic a avui (zero
-- regressio). Mateix patro exacte que schema_v49 ja va usar per afegir
-- p_org_type: cal `drop function` abans de `create` perque una signatura
-- diferent no reemplaça la funcio existent, en crea una de sobrecarregada.
drop function if exists register_hospital(text, text, text);

create or replace function register_hospital(
  p_name text,
  p_display_name text default null,
  p_org_type text default 'hospital',
  p_new_group_name text default null,
  p_group_code text default null
)
returns table (
  id uuid, name text, invite_code text, cif text, owner_id uuid, org_type text,
  group_id uuid, group_code text
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_alphabet text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text;
  v_group_code text;
  v_org_id uuid;
  v_group_id uuid;
  v_attempt int := 0;
begin
  if v_user_id is null then
    raise exception 'Cal iniciar sessió per registrar un grup.';
  end if;
  if exists (select 1 from profiles where id = v_user_id and organization_id is not null) then
    raise exception 'Ja pertanys a un grup -- surt-ne abans de crear-ne un altre.';
  end if;
  if p_new_group_name is not null and p_group_code is not null then
    raise exception 'Tria crear un grup nou o unir-te a un grup existent, no les dues coses.';
  end if;

  if p_new_group_name is not null then
    loop
      v_attempt := v_attempt + 1;
      select string_agg(substr(v_alphabet, (get_byte(gen_random_bytes(8), i) % length(v_alphabet)) + 1, 1), '')
        into v_group_code
        from generate_series(0, 7) i;
      begin
        insert into hospital_groups (name, group_code, created_by)
        values (trim(p_new_group_name), v_group_code, v_user_id)
        returning hospital_groups.id into v_group_id;
        exit;
      exception when unique_violation then
        if v_attempt >= 5 then
          raise exception 'No s''ha pogut generar un codi de grup únic. Torna-ho a provar.';
        end if;
      end;
    end loop;
  elsif p_group_code is not null then
    select hg.id, hg.group_code into v_group_id, v_group_code
      from hospital_groups hg
      where hg.group_code = upper(regexp_replace(p_group_code, '[\s-]', '', 'g'));
    if v_group_id is null then
      raise exception 'Codi de grup no vàlid.';
    end if;
  end if;

  v_attempt := 0;
  loop
    v_attempt := v_attempt + 1;
    select string_agg(substr(v_alphabet, (get_byte(gen_random_bytes(8), i) % length(v_alphabet)) + 1, 1), '')
      into v_code
      from generate_series(0, 7) i;
    begin
      insert into organizations (name, invite_code, created_by, owner_id, org_type, group_id)
      values (trim(p_name), v_code, v_user_id, v_user_id, p_org_type, v_group_id)
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

  return query
    select o.id, o.name, o.invite_code, o.cif, o.owner_id, o.org_type, o.group_id, v_group_code
    from organizations o where o.id = v_org_id;
end;
$$;

revoke all on function register_hospital(text, text, text, text, text) from public, anon;
grant execute on function register_hospital(text, text, text, text, text) to authenticated;

-- Llista blanca explicita de columnes segures de les organitzacions
-- germanes del meu grup -- mai invite_code/cif/owner_id (schema_v31 ja va
-- haver de tancar una fuita real amb aquestes columnes). `organizations`
-- NO guanya cap policy RLS addicional per aquest motiu.
create or replace function list_group_sibling_organizations()
returns table (id uuid, name text, org_type text)
language sql
security definer
stable
set search_path = public
as $$
  select o.id, o.name, o.org_type
  from organizations o
  where my_group_id() is not null
    and o.group_id = my_group_id()
    and o.id <> my_hospital_id();
$$;

revoke all on function list_group_sibling_organizations() from public, anon;
grant execute on function list_group_sibling_organizations() to authenticated;

-- 5 policies addicionals de NOMES LECTURA. Postgres combina policies
-- PERMISSIVE amb OR per a `select`, aixi que aquestes son purament
-- additives: no toquen ni debiliten cap policy existent (ni les de
-- select "del meu propi workspace", ni cap d'insert/update/delete).
create policy "workspaces_select_group_sibling" on workspaces
  for select using (
    my_group_id() is not null
    and organization_id in (select o.id from organizations o where o.group_id = my_group_id())
  );

create policy "trays_select_group_sibling" on trays
  for select using (
    my_group_id() is not null
    and organization_id in (select o.id from organizations o where o.group_id = my_group_id())
  );

create policy "tray_versions_select_group_sibling" on tray_versions
  for select using (
    status = 'published'
    and exists (
      select 1 from trays t
      join organizations o on o.id = t.organization_id
      where t.id = tray_versions.tray_id
        and my_group_id() is not null
        and o.group_id = my_group_id()
    )
  );

create policy "group_documents_select_group_sibling" on group_documents
  for select using (
    my_group_id() is not null
    and organization_id in (select o.id from organizations o where o.group_id = my_group_id())
  );

create policy "group_document_versions_select_group_sibling" on group_document_versions
  for select using (
    status = 'published'
    and exists (
      select 1 from group_documents gd
      join organizations o on o.id = gd.organization_id
      where gd.id = group_document_versions.document_id
        and my_group_id() is not null
        and o.group_id = my_group_id()
    )
  );

-- Adopcio (copia puntual) d'una bandeja d'una seu germana del mateix grup
-- cap al meu propi espai -- nomes bandeges, no tecniques/protocols (mateix
-- criteri ja aplicat a adopt_public_tray: no generalitzar per a un sol
-- consumidor). Deliberadament NO toca upstream_public_tray_id/
-- upstream_adopted_version_id/sync_status: aquestes columnes estan
-- lligades per un check constraint pensat nomes per a l'origen
-- public_trays -- una adopcio entre seus es una copia puntual, no una
-- relacio sincronitzable.
create or replace function adopt_group_tray(p_source_tray_id uuid, p_target_workspace_id uuid)
returns tray_versions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_target_org uuid;
  v_target_group uuid;
  v_source_org uuid;
  v_source_group uuid;
  v_source_version_id uuid;
  v_source_version tray_versions;
  v_new_tray_id uuid;
  v_new_version tray_versions;
begin
  if my_workspace_role(p_target_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autoritzat per adoptar contingut en aquest espai';
  end if;

  select organization_id into v_target_org from workspaces where id = p_target_workspace_id;
  if v_target_org is null then
    raise exception 'Espai no trobat';
  end if;
  select group_id into v_target_group from organizations where id = v_target_org;

  select organization_id, published_version_id into v_source_org, v_source_version_id
    from trays where id = p_source_tray_id;
  if v_source_org is null then
    raise exception 'Bandeja d''origen no trobada';
  end if;
  select group_id into v_source_group from organizations where id = v_source_org;

  if v_target_group is null or v_source_group is null or v_target_group <> v_source_group then
    raise exception 'Aquesta safata no pertany al mateix grup.';
  end if;
  if v_source_version_id is null then
    raise exception 'Aquesta safata encara no té cap versió publicada.';
  end if;

  select * into v_source_version from tray_versions where id = v_source_version_id;

  insert into trays (organization_id, workspace_id, created_by)
  values (v_target_org, p_target_workspace_id, auth.uid())
  returning id into v_new_tray_id;

  insert into tray_versions (
    tray_id, version_number, status, name, specialty_id, description, items, observations,
    author_id, comment
  )
  values (
    v_new_tray_id, 1, 'draft', v_source_version.name, v_source_version.specialty_id,
    v_source_version.description, v_source_version.items, v_source_version.observations,
    auth.uid(), 'Importada des d''un altre centre del grup'
  )
  returning * into v_new_version;

  perform log_audit_event(
    v_target_org,
    'tray_adopted_from_group',
    'tray',
    v_new_tray_id,
    p_target_workspace_id,
    jsonb_build_object('source_tray_id', p_source_tray_id, 'source_organization_id', v_source_org)
  );

  return v_new_version;
end;
$$;

revoke all on function adopt_group_tray(uuid, uuid) from public, anon;
grant execute on function adopt_group_tray(uuid, uuid) to authenticated;
