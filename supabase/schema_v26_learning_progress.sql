-- Sincronizar el progreso de aprendizaje a Supabase (prerrequisito de
-- EPIC 8 · Contextual Learning): antes solo vivia en shared_preferences,
-- por dispositivo, sin sincronizar entre sesiones. Mismo patron que
-- `favorites` (schema_v18): tabla por usuario, ref_type/ref_id polimorfico,
-- RLS por auth.uid() = user_id, sin RPC (no es una accion sensible).
--
-- box/next_review_at viven en la misma fila que learned_at: son "mi
-- relacion con este instrumento" -- se puede repasar (EPIC 8) algo que aun
-- no se ha marcado como aprendido.
create table if not exists learning_progress (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  ref_type text not null check (ref_type in ('catalog', 'custom')),
  ref_id text not null,
  learned_at timestamptz,
  box int not null default 1,
  next_review_at timestamptz,
  unique (user_id, ref_type, ref_id)
);

create index if not exists learning_progress_user_idx on learning_progress (user_id);

alter table learning_progress enable row level security;

drop policy if exists "learning_progress_select" on learning_progress;
create policy "learning_progress_select" on learning_progress for select using (auth.uid() = user_id);

drop policy if exists "learning_progress_insert" on learning_progress;
create policy "learning_progress_insert" on learning_progress for insert with check (auth.uid() = user_id);

drop policy if exists "learning_progress_update" on learning_progress;
create policy "learning_progress_update" on learning_progress for update using (auth.uid() = user_id);

drop policy if exists "learning_progress_delete" on learning_progress;
create policy "learning_progress_delete" on learning_progress for delete using (auth.uid() = user_id);

-- Mejores puntuaciones de quiz por categoria, mismo criterio que
-- active_work_mode (schema_v18): una preferencia simple en profiles, sin
-- tabla ni RPC aparte.
alter table profiles add column if not exists quiz_best_scores jsonb not null default '{}'::jsonb;
