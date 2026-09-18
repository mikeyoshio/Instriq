-- Buzon publico de sugerencias en la landing (sugerencias.html, no la
-- app): cualquier visitante puede proponer un cambio y votar los que ya
-- existen, sin cuenta. Mismo patron de acceso publico por anon key que
-- get_public_organization_count (schema_v36).
--
-- Identidad de quien vota: sin login real no hay forma de verificar
-- "este voto es tuyo", asi que se usa un client_id aleatorio generado
-- en el navegador y guardado en localStorage. Evita el voto doble por
-- accidente (recargar la pagina, volver a tocar el boton) y el voto
-- doble casual desde el mismo navegador; no evita un abuso deliberado
-- con multiples client_id. Mismo criterio de mitigacion parcial y
-- documentada, no resuelta del todo, que ya se acepta para el spam de
-- candidaturas en docs/EPIC_COMMUNITY_GOVERNANCE.md -- razonable a
-- esta escala.
--
-- Por eso mismo no hay policies de update/delete en ninguna de las dos
-- tablas: un voto es definitivo (no existe "quitar voto") y moderar
-- sugerencias (marcarlas 'shipped', borrar spam) lo hace la fundadora
-- a mano por SQL directo, igual que el arranque manual del Editorial
-- Board.

create table if not exists feature_suggestions (
  id uuid primary key default gen_random_uuid(),
  title text not null check (char_length(title) between 4 and 140),
  description text check (description is null or char_length(description) <= 1000),
  client_id text not null check (char_length(client_id) between 8 and 100),
  status text not null default 'open' check (status in ('open', 'planned', 'shipped', 'declined')),
  created_at timestamptz not null default now()
);

create index if not exists feature_suggestions_status_idx on feature_suggestions (status);
create index if not exists feature_suggestions_created_at_idx on feature_suggestions (created_at desc);

alter table feature_suggestions enable row level security;

drop policy if exists "feature_suggestions_select" on feature_suggestions;
create policy "feature_suggestions_select" on feature_suggestions
  for select using (true);

drop policy if exists "feature_suggestions_insert" on feature_suggestions;
create policy "feature_suggestions_insert" on feature_suggestions
  for insert to anon, authenticated
  with check (true);

create table if not exists feature_suggestion_votes (
  id uuid primary key default gen_random_uuid(),
  suggestion_id uuid not null references feature_suggestions(id) on delete cascade,
  client_id text not null check (char_length(client_id) between 8 and 100),
  created_at timestamptz not null default now(),
  unique (suggestion_id, client_id)
);

create index if not exists feature_suggestion_votes_suggestion_idx on feature_suggestion_votes (suggestion_id);

alter table feature_suggestion_votes enable row level security;

drop policy if exists "feature_suggestion_votes_select" on feature_suggestion_votes;
create policy "feature_suggestion_votes_select" on feature_suggestion_votes
  for select using (true);

drop policy if exists "feature_suggestion_votes_insert" on feature_suggestion_votes;
create policy "feature_suggestion_votes_insert" on feature_suggestion_votes
  for insert to anon, authenticated
  with check (true);

-- Una sola llamada: titulo + recuento de votos + si este client_id ya
-- voto, para que la landing pueda pintar el estado "ya votado" sin dar
-- la vuelta a la tabla de votos completa (esa no hace falta exponerla
-- aparte, aunque su SELECT tambien es publico).
create or replace function list_feature_suggestions(p_client_id text default null)
returns table (
  id uuid,
  title text,
  description text,
  status text,
  created_at timestamptz,
  vote_count bigint,
  voted_by_me boolean
)
language sql
stable
as $$
  select
    s.id,
    s.title,
    s.description,
    s.status,
    s.created_at,
    count(v.id) as vote_count,
    coalesce(bool_or(v.client_id = p_client_id), false) as voted_by_me
  from feature_suggestions s
  left join feature_suggestion_votes v on v.suggestion_id = s.id
  group by s.id
  order by count(v.id) desc, s.created_at desc;
$$;

revoke all on function list_feature_suggestions(text) from public;
grant execute on function list_feature_suggestions(text) to anon, authenticated;
