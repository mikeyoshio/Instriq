-- Endurit la moderacio de fotos publiques: schema_v16/v48 ja tenien revisio
-- humana abans de MOSTRAR una foto dins de l'app, pero el bucket de Storage
-- era public des del primer instant -- qualsevol fitxer pujat (contingut
-- il·legal inclos) era recuperable per la seva URL directa abans que cap
-- persona l'hagues revisat, i es quedava accessible per sempre encara que
-- es rebutgés (nomes canviava una columna d'estat, mai es borrava l'arxiu).
--
-- Fix: els 2 buckets passen a privats. La lectura es controla amb RLS igual
-- que ja fan tray-photos/custom-instrument-photos (nomes es pot generar una
-- signed URL si la fila associada esta aprovada/publicada, o si ets qui l'ha
-- pujat, o un admin/revisor) -- una persona anonima segueix podent veure una
-- foto JA aprovada (createSignedUrl no exigeix auth.uid(), nomes que la RLS
-- de lectura es compleixi), pero mai una de pendent.

-- 1. catalog-community-photos ------------------------------------------------

update storage.buckets set public = false where id = 'catalog-community-photos';

drop policy if exists "catalog_community_photos_select" on storage.objects;
create policy "catalog_community_photos_select" on storage.objects
  for select using (
    bucket_id = 'catalog-community-photos'
    and (
      exists (
        select 1 from catalog_community_photos ccp
        where ccp.photo_path = storage.objects.name and ccp.status = 'approved'
      )
      or exists (
        select 1 from catalog_community_photos ccp
        where ccp.photo_path = storage.objects.name and ccp.submitted_by = auth.uid()
      )
      or exists (select 1 from profiles where id = auth.uid() and is_admin = true)
    )
  );

-- Nova: permet esborrar l'arxiu de debo quan es rebutja (catalog_community_photos
-- te un estat 'rejected' terminal, sense flux de revisio -- a diferencia de
-- public_instrument_versions, veure mes avall).
drop policy if exists "catalog_community_photos_delete" on storage.objects;
create policy "catalog_community_photos_delete" on storage.objects
  for delete using (
    bucket_id = 'catalog-community-photos'
    and exists (select 1 from profiles where id = auth.uid() and is_admin = true)
  );

-- 2. public-instrument-photos -------------------------------------------------
-- NO s'afegeix policy de delete aqui: rebutjar una public_instrument_version
-- la torna a 'draft' (flux de revisa-i-reenvia, no terminal) -- esborrar
-- l'arxiu trencaria que l'autor segueixi veient/reemplaçant la seva propia
-- foto en esborrany.

update storage.buckets set public = false where id = 'public-instrument-photos';

drop policy if exists "public_instrument_photos_select" on storage.objects;
create policy "public_instrument_photos_select" on storage.objects
  for select using (
    bucket_id = 'public-instrument-photos'
    and (
      exists (
        select 1 from public_instrument_versions piv
        where piv.photo_path = storage.objects.name and piv.status = 'published'
      )
      or exists (
        select 1 from public_instrument_versions piv
        where piv.photo_path = storage.objects.name and piv.author_id = auth.uid()
      )
      or my_is_reviewer_or_above()
    )
  );
