import 'tray.dart' show InstrumentRefType, InstrumentRefTypeLabel;

/// Resultado real de un ítem del checklist en una sesión de preparación
/// concreta: lo que se pidió (`expectedQty`, copiado de la versión publicada
/// en el momento de preparar) frente a lo que había de verdad (`actualQty`/
/// `present`). Es un snapshot, no una referencia viva a `TrayItem` — si la
/// definición de la bandeja cambia después, esta sesión sigue reflejando lo
/// que pasó ese día (EPIC 4).
class TrayPreparationItemResult {
  final InstrumentRefType instrumentRefType;
  final String instrumentRefId;
  final int expectedQty;
  final int actualQty;
  final bool present;
  final String? note;

  const TrayPreparationItemResult({
    required this.instrumentRefType,
    required this.instrumentRefId,
    required this.expectedQty,
    required this.actualQty,
    required this.present,
    this.note,
  });

  TrayPreparationItemResult copyWith({int? actualQty, bool? present, String? note}) => TrayPreparationItemResult(
        instrumentRefType: instrumentRefType,
        instrumentRefId: instrumentRefId,
        expectedQty: expectedQty,
        actualQty: actualQty ?? this.actualQty,
        present: present ?? this.present,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'instrument_ref_type': instrumentRefType.dbValue,
        'instrument_ref_id': instrumentRefId,
        'expected_qty': expectedQty,
        'actual_qty': actualQty,
        'present': present,
        'note': note,
      };

  factory TrayPreparationItemResult.fromJson(Map<String, dynamic> json) {
    return TrayPreparationItemResult(
      instrumentRefType: InstrumentRefTypeLabel.fromDb(json['instrument_ref_type'] as String),
      instrumentRefId: json['instrument_ref_id'] as String,
      expectedQty: (json['expected_qty'] as num?)?.toInt() ?? 1,
      actualQty: (json['actual_qty'] as num?)?.toInt() ?? 0,
      present: json['present'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }
}

enum TrayPreparationStatus { prepared, qcPassed, qcFailed }

extension TrayPreparationStatusLabel on TrayPreparationStatus {
  String get dbValue {
    switch (this) {
      case TrayPreparationStatus.prepared:
        return 'prepared';
      case TrayPreparationStatus.qcPassed:
        return 'qc_passed';
      case TrayPreparationStatus.qcFailed:
        return 'qc_failed';
    }
  }

  static TrayPreparationStatus fromDb(String value) {
    switch (value) {
      case 'prepared':
        return TrayPreparationStatus.prepared;
      case 'qc_passed':
        return TrayPreparationStatus.qcPassed;
      case 'qc_failed':
        return TrayPreparationStatus.qcFailed;
      default:
        throw ArgumentError('Estado de sesión de preparación desconocido: $value');
    }
  }
}

/// Un montaje físico real de una bandeja tras el lavado/esterilización:
/// quién la preparó, qué encontró item a item, y el control de
/// calidad/validación de otra persona (o la misma) sobre esa sesión
/// concreta (EPIC 4 · Bandejas 2.0).
class TrayPreparationSession {
  final String id;
  final String trayId;
  final String trayVersionId;
  final String? preparedBy;
  final DateTime preparedAt;
  final List<TrayPreparationItemResult> itemResults;
  final TrayPreparationStatus status;
  final String? qcBy;
  final DateTime? qcAt;
  final String? qcNotes;

  /// `display_name` de `profiles`, resuelto aparte por
  /// [TrayPreparationService.fetchSessions] (mismo patrón que
  /// `AuditService.fetchAuditLog` — `prepared_by`/`qc_by` referencian
  /// `auth.users`, no `profiles`, así que PostgREST no puede embeberlo).
  final String? preparedByName;
  final String? qcByName;

  const TrayPreparationSession({
    required this.id,
    required this.trayId,
    required this.trayVersionId,
    this.preparedBy,
    required this.preparedAt,
    this.itemResults = const [],
    this.status = TrayPreparationStatus.prepared,
    this.qcBy,
    this.qcAt,
    this.qcNotes,
    this.preparedByName,
    this.qcByName,
  });

  TrayPreparationSession copyWith({String? preparedByName, String? qcByName}) {
    return TrayPreparationSession(
      id: id,
      trayId: trayId,
      trayVersionId: trayVersionId,
      preparedBy: preparedBy,
      preparedAt: preparedAt,
      itemResults: itemResults,
      status: status,
      qcBy: qcBy,
      qcAt: qcAt,
      qcNotes: qcNotes,
      preparedByName: preparedByName ?? this.preparedByName,
      qcByName: qcByName ?? this.qcByName,
    );
  }

  factory TrayPreparationSession.fromRow(Map<String, dynamic> row) {
    return TrayPreparationSession(
      id: row['id'] as String,
      trayId: row['tray_id'] as String,
      trayVersionId: row['tray_version_id'] as String,
      preparedBy: row['prepared_by'] as String?,
      preparedAt: DateTime.parse(row['prepared_at'] as String),
      itemResults: (row['item_results'] as List<dynamic>? ?? [])
          .map((e) => TrayPreparationItemResult.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      status: TrayPreparationStatusLabel.fromDb(row['status'] as String),
      qcBy: row['qc_by'] as String?,
      qcAt: row['qc_at'] != null ? DateTime.tryParse(row['qc_at'] as String) : null,
      qcNotes: row['qc_notes'] as String?,
    );
  }
}
