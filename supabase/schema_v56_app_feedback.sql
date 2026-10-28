-- Mecanismo de feedback/soporte enviado directamente desde la app (propuesta
-- de producto auditada esta sesion, confirmada como "no implementada" --
-- cero resultados al grepear feedback/report_bug/contact/mailto en lib/).
--
-- Deliberadamente simple: no hay pantalla de gestion/bandeja de feedback en
-- esta primera ronda (no se pidio, seria alcance nuevo no solicitado) -- el
-- propietario del proyecto lo consulta via Supabase Studio/SQL. Por eso no
-- hay ninguna policy de select para authenticated/anon (solo el rol
-- service_role, que bypassa RLS, puede leer).
--
-- Unica desviacion deliberada del patron "RPC solo para authenticated" que
-- sigue el resto del proyecto: el feedback debe poder enviarse tambien en
-- modo invitado (sin sesion) -- es la via mas abierta de toda la app a
-- proposito, asi que user_id/organization_id son nullable y el RPC se
-- concede tambien a `anon`.

create table if not exists app_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  organization_id uuid references organizations(id) on delete set null,
  category text not null check (category in ('bug', 'suggestion', 'other')),
  message text not null check (char_length(trim(message)) > 0),
  app_version text,
  platform text,
  status text not null default 'open' check (status in ('open', 'resolved')),
  created_at timestamptz not null default now()
);

alter table app_feedback enable row level security;
-- Sin policies de select/insert/update/delete para authenticated/anon a
-- proposito: toda la escritura pasa por submit_app_feedback (security
-- definer) y toda la lectura queda para service_role/Supabase Studio.

create or replace function submit_app_feedback(
  p_category text,
  p_message text,
  p_app_version text default null,
  p_platform text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_id uuid;
  v_organization_id uuid;
begin
  if p_category not in ('bug', 'suggestion', 'other') then
    raise exception 'Categoria de feedback no valida';
  end if;
  if char_length(trim(coalesce(p_message, ''))) = 0 then
    raise exception 'El mensaje no puede estar vacio';
  end if;

  -- my_hospital_id() devuelve null para un usuario sin organizacion (o sin
  -- sesion) -- aqui es un dato opcional de contexto, nunca un bloqueo, a
  -- diferencia de report_instrument_incident.
  if auth.uid() is not null then
    v_organization_id := my_hospital_id();
  end if;

  insert into app_feedback (user_id, organization_id, category, message, app_version, platform)
  values (auth.uid(), v_organization_id, p_category, trim(p_message), p_app_version, p_platform)
  returning id into v_id;

  return v_id;
end;
$$;

revoke all on function submit_app_feedback(text, text, text, text) from public;
grant execute on function submit_app_feedback(text, text, text, text) to authenticated, anon;
