-- Cuestionarios configurables por supervisor/docente (propuesta de producto
-- auditada esta sesión, confirmada como "no implementada" -- QuizScreen solo
-- generaba 10 preguntas aleatorias de todo el catálogo).
--
-- Deliberadamente ligera: sin versionado ni flujo de aprobación (es
-- configuración de un supervisor, no contenido clínico a revisar) -- mismo
-- criterio exacto que `favorites`/`content_follows`. Solo instrumentos de
-- catálogo (no instrumental personalizado del equipo, mismo motivo ya
-- documentado en schema_v59/tray_detail_screen.dart: modelo de datos
-- distinto, sin el mismo conjunto de campos).
create table if not exists team_quizzes (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references teams(id) on delete cascade,
  title text not null check (char_length(trim(title)) > 0),
  instrument_ids jsonb not null default '[]'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists team_quizzes_team_idx on team_quizzes (team_id);

alter table team_quizzes enable row level security;

-- Lectura abierta a cualquier miembro de la misma organización -- mismo
-- criterio que `teams` en si (schema_v21_teams_and_login_audit.sql: un
-- equipo con nombre es visible a toda la organización, no solo a sus
-- miembros), y encaja con el propósito de un cuestionario de formación.
create policy "team_quizzes_select" on team_quizzes
  for select using (
    exists (select 1 from teams t where t.id = team_quizzes.team_id and t.organization_id = my_hospital_id())
  );

-- Crear/borrar: mismo umbral exacto que team_learning_progress (admin de
-- organización, o approver en algún espacio) -- quien ya puede supervisar
-- el progreso de un equipo, puede prepararle material de formación.
create policy "team_quizzes_insert" on team_quizzes
  for insert with check (
    (
      my_is_hospital_admin()
      or exists (select 1 from workspace_members where user_id = auth.uid() and role = 'approver')
    )
    and exists (select 1 from teams t where t.id = team_id and t.organization_id = my_hospital_id())
  );

create policy "team_quizzes_delete" on team_quizzes
  for delete using (
    my_is_hospital_admin()
    or exists (select 1 from workspace_members where user_id = auth.uid() and role = 'approver')
  );
