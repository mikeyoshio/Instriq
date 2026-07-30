-- Bug real detectado en verificacion manual (emulador sin sesion iniciada):
-- el catalogo global de instrumental funciona SIN login
-- (CatalogScreen/InstrumentDetailScreen no requieren sesion), pero las
-- policies de select de instrument_sterilization_methods/
-- instrument_technical_info (schema_v15) exigian auth.role() =
-- 'authenticated' incluso para datos globales (hospital_id is null),
-- bloqueando la lectura a usuarios anonimos -- la seccion de
-- "Esterilitzacio"/"Fitxa tecnica" se mostraba vacia para cualquiera sin
-- cuenta, aunque el dato ya existiera en la tabla.
--
-- Se corrige quitando esa exigencia solo para el caso global (hospital_id
-- is null): esta informacion es tan publica como la propia descripcion del
-- instrumento. El caso hospital_id is not null (particularidad de un
-- custom_instrument, privado por workspace) sigue exigiendo
-- my_workspace_role como hasta ahora, sin cambios.

drop policy if exists instrument_sterilization_methods_select on instrument_sterilization_methods;
create policy instrument_sterilization_methods_select on instrument_sterilization_methods
  for select using (
    (hospital_id is null)
    or (hospital_id is not null and my_workspace_role(workspace_id) is not null)
  );

drop policy if exists instrument_technical_info_select on instrument_technical_info;
create policy instrument_technical_info_select on instrument_technical_info
  for select using (
    (hospital_id is null)
    or (hospital_id is not null and my_workspace_role(workspace_id) is not null)
  );
