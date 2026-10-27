-- EPIC: Modo de Trabajo funcional -- Docente ve el progreso de aprendizaje
-- de su equipo (residentes/alumnos). `learning_progress` es de lectura
-- propia únicamente por RLS (ver schema_v8/progress_service.dart), así que
-- esta función hace de puerta: solo quien ya es admin de organización o
-- approver en algún espacio (mismo criterio que `canApproveAnyWorkspace` en
-- ProfileService, derivado de la misma forma) puede consultar el progreso
-- de otra persona, y solo para un equipo de su propia organización.

create or replace function team_learning_progress(p_team_id uuid)
returns table (
  user_id uuid,
  display_name text,
  learned_count bigint,
  due_count bigint,
  quiz_best_scores jsonb
)
language plpgsql
security definer
stable
set search_path = public
as $$
begin
  if not (
    my_is_hospital_admin()
    or exists (
      select 1 from workspace_members
      where user_id = auth.uid() and role = 'approver'
    )
  ) then
    raise exception 'No autorizado para ver el progreso de un equipo';
  end if;

  if not exists (
    select 1 from teams where id = p_team_id and organization_id = my_hospital_id()
  ) then
    raise exception 'Equipo no encontrado';
  end if;

  return query
  select
    tm.user_id,
    p.display_name,
    coalesce((
      select count(*) from learning_progress lp
      where lp.user_id = tm.user_id and lp.ref_type = 'catalog' and lp.learned_at is not null
    ), 0) as learned_count,
    coalesce((
      select count(*) from learning_progress lp
      where lp.user_id = tm.user_id and lp.ref_type = 'catalog'
        and lp.next_review_at is not null and lp.next_review_at <= now()
    ), 0) as due_count,
    coalesce(p.quiz_best_scores, '{}'::jsonb) as quiz_best_scores
  from team_members tm
  join profiles p on p.id = tm.user_id
  where tm.team_id = p_team_id;
end;
$$;

revoke all on function team_learning_progress(uuid) from public;
revoke all on function team_learning_progress(uuid) from anon;
grant execute on function team_learning_progress(uuid) to authenticated;
