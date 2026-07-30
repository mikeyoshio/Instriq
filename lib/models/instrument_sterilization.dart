/// Método de esterilización de un instrumento (catálogo global o instrumento
/// personalizado de un equipo, ver [SterilizationMethodEntry.instrumentRefType]).
/// Ver supabase/schema_v15_clinical_knowledge_model.sql para el modelo
/// completo (referencia polimórfica, RLS, catálogo global vs. workspace).
enum SterilizationMethod {
  vapor,
  plasma,
  oxidoEtileno,
  bajaTemperatura,
  desechable,
  noEsterilizable,
}

extension SterilizationMethodLabel on SterilizationMethod {
  String get label {
    switch (this) {
      case SterilizationMethod.vapor:
        return 'Vapor (autoclave)';
      case SterilizationMethod.plasma:
        return 'Plasma de peróxido de hidrógeno';
      case SterilizationMethod.oxidoEtileno:
        return 'Óxido de etileno';
      case SterilizationMethod.bajaTemperatura:
        return 'Baja temperatura (otros)';
      case SterilizationMethod.desechable:
        return 'Desechable (un solo uso)';
      case SterilizationMethod.noEsterilizable:
        return 'No esterilizable';
    }
  }

  String get dbValue {
    switch (this) {
      case SterilizationMethod.vapor:
        return 'vapor';
      case SterilizationMethod.plasma:
        return 'plasma';
      case SterilizationMethod.oxidoEtileno:
        return 'oxido_etileno';
      case SterilizationMethod.bajaTemperatura:
        return 'baja_temperatura';
      case SterilizationMethod.desechable:
        return 'desechable';
      case SterilizationMethod.noEsterilizable:
        return 'no_esterilizable';
    }
  }

  static SterilizationMethod fromDb(String value) {
    switch (value) {
      case 'vapor':
        return SterilizationMethod.vapor;
      case 'plasma':
        return SterilizationMethod.plasma;
      case 'oxido_etileno':
        return SterilizationMethod.oxidoEtileno;
      case 'baja_temperatura':
        return SterilizationMethod.bajaTemperatura;
      case 'desechable':
        return SterilizationMethod.desechable;
      case 'no_esterilizable':
        return SterilizationMethod.noEsterilizable;
      default:
        throw ArgumentError('Método de esterilización desconocido: $value');
    }
  }
}

/// Una fila de `instrument_sterilization_methods`. [organizationId]/[workspaceId]
/// nulos significan que es un dato de catálogo global (curado, visible para
/// cualquier hospital); no nulos, que es una particularidad de un
/// `custom_instrument` de ese workspace.
class SterilizationMethodEntry {
  final String? id;
  final String instrumentRefType;
  final String instrumentRefId;
  final String? organizationId;
  final String? workspaceId;
  final SterilizationMethod method;
  final String? temperature;
  final String? timeMinutes;
  final String? pressure;
  final String? drying;
  final String? recommendedCycle;
  final String? compatibilityNotes;
  final String? restrictions;
  final String? observations;

  const SterilizationMethodEntry({
    this.id,
    required this.instrumentRefType,
    required this.instrumentRefId,
    this.organizationId,
    this.workspaceId,
    required this.method,
    this.temperature,
    this.timeMinutes,
    this.pressure,
    this.drying,
    this.recommendedCycle,
    this.compatibilityNotes,
    this.restrictions,
    this.observations,
  });

  Map<String, dynamic> toRow() => {
        'instrument_ref_type': instrumentRefType,
        'instrument_ref_id': instrumentRefId,
        'organization_id': organizationId,
        'workspace_id': workspaceId,
        'method': method.dbValue,
        'temperature': temperature,
        'time_minutes': timeMinutes,
        'pressure': pressure,
        'drying': drying,
        'recommended_cycle': recommendedCycle,
        'compatibility_notes': compatibilityNotes,
        'restrictions': restrictions,
        'observations': observations,
      };

  SterilizationMethodEntry copyWith({
    SterilizationMethod? method,
    String? temperature,
    String? timeMinutes,
    String? pressure,
    String? drying,
    String? recommendedCycle,
    String? compatibilityNotes,
    String? restrictions,
    String? observations,
  }) {
    return SterilizationMethodEntry(
      id: id,
      instrumentRefType: instrumentRefType,
      instrumentRefId: instrumentRefId,
      organizationId: organizationId,
      workspaceId: workspaceId,
      method: method ?? this.method,
      temperature: temperature ?? this.temperature,
      timeMinutes: timeMinutes ?? this.timeMinutes,
      pressure: pressure ?? this.pressure,
      drying: drying ?? this.drying,
      recommendedCycle: recommendedCycle ?? this.recommendedCycle,
      compatibilityNotes: compatibilityNotes ?? this.compatibilityNotes,
      restrictions: restrictions ?? this.restrictions,
      observations: observations ?? this.observations,
    );
  }

  factory SterilizationMethodEntry.fromRow(Map<String, dynamic> row) {
    return SterilizationMethodEntry(
      id: row['id'] as String?,
      instrumentRefType: row['instrument_ref_type'] as String,
      instrumentRefId: row['instrument_ref_id'] as String,
      organizationId: row['organization_id'] as String?,
      workspaceId: row['workspace_id'] as String?,
      method: SterilizationMethodLabel.fromDb(row['method'] as String),
      temperature: row['temperature'] as String?,
      timeMinutes: row['time_minutes'] as String?,
      pressure: row['pressure'] as String?,
      drying: row['drying'] as String?,
      recommendedCycle: row['recommended_cycle'] as String?,
      compatibilityNotes: row['compatibility_notes'] as String?,
      restrictions: row['restrictions'] as String?,
      observations: row['observations'] as String?,
    );
  }
}

/// La fila (única por instrumento) de `instrument_technical_info`.
/// [manufacturerId]/[ifuDocumentId] son FKs (a `manufacturers`/
/// `reference_documents`) desde Fase C — las columnas de texto libre
/// `manufacturer`/`ifu_url` ya no existen en la BD.
class InstrumentTechnicalInfo {
  final String? id;
  final String instrumentRefType;
  final String instrumentRefId;
  final String? organizationId;
  final String? workspaceId;
  final String? manufacturerId;
  final String? ifuDocumentId;
  final String? maintenanceNotes;
  final String? inspectionNotes;
  final String? usefulLifeNotes;

  const InstrumentTechnicalInfo({
    this.id,
    required this.instrumentRefType,
    required this.instrumentRefId,
    this.organizationId,
    this.workspaceId,
    this.manufacturerId,
    this.ifuDocumentId,
    this.maintenanceNotes,
    this.inspectionNotes,
    this.usefulLifeNotes,
  });

  Map<String, dynamic> toRow() => {
        'instrument_ref_type': instrumentRefType,
        'instrument_ref_id': instrumentRefId,
        'organization_id': organizationId,
        'workspace_id': workspaceId,
        'manufacturer_id': manufacturerId,
        'ifu_document_id': ifuDocumentId,
        'maintenance_notes': maintenanceNotes,
        'inspection_notes': inspectionNotes,
        'useful_life_notes': usefulLifeNotes,
      };

  InstrumentTechnicalInfo copyWith({
    String? manufacturerId,
    bool clearManufacturerId = false,
    String? ifuDocumentId,
    bool clearIfuDocumentId = false,
    String? maintenanceNotes,
    String? inspectionNotes,
    String? usefulLifeNotes,
  }) {
    return InstrumentTechnicalInfo(
      id: id,
      instrumentRefType: instrumentRefType,
      instrumentRefId: instrumentRefId,
      organizationId: organizationId,
      workspaceId: workspaceId,
      manufacturerId: clearManufacturerId ? null : (manufacturerId ?? this.manufacturerId),
      ifuDocumentId: clearIfuDocumentId ? null : (ifuDocumentId ?? this.ifuDocumentId),
      maintenanceNotes: maintenanceNotes ?? this.maintenanceNotes,
      inspectionNotes: inspectionNotes ?? this.inspectionNotes,
      usefulLifeNotes: usefulLifeNotes ?? this.usefulLifeNotes,
    );
  }

  factory InstrumentTechnicalInfo.fromRow(Map<String, dynamic> row) {
    return InstrumentTechnicalInfo(
      id: row['id'] as String?,
      instrumentRefType: row['instrument_ref_type'] as String,
      instrumentRefId: row['instrument_ref_id'] as String,
      organizationId: row['organization_id'] as String?,
      workspaceId: row['workspace_id'] as String?,
      manufacturerId: row['manufacturer_id'] as String?,
      ifuDocumentId: row['ifu_document_id'] as String?,
      maintenanceNotes: row['maintenance_notes'] as String?,
      inspectionNotes: row['inspection_notes'] as String?,
      usefulLifeNotes: row['useful_life_notes'] as String?,
    );
  }
}
