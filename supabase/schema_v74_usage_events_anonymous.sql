-- schema_v74: analítica d'ús anònima.
--
-- Fins ara cada event (vista, cerca, obertura) es guardava amb user_id, l'hora
-- exacta i el text sencer de la cerca. Cap estadística no fa servir user_id
-- ni l'hora (organization_usage_stats compta per finestres de 30 dies), així
-- que es guardava més del necessari. A partir d'ara:
--   * user_id sempre null (no se sap qui ha fet què);
--   * created_at arrodonit al dia (sense hora ni ordre dins del dia);
--   * la cerca, retallada a 60 caràcters.
-- organization_id es manté: alimenta el panell del grup, no identifica ningú.
-- Ho explica a la persona usuària DataCollectionScreen (Perfil).

create or replace function record_usage_event(
  p_event_type text,
  p_ref_type text default null,
  p_ref_id text default null,
  p_query text default null,
  p_utm_source text default null,
  p_utm_medium text default null,
  p_utm_campaign text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if p_event_type not in ('view', 'search', 'search_zero_results', 'app_open') then
    raise exception 'Tipo de evento no valido';
  end if;
  insert into usage_events (
    organization_id, user_id, event_type, ref_type, ref_id, query,
    utm_source, utm_medium, utm_campaign, created_at
  )
  values (
    my_hospital_id(), null, p_event_type, p_ref_type, p_ref_id, left(nullif(trim(p_query), ''), 60),
    p_utm_source, p_utm_medium, p_utm_campaign, date_trunc('day', now())
  );
end;
$$;

-- Dades ja guardades: mateixa anonimització. IRREVERSIBLE.
-- 1) Previsualitza quantes files canviaran:
--    select count(*) filter (where user_id is not null) as amb_usuari,
--           count(*) filter (where created_at <> date_trunc('day', created_at)) as amb_hora,
--           count(*) filter (where length(query) > 60) as cerques_llargues
--    from usage_events;
-- 2) Aplica-ho:
update usage_events
set user_id = null,
    created_at = date_trunc('day', created_at),
    query = left(query, 60)
where user_id is not null
   or created_at <> date_trunc('day', created_at)
   or length(query) > 60;
