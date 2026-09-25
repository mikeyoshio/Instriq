import '../l10n/app_localizations.dart';

/// Espejo de `organizations.org_type` (`schema_v20_organizations_rename.sql`,
/// check constraint) -- las mismas 6 categorías que ya existen en la
/// landing ("Per a qui és", `landing/index.html`), ahora también
/// seleccionables al crear el grupo, no solo como copy de marketing.
enum OrgType {
  hospital,
  clinica,
  universidad,
  centroSimulacion,
  fabricante,
  equipoPrivado;

  String get dbValue => switch (this) {
        OrgType.hospital => 'hospital',
        OrgType.clinica => 'clinica',
        OrgType.universidad => 'universidad',
        OrgType.centroSimulacion => 'centro_simulacion',
        OrgType.fabricante => 'fabricante',
        OrgType.equipoPrivado => 'equipo_privado',
      };

  static OrgType fromDb(String value) => switch (value) {
        'clinica' => OrgType.clinica,
        'universidad' => OrgType.universidad,
        'centro_simulacion' => OrgType.centroSimulacion,
        'fabricante' => OrgType.fabricante,
        'equipo_privado' => OrgType.equipoPrivado,
        _ => OrgType.hospital,
      };
}

extension OrgTypeLabel on OrgType {
  String label(AppLocalizations l10n) => switch (this) {
        OrgType.hospital => l10n.orgTypeHospital,
        OrgType.clinica => l10n.orgTypeClinica,
        OrgType.universidad => l10n.orgTypeUniversidad,
        OrgType.centroSimulacion => l10n.orgTypeCentroSimulacion,
        OrgType.fabricante => l10n.orgTypeFabricante,
        OrgType.equipoPrivado => l10n.orgTypeEquipoPrivado,
      };
}
