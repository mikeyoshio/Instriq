-- GDPR: exportar y eliminar la cuenta propia. La mayoria de columnas de
-- autoria (created_by/author_id/approved_by) ya se definieron desde el
-- principio como "references auth.users(id) on delete set null", asi que
-- borrar la fila de auth.users ya anonimiza automaticamente casi todo el
-- contenido sin tocar esas tablas a mano. Solo hospitals.owner_id (Fase B)
-- no tiene esa clausula, porque queremos bloquear el borrado si esa
-- persona es propietaria de un grupo con mas gente.

-- 1. Eliminar mi cuenta --------------------------------------------------------

create or replace function delete_my_account()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owned_hospital_id uuid;
  v_has_other_members boolean;
begin
  select id into v_owned_hospital_id from hospitals where owner_id = auth.uid();

  if v_owned_hospital_id is not null then
    select exists (
      select 1 from profiles
      where hospital_id = v_owned_hospital_id and id <> auth.uid()
    ) into v_has_other_members;

    if v_has_other_members then
      raise exception 'Eres propietaria/o de un grupo con más miembros. Transfiere la propiedad antes de eliminar tu cuenta.';
    end if;

    -- Propietaria/o sin nadie mas en el grupo: se borra tambien el grupo
    -- (la cascada existente se lleva espacios, roles, tecnicas/protocolos,
    -- versiones y tarjetas de ese grupo).
    delete from hospitals where id = v_owned_hospital_id;
  end if;

  delete from auth.users where id = auth.uid();
end;
$$;

-- 2. Exportar mis datos ---------------------------------------------------------

create or replace function export_my_account_data()
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result json;
begin
  select json_build_object(
    'profile', (
      select json_build_object(
        'display_name', p.display_name,
        'hospital_name', h.name,
        'is_admin', p.is_admin,
        'is_owner', h.owner_id = p.id,
        'created_at', p.created_at
      )
      from profiles p
      left join hospitals h on h.id = p.hospital_id
      where p.id = auth.uid()
    ),
    'workspace_roles', (
      select coalesce(json_agg(json_build_object(
        'workspace', w.name,
        'role', wm.role
      )), '[]'::json)
      from workspace_members wm
      join workspaces w on w.id = wm.workspace_id
      where wm.user_id = auth.uid()
    ),
    'documents_authored', (
      select coalesce(json_agg(json_build_object(
        'kind', gd.kind,
        'workspace', w.name,
        'title', gdv.title,
        'status', gdv.status,
        'version_number', gdv.version_number,
        'created_at', gdv.created_at
      )), '[]'::json)
      from group_document_versions gdv
      join group_documents gd on gd.id = gdv.document_id
      join workspaces w on w.id = gd.workspace_id
      where gdv.author_id = auth.uid()
    ),
    'documents_approved', (
      select coalesce(json_agg(json_build_object(
        'kind', gd.kind,
        'workspace', w.name,
        'title', gdv.title,
        'version_number', gdv.version_number,
        'approved_at', gdv.approved_at
      )), '[]'::json)
      from group_document_versions gdv
      join group_documents gd on gd.id = gdv.document_id
      join workspaces w on w.id = gd.workspace_id
      where gdv.approved_by = auth.uid()
    ),
    'preference_cards_created', (
      select coalesce(json_agg(json_build_object(
        'workspace', w.name,
        'surgeon_name', pc.surgeon_name,
        'procedure_name', pc.procedure_name,
        'created_at', pc.created_at
      )), '[]'::json)
      from preference_cards pc
      join workspaces w on w.id = pc.workspace_id
      where pc.created_by = auth.uid()
    )
  ) into v_result;

  return v_result;
end;
$$;
