import 'group_document_version.dart' show GroupDocumentVersionStatus, GroupDocumentVersionStatusLabel;

/// Método de esterilización de un instrumento (catálogo global o instrumento
/// personalizado de un equipo, ver [SterilizationMethodEntry.instrumentRefType]).
/// Ver supabase/schema_v32_cssd_workspace.sql para el modelo completo
/// (referencia polimórfica, RLS, catálogo global vs. workspace, versionado).
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

/// Cabecera de `instrument_sterilization_methods`. El contenido (método,
/// parámetros, lubricación...) vive en [SterilizationMethodVersion] — igual
/// que [PreferenceCard]/[Tray] (ver schema_v32_cssd_workspace.sql). Un mismo
/// instrumento puede tener varias cabeceras (una por método de
/// esterilización posible), cada una con su propio historial de versiones.
class SterilizationMethodEntry {
  final String? id;
  final String instrumentRefType;
  final String instrumentRefId;
  final String? organizationId;
  final String? workspaceId;
  final String? createdBy;
  final DateTime? createdAt;
  final String? publishedVersionId;
  final SterilizationMethodVersion? publishedVersion;

  const SterilizationMethodEntry({
    this.id,
    required this.instrumentRefType,
    required this.instrumentRefId,
    this.organizationId,
    this.workspaceId,
    this.createdBy,
    this.createdAt,
    this.publishedVersionId,
    this.publishedVersion,
  });

  SterilizationMethodEntry copyWith({
    String? publishedVersionId,
    SterilizationMethodVersion? publishedVersion,
  }) {
    return SterilizationMethodEntry(
      id: id,
      instrumentRefType: instrumentRefType,
      instrumentRefId: instrumentRefId,
      organizationId: organizationId,
      workspaceId: workspaceId,
      createdBy: createdBy,
      createdAt: createdAt,
      publishedVersionId: publishedVersionId ?? this.publishedVersionId,
      publishedVersion: publishedVersion ?? this.publishedVersion,
    );
  }

  factory SterilizationMethodEntry.fromRow(Map<String, dynamic> row) {
    final versionRow = row['published_version'] as Map<String, dynamic>?;
    return SterilizationMethodEntry(
      id: row['id'] as String?,
      instrumentRefType: row['instrument_ref_type'] as String,
      instrumentRefId: row['instrument_ref_id'] as String,
      organizationId: row['organization_id'] as String?,
      workspaceId: row['workspace_id'] as String?,
      createdBy: row['created_by'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      publishedVersionId: row['published_version_id'] as String?,
      publishedVersion: versionRow != null ? SterilizationMethodVersion.fromRow(versionRow) : null,
    );
  }
}

/// Una versión concreta del contenido de una [SterilizationMethodEntry].
/// Cada edición crea una versión nueva en vez de sobrescribir la anterior,
/// con el mismo workflow borrador -> en revisión -> publicada -> archivada
/// que [PreferenceCardVersion]/[TrayVersion].
class SterilizationMethodVersion {
  final String id;
  final String methodId;
  final int versionNumber;
  final GroupDocumentVersionStatus status;
  final SterilizationMethod method;
  final String? temperature;
  final String? timeMinutes;
  final String? pressure;
  final String? drying;
  final String? recommendedCycle;
  final String? compatibilityNotes;
  final String? restrictions;
  final String? observations;

  /// Lubricación: bullet propio de EPIC 3 (antes no existía como campo
  /// estructurado, era parte del texto libre de [observations]).
  final bool lubricationRequired;
  final String? lubricationType;
  final String? lubricationNotes;

  final String? authorId;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? comment;
  final String? basedOnVersionId;
  final DateTime? createdAt;

  /// true si esta versión solo existe localmente todavía — ver
  /// [GroupDocumentVersion.pendingSync] (mismo patrón, generalizado a
  /// esterilización en EPIC 7).
  final bool pendingSync;

  const SterilizationMethodVersion({
    required this.id,
    required this.methodId,
    required this.versionNumber,
    required this.status,
    required this.method,
    this.temperature,
    this.timeMinutes,
    this.pressure,
    this.drying,
    this.recommendedCycle,
    this.compatibilityNotes,
    this.restrictions,
    this.observations,
    this.lubricationRequired = false,
    this.lubricationType,
    this.lubricationNotes,
    this.authorId,
    this.approvedBy,
    this.approvedAt,
    this.comment,
    this.basedOnVersionId,
    this.createdAt,
    this.pendingSync = false,
  });

  Map<String, dynamic> toRow() => {
        'method': method.dbValue,
        'temperature': temperature,
        'time_minutes': timeMinutes,
        'pressure': pressure,
        'drying': drying,
        'recommended_cycle': recommendedCycle,
        'compatibility_notes': compatibilityNotes,
        'restrictions': restrictions,
        'observations': observations,
        'lubrication_required': lubricationRequired,
        'lubrication_type': lubricationType,
        'lubrication_notes': lubricationNotes,
        'comment': comment,
      };

  /// [clearTemperature]..[clearLubricationNotes]: campos nullable donde pasar
  /// `null` no basta para vaciarlos (se confundiría con "no lo toques") —
  /// hay que pedirlo explícitamente, mismo patrón que [TrayVersion.copyWith].
  SterilizationMethodVersion copyWith({
    SterilizationMethod? method,
    String? temperature,
    bool clearTemperature = false,
    String? timeMinutes,
    bool clearTimeMinutes = false,
    String? pressure,
    bool clearPressure = false,
    String? drying,
    bool clearDrying = false,
    String? recommendedCycle,
    bool clearRecommendedCycle = false,
    String? compatibilityNotes,
    bool clearCompatibilityNotes = false,
    String? restrictions,
    bool clearRestrictions = false,
    String? observations,
    bool clearObservations = false,
    bool? lubricationRequired,
    String? lubricationType,
    bool clearLubricationType = false,
    String? lubricationNotes,
    bool clearLubricationNotes = false,
    String? comment,
    bool? pendingSync,
  }) {
    return SterilizationMethodVersion(
      id: id,
      methodId: methodId,
      versionNumber: versionNumber,
      status: status,
      method: method ?? this.method,
      temperature: clearTemperature ? null : (temperature ?? this.temperature),
      timeMinutes: clearTimeMinutes ? null : (timeMinutes ?? this.timeMinutes),
      pressure: clearPressure ? null : (pressure ?? this.pressure),
      drying: clearDrying ? null : (drying ?? this.drying),
      recommendedCycle: clearRecommendedCycle ? null : (recommendedCycle ?? this.recommendedCycle),
      compatibilityNotes: clearCompatibilityNotes ? null : (compatibilityNotes ?? this.compatibilityNotes),
      restrictions: clearRestrictions ? null : (restrictions ?? this.restrictions),
      observations: clearObservations ? null : (observations ?? this.observations),
      lubricationRequired: lubricationRequired ?? this.lubricationRequired,
      lubricationType: clearLubricationType ? null : (lubricationType ?? this.lubricationType),
      lubricationNotes: clearLubricationNotes ? null : (lubricationNotes ?? this.lubricationNotes),
      authorId: authorId,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      comment: comment ?? this.comment,
      basedOnVersionId: basedOnVersionId,
      createdAt: createdAt,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  factory SterilizationMethodVersion.fromRow(Map<String, dynamic> row) {
    return SterilizationMethodVersion(
      id: row['id'] as String,
      methodId: row['method_id'] as String,
      versionNumber: row['version_number'] as int,
      status: GroupDocumentVersionStatusLabel.fromDb(row['status'] as String),
      method: SterilizationMethodLabel.fromDb(row['method'] as String),
      temperature: row['temperature'] as String?,
      timeMinutes: row['time_minutes'] as String?,
      pressure: row['pressure'] as String?,
      drying: row['drying'] as String?,
      recommendedCycle: row['recommended_cycle'] as String?,
      compatibilityNotes: row['compatibility_notes'] as String?,
      restrictions: row['restrictions'] as String?,
      observations: row['observations'] as String?,
      lubricationRequired: row['lubrication_required'] as bool? ?? false,
      lubricationType: row['lubrication_type'] as String?,
      lubricationNotes: row['lubrication_notes'] as String?,
      authorId: row['author_id'] as String?,
      approvedBy: row['approved_by'] as String?,
      approvedAt: row['approved_at'] != null ? DateTime.tryParse(row['approved_at'] as String) : null,
      comment: row['comment'] as String?,
      basedOnVersionId: row['based_on_version_id'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      pendingSync: row['pending_sync'] as bool? ?? false,
    );
  }
}

/// Cabecera (única por instrumento) de `instrument_technical_info`. El
/// contenido vive en [InstrumentTechnicalInfoVersion] — mismo patrón que
/// [SterilizationMethodEntry].
class InstrumentTechnicalInfo {
  final String? id;
  final String instrumentRefType;
  final String instrumentRefId;
  final String? organizationId;
  final String? workspaceId;
  final String? createdBy;
  final DateTime? createdAt;
  final String? publishedVersionId;
  final InstrumentTechnicalInfoVersion? publishedVersion;

  const InstrumentTechnicalInfo({
    this.id,
    required this.instrumentRefType,
    required this.instrumentRefId,
    this.organizationId,
    this.workspaceId,
    this.createdBy,
    this.createdAt,
    this.publishedVersionId,
    this.publishedVersion,
  });

  InstrumentTechnicalInfo copyWith({
    String? publishedVersionId,
    InstrumentTechnicalInfoVersion? publishedVersion,
  }) {
    return InstrumentTechnicalInfo(
      id: id,
      instrumentRefType: instrumentRefType,
      instrumentRefId: instrumentRefId,
      organizationId: organizationId,
      workspaceId: workspaceId,
      createdBy: createdBy,
      createdAt: createdAt,
      publishedVersionId: publishedVersionId ?? this.publishedVersionId,
      publishedVersion: publishedVersion ?? this.publishedVersion,
    );
  }

  factory InstrumentTechnicalInfo.fromRow(Map<String, dynamic> row) {
    final versionRow = row['published_version'] as Map<String, dynamic>?;
    return InstrumentTechnicalInfo(
      id: row['id'] as String?,
      instrumentRefType: row['instrument_ref_type'] as String,
      instrumentRefId: row['instrument_ref_id'] as String,
      organizationId: row['organization_id'] as String?,
      workspaceId: row['workspace_id'] as String?,
      createdBy: row['created_by'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      publishedVersionId: row['published_version_id'] as String?,
      publishedVersion: versionRow != null ? InstrumentTechnicalInfoVersion.fromRow(versionRow) : null,
    );
  }
}

/// Una versión concreta del contenido de un [InstrumentTechnicalInfo].
/// [manufacturerId]/[ifuDocumentId] son FKs (a `manufacturers`/
/// `reference_documents`); [maintenanceIntervalDays]/[lastMaintenanceAt] son
/// el mantenimiento estructurado nuevo de EPIC 3 (antes texto libre).
class InstrumentTechnicalInfoVersion {
  final String id;
  final String infoId;
  final int versionNumber;
  final GroupDocumentVersionStatus status;
  final String? manufacturerId;
  final String? ifuDocumentId;
  final String? maintenanceNotes;
  final String? inspectionNotes;
  final String? usefulLifeNotes;
  final int? maintenanceIntervalDays;
  final DateTime? lastMaintenanceAt;
  final String? authorId;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? comment;
  final String? basedOnVersionId;
  final DateTime? createdAt;

  /// true si esta versión solo existe localmente todavía — ver
  /// [GroupDocumentVersion.pendingSync] (mismo patrón, generalizado a ficha
  /// técnica en EPIC 7).
  final bool pendingSync;

  const InstrumentTechnicalInfoVersion({
    required this.id,
    required this.infoId,
    required this.versionNumber,
    required this.status,
    this.manufacturerId,
    this.ifuDocumentId,
    this.maintenanceNotes,
    this.inspectionNotes,
    this.usefulLifeNotes,
    this.maintenanceIntervalDays,
    this.lastMaintenanceAt,
    this.authorId,
    this.approvedBy,
    this.approvedAt,
    this.comment,
    this.basedOnVersionId,
    this.createdAt,
    this.pendingSync = false,
  });

  Map<String, dynamic> toRow() => {
        'manufacturer_id': manufacturerId,
        'ifu_document_id': ifuDocumentId,
        'maintenance_notes': maintenanceNotes,
        'inspection_notes': inspectionNotes,
        'useful_life_notes': usefulLifeNotes,
        'maintenance_interval_days': maintenanceIntervalDays,
        'last_maintenance_at': lastMaintenanceAt?.toIso8601String().split('T').first,
        'comment': comment,
      };

  /// [clearManufacturerId]..[clearLastMaintenanceAt]: campos nullable donde
  /// pasar `null` no basta para vaciarlos — hay que pedirlo explícitamente,
  /// mismo patrón que [InstrumentTechnicalInfo.copyWith] anterior a esta fase.
  InstrumentTechnicalInfoVersion copyWith({
    String? manufacturerId,
    bool clearManufacturerId = false,
    String? ifuDocumentId,
    bool clearIfuDocumentId = false,
    String? maintenanceNotes,
    bool clearMaintenanceNotes = false,
    String? inspectionNotes,
    bool clearInspectionNotes = false,
    String? usefulLifeNotes,
    bool clearUsefulLifeNotes = false,
    int? maintenanceIntervalDays,
    bool clearMaintenanceIntervalDays = false,
    DateTime? lastMaintenanceAt,
    bool clearLastMaintenanceAt = false,
    String? comment,
    bool? pendingSync,
  }) {
    return InstrumentTechnicalInfoVersion(
      id: id,
      infoId: infoId,
      versionNumber: versionNumber,
      status: status,
      manufacturerId: clearManufacturerId ? null : (manufacturerId ?? this.manufacturerId),
      ifuDocumentId: clearIfuDocumentId ? null : (ifuDocumentId ?? this.ifuDocumentId),
      maintenanceNotes: clearMaintenanceNotes ? null : (maintenanceNotes ?? this.maintenanceNotes),
      inspectionNotes: clearInspectionNotes ? null : (inspectionNotes ?? this.inspectionNotes),
      usefulLifeNotes: clearUsefulLifeNotes ? null : (usefulLifeNotes ?? this.usefulLifeNotes),
      maintenanceIntervalDays:
          clearMaintenanceIntervalDays ? null : (maintenanceIntervalDays ?? this.maintenanceIntervalDays),
      lastMaintenanceAt: clearLastMaintenanceAt ? null : (lastMaintenanceAt ?? this.lastMaintenanceAt),
      authorId: authorId,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      comment: comment ?? this.comment,
      basedOnVersionId: basedOnVersionId,
      createdAt: createdAt,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  factory InstrumentTechnicalInfoVersion.fromRow(Map<String, dynamic> row) {
    return InstrumentTechnicalInfoVersion(
      id: row['id'] as String,
      infoId: row['info_id'] as String,
      versionNumber: row['version_number'] as int,
      status: GroupDocumentVersionStatusLabel.fromDb(row['status'] as String),
      manufacturerId: row['manufacturer_id'] as String?,
      ifuDocumentId: row['ifu_document_id'] as String?,
      maintenanceNotes: row['maintenance_notes'] as String?,
      inspectionNotes: row['inspection_notes'] as String?,
      usefulLifeNotes: row['useful_life_notes'] as String?,
      maintenanceIntervalDays: row['maintenance_interval_days'] as int?,
      lastMaintenanceAt:
          row['last_maintenance_at'] != null ? DateTime.tryParse(row['last_maintenance_at'] as String) : null,
      authorId: row['author_id'] as String?,
      approvedBy: row['approved_by'] as String?,
      approvedAt: row['approved_at'] != null ? DateTime.tryParse(row['approved_at'] as String) : null,
      comment: row['comment'] as String?,
      basedOnVersionId: row['based_on_version_id'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      pendingSync: row['pending_sync'] as bool? ?? false,
    );
  }
}
