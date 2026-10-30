-- Amplia l'analitica d'us (schema_v23) en 2 punts demanats per l'usuari
-- (2026-10-30), independents entre si pero servits pel mateix event log:
--
-- 1) Fins ara `record_usage_event` descartava en silenci qualsevol vista o
--    cerca sense organitzacio ("invitado o sin grupo: no hay a que
--    organizacion atribuir el evento"), deixant fora precisament la majoria
--    de navegacio del cataleg -- una app gratuita, amb molt transit sense
--    compte. Es registra ara igual, amb organization_id nul. La consulta
--    agregada per organitzacio (`organization_usage_stats`) no canvia de
--    comportament -- segueix nomes mostrant les files de la propia
--    organitzacio a qui ja n'era admin. Les files sense organitzacio (ni les
--    de qualsevol altra organitzacio) nomes son consultables per SQL directe
--    contra el projecte real, igual que la resta d'analitica de plataforma
--    d'aquesta sessio -- no hi ha cap "admin de plataforma" a l'app.
--
-- 2) Nou event_type 'app_open' + 3 columnes utm_* per mesurar conversio real
--    del landing (clic a "Abre la app" amb utm_source/medium/campaign) cap a
--    una obertura real de l'app web -- abans no existia cap mecanisme per a
--    aixo. Mateixos noms de parametre que ja fa servir landing/index.html.

alter table usage_events alter column organization_id drop not null;

alter table usage_events add column if not exists utm_source text;
alter table usage_events add column if not exists utm_medium text;
alter table usage_events add column if not exists utm_campaign text;

alter table usage_events drop constraint usage_events_event_type_check;
alter table usage_events add constraint usage_events_event_type_check
  check (event_type in ('view', 'search', 'search_zero_results', 'app_open'));

drop policy if exists usage_events_insert on usage_events;
create policy usage_events_insert on usage_events
  for insert with check (organization_id = my_hospital_id() or organization_id is null);

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
declare
  v_organization_id uuid;
begin
  v_organization_id := my_hospital_id(); -- null per a convidats o gent sense grup: es registra igual
  if p_event_type not in ('view', 'search', 'search_zero_results', 'app_open') then
    raise exception 'Tipo de evento no valido';
  end if;
  insert into usage_events (
    organization_id, user_id, event_type, ref_type, ref_id, query,
    utm_source, utm_medium, utm_campaign
  )
  values (
    v_organization_id, auth.uid(), p_event_type, p_ref_type, p_ref_id, p_query,
    p_utm_source, p_utm_medium, p_utm_campaign
  );
end;
$$;
