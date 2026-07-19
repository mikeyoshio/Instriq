-- Fase B de la evolucion de Instriq: roles granulares. Owner y Administrator
-- operan a nivel de organizacion (hospital); Approver, Editor y Reader se
-- asignan por espacio de trabajo. Sustituye el modelo binario (is_admin)
-- por algo mas fino, sin romper el acceso de quien ya usa la app (backfill
-- de compatibilidad mas abajo). Ejecutar despues de schema_v6_workspaces.sql.

-- 1. Owner por organizacion --------------------------------------------------

alter table hospitals add column if not exists owner_id uuid references auth.users(id);

update hospitals set owner_id = created_by where owner_id is null;

create or replace function my_is_hospital_owner()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select coalesce(
    (select owner_id = auth.uid() from hospitals where id = my_hospital_id()),
    false
  )
$$;

create or replace function transfer_hospital_ownership(new_owner_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not my_is_hospital_owner() then
    raise exception 'Solo la propietaria o el propietario actual puede transferir la propiedad';
  end if;

  if not exists (
    select 1 from profiles where id = new_owner_id and hospital_id = my_hospital_id()
  ) then
    raise exception 'La persona indicada no pertenece a este grupo';
  end if;

  update hospitals set owner_id = new_owner_id where id = my_hospital_id();
end;
$$;

-- 2. Roles por espacio de trabajo --------------------------------------------

create table if not exists workspace_members (
  id uuid primary key default gen_random_uuid(),
  workspace_id uuid not null references workspaces(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('reader', 'editor', 'approver')),
  created_at timestamptz not null default now(),
  unique (workspace_id, user_id)
);

create index if not exists workspace_members_workspace_idx on workspace_members (workspace_id);
create index if not exists workspace_members_user_idx on workspace_members (user_id);

alter table workspace_members enable row level security;

drop policy if exists "workspace_members_select" on workspace_members;
create policy "workspace_members_select" on workspace_members
  for select using (
    user_id = auth.uid()
    or (
      my_is_hospital_admin()
      and exists (
        select 1 from workspaces w
        where w.id = workspace_members.workspace_id and w.hospital_id = my_hospital_id()
      )
    )
  );

drop policy if exists "workspace_members_insert_admin" on workspace_members;
create policy "workspace_members_insert_admin" on workspace_members
  for insert with check (
    my_is_hospital_admin()
    and exists (select 1 from workspaces w where w.id = workspace_id and w.hospital_id = my_hospital_id())
  );

drop policy if exists "workspace_members_update_admin" on workspace_members;
create policy "workspace_members_update_admin" on workspace_members
  for update using (
    my_is_hospital_admin()
    and exists (select 1 from workspaces w where w.id = workspace_id and w.hospital_id = my_hospital_id())
  );

drop policy if exists "workspace_members_delete_admin" on workspace_members;
create policy "workspace_members_delete_admin" on workspace_members
  for delete using (
    my_is_hospital_admin()
    and exists (select 1 from workspaces w where w.id = workspace_id and w.hospital_id = my_hospital_id())
  );

-- Backfill de compatibilidad: quien ya es miembro normal (no admin) de un
-- hospital pasa a ser Editor en todos los espacios que ya existen, para no
-- perder acceso al contenido que ya podia crear/editar.
insert into workspace_members (workspace_id, user_id, role)
select w.id, p.id, 'editor'
from profiles p
join workspaces w on w.hospital_id = p.hospital_id
where p.hospital_id is not null
  and p.is_admin = false
on conflict (workspace_id, user_id) do nothing;

-- 3. Helper de rol efectivo por espacio ---------------------------------------

create or replace function my_workspace_role(p_workspace_id uuid)
returns text
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_hospital_id uuid;
  v_role text;
begin
  select hospital_id into v_hospital_id from workspaces where id = p_workspace_id;
  if v_hospital_id is null or v_hospital_id <> my_hospital_id() then
    return null;
  end if;
  if my_is_hospital_admin() then
    return 'administrator';
  end if;
  select role into v_role from workspace_members
    where workspace_id = p_workspace_id and user_id = auth.uid();
  return v_role;
end;
$$;

-- 4. RLS de contenido por rol de espacio --------------------------------------

drop policy if exists "group_documents_select_same_hospital" on group_documents;
create policy "group_documents_select_role" on group_documents
  for select using (my_workspace_role(workspace_id) is not null);

drop policy if exists "group_documents_insert_same_hospital" on group_documents;
create policy "group_documents_insert_role" on group_documents
  for insert with check (
    hospital_id = my_hospital_id()
    and my_workspace_role(workspace_id) in ('editor', 'approver', 'administrator')
  );

drop policy if exists "group_documents_update_same_hospital" on group_documents;
create policy "group_documents_update_role" on group_documents
  for update using (my_workspace_role(workspace_id) in ('approver', 'administrator'));

drop policy if exists "group_documents_delete_same_hospital" on group_documents;
create policy "group_documents_delete_role" on group_documents
  for delete using (my_workspace_role(workspace_id) in ('approver', 'administrator'));

drop policy if exists "group_document_versions_select" on group_document_versions;
create policy "group_document_versions_select_role" on group_document_versions
  for select using (
    my_workspace_role((select workspace_id from group_documents where id = document_id)) is not null
    and (
      status = 'published'
      or author_id = auth.uid()
      or my_workspace_role((select workspace_id from group_documents where id = document_id)) = 'approver'
      or my_is_hospital_admin()
    )
  );

drop policy if exists "group_document_versions_insert" on group_document_versions;
create policy "group_document_versions_insert_role" on group_document_versions
  for insert with check (
    status = 'draft'
    and author_id = auth.uid()
    and my_workspace_role((select workspace_id from group_documents where id = document_id))
        in ('editor', 'approver', 'administrator')
  );

drop policy if exists "group_document_versions_update_own_draft" on group_document_versions;
create policy "group_document_versions_update_own_draft_role" on group_document_versions
  for update using (
    status = 'draft'
    and author_id = auth.uid()
    and my_workspace_role((select workspace_id from group_documents where id = document_id))
        in ('editor', 'approver', 'administrator')
  );

drop policy if exists "cards_select_same_hospital" on preference_cards;
create policy "cards_select_role" on preference_cards
  for select using (my_workspace_role(workspace_id) is not null);

drop policy if exists "cards_insert_same_hospital" on preference_cards;
create policy "cards_insert_role" on preference_cards
  for insert with check (
    hospital_id = my_hospital_id()
    and my_workspace_role(workspace_id) in ('editor', 'approver', 'administrator')
  );

drop policy if exists "cards_update_same_hospital" on preference_cards;
create policy "cards_update_role" on preference_cards
  for update using (my_workspace_role(workspace_id) in ('editor', 'approver', 'administrator'));

drop policy if exists "cards_delete_same_hospital" on preference_cards;
create policy "cards_delete_role" on preference_cards
  for delete using (my_workspace_role(workspace_id) in ('approver', 'administrator'));

-- 5. Transiciones de workflow (schema_v5) aceptan tambien al Approver del espacio

create or replace function approve_group_document_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_document_id uuid;
  v_workspace_id uuid;
begin
  select document_id into v_document_id
  from group_document_versions
  where id = p_version_id and status = 'in_review';

  if v_document_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id into v_workspace_id from group_documents where id = v_document_id;

  if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'Solo quien aprueba en este espacio puede aprobar cambios';
  end if;

  update group_document_versions
  set status = 'archived'
  where document_id = v_document_id and status = 'published';

  update group_document_versions
  set status = 'published',
      approved_by = auth.uid(),
      approved_at = now(),
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;

  update group_documents
  set published_version_id = p_version_id
  where id = v_document_id;
end;
$$;

create or replace function reject_group_document_version(p_version_id uuid, p_review_comment text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_document_id uuid;
  v_workspace_id uuid;
begin
  select document_id into v_document_id
  from group_document_versions
  where id = p_version_id and status = 'in_review';

  if v_document_id is null then
    raise exception 'Version no valida o no esta en revision';
  end if;

  select workspace_id into v_workspace_id from group_documents where id = v_document_id;

  if my_workspace_role(v_workspace_id) not in ('approver', 'administrator') then
    raise exception 'Solo quien aprueba en este espacio puede rechazar cambios';
  end if;

  update group_document_versions
  set status = 'draft',
      comment = coalesce(p_review_comment, comment)
  where id = p_version_id;
end;
$$;

create or replace function restore_group_document_version(p_version_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_document_id uuid;
  v_workspace_id uuid;
  v_next_version int;
  v_new_id uuid;
begin
  select document_id into v_document_id
  from group_document_versions
  where id = p_version_id;

  if v_document_id is null then
    raise exception 'Version no encontrada';
  end if;

  select workspace_id into v_workspace_id from group_documents where id = v_document_id;

  if my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado';
  end if;

  select coalesce(max(version_number), 0) + 1 into v_next_version
  from group_document_versions
  where document_id = v_document_id;

  insert into group_document_versions (
    document_id, version_number, status, title, specialty, content,
    steps, related_instrument_ids, author_id, comment, based_on_version_id
  )
  select
    v_document_id, v_next_version, 'draft', title, specialty, content,
    steps, related_instrument_ids, auth.uid(),
    'Restaurada desde una version anterior', p_version_id
  from group_document_versions
  where id = p_version_id
  returning id into v_new_id;

  return v_new_id;
end;
$$;
