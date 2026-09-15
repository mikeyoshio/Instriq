-- ADR-001 §0 (docs/ADR_001_KNOWLEDGE_GOVERNANCE.md): "adopció d'organització
-- sobre contingut públic" -- Opció C, referència upstream amb sincronització
-- conscient de la divergència. Primer candidat real segons el propi ADR §8
-- (les safates ja tenen versionat i duplicació, "adoptar-ne una de pública
-- és una extensió natural, no un redisseny") -- aquesta migració ho limita
-- deliberadament a bandejas; tècniques/targetes queden per a una ronda
-- futura, mateix criteri de "no generalitzar amb un únic consumidor" ja
-- aplicat a ADR-004.
--
-- Model de dades (ADR-001 §0, decidit pel propietari):
--   Source     -> upstream_public_tray_id (de quin element públic prové)
--   Parent     -> upstream_adopted_version_id (versió pública concreta en
--                 el moment de l'adopció/última actualització)
--   Sync Status -> enum emmagatzemat, no derivat: synced/customized/independent
--
-- Decisió d'interpretació (aquest fitxer): §2.3 del document parla
-- d'esborrar upstream_ref_id en "Deixar de seguir", però §0 defineix
-- 'independent' com un valor del propi enum -- es tria conservar sempre
-- upstream_public_tray_id (procedència, útil encara que ja no se segueixi)
-- i fer servir sync_status='independent' per a "ja no rep actualitzacions",
-- en comptes de perdre la referència històrica.
--
-- La transició synced -> customized és automàtica en cada edició de
-- contingut real (trigger sobre tray_versions, comparant els camps de
-- contingut, no que sigui una acció manual) -- exactament el mecanisme
-- descrit a ADR-001 §0.7. customized -> independent i synced -> independent
-- són sempre una acció explícita de l'usuari ("Deixar de seguir"). Mai hi ha
-- transició automàtica cap a 'synced': només "Actualitzar" (RPC
-- update_tray_from_upstream) ho fa, i explícitament, mai en silenci
-- (ADR-001 §9: "mai una actualització silenciosa, ni tan sols en sincronitzat").

alter table trays
  add column if not exists upstream_public_tray_id uuid references public_trays(id) on delete set null,
  add column if not exists upstream_adopted_version_id uuid references public_tray_versions(id) on delete set null,
  add column if not exists sync_status text check (sync_status in ('synced', 'customized', 'independent'));

alter table trays drop constraint if exists trays_sync_status_requires_upstream;
alter table trays
  add constraint trays_sync_status_requires_upstream
  check ((upstream_public_tray_id is null) = (sync_status is null));

create index if not exists trays_upstream_public_tray_idx on trays (upstream_public_tray_id) where upstream_public_tray_id is not null;

-- Transició automàtica synced -> customized en la primera edició de
-- contingut real des de l'adopció (o des de la darrera "Actualitzar").
-- Compara només columnes de contingut, mai status/timestamps/comment: així
-- publicar la primera versió adoptada sense cap canvi (esborrany -> revisió
-- -> aprovada) NO la marca com a personalitzada -- només un canvi real de
-- contingut ho fa. `update_tray_from_upstream` (més avall) desfà aquesta
-- marca explícitament al final de la seva pròpia transacció quan el que ha
-- canviat és precisament tornar-se a igualar amb l'origen.
create or replace function mark_tray_customized_on_content_change()
returns trigger
language plpgsql
security definer
set search_path = 'public'
as $function$
begin
  if (new.name, new.specialty_id, new.description, new.photo_paths, new.items, new.observations)
     is distinct from
     (old.name, old.specialty_id, old.description, old.photo_paths, old.items, old.observations) then
    update trays set sync_status = 'customized'
    where id = new.tray_id and sync_status = 'synced';
  end if;
  return new;
end;
$function$;

drop trigger if exists tray_versions_mark_customized on tray_versions;
create trigger tray_versions_mark_customized
after update on tray_versions
for each row execute function mark_tray_customized_on_content_change();

-- Adopta un element de la Biblioteca Pública: crea una bandeja PRIVADA nova
-- (capçalera + versió 1 en esborrany), amb el contingut de la versió
-- PUBLICADA de l'origen -- calcada de duplicate_tray (schema_v25), amb la
-- diferència que la font és public_trays, no una altra bandeja de
-- l'organització, i que sí queda marcada com a seguint l'origen.
create or replace function adopt_public_tray(p_public_tray_id uuid, p_workspace_id uuid)
returns tray_versions
language plpgsql
security definer
set search_path = 'public'
as $function$
declare
  v_organization_id uuid;
  v_source_version public_tray_versions;
  v_new_tray_id uuid;
  v_new_version tray_versions;
begin
  if my_workspace_role(p_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado para adoptar contenido público en este espacio';
  end if;

  select organization_id into v_organization_id from workspaces where id = p_workspace_id;
  if v_organization_id is null then
    raise exception 'Espacio no encontrado';
  end if;

  select ptv.* into v_source_version
  from public_tray_versions ptv
  join public_trays pt on pt.published_version_id = ptv.id
  where pt.id = p_public_tray_id;

  if v_source_version.id is null then
    raise exception 'Esta bandeja pública todavía no tiene una versión publicada';
  end if;

  insert into trays (
    organization_id, workspace_id, created_by,
    upstream_public_tray_id, upstream_adopted_version_id, sync_status
  )
  values (
    v_organization_id, p_workspace_id, auth.uid(),
    p_public_tray_id, v_source_version.id, 'synced'
  )
  returning id into v_new_tray_id;

  insert into tray_versions (
    tray_id, version_number, status, name, specialty_id, description, items, observations,
    author_id, comment
  )
  values (
    v_new_tray_id, 1, 'draft', v_source_version.name, v_source_version.specialty_id,
    v_source_version.description, v_source_version.items, v_source_version.observations,
    auth.uid(), 'Adoptada desde la Biblioteca Pública'
  )
  returning * into v_new_version;

  perform log_audit_event(
    v_organization_id,
    'tray_adopted',
    'tray',
    v_new_tray_id,
    p_workspace_id,
    jsonb_build_object('source_public_tray_id', p_public_tray_id)
  );

  return v_new_version;
end;
$function$;

-- "Deixar de seguir": deixa de rebre senyal d'actualitzacions, sense perdre
-- la procedència (ver decisió d'interpretació més amunt). Irreversible des
-- de la UI a propòsit -- tornar a "seguir" seria una nova adopció.
create or replace function stop_following_public_tray(p_tray_id uuid)
returns void
language plpgsql
security definer
set search_path = 'public'
as $function$
declare
  v_organization_id uuid;
  v_workspace_id uuid;
begin
  select organization_id, workspace_id into v_organization_id, v_workspace_id
  from trays where id = p_tray_id;

  if v_organization_id is null or v_organization_id <> my_hospital_id() then
    raise exception 'Bandeja no encontrada en tu organización';
  end if;
  if my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado';
  end if;

  update trays set sync_status = 'independent'
  where id = p_tray_id and upstream_public_tray_id is not null and sync_status <> 'independent';

  perform log_audit_event(v_organization_id, 'tray_stopped_following_upstream', 'tray', p_tray_id, v_workspace_id, '{}'::jsonb);
end;
$function$;

-- "Actualitzar": només té sentit sobre una bandeja 'synced' (si ja està
-- 'customized', l'usuari ha de triar "Revisar canvis" al client, que
-- deliberadament NO es resol aquí -- comparació estructurada fora d'abast
-- d'aquesta primera ronda, ADR-001 §5). Crea/actualitza el propi esborrany
-- en curs amb el contingut ACTUAL de l'origen públic i mou
-- upstream_adopted_version_id endavant. Mai publica sol -- com qualsevol
-- altre canvi, cal "Enviar a revisió" explícitament (ADR-001 §9: mai una
-- actualització silenciosa).
create or replace function update_tray_from_upstream(p_tray_id uuid)
returns tray_versions
language plpgsql
security definer
set search_path = 'public'
as $function$
declare
  v_organization_id uuid;
  v_workspace_id uuid;
  v_upstream_id uuid;
  v_sync_status text;
  v_source_version public_tray_versions;
  v_existing_draft tray_versions;
  v_next_version_number int;
  v_result tray_versions;
begin
  select organization_id, workspace_id, upstream_public_tray_id, sync_status
    into v_organization_id, v_workspace_id, v_upstream_id, v_sync_status
  from trays where id = p_tray_id;

  if v_organization_id is null or v_organization_id <> my_hospital_id() then
    raise exception 'Bandeja no encontrada en tu organización';
  end if;
  if my_workspace_role(v_workspace_id) not in ('editor', 'approver', 'administrator') then
    raise exception 'No autorizado';
  end if;
  if v_upstream_id is null or v_sync_status <> 'synced' then
    raise exception 'Esta bandeja no sigue ningún origen público sincronizado';
  end if;

  select ptv.* into v_source_version
  from public_tray_versions ptv
  join public_trays pt on pt.published_version_id = ptv.id
  where pt.id = v_upstream_id;

  if v_source_version.id is null then
    raise exception 'El origen público ya no tiene una versión publicada';
  end if;

  select * into v_existing_draft
  from tray_versions
  where tray_id = p_tray_id and author_id = auth.uid() and status = 'draft'
  order by version_number desc
  limit 1;

  if v_existing_draft.id is not null then
    update tray_versions set
      name = v_source_version.name,
      specialty_id = v_source_version.specialty_id,
      description = v_source_version.description,
      items = v_source_version.items,
      observations = v_source_version.observations,
      comment = 'Actualizada desde la Biblioteca Pública'
    where id = v_existing_draft.id
    returning * into v_result;
  else
    select coalesce(max(version_number), 0) + 1 into v_next_version_number from tray_versions where tray_id = p_tray_id;
    insert into tray_versions (
      tray_id, version_number, status, name, specialty_id, description, items, observations,
      author_id, comment
    )
    values (
      p_tray_id, v_next_version_number, 'draft', v_source_version.name, v_source_version.specialty_id,
      v_source_version.description, v_source_version.items, v_source_version.observations,
      auth.uid(), 'Actualizada desde la Biblioteca Pública'
    )
    returning * into v_result;
  end if;

  -- El trigger de arriba ya habrá marcado la bandeja como 'customized' al
  -- cambiar el contenido de la fila -- se deshace aquí a propósito: esto es
  -- re-sincronizar con el origen, no divergir de él.
  update trays set upstream_adopted_version_id = v_source_version.id, sync_status = 'synced'
  where id = p_tray_id;

  perform log_audit_event(v_organization_id, 'tray_updated_from_upstream', 'tray', p_tray_id, v_workspace_id, '{}'::jsonb);

  return v_result;
end;
$function$;

revoke all on function adopt_public_tray(p_public_tray_id uuid, p_workspace_id uuid) from public;
grant execute on function adopt_public_tray(p_public_tray_id uuid, p_workspace_id uuid) to authenticated;
revoke all on function stop_following_public_tray(p_tray_id uuid) from public;
grant execute on function stop_following_public_tray(p_tray_id uuid) to authenticated;
revoke all on function update_tray_from_upstream(p_tray_id uuid) from public;
grant execute on function update_tray_from_upstream(p_tray_id uuid) to authenticated;
