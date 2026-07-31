-- Fase D (1/2): roles asignados a equipos + auditoria de login.
--
-- Hasta ahora un rol de espacio (workspace_members) solo se podia asignar a
-- una persona a la vez -- si un equipo entero (p.ej. "Turno de tarde")
-- necesitaba acceso de editor a un espacio, habia que repetir la asignacion
-- usuario por usuario. "teams"/"team_members" introduce un grupo con nombre
-- dentro de la organizacion; "workspace_team_roles" asigna un rol de espacio
-- a ese equipo entero. my_workspace_role() ahora calcula el maximo privilegio
-- entre el rol directo de la persona y el heredado de cualquier equipo al
-- que pertenezca -- so no se pierde ninguna asignacion individual ya hecha.

create table if not exists teams (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now(),
  unique (organization_id, name)
);

alter table teams enable row level security;

create policy teams_select on teams
  for select using (organization_id = my_hospital_id());

create policy teams_insert on teams
  for insert with check (organization_id = my_hospital_id() and my_is_hospital_admin());

create policy teams_delete on teams
  for delete using (organization_id = my_hospital_id() and my_is_hospital_admin());

create table if not exists team_members (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references teams(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  unique (team_id, user_id)
);

create index if not exists team_members_team_idx on team_members (team_id);
create index if not exists team_members_user_idx on team_members (user_id);

alter table team_members enable row level security;

create policy team_members_select on team_members
  for select using (
    exists (select 1 from teams t where t.id = team_members.team_id and t.organization_id = my_hospital_id())
  );

create policy team_members_insert on team_members
  for insert with check (
    my_is_hospital_admin()
    and exists (select 1 from teams t where t.id = team_members.team_id and t.organization_id = my_hospital_id())
  );

create policy team_members_delete on team_members
  for delete using (
    my_is_hospital_admin()
    and exists (select 1 from teams t where t.id = team_members.team_id and t.organization_id = my_hospital_id())
  );

create table if not exists workspace_team_roles (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  team_id uuid not null references teams(id) on delete cascade,
  role text not null check (role in ('reader', 'editor', 'approver')),
  created_at timestamptz not null default now(),
  unique (workspace_id, team_id)
);

create index if not exists workspace_team_roles_workspace_idx on workspace_team_roles (workspace_id);
create index if not exists workspace_team_roles_team_idx on workspace_team_roles (team_id);

alter table workspace_team_roles enable row level security;

create policy workspace_team_roles_select on workspace_team_roles
  for select using (
    exists (select 1 from workspaces w where w.id = workspace_team_roles.workspace_id and w.organization_id = my_hospital_id())
  );

create policy workspace_team_roles_insert on workspace_team_roles
  for insert with check (
    my_is_hospital_admin()
    and exists (select 1 from workspaces w where w.id = workspace_team_roles.workspace_id and w.organization_id = my_hospital_id())
  );

create policy workspace_team_roles_update on workspace_team_roles
  for update using (
    my_is_hospital_admin()
    and exists (select 1 from workspaces w where w.id = workspace_team_roles.workspace_id and w.organization_id = my_hospital_id())
  );

create policy workspace_team_roles_delete on workspace_team_roles
  for delete using (
    my_is_hospital_admin()
    and exists (select 1 from workspaces w where w.id = workspace_team_roles.workspace_id and w.organization_id = my_hospital_id())
  );

-- my_workspace_role: se mantiene el nombre/firma (toda policy existente lo
-- invoca por OID, "create or replace" no rompe nada) -- ahora tambien mira
-- workspace_team_roles via team_members y devuelve el mayor privilegio entre
-- el rol directo y el de equipo (approver > editor > reader).
create or replace function my_workspace_role(p_workspace_id uuid)
returns text
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_direct_role text;
  v_team_role text;
begin
  select organization_id into v_organization_id from workspaces where id = p_workspace_id;
  if v_organization_id is null or v_organization_id <> my_hospital_id() then
    return null;
  end if;
  if my_is_hospital_admin() then
    return 'administrator';
  end if;

  select role into v_direct_role from workspace_members
    where workspace_id = p_workspace_id and user_id = auth.uid();

  select wtr.role into v_team_role
    from workspace_team_roles wtr
    join team_members tm on tm.team_id = wtr.team_id
    where wtr.workspace_id = p_workspace_id and tm.user_id = auth.uid()
    order by case wtr.role when 'approver' then 3 when 'editor' then 2 else 1 end desc
    limit 1;

  if v_direct_role is null then
    return v_team_role;
  end if;
  if v_team_role is null then
    return v_direct_role;
  end if;
  if (case v_direct_role when 'approver' then 3 when 'editor' then 2 else 1 end)
     >= (case v_team_role when 'approver' then 3 when 'editor' then 2 else 1 end) then
    return v_direct_role;
  end if;
  return v_team_role;
end;
$$;

create or replace function create_team(p_name text)
returns teams
language plpgsql
security definer
set search_path = public
as $$
declare
  v_team teams;
begin
  if not my_is_hospital_admin() then
    raise exception 'Solo un administrador del grupo puede crear equipos';
  end if;
  insert into teams (organization_id, name) values (my_hospital_id(), p_name)
  returning * into v_team;
  perform log_audit_event(my_hospital_id(), 'team_created', 'team', v_team.id, null, jsonb_build_object('name', p_name));
  return v_team;
end;
$$;

create or replace function delete_team(p_team_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not my_is_hospital_admin() then
    raise exception 'Solo un administrador del grupo puede eliminar equipos';
  end if;
  if not exists (select 1 from teams where id = p_team_id and organization_id = my_hospital_id()) then
    raise exception 'Equipo no encontrado';
  end if;
  perform log_audit_event(my_hospital_id(), 'team_deleted', 'team', p_team_id, null, '{}'::jsonb);
  delete from teams where id = p_team_id;
end;
$$;

create or replace function add_team_member(p_team_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not my_is_hospital_admin() then
    raise exception 'Solo un administrador del grupo puede gestionar equipos';
  end if;
  if not exists (select 1 from teams where id = p_team_id and organization_id = my_hospital_id()) then
    raise exception 'Equipo no encontrado';
  end if;
  if not exists (select 1 from profiles where id = p_user_id and organization_id = my_hospital_id()) then
    raise exception 'La persona no pertenece a este grupo';
  end if;
  insert into team_members (team_id, user_id) values (p_team_id, p_user_id)
  on conflict (team_id, user_id) do nothing;
  perform log_audit_event(my_hospital_id(), 'team_member_added', 'team', p_team_id, null, jsonb_build_object('user_id', p_user_id));
end;
$$;

create or replace function remove_team_member(p_team_id uuid, p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not my_is_hospital_admin() then
    raise exception 'Solo un administrador del grupo puede gestionar equipos';
  end if;
  delete from team_members where team_id = p_team_id and user_id = p_user_id
    and team_id in (select id from teams where organization_id = my_hospital_id());
  perform log_audit_event(my_hospital_id(), 'team_member_removed', 'team', p_team_id, null, jsonb_build_object('user_id', p_user_id));
end;
$$;

create or replace function set_workspace_team_role(p_workspace_id uuid, p_team_id uuid, p_role text)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
begin
  if p_role not in ('reader', 'editor', 'approver') then
    raise exception 'Rol no valido';
  end if;
  if not my_is_hospital_admin() then
    raise exception 'Solo un administrador del grupo puede cambiar roles';
  end if;
  select organization_id into v_organization_id from workspaces where id = p_workspace_id;
  if v_organization_id is null or v_organization_id <> my_hospital_id() then
    raise exception 'No autorizado';
  end if;
  if not exists (select 1 from teams where id = p_team_id and organization_id = v_organization_id) then
    raise exception 'Equipo no encontrado';
  end if;
  insert into workspace_team_roles (workspace_id, team_id, role)
  values (p_workspace_id, p_team_id, p_role)
  on conflict (workspace_id, team_id) do update set role = excluded.role;
  perform log_audit_event(v_organization_id, 'workspace_team_role_changed', 'workspace_team_role', p_team_id, p_workspace_id, jsonb_build_object('role', p_role));
end;
$$;

create or replace function remove_workspace_team_role(p_workspace_id uuid, p_team_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
begin
  if not my_is_hospital_admin() then
    raise exception 'Solo un administrador del grupo puede cambiar roles';
  end if;
  select organization_id into v_organization_id from workspaces where id = p_workspace_id;
  if v_organization_id is null or v_organization_id <> my_hospital_id() then
    raise exception 'No autorizado';
  end if;
  delete from workspace_team_roles where workspace_id = p_workspace_id and team_id = p_team_id;
  perform log_audit_event(v_organization_id, 'workspace_team_role_changed', 'workspace_team_role', p_team_id, p_workspace_id, jsonb_build_object('role', null));
end;
$$;

-- Auditoria de login: solo se llama desde Dart en AuthChangeEvent.signedIn
-- (nunca en initialSession, para no registrar un login en cada reapertura de
-- la app con sesion persistida). organization_id puede ser null (persona sin
-- grupo todavia) -- se inserta igual, aunque hoy nadie pueda leerlo (RLS de
-- audit_log exige ser admin de esa organizacion; no existe rol de
-- superadmin de plataforma todavia, no se inventa aqui).
create or replace function log_login_event()
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into audit_log (organization_id, actor_id, action, entity_type, entity_id)
  values (my_hospital_id(), auth.uid(), 'user_signed_in', 'profile', auth.uid());
end;
$$;
