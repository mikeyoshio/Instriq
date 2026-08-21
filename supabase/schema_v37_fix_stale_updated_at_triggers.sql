-- Bug real trobat en una bateria de proves en viu (2026-08-20): aprovar
-- QUALSEVOL mètode d'esterilització o fitxa tècnica (catàleg global o
-- instrumental personalitzat) fallava amb
--   PostgrestException: record "new" has no field "updated_at" (42703)
--
-- Causa: schema_v15_clinical_knowledge_model.sql va crear
-- instrument_sterilization_methods/instrument_technical_info amb una
-- columna updated_at i un trigger BEFORE UPDATE que l'actualitza.
-- schema_v32_cssd_workspace.sql (EPIC 3) va eliminar la columna updated_at
-- d'aquestes 2 taules (ja no calia, published_version_id ja fa de rastre
-- de canvi) però mai va eliminar el trigger corresponent -- des de
-- llavors, qualsevol UPDATE a aquestes capçaleres (p.ex. approve_*_version
-- fixant published_version_id) ha fallat en sec. Aquest camí de codi mai
-- s'havia provat en viu fins ara (verificació manual pendent des de la
-- implementació original d'EPIC 3), així que el bug havia passat
-- desapercebut.
drop trigger if exists instrument_sterilization_methods_set_updated_at on instrument_sterilization_methods;
drop function if exists set_instrument_sterilization_method_updated_at();

drop trigger if exists instrument_technical_info_set_updated_at on instrument_technical_info;
drop function if exists set_instrument_technical_info_updated_at();
