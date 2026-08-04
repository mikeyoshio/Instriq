-- Corrige un bug real de deriva por duplicacion manual del patron de
-- versionado (encontrado durante la investigacion de ADR-004,
-- docs/ADR_004_VERSIONING.md): preference_card_versions nunca tuvo las
-- restricciones de unicidad que SI tienen group_document_versions
-- (schema_v5) y tray_versions (schema_v15) desde su creacion -- nada
-- impedia dos versiones con el mismo version_number para la misma
-- tarjeta, ni dos versiones publicadas a la vez. Verificado antes de
-- aplicar: no hay filas existentes que violen ninguna de las dos reglas.

alter table preference_card_versions
  add constraint preference_card_versions_card_id_version_number_key
  unique (card_id, version_number);

-- Como mucho una version publicada por tarjeta -- mismo criterio que
-- group_document_versions_one_published_idx / tray_versions_one_published_idx.
create unique index if not exists preference_card_versions_one_published_idx
  on preference_card_versions (card_id)
  where status = 'published';
