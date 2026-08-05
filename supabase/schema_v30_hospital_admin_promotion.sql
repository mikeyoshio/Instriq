-- Nivell 2, Tasca B2: hoy ningún RPC permite fijar profiles.is_admin = true
-- para OTRO usuario (solo auto-concesión en registerHospital() y
-- auto-revocación en joinHospitalWithCode()/removeMember()). Este RPC cubre
-- el caso que falta: un admin promueve/despromueve a otro miembro del mismo
-- grupo. Mismo patrón de autorización que transfer_hospital_ownership()
-- (schema_v20_organizations_rename.sql): security definer, exige
-- my_is_hospital_admin() y que el destinatario pertenezca a la misma
-- organización.
--
-- action-type de audit_log elegido: 'hospital_admin_changed', entity_type
-- 'profile'. Se descarta reutilizar 'workspace_member_role_changed' (usado
-- por set_workspace_member_role/remove_workspace_member_role): ese tipo es
-- específicamente para filas de workspace_members (rol POR ESPACIO), y esto
-- es un cambio de profiles.is_admin (flag global de organización) -- misma
-- distinción que ya hace el comentario de workspace_role.dart ("administrator
-- nunca se guarda en workspace_members"). 'hospital_admin_changed' sigue el
-- mismo idioma que 'hospital_ownership_transferred' (acción a nivel de
-- organización, no de espacio), y entity_type 'profile' ya se usa para
-- 'user_signed_in' (schema_v21) cuando la fila afectada es la del propio
-- usuario en `profiles`.

create or replace function set_hospital_admin(p_user_id uuid, p_is_admin boolean)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_previous_is_admin boolean;
  v_admin_count int;
begin
  if not my_is_hospital_admin() then
    raise exception 'Solo un administrador del grupo puede cambiar el rol de administrador';
  end if;

  select organization_id, is_admin into v_organization_id, v_previous_is_admin
  from profiles
  where id = p_user_id;

  if v_organization_id is null or v_organization_id <> my_hospital_id() then
    raise exception 'La persona indicada no pertenece a este grupo';
  end if;

  if p_is_admin = false and v_previous_is_admin then
    select count(*) into v_admin_count
    from profiles
    where organization_id = v_organization_id and is_admin = true;

    if v_admin_count <= 1 then
      raise exception 'No se puede quitar el último administrador del grupo';
    end if;
  end if;

  update profiles set is_admin = p_is_admin where id = p_user_id;

  perform log_audit_event(
    v_organization_id,
    'hospital_admin_changed',
    'profile',
    p_user_id,
    null,
    jsonb_build_object('previous_is_admin', v_previous_is_admin, 'new_is_admin', p_is_admin)
  );
end;
$$;

-- Nota RLS (verificado, sin migración adicional): "workspace_members_select"
-- (schema_v7_roles.sql) ya permite "user_id = auth.uid()" -- un miembro
-- normal ya puede leer sus propias filas de workspace_members. El rename de
-- columnas de schema_v20 (hospital_id -> organization_id en `workspaces`) no
-- rompe esta policy: Postgres reescribe las definiciones de policy que
-- referencian una columna renombrada, no hace falta recrearla.
