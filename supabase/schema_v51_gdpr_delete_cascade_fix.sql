-- Corrige un bug real encontrado en la auditoria de cara a la v1.0:
-- delete_my_account() (schema_v20_organizations_rename.sql) borra
-- `organizations` confiando en que la cascada existente se lleva todo el
-- contenido del grupo, pero 4 tablas (custom_instruments, trays,
-- instrument_sterilization_methods, instrument_technical_info) nunca
-- tuvieron `on delete cascade` en sus FK a organizations/workspaces -- a
-- diferencia de group_documents, preference_cards, workspace_members,
-- surgeons, taggings y reference_documents, que si lo tienen desde el
-- principio.
--
-- Efecto real: cualquier propietaria/o de un grupo sin mas miembros (el
-- caso "equipo privado" que la propia app soporta explicitamente) que haya
-- creado alguna vez una safata, instrumental personalizado, un metodo de
-- esterilizacion o una ficha tecnica en su espacio, no puede borrar su
-- cuenta -- la transaccion entera falla con una violacion de FK y se
-- deshace, incluido el `delete from auth.users` final. La solicitud de
-- borrado RGPD del usuario falla en silencio.

alter table custom_instruments
  drop constraint if exists custom_instruments_hospital_id_fkey,
  add constraint custom_instruments_hospital_id_fkey
    foreign key (organization_id) references organizations(id) on delete cascade;

alter table custom_instruments
  drop constraint if exists custom_instruments_workspace_id_fkey,
  add constraint custom_instruments_workspace_id_fkey
    foreign key (workspace_id) references workspaces(id) on delete cascade;

alter table trays
  drop constraint if exists trays_hospital_id_fkey,
  add constraint trays_hospital_id_fkey
    foreign key (organization_id) references organizations(id) on delete cascade;

alter table trays
  drop constraint if exists trays_workspace_id_fkey,
  add constraint trays_workspace_id_fkey
    foreign key (workspace_id) references workspaces(id) on delete cascade;

alter table instrument_sterilization_methods
  drop constraint if exists instrument_sterilization_methods_hospital_id_fkey,
  add constraint instrument_sterilization_methods_hospital_id_fkey
    foreign key (organization_id) references organizations(id) on delete cascade;

alter table instrument_sterilization_methods
  drop constraint if exists instrument_sterilization_methods_workspace_id_fkey,
  add constraint instrument_sterilization_methods_workspace_id_fkey
    foreign key (workspace_id) references workspaces(id) on delete cascade;

alter table instrument_technical_info
  drop constraint if exists instrument_technical_info_hospital_id_fkey,
  add constraint instrument_technical_info_hospital_id_fkey
    foreign key (organization_id) references organizations(id) on delete cascade;

alter table instrument_technical_info
  drop constraint if exists instrument_technical_info_workspace_id_fkey,
  add constraint instrument_technical_info_workspace_id_fkey
    foreign key (workspace_id) references workspaces(id) on delete cascade;
