-- schema_v73: el botó "Reportar un error" (catalog_content_reports, v45) ara
-- també és a les postures quirúrgiques i a les guies perioperatòries del
-- catàleg compilat. Mateixa taula i mateixa cua de l'Editorial Board; només
-- s'amplien els tipus admesos. instrument_ref_id és l'id de la postura/guia.
alter table catalog_content_reports
  drop constraint if exists catalog_content_reports_instrument_ref_type_check;
alter table catalog_content_reports
  add constraint catalog_content_reports_instrument_ref_type_check
  check (instrument_ref_type in ('catalog', 'custom', 'position', 'guide'));
