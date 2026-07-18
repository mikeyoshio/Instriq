-- Incremento sobre schema.sql: alta de hospitales por autoservicio (con CIF)
-- y rol de administrador de hospital. Ejecutar en el SQL Editor de Supabase
-- DESPUÉS de haber aplicado schema.sql.

alter table hospitals add column if not exists cif text;
alter table hospitals add column if not exists created_by uuid references auth.users(id) on delete set null;

-- Evita CIFs duplicados (un hospital ya registrado no puede registrarse dos veces).
create unique index if not exists hospitals_cif_unique_idx on hospitals (cif) where cif is not null;

alter table profiles add column if not exists is_admin boolean not null default false;

-- Alta de hospital por autoservicio: cualquier usuario autenticado puede crear uno.
drop policy if exists "hospitals_insert_self_service" on hospitals;
create policy "hospitals_insert_self_service" on hospitals
  for insert with check (auth.uid() is not null);

-- Solo el admin del hospital puede modificarlo (p. ej. regenerar el código de invitación).
drop policy if exists "hospitals_update_by_admin" on hospitals;
create policy "hospitals_update_by_admin" on hospitals
  for update using (
    id = (select hospital_id from profiles where id = auth.uid() and is_admin = true)
  );

-- Los miembros de un mismo hospital pueden verse entre sí (necesario para la
-- pantalla de gestión de miembros del admin).
drop policy if exists "profiles_select_own" on profiles;
create policy "profiles_select_same_hospital" on profiles
  for select using (
    auth.uid() = id
    or hospital_id = (select hospital_id from profiles where id = auth.uid())
  );

-- Solo el admin puede editar el perfil de otros miembros de su hospital
-- (usado para expulsar: pone hospital_id a null).
drop policy if exists "profiles_update_own" on profiles;
create policy "profiles_update_own_or_admin" on profiles
  for update using (
    auth.uid() = id
    or hospital_id = (select hospital_id from profiles where id = auth.uid() and is_admin = true)
  );
