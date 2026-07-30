-- Endurecimiento de seguridad a raiz del Supabase database linter.
--
-- 1) function_search_path_mutable (WARN, 3 funciones): set_updated_at,
--    check_workspace_matches_hospital, set_custom_instrument_updated_at se
--    crearon sin "set search_path = public". Sin eso, si alguna vez alguien
--    consigue crear objetos con el mismo nombre en otro esquema que quede
--    antes que "public" en el search_path de la sesion, la funcion podria
--    acabar llamando a esos objetos en vez de a los de "public". Es un
--    escenario improbable aqui (no hay esquemas de terceros en este
--    proyecto), pero fijar search_path no tiene coste y es la recomendacion
--    estandar de Supabase/Postgres para toda funcion. Se hace "create or
--    replace" con el mismo cuerpo exacto que ya tenian, solo anadiendo la
--    clausula.
--
-- 2) anon_security_definer_function_executable / authenticated_... (WARN,
--    todas las funciones RPC de la app): esto es ESPERADO por diseno, no se
--    toca. Todas estas funciones (approve_group_document_version,
--    create_group_document, my_workspace_role, etc.) estan pensadas
--    exactamente para llamarse desde el cliente via /rest/v1/rpc/... sin
--    pasar por una tabla con RLS de por medio -- cada una hace su propia
--    comprobacion de auth.uid()/rol al principio (ver schema_v5/v7/v9/v10).
--    Revocar EXECUTE aqui romperia la app entera. El linter avisa de esto
--    en cualquier proyecto que use este patron (RPC con su propia
--    autorizacion interna en vez de solo RLS de tabla), no es un hallazgo
--    especifico de un fallo real.
--
--    Unica excepcion revisada aparte: can_access_custom_instrument_photo()
--    (schema_v13) SI necesita seguir siendo ejecutable por anon/authenticated
--    aunque solo la usen las policies de storage.objects -- las policies de
--    Storage se evaluan con el rol de quien hace la peticion (anon/
--    authenticated), no con un rol interno aparte, asi que revocar EXECUTE
--    ahi rompería la subida/lectura de fotos para usuarios reales. Se deja
--    tal cual, es un falso positivo de este linter para este patron de uso.
--
-- 3) auth_leaked_password_protection (WARN): esto NO se puede activar por
--    SQL, es un toggle del propio servicio de Auth. Pendiente manual:
--    Authentication -> Policies (o Providers -> Email) -> activar
--    "Leaked password protection" (comprueba contra HaveIBeenPwned al
--    registrarse/cambiar contraseña). Un clic, sin efectos secundarios.

create or replace function set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function check_workspace_matches_hospital()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if not exists (
    select 1 from workspaces
    where id = new.workspace_id and hospital_id = new.hospital_id
  ) then
    raise exception 'El espacio no pertenece al mismo grupo que el contenido';
  end if;
  return new;
end;
$$;

create or replace function set_custom_instrument_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
