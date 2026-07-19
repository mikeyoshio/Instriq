-- Fase 2 de la nueva vision de Instriq: contenido propio del grupo mas alla
-- de las tarjetas de preferencia. Una sola tabla para tecnicas quirurgicas
-- y protocolos (mismo patron de RLS, misma forma de CRUD), distinguidos por
-- la columna "kind". Ejecutar despues de schema_v3_fix_rls_recursion.sql.

create table if not exists group_documents (
  id uuid primary key default gen_random_uuid(),
  hospital_id uuid not null references hospitals(id) on delete cascade,
  kind text not null check (kind in ('technique', 'protocol')),
  title text not null,
  specialty text,
  content text,
  steps jsonb not null default '[]'::jsonb,
  related_instrument_ids jsonb not null default '[]'::jsonb,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists group_documents_hospital_kind_idx on group_documents (hospital_id, kind);

alter table group_documents enable row level security;

-- Reutiliza my_hospital_id()/my_is_hospital_admin() de schema_v3 (evita la
-- recursion de RLS que tuvimos con profiles).
drop policy if exists "group_documents_select_same_hospital" on group_documents;
create policy "group_documents_select_same_hospital" on group_documents
  for select using (hospital_id = my_hospital_id());

drop policy if exists "group_documents_insert_same_hospital" on group_documents;
create policy "group_documents_insert_same_hospital" on group_documents
  for insert with check (hospital_id = my_hospital_id());

drop policy if exists "group_documents_update_same_hospital" on group_documents;
create policy "group_documents_update_same_hospital" on group_documents
  for update using (hospital_id = my_hospital_id());

drop policy if exists "group_documents_delete_same_hospital" on group_documents;
create policy "group_documents_delete_same_hospital" on group_documents
  for delete using (hospital_id = my_hospital_id());

-- Mantener updated_at al dia en cada edicion.
create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists group_documents_set_updated_at on group_documents;
create trigger group_documents_set_updated_at
  before update on group_documents
  for each row execute function set_updated_at();
