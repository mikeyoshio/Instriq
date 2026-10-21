-- Vistes de creixement/activitat per consultar directament des del SQL
-- Editor o el Table Editor de Supabase (mai des de l'app): altes
-- d'usuaris i d'organitzacions per setmana, i usuaris actius per dia
-- (basat en l'event 'user_signed_in' que ja es registra a audit_log des
-- de schema_v21). A petició explícita de l'usuari, no es construeix cap
-- pantalla ni servei dins l'app per això -- nomes aquestes 3 vistes.
--
-- Deliberadament NO exposades via REST (sense grant a anon/authenticated):
-- nomes visibles per a qui es connecta amb el rol postgres/service_role
-- (el SQL Editor i el Table Editor del dashboard de Supabase hi tenen
-- accés per defecte). Mateix filtre demo/test/qa que ja fa servir
-- get_public_organization_count() (schema_v36) perquè les xifres de
-- creixement no quedin inflades per equips de prova.

create or replace view v_user_signups_weekly as
select
  date_trunc('week', created_at)::date as week_start,
  count(*)::int as new_users,
  sum(count(*)) over (order by date_trunc('week', created_at))::int as cumulative_users
from profiles
group by 1
order by 1;

create or replace view v_organization_growth_weekly as
select
  date_trunc('week', created_at)::date as week_start,
  count(*)::int as new_organizations,
  sum(count(*)) over (order by date_trunc('week', created_at))::int as cumulative_organizations
from organizations
where name !~* '(demo|test|qa|prova|prueba)'
group by 1
order by 1;

create or replace view v_active_users_daily as
select
  created_at::date as day,
  count(distinct actor_id)::int as active_users
from audit_log
where action = 'user_signed_in'
group by 1
order by 1;

revoke all on v_user_signups_weekly from public, anon, authenticated;
revoke all on v_organization_growth_weekly from public, anon, authenticated;
revoke all on v_active_users_daily from public, anon, authenticated;
