-- Notificación activa de seguimiento (propuesta de producto auditada esta
-- sesión): hasta ahora solo existía detección pasiva (bandejas adoptadas de
-- la Biblioteca Pública, al abrir la pantalla). Esta tabla deja "seguir" un
-- contenido propio del equipo y recibir un push real cuando se publica una
-- versión nueva -- ver la extensión de supabase/functions/send-push/index.ts
-- (no forma parte de este archivo, es TypeScript/Deno, se despliega aparte).
--
-- Importante: `ref_type`/`ref_id` aquí son a nivel de ENTIDAD estable
-- (document_id/tray_id/card_id/custom_instrument_id), no de versión --
-- "seguir esta técnica" debe sobrevivir a que se publique una versión
-- nueva, nunca apuntar a un snapshot concreto. Por eso reutiliza EXACTAMENTE
-- los mismos valores de ref_type que `favorites`/`recent_views`
-- (schema_v18_work_mode_favorites_recent.sql: 'group_document', 'tray',
-- 'preference_card', 'custom'), no los de schema_v57/v58
-- ('group_document_version', etc., a nivel de versión concreta).
--
-- Mismo criterio exacto que `favorites`: estrictamente por usuario, RLS
-- directa sin RPC (no es una escritura lo bastante sensible como para
-- auditar), nunca ligada a workspace.
create table if not exists content_follows (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  ref_type text not null check (ref_type in ('group_document', 'tray', 'preference_card', 'custom')),
  ref_id uuid not null,
  created_at timestamptz not null default now(),
  unique (user_id, ref_type, ref_id)
);

create index if not exists content_follows_ref_idx on content_follows (ref_type, ref_id);

alter table content_follows enable row level security;

create policy "content_follows_select_own" on content_follows
  for select using (user_id = auth.uid());

create policy "content_follows_insert_own" on content_follows
  for insert with check (user_id = auth.uid());

create policy "content_follows_delete_own" on content_follows
  for delete using (user_id = auth.uid());

-- La Edge Function send-push usa el service_role (bypassa RLS) para
-- resolver seguidores -- no hace falta ninguna policy adicional de lectura
-- cross-user aquí.
