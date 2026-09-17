-- Auditoria de seguretat (2026-09), hallazgo BAJO: `can_access_tray_photo`
-- (schema_v15) i `can_access_custom_instrument_photo` (schema_v13) comproven
-- el rol sobre el `workspace_id` de la ruta de l'objecte, pero mai que el
-- tray_id/custom_instrument_id (tercer segment) pertanyi de veritat a aquest
-- workspace -- un editor amb accés legítim a un workspace podia pujar un
-- fitxer sota l'id d'una altra bandeja/instrument del mateix workspace (o
-- orfe). Impacte baix: no travessa organitzacions (my_workspace_role ja ho
-- impedeix), es nomes un problema d'integritat de dades dins del mateix
-- workspace. Es corregeix afegint la comprovacio que faltava.

create or replace function can_access_tray_photo(object_name text, need_write boolean)
returns boolean
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_segments text[];
  v_workspace_id uuid;
  v_tray_id uuid;
  v_role text;
begin
  v_segments := storage.foldername(object_name);
  if array_length(v_segments, 1) is null or array_length(v_segments, 1) < 3 then
    return false;
  end if;

  begin
    v_workspace_id := v_segments[2]::uuid;
    v_tray_id := v_segments[3]::uuid;
  exception when invalid_text_representation then
    return false;
  end;

  v_role := my_workspace_role(v_workspace_id);

  if not exists (select 1 from trays where id = v_tray_id and workspace_id = v_workspace_id) then
    return false;
  end if;

  if need_write then
    return v_role in ('editor', 'approver', 'administrator');
  end if;

  return v_role is not null;
end;
$$;

create or replace function can_access_custom_instrument_photo(object_name text, need_write boolean)
returns boolean
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_segments text[];
  v_workspace_id uuid;
  v_instrument_id uuid;
  v_role text;
begin
  v_segments := storage.foldername(object_name);
  if array_length(v_segments, 1) is null or array_length(v_segments, 1) < 3 then
    return false;
  end if;

  begin
    v_workspace_id := v_segments[2]::uuid;
    v_instrument_id := v_segments[3]::uuid;
  exception when invalid_text_representation then
    return false;
  end;

  v_role := my_workspace_role(v_workspace_id);

  if not exists (
    select 1 from custom_instruments where id = v_instrument_id and workspace_id = v_workspace_id
  ) then
    return false;
  end if;

  if need_write then
    return v_role in ('editor', 'approver', 'administrator');
  end if;

  return v_role is not null;
end;
$$;
