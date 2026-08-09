-- Auditoria de seguretat (2026-08): 3 forats crítics trobats, tots amb la
-- mateixa arrel -- `profiles`/`organizations` confiaven en RLS de fila sencera
-- per a operacions que en realitat necessitaven restricció de columna o
-- d'abast, i dues escriptures sensibles es feien directament des del client
-- Dart en lloc de passar per una funció que verifiqués de veritat qui pot
-- fer què. Aquesta migració no canvia cap comportament visible per a un ús
-- legítim -- reprodueix exactament el que `registerHospital`/
-- `joinHospitalWithCode`/`removeMember` ja feien, però ara des del servidor.

-- 1) CRÍTIC -- auto-promoció a admin / bretxa entre organitzacions.
-- "profiles_update_own_or_admin" (schema_v3_fix_rls_recursion.sql) permet a
-- qualsevol usuari actualitzar la seva pròpia fila sense `with check`, així
-- que un client pot fer `update profiles set is_admin=true` o reescriure el
-- seu propi `organization_id` directament, saltant-se `set_hospital_admin` i
-- tot el model de pertinença a organització. RLS és per fila, no per
-- columna -- la manera correcta de bloquejar columnes concretes és un
-- trigger. Les funcions legítimes que SÍ necessiten canviar aquestes dues
-- columnes (definides més avall) activen un flag de transacció abans de
-- fer-ho; qualsevol altra escriptura (directa des del client) queda
-- bloquejada encara que la RLS de fila l'hagués permès.
create or replace function guard_profile_privilege_columns()
returns trigger
language plpgsql
as $$
begin
  if (new.is_admin is distinct from old.is_admin or new.organization_id is distinct from old.organization_id)
     and coalesce(current_setting('app.bypass_profile_guard', true), '') <> 'on' then
    raise exception 'No es pot modificar is_admin ni organization_id directament -- cal fer-ho a través de les funcions autoritzades (registrar/unir-se a un grup, promoure/treure admin, expulsar un membre).';
  end if;
  return new;
end;
$$;

drop trigger if exists profiles_guard_privilege_columns on profiles;
create trigger profiles_guard_privilege_columns
before update on profiles
for each row execute function guard_profile_privilege_columns();

-- 2) CRÍTIC -- `organizations` és llegible per tothom (`anon` inclòs) i
-- exposa invite_code + cif + owner_id de totes les organitzacions. Naixia
-- de la necessitat de validar un codi d'invitació abans d'unir-se -- ara
-- aquesta validació la fa `join_hospital_with_code()` (definida més avall,
-- security definer, sense passar per RLS), així que el client ja no
-- necessita poder llegir organitzacions alienes.
drop policy if exists "hospitals_select_by_invite" on organizations;
create policy "organizations_select_own" on organizations
  for select using (id = my_hospital_id());

-- 3) Registrar un grup nou -- reemplaça l'insert+upsert directe que feia
-- `ProfileService.registerHospital()`. Mateix codi d'invitació únic amb
-- reintent (fins 5 cops), mateixa forma de retorn que `Hospital.fromRow`
-- espera. Afegeix una comprovació que abans no hi havia: no es pot registrar
-- un grup nou si ja en tens un (evita un estat inconsistent, no bloqueja cap
-- ús legítim d'avui).
create or replace function register_hospital(p_name text, p_display_name text default null)
returns table (id uuid, name text, invite_code text, cif text, owner_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  -- Mateix alfabet que `generateInviteCode()` (lib/utils/invite_code.dart):
  -- sense 0/O ni 1/I, per a codis llegibles a mà.
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
      insert into organizations (name, invite_code, created_by, owner_id)
      values (trim(p_name), v_code, v_user_id, v_user_id)
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

  return query select o.id, o.name, o.invite_code, o.cif, o.owner_id from organizations o where o.id = v_org_id;
end;
$$;

-- 4) Unir-se a un grup amb codi -- reemplaça la consulta directa a
-- `organizations` (que exigia llegir-les totes, veure #2) + l'upsert directe
-- de `ProfileService.joinHospitalWithCode()`. Retorna 0 files si el codi no
-- existeix (el client ja distingeix aquest cas comprovant una llista buida).
create or replace function join_hospital_with_code(p_invite_code text, p_display_name text default null)
returns table (id uuid, name text, invite_code text, cif text, owner_id uuid)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_normalized text := upper(regexp_replace(p_invite_code, '[\s-]', '', 'g'));
  v_org_id uuid;
begin
  if v_user_id is null then
    raise exception 'Cal iniciar sessió per unir-se a un grup.';
  end if;
  if exists (select 1 from profiles where id = v_user_id and organization_id is not null) then
    raise exception 'Ja pertanys a un grup -- surt-ne abans d''unir-te a un altre.';
  end if;

  select o.id into v_org_id from organizations o where o.invite_code = v_normalized;
  if v_org_id is null then
    return;
  end if;

  perform set_config('app.bypass_profile_guard', 'on', true);
  insert into profiles (id, organization_id, is_admin, display_name)
  values (v_user_id, v_org_id, false, p_display_name)
  on conflict (id) do update set
    organization_id = excluded.organization_id,
    is_admin = excluded.is_admin,
    display_name = coalesce(excluded.display_name, profiles.display_name);

  return query select o.id, o.name, o.invite_code, o.cif, o.owner_id from organizations o where o.id = v_org_id;
end;
$$;

-- 5) CRÍTIC -- expulsar un membre no comprovava el seu rol al servidor.
-- `ProfileService.removeMember()` feia `update profiles ... where id =
-- userId` directament; la UI amaga el botó per a admins/propietari
-- (`manage_hospital_screen.dart`) però res ho garantia al servidor -- un
-- admin (no calia ser propietari) podia expulsar un altre admin o la
-- propietària/el propietari cridant la mateixa crida directament. Aquest RPC
-- reprodueix exactament el que la UI ja prometia, ara de veritat.
create or replace function remove_hospital_member(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_owner_id uuid;
begin
  if not my_is_hospital_admin() then
    raise exception 'Només un administrador del grup pot expulsar membres';
  end if;

  select organization_id into v_organization_id from profiles where id = p_user_id;
  if v_organization_id is null or v_organization_id <> my_hospital_id() then
    raise exception 'La persona indicada no pertany a aquest grup';
  end if;

  select owner_id into v_owner_id from organizations where id = v_organization_id;
  if p_user_id = v_owner_id then
    raise exception 'No es pot expulsar la propietària o el propietari del grup';
  end if;
  if exists (select 1 from profiles where id = p_user_id and is_admin = true) then
    raise exception 'No es pot expulsar una altra administradora o administrador -- primer treu-li el rol d''admin';
  end if;

  perform set_config('app.bypass_profile_guard', 'on', true);
  update profiles set organization_id = null, is_admin = false where id = p_user_id;

  perform log_audit_event(v_organization_id, 'hospital_member_removed', 'profile', p_user_id, null, '{}'::jsonb);
end;
$$;

-- 6) CRÍTIC (arreglat de pas) -- `set_hospital_admin` (schema_v30) ja
-- comprovava que qui truca és admin i que el destinatari és del mateix grup,
-- però (a) mai activava el flag del punt #1, així que el nou trigger l'hauria
-- bloquejat, i (b) la comprovació de "no treure l'últim admin" era una
-- condició de carrera (TOCTOU): dues crides simultànies podien passar totes
-- dues la comprovació de comptatge abans que cap fes el seu update, deixant
-- l'organització sense cap admin. Es bloquegen ara les files d'admin
-- d'aquesta organització (`for update`) abans de comptar-les, així una
-- segona transacció concurrent espera a que la primera acabi i veu el
-- recompte ja actualitzat.
create or replace function set_hospital_admin(p_user_id uuid, p_is_admin boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_previous_is_admin boolean;
  v_admin_count int;
begin
  if not my_is_hospital_admin() then
    raise exception 'Solo un administrador del grupo puede cambiar el rol de administrador';
  end if;

  select organization_id, is_admin into v_organization_id, v_previous_is_admin
  from profiles
  where id = p_user_id;

  if v_organization_id is null or v_organization_id <> my_hospital_id() then
    raise exception 'La persona indicada no pertenece a este grupo';
  end if;

  if p_is_admin = false and v_previous_is_admin then
    perform 1 from profiles where organization_id = v_organization_id and is_admin = true for update;

    select count(*) into v_admin_count
    from profiles
    where organization_id = v_organization_id and is_admin = true;

    if v_admin_count <= 1 then
      raise exception 'No se puede quitar el último administrador del grupo';
    end if;
  end if;

  perform set_config('app.bypass_profile_guard', 'on', true);
  update profiles set is_admin = p_is_admin where id = p_user_id;

  perform log_audit_event(
    v_organization_id,
    'hospital_admin_changed',
    'profile',
    p_user_id,
    null,
    jsonb_build_object('previous_is_admin', v_previous_is_admin, 'new_is_admin', p_is_admin)
  );
end;
$$;

-- 7) ALT -- `log_audit_event` no comprovava qui la crida: qualsevol usuari
-- autenticat podia injectar files d'auditoria falses a QUALSEVOL
-- organització (i, de rebot, disparar el webhook de notificacions push
-- enganxat a `audit_log`). Ara exigeix que l'organització indicada coincideixi
-- amb la del qui truca. A més, es treu el permís d'execució directa a
-- `anon`/`authenticated` -- només les altres funcions ja verificades (totes
-- propietat del mateix rol) poden cridar-la internament; un client no la pot
-- invocar mai directament via /rpc/log_audit_event.
create or replace function log_audit_event(
  p_organization_id uuid,
  p_action text,
  p_entity_type text,
  p_entity_id uuid,
  p_workspace_id uuid,
  p_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_organization_id <> my_hospital_id() then
    raise exception 'No es pot registrar un esdeveniment d''auditoria per a una altra organització';
  end if;
  insert into audit_log (organization_id, actor_id, action, entity_type, entity_id, workspace_id, metadata)
  values (p_organization_id, auth.uid(), p_action, p_entity_type, p_entity_id, p_workspace_id, coalesce(p_metadata, '{}'::jsonb));
end;
$$;

revoke execute on function log_audit_event(uuid, text, text, uuid, uuid, jsonb) from anon, authenticated;
