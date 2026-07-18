-- Corrige "infinite recursion detected in policy for relation profiles".
-- Causa: las políticas de profiles de schema_v2 comparan contra un subquery
-- sobre la propia tabla profiles, lo que Postgres no puede evaluar sin recursión.
-- Solución: funciones security definer (ejecutadas como el owner, que en
-- Supabase es un rol que salta RLS) para leer el hospital/admin del usuario
-- actual sin re-disparar las políticas de profiles.

create or replace function my_hospital_id()
returns uuid
language sql
security definer
stable
set search_path = public
as $$
  select hospital_id from profiles where id = auth.uid()
$$;

create or replace function my_is_hospital_admin()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select coalesce((select is_admin from profiles where id = auth.uid()), false)
$$;

drop policy if exists "profiles_select_same_hospital" on profiles;
create policy "profiles_select_same_hospital" on profiles
  for select using (
    auth.uid() = id
    or hospital_id = my_hospital_id()
  );

drop policy if exists "profiles_update_own_or_admin" on profiles;
create policy "profiles_update_own_or_admin" on profiles
  for update using (
    auth.uid() = id
    or (hospital_id = my_hospital_id() and my_is_hospital_admin())
  );

-- De paso, usar la misma función en preference_cards y hospitals evita el
-- mismo riesgo si en el futuro se anidan políticas parecidas.
drop policy if exists "cards_select_same_hospital" on preference_cards;
create policy "cards_select_same_hospital" on preference_cards
  for select using (hospital_id = my_hospital_id());

drop policy if exists "cards_insert_same_hospital" on preference_cards;
create policy "cards_insert_same_hospital" on preference_cards
  for insert with check (hospital_id = my_hospital_id());

drop policy if exists "cards_update_same_hospital" on preference_cards;
create policy "cards_update_same_hospital" on preference_cards
  for update using (hospital_id = my_hospital_id());

drop policy if exists "cards_delete_same_hospital" on preference_cards;
create policy "cards_delete_same_hospital" on preference_cards
  for delete using (hospital_id = my_hospital_id());

drop policy if exists "hospitals_update_by_admin" on hospitals;
create policy "hospitals_update_by_admin" on hospitals
  for update using (id = my_hospital_id() and my_is_hospital_admin());
