-- Fase D (2/2): analitica de uso real. Hasta ahora "analytics_service.dart"
-- solo media cobertura de contenido (cuantas tecnicas/protocolos hay
-- publicados por especialidad), nunca uso real -- que se consulta mas, que
-- se busca, que busqueda no encuentra nada, y cuanto trabajo propio tiene
-- cada persona a medio hacer. Se guarda a nivel de organizacion (no es
-- analitica de plataforma global), visible solo para quien administra esa
-- organizacion -- mismo criterio de privacidad que audit_log.

create table if not exists usage_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references organizations(id) on delete cascade,
  user_id uuid references auth.users(id) on delete set null,
  event_type text not null check (event_type in ('view', 'search', 'search_zero_results')),
  ref_type text,
  ref_id text,
  query text,
  created_at timestamptz not null default now()
);

create index if not exists usage_events_org_type_idx on usage_events (organization_id, event_type, created_at desc);

alter table usage_events enable row level security;

-- Insert: cualquier miembro de su propia organizacion (registrar su propio
-- uso). Select: solo admin de esa organizacion -- mismo criterio que
-- audit_log_select_admin, esto es analitica de equipo, no dato personal
-- expuesto a cualquiera.
create policy usage_events_insert on usage_events
  for insert with check (organization_id = my_hospital_id());

create policy usage_events_select on usage_events
  for select using (organization_id = my_hospital_id() and my_is_hospital_admin());

-- Registrar un evento no debe fallar nunca el flujo de quien lo dispara (una
-- vista o busqueda no es una accion critica) -- security definer + swallow
-- de errores en el propio Dart (no aqui), pero validamos organization_id
-- contra la sesion real para que nadie pueda escribir eventos en nombre de
-- otra organizacion via un RPC directo.
create or replace function record_usage_event(
  p_event_type text,
  p_ref_type text default null,
  p_ref_id text default null,
  p_query text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
begin
  v_organization_id := my_hospital_id();
  if v_organization_id is null then
    return; -- invitado o sin grupo: no hay a que organizacion atribuir el evento
  end if;
  if p_event_type not in ('view', 'search', 'search_zero_results') then
    raise exception 'Tipo de evento no valido';
  end if;
  insert into usage_events (organization_id, user_id, event_type, ref_type, ref_id, query)
  values (v_organization_id, auth.uid(), p_event_type, p_ref_type, p_ref_id, p_query);
end;
$$;

-- organization_usage_stats: mismo criterio que hospital_content_stats
-- (nombre con "hospital" por consistencia con el resto de RPCs de esta
-- ronda, aunque el parametro representa una organizacion) -- top vistas,
-- top busquedas, busquedas sin resultado, y borradores propios pendientes
-- por persona (limitado a las ultimas 30 dias, para que la vista no crezca
-- sin limite y siga reflejando actividad reciente).
create or replace function organization_usage_stats(p_organization_id uuid)
returns json
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_result json;
begin
  if p_organization_id is null or p_organization_id <> my_hospital_id() or not my_is_hospital_admin() then
    raise exception 'No autorizado';
  end if;

  select json_build_object(
    'top_viewed', (
      select coalesce(json_agg(row_to_json(t)), '[]'::json)
      from (
        select ref_type, ref_id, count(*) as view_count
        from usage_events
        where organization_id = p_organization_id
          and event_type = 'view'
          and created_at > now() - interval '30 days'
        group by ref_type, ref_id
        order by count(*) desc
        limit 10
      ) t
    ),
    'top_searches', (
      select coalesce(json_agg(row_to_json(t)), '[]'::json)
      from (
        select query, count(*) as search_count
        from usage_events
        where organization_id = p_organization_id
          and event_type = 'search'
          and query is not null and trim(query) <> ''
          and created_at > now() - interval '30 days'
        group by query
        order by count(*) desc
        limit 10
      ) t
    ),
    'zero_result_searches', (
      select coalesce(json_agg(row_to_json(t)), '[]'::json)
      from (
        select query, count(*) as search_count
        from usage_events
        where organization_id = p_organization_id
          and event_type = 'search_zero_results'
          and query is not null and trim(query) <> ''
          and created_at > now() - interval '30 days'
        group by query
        order by count(*) desc
        limit 10
      ) t
    ),
    'pending_drafts_by_person', (
      select coalesce(json_agg(row_to_json(t)), '[]'::json)
      from (
        select p.display_name, count(*) as draft_count
        from (
          select gdv.author_id
          from group_document_versions gdv
          join group_documents gd on gd.id = gdv.document_id
          where gd.organization_id = p_organization_id and gdv.status = 'draft'
          union all
          select tv.author_id
          from tray_versions tv
          join trays t on t.id = tv.tray_id
          where t.organization_id = p_organization_id and tv.status = 'draft'
          union all
          select pcv.author_id
          from preference_card_versions pcv
          join preference_cards pc on pc.id = pcv.card_id
          where pc.organization_id = p_organization_id and pcv.status = 'draft'
        ) drafts
        join profiles p on p.id = drafts.author_id
        group by p.id, p.display_name
        order by count(*) desc
      ) t
    )
  ) into v_result;

  return v_result;
end;
$$;
