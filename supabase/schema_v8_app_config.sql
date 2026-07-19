-- Configuracion global de la app (no ligada a ningun hospital): version
-- minima/ultima publicada, para avisar de actualizaciones disponibles.
-- Fila unica (id siempre 1). Se edita a mano desde el SQL Editor al
-- publicar cada release, no desde la app.

create table if not exists app_config (
  id int primary key default 1,
  min_version text not null default '1.0.0',
  latest_version text not null default '1.0.0',
  message text,
  android_url text,
  ios_url text,
  updated_at timestamptz not null default now(),
  constraint app_config_singleton check (id = 1)
);

insert into app_config (id, min_version, latest_version)
values (1, '1.0.0', '1.0.0')
on conflict (id) do nothing;

alter table app_config enable row level security;

-- Lectura publica, incluso sin sesion: el aviso debe funcionar en modo invitado.
drop policy if exists "app_config_select_public" on app_config;
create policy "app_config_select_public" on app_config
  for select using (true);
