-- schema_v67: hotfixos crítics de l'auditoria 2026-11
-- (docs/auditoria_2026-11_direccio_v1.2_v2.md).
--
-- 1) Fuga cross-organització als tokens .ics de l'agenda quirúrgica (v64).
--    my_is_hospital_admin() només comprova profiles.is_admin del cridant, no
--    a QUINA organització és admin; com que anava en un OR, un admin de
--    qualsevol organització podia llegir o rotar el token .ics d'un cirurgià
--    d'una altra. Ara el camí d'admin exigeix també que la seva organització
--    sigui la del cirurgià. La branca de workspace_members ja ho comprovava.
--
-- 2) Storage sense límits: cap bucket tenia file_size_limit ni
--    allowed_mime_types, i l'INSERT de catalog-community-photos només exigia
--    el bucket. Límit de 10 MB (el client no comprimeix: una foto de mòbil
--    sol fer 3-8 MB) i només imatges. El SDK de Supabase dedueix el MIME de
--    l'extensió de la ruta, i els 4 serveis que pugen fitxers sempre posen
--    una extensió d'imatge (o 'jpg' per defecte), així que cap pujada
--    legítima no es veu afectada. Els límits de bucket només apliquen a
--    pujades noves.
--    La ruta de catalog-community-photos ({ref_type}/{ref_id}/{fitxer}) no
--    porta l'usuari, així que no es pot lligar l'objecte a qui el puja sense
--    canviar el client -- i l'app de Windows ja publicada a Store seguiria
--    amb el format antic. Es valida l'estructura (2 carpetes, ref_type
--    vàlid); el límit de mida/tipus ja tanca el vector d'abús de cost.

create or replace function surgical_agenda_ics_token(p_surgeon_id uuid)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_organization_id uuid;
  v_token uuid;
begin
  select organization_id into v_organization_id from surgeons where id = p_surgeon_id;
  if v_organization_id is null then
    raise exception 'Cirujano no encontrado';
  end if;
  if not (
    (my_is_hospital_admin() and v_organization_id = my_hospital_id()) or exists (
      select 1 from workspace_members wm join workspaces w on w.id = wm.workspace_id
      where wm.user_id = auth.uid() and wm.role in ('editor', 'approver', 'administrator')
        and w.organization_id = v_organization_id
    )
  ) then
    raise exception 'No autorizado para ver el enlace de calendario de este cirujano';
  end if;

  select token into v_token from surgeon_ics_tokens where surgeon_id = p_surgeon_id;
  if v_token is null then
    insert into surgeon_ics_tokens (surgeon_id) values (p_surgeon_id) returning token into v_token;
  end if;
  return v_token;
end;
$function$;

create or replace function regenerate_surgical_agenda_ics_token(p_surgeon_id uuid)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_organization_id uuid;
  v_token uuid;
begin
  select organization_id into v_organization_id from surgeons where id = p_surgeon_id;
  if v_organization_id is null then
    raise exception 'Cirujano no encontrado';
  end if;
  if not (
    (my_is_hospital_admin() and v_organization_id = my_hospital_id()) or exists (
      select 1 from workspace_members wm join workspaces w on w.id = wm.workspace_id
      where wm.user_id = auth.uid() and wm.role in ('editor', 'approver', 'administrator')
        and w.organization_id = v_organization_id
    )
  ) then
    raise exception 'No autorizado para regenerar el enlace de calendario de este cirujano';
  end if;

  insert into surgeon_ics_tokens (surgeon_id, token, rotated_at)
  values (p_surgeon_id, gen_random_uuid(), now())
  on conflict (surgeon_id) do update set token = excluded.token, rotated_at = now()
  returning token into v_token;

  perform log_audit_event(v_organization_id, 'surgical_agenda_ics_token_regenerated', 'surgeon', p_surgeon_id, null, '{}'::jsonb);
  return v_token;
end;
$function$;

update storage.buckets
set file_size_limit = 10485760,
    allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif']
where id in ('custom-instrument-photos', 'tray-photos', 'catalog-community-photos', 'public-instrument-photos');

drop policy if exists "catalog_community_photos_insert" on storage.objects;
create policy "catalog_community_photos_insert" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'catalog-community-photos'
    and array_length(storage.foldername(name), 1) = 2
    and (storage.foldername(name))[1] in ('catalog', 'custom')
  );

-- Verificació (executar després d'aplicar):
--   select id, file_size_limit, allowed_mime_types from storage.buckets;
--   -- Amb un admin de l'org A, contra un cirurgià de l'org B: ha de fallar.
--   select surgical_agenda_ics_token('<surgeon_id_org_B>');
