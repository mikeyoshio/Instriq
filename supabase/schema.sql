-- Esquema para compartir tarjetas de preferencia entre enfermeras del mismo hospital.
-- Ejecutar en el SQL Editor del proyecto Supabase.

create extension if not exists "pgcrypto";

create table if not exists hospitals (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  invite_code text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  hospital_id uuid references hospitals(id) on delete set null,
  display_name text,
  created_at timestamptz not null default now()
);

create table if not exists preference_cards (
  id uuid primary key default gen_random_uuid(),
  hospital_id uuid not null references hospitals(id) on delete cascade,
  surgeon_name text not null,
  procedure_name text not null,
  items jsonb not null default '[]'::jsonb,
  general_notes text,
  validated boolean not null default false,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists preference_cards_hospital_idx on preference_cards(hospital_id);

-- RLS: cada enfermera solo ve/edita tarjetas de su propio hospital.
alter table hospitals enable row level security;
alter table profiles enable row level security;
alter table preference_cards enable row level security;

create policy "hospitals_select_by_invite" on hospitals
  for select using (true); -- necesario para validar el código de invitación antes de unirse

create policy "profiles_select_own" on profiles
  for select using (auth.uid() = id);

create policy "profiles_update_own" on profiles
  for update using (auth.uid() = id);

create policy "profiles_insert_own" on profiles
  for insert with check (auth.uid() = id);

create policy "cards_select_same_hospital" on preference_cards
  for select using (
    hospital_id = (select hospital_id from profiles where id = auth.uid())
  );

create policy "cards_insert_same_hospital" on preference_cards
  for insert with check (
    hospital_id = (select hospital_id from profiles where id = auth.uid())
  );

create policy "cards_update_same_hospital" on preference_cards
  for update using (
    hospital_id = (select hospital_id from profiles where id = auth.uid())
  );

create policy "cards_delete_same_hospital" on preference_cards
  for delete using (
    hospital_id = (select hospital_id from profiles where id = auth.uid())
  );
