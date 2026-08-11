import '../data/instruments_data.dart';
import '../models/custom_instrument.dart';
import 'group_document_version.dart' show GroupDocumentVersionStatus, GroupDocumentVersionStatusLabel;

/// Origen de un [TrayItem]: mismo patrón polimórfico ya documentado en
/// supabase/schema_v15_clinical_knowledge_model.sql (instrument_ref_type/
/// instrument_ref_id), sin FK real porque el catálogo curado vive en Dart
/// (`lib/data/instruments_data.dart`), no en una tabla.
enum InstrumentRefType { catalog, custom }

extension InstrumentRefTypeLabel on InstrumentRefType {
  String get dbValue => name;

  static InstrumentRefType fromDb(String value) {
    return InstrumentRefType.values.firstWhere((t) => t.dbValue == value);
  }
}

/// Un elemento del checklist de una bandeja: referencia a un instrumento
/// (del catálogo global o personalizado del workspace) más la cantidad
/// esperada dentro de la bandeja.
class TrayItem {
  final InstrumentRefType instrumentRefType;
  final String instrumentRefId;
  final int expectedQty;

  /// Posición física dentro de la bandeja (p.ej. "Bandeja superior, fila 1"),
  /// texto libre porque el layout de una safata varía mucho entre equipos —
  /// no hay un esquema de slots estandarizado que valga para todos (EPIC 4).
  final String? position;

  const TrayItem({
    required this.instrumentRefType,
    required this.instrumentRefId,
    this.expectedQty = 1,
    this.position,
  });

  TrayItem copyWith({int? expectedQty, String? position, bool clearPosition = false}) => TrayItem(
        instrumentRefType: instrumentRefType,
        instrumentRefId: instrumentRefId,
        expectedQty: expectedQty ?? this.expectedQty,
        position: clearPosition ? null : (position ?? this.position),
      );

  Map<String, dynamic> toJson() => {
        'instrument_ref_type': instrumentRefType.dbValue,
        'instrument_ref_id': instrumentRefId,
        'expected_qty': expectedQty,
        'position': position,
      };

  factory TrayItem.fromJson(Map<String, dynamic> json) {
    return TrayItem(
      instrumentRefType: InstrumentRefTypeLabel.fromDb(json['instrument_ref_type'] as String),
      instrumentRefId: json['instrument_ref_id'] as String,
      expectedQty: (json['expected_qty'] as num?)?.toInt() ?? 1,
      position: json['position'] as String?,
    );
  }

  /// Nombre a mostrar, resuelto contra el catálogo global (`kInstruments`) o
  /// el instrumental personalizado del workspace ya cargado (mismo patrón de
  /// resolución que se usa para `related_instrument_ids` en técnicas/
  /// protocolos). Si no se encuentra (p.ej. instrumento personalizado
  /// borrado), devuelve el id crudo para no perder la referencia.
  String resolveName(List<CustomInstrument> customInstruments) {
    if (instrumentRefType == InstrumentRefType.catalog) {
      for (final i in kInstruments) {
        if (i.id == instrumentRefId) return i.name;
      }
      return instrumentRefId;
    }
    for (final c in customInstruments) {
      if (c.id == instrumentRefId) return c.name;
    }
    return instrumentRefId;
  }
}

/// Cabecera de una bandeja de instrumental. El contenido (nombre,
/// especialidad, fotos, items, observaciones) vive en [TrayVersion] — igual
/// que [GroupDocument]/[GroupDocumentVersion].
class Tray {
  final String id;
  final String organizationId;
  final String workspaceId;
  final String? createdBy;
  final DateTime? createdAt;
  final String? publishedVersionId;
  final TrayVersion? publishedVersion;

  const Tray({
    required this.id,
    required this.organizationId,
    required this.workspaceId,
    this.createdBy,
    this.createdAt,
    this.publishedVersionId,
    this.publishedVersion,
  });

  Tray copyWith({String? publishedVersionId, TrayVersion? publishedVersion}) {
    return Tray(
      id: id,
      organizationId: organizationId,
      workspaceId: workspaceId,
      createdBy: createdBy,
      createdAt: createdAt,
      publishedVersionId: publishedVersionId ?? this.publishedVersionId,
      publishedVersion: publishedVersion ?? this.publishedVersion,
    );
  }

  factory Tray.fromRow(Map<String, dynamic> row) {
    final versionRow = row['published_version'] as Map<String, dynamic>?;
    return Tray(
      id: row['id'] as String,
      organizationId: row['organization_id'] as String,
      workspaceId: row['workspace_id'] as String,
      createdBy: row['created_by'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      publishedVersionId: row['published_version_id'] as String?,
      publishedVersion: versionRow != null ? TrayVersion.fromRow(versionRow) : null,
    );
  }

  /// Fila completa para [OfflineCacheService] — ver [GroupDocument.toCacheRow].
  Map<String, dynamic> toCacheRow() => {
        'id': id,
        'organization_id': organizationId,
        'workspace_id': workspaceId,
        'created_by': createdBy,
        'created_at': createdAt?.toIso8601String(),
        'published_version_id': publishedVersionId,
        'published_version': publishedVersion?.toCacheRow(),
      };
}

/// Una versión concreta del contenido de una [Tray]. Calcado de
/// [GroupDocumentVersion]: cada edición crea una versión nueva en vez de
/// sobrescribir la anterior, con el mismo workflow borrador -> en revisión
/// -> publicada -> archivada (reutiliza [GroupDocumentVersionStatus]).
class TrayVersion {
  final String id;
  final String trayId;
  final int versionNumber;
  final GroupDocumentVersionStatus status;
  final String name;

  /// Texto libre heredado, ya no se escribe desde código nuevo (ver
  /// [specialtyId]) — se conserva solo para mostrar filas antiguas sin migrar.
  final String? specialty;

  /// FK a `specialties` (Fase C). Fuente de verdad para código nuevo.
  final String? specialtyId;
  final String? description;
  final List<String> photoPaths;
  final List<TrayItem> items;
  final String? observations;
  final String? authorId;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? comment;
  final String? basedOnVersionId;
  final DateTime? createdAt;

  /// true si esta versión solo existe localmente todavía — ver
  /// [GroupDocumentVersion.pendingSync] (mismo patrón, generalizado a
  /// bandejas en EPIC 7).
  final bool pendingSync;

  const TrayVersion({
    required this.id,
    required this.trayId,
    required this.versionNumber,
    required this.status,
    required this.name,
    this.specialty,
    this.specialtyId,
    this.description,
    this.photoPaths = const [],
    this.items = const [],
    this.observations,
    this.authorId,
    this.approvedBy,
    this.approvedAt,
    this.comment,
    this.basedOnVersionId,
    this.createdAt,
    this.pendingSync = false,
  });

  Map<String, dynamic> toRow() => {
        'name': name,
        'specialty_id': specialtyId,
        'description': description,
        'photo_paths': photoPaths,
        'items': items.map((i) => i.toJson()).toList(),
        'observations': observations,
        'comment': comment,
      };

  /// [clearSpecialtyId]/[clearDescription]/[clearObservations]: campos
  /// nullable donde pasar `null` no basta para vaciarlos (se confundiría con
  /// "no lo toques") — hay que pedirlo explícitamente, mismo patrón que
  /// [GroupDocumentVersion.copyWith].
  TrayVersion copyWith({
    String? name,
    String? specialtyId,
    bool clearSpecialtyId = false,
    String? description,
    bool clearDescription = false,
    List<String>? photoPaths,
    List<TrayItem>? items,
    String? observations,
    bool clearObservations = false,
    String? comment,
    bool? pendingSync,
  }) {
    return TrayVersion(
      id: id,
      trayId: trayId,
      versionNumber: versionNumber,
      status: status,
      name: name ?? this.name,
      specialty: specialty,
      specialtyId: clearSpecialtyId ? null : (specialtyId ?? this.specialtyId),
      description: clearDescription ? null : (description ?? this.description),
      photoPaths: photoPaths ?? this.photoPaths,
      items: items ?? this.items,
      observations: clearObservations ? null : (observations ?? this.observations),
      authorId: authorId,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      comment: comment ?? this.comment,
      basedOnVersionId: basedOnVersionId,
      createdAt: createdAt,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  factory TrayVersion.fromRow(Map<String, dynamic> row) {
    return TrayVersion(
      id: row['id'] as String,
      trayId: row['tray_id'] as String,
      versionNumber: row['version_number'] as int,
      status: GroupDocumentVersionStatusLabel.fromDb(row['status'] as String),
      name: row['name'] as String? ?? '',
      specialty: row['specialty'] as String?,
      specialtyId: row['specialty_id'] as String?,
      description: row['description'] as String?,
      photoPaths: (row['photo_paths'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      items: (row['items'] as List<dynamic>? ?? [])
          .map((e) => TrayItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      observations: row['observations'] as String?,
      authorId: row['author_id'] as String?,
      approvedBy: row['approved_by'] as String?,
      approvedAt: row['approved_at'] != null ? DateTime.tryParse(row['approved_at'] as String) : null,
      comment: row['comment'] as String?,
      basedOnVersionId: row['based_on_version_id'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      pendingSync: row['pending_sync'] as bool? ?? false,
    );
  }

  /// Fila completa para [OfflineCacheService] — ver
  /// [GroupDocumentVersion.toCacheRow].
  Map<String, dynamic> toCacheRow() => {
        'id': id,
        'tray_id': trayId,
        'version_number': versionNumber,
        'status': status.dbValue,
        'name': name,
        'specialty': specialty,
        'specialty_id': specialtyId,
        'description': description,
        'photo_paths': photoPaths,
        'items': items.map((i) => i.toJson()).toList(),
        'observations': observations,
        'author_id': authorId,
        'approved_by': approvedBy,
        'approved_at': approvedAt?.toIso8601String(),
        'comment': comment,
        'based_on_version_id': basedOnVersionId,
        'created_at': createdAt?.toIso8601String(),
        'pending_sync': pendingSync,
      };
}
