-- Fase B: Mode de Treball unic (substitueix el perfil professional
-- multi-seleccio) + favorits + activitat recent, tots dos estrictament
-- personals (auth.uid() = user_id), no auditables ni lligats a workspace.

alter table profiles drop column if exists professional_profiles;
alter table profiles add column if not exists active_work_mode text;

create table if not exists favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  ref_type text not null check (ref_type in ('catalog', 'custom', 'group_document', 'tray')),
  ref_id text not null,
  created_at timestamptz not null default now(),
  unique (user_id, ref_type, ref_id)
);

alter table favorites enable row level security;

create policy favorites_select on favorites
  for select using (auth.uid() = user_id);

create policy favorites_insert on favorites
  for insert with check (auth.uid() = user_id);

create policy favorites_delete on favorites
  for delete using (auth.uid() = user_id);

create table if not exists recent_views (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  ref_type text not null check (ref_type in ('catalog', 'custom', 'group_document', 'tray')),
  ref_id text not null,
  viewed_at timestamptz not null default now(),
  unique (user_id, ref_type, ref_id)
);

alter table recent_views enable row level security;

create policy recent_views_select on recent_views
  for select using (auth.uid() = user_id);

create policy recent_views_upsert on recent_views
  for insert with check (auth.uid() = user_id);

create policy recent_views_update on recent_views
  for update using (auth.uid() = user_id);
