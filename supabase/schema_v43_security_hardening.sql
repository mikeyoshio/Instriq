-- Auditoria de seguretat (2026-09): revisio independent (no nomes el diff
-- pendent) sobre les migracions mes recents (v33-v42). Dos forats ALTS i un
-- de MITJA, tots amb arrel similar a la ja corregida a schema_v31 per a
-- `profiles`: RLS es per fila, no per columna, i dues Edge Functions
-- confiaven cegament en el payload d'un webhook sense autenticar-lo de
-- veritat.

-- ============================================================
-- 1) ALT -- "organizations_update_by_admin" (schema_v3, taula renombrada a
--    schema_v20) no te `with check`, aixi que un admin d'organitzacio (no
--    cal ser el propietari) pot fer, directament des del client:
--      update organizations set owner_id = <uuid arbitrari> where id = ...
--    saltant-se `transfer_hospital_ownership()` per complet: sense pas per
--    `log_audit_event`, i podent apuntar `owner_id` a algu que no pertanyi
--    ni tan sols al grup, trencant l'invariant que `remove_hospital_member`
--    dona per fet (que `owner_id` sempre es membre real i mai s'expulsa).
--    Mateix patro que `guard_profile_privilege_columns` (schema_v31): un
--    trigger bloqueja la columna sensible tret que la funcio autoritzada
--    activi el flag abans d'escriure.
-- ============================================================

create or replace function guard_organization_owner_column()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  if new.owner_id is distinct from old.owner_id
     and coalesce(current_setting('app.bypass_organization_owner_guard', true), '') <> 'on' then
    raise exception 'No es pot modificar owner_id directament -- cal fer-ho a traves de transfer_hospital_ownership().';
  end if;
  return new;
end;
$$;

drop trigger if exists organizations_guard_owner_column on organizations;
create trigger organizations_guard_owner_column
before update on organizations
for each row execute function guard_organization_owner_column();

create or replace function transfer_hospital_ownership(new_owner_id uuid)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_organization_id uuid;
  v_previous_owner_id uuid;
begin
  if not my_is_hospital_owner() then
    raise exception 'Solo la propietaria o el propietario actual puede transferir la propiedad';
  end if;

  if not exists (
    select 1 from profiles where id = new_owner_id and organization_id = my_hospital_id()
  ) then
    raise exception 'La persona indicada no pertenece a este grupo';
  end if;

  v_organization_id := my_hospital_id();
  v_previous_owner_id := auth.uid();

  perform set_config('app.bypass_organization_owner_guard', 'on', true);
  update organizations set owner_id = new_owner_id where id = v_organization_id;

  perform log_audit_event(
    v_organization_id,
    'hospital_ownership_transferred',
    'hospital',
    v_organization_id,
    null,
    jsonb_build_object('previous_owner_id', v_previous_owner_id, 'new_owner_id', new_owner_id)
  );
end;
$$;

-- ============================================================
-- 2) MITJA -- "group_document_videos_select" (schema_v38) no filtra per
--    `status`: el seu propi comentari original diu que aqui, a diferencia
--    d'instrument_incidents, l'estat SI hauria de bloquejar la visibilitat
--    fins aprovar-se (com catalog_community_photos), pero la policy no ho
--    feia -- qualsevol membre del workspace veia videos `pending`/`rejected`
--    d'altres persones. El filtrat real nomes vivia al client
--    (group_document_detail_screen.dart), que es cosmetic.
-- ============================================================

drop policy if exists group_document_videos_select on group_document_videos;
create policy group_document_videos_select on group_document_videos
  for select using (
    organization_id = my_hospital_id()
    and (
      status = 'approved'
      or submitted_by = auth.uid()
      or my_workspace_role(workspace_id) in ('approver', 'administrator')
    )
  );

-- ============================================================
-- 3) ALT/MITJA -- Edge Functions `send-push` i `send-invitation-email` es
--    criden des d'un trigger/webhook de base de dades, pero cap de les dues
--    comprovava que la crida realment vingues d'aquest trigger: nomes
--    exigien un JWT valid, i la anon key es publica (embeguda a l'app i a
--    la landing) -- qualsevol persona a internet podia fer POST directe a
--    l'endpoint amb un body fabricat i (a) fer que Instriq envii un correu
--    real des de hola@instriq.org amb contingut gairebe lliure (relay de
--    phishing/spam amb domini legitim), o (b) injectar contingut en una
--    notificacio push a usuaris reals d'un workspace conegut.
--
--    Fix: un secret compartit nou, guardat a Supabase Vault
--    ('webhook_shared_secret', creat fora d'aquesta migracio -- mai en un
--    fitxer versionat d'un repo public) i tambe com a secret de les dues
--    Edge Functions (WEBHOOK_SHARED_SECRET). `trigger_send_push()` ja es
--    una funcio normal que construeix les seves capçaleres dinamicament,
--    aixi que pot llegir el secret de Vault en temps real -- es el que es
--    canvia aqui, de forma segura de versionar (el valor real nomes viu a
--    Vault, mai en aquest fitxer).
--
--    El trigger `invitations` (webhook estil Dashboard, schema_v41) NO es
--    pot arreglar aqui: les seves capçaleres son un literal fixat en el
--    moment de fer CREATE TRIGGER (arguments de trigger sempre son text
--    literal a PostgreSQL, mai una subquery), aixi que incloure-hi el
--    secret real exigiria escriure'l en clar en aquest fitxer -- inacceptable
--    en un repo public. Es va actualitzar DIRECTAMENT contra producció
--    (fora de control de versions), afegint la mateixa capçalera
--    'X-Webhook-Secret'. Per reproduir-ho en un projecte nou: recrear el
--    trigger 'invitations' sobre 'invitations' AFTER INSERT amb
--    supabase_functions.http_request(...) igual que el que genera el
--    Dashboard (Database -> Webhooks), afegint una capçalera
--    'X-Webhook-Secret' amb el mateix valor guardat a WEBHOOK_SHARED_SECRET.
-- ============================================================

create or replace function trigger_send_push()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_shared_secret text;
begin
  select decrypted_secret into v_shared_secret
    from vault.decrypted_secrets where name = 'webhook_shared_secret';

  perform net.http_post(
    url := 'https://ssskgmlubgcjvhdmayhp.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNzc2tnbWx1YmdjanZoZG1heWhwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQyMjU0NjcsImV4cCI6MjA5OTgwMTQ2N30.w6SBsnM8QCWEiPxB5sTtiRZk_-rh3Q0ceE7U89HjaoY',
      'X-Webhook-Secret', coalesce(v_shared_secret, '')
    ),
    body := jsonb_build_object(
      'type', 'INSERT',
      'table', 'audit_log',
      'schema', 'public',
      'record', to_jsonb(new),
      'old_record', null
    ),
    timeout_milliseconds := 5000
  );
  return new;
end;
$$;
