enum DocumentKind { technique, protocol }

extension DocumentKindLabel on DocumentKind {
  String get label {
    switch (this) {
      case DocumentKind.technique:
        return 'Técnica quirúrgica';
      case DocumentKind.protocol:
        return 'Protocolo';
    }
  }

  String get dbValue => name;

  static DocumentKind fromDb(String value) {
    return DocumentKind.values.firstWhere((k) => k.dbValue == value);
  }
}

/// Documento de conocimiento propio de un grupo: técnica quirúrgica o
/// protocolo. Distinto de las tarjetas de preferencia (que son por
/// cirujano/procedimiento) — esto documenta cómo trabaja el equipo en general.
class GroupDocument {
  final String id;
  final DocumentKind kind;
  final String title;
  final String? specialty;
  final String? content;
  final List<String> steps;
  final List<String> relatedInstrumentIds;
  final String? createdBy;
  final DateTime? updatedAt;

  const GroupDocument({
    required this.id,
    required this.kind,
    required this.title,
    this.specialty,
    this.content,
    this.steps = const [],
    this.relatedInstrumentIds = const [],
    this.createdBy,
    this.updatedAt,
  });

  Map<String, dynamic> toRow({required String hospitalId}) => {
        'hospital_id': hospitalId,
        'kind': kind.dbValue,
        'title': title,
        'specialty': specialty,
        'content': content,
        'steps': steps,
        'related_instrument_ids': relatedInstrumentIds,
      };

  factory GroupDocument.fromRow(Map<String, dynamic> row) {
    return GroupDocument(
      id: row['id'] as String,
      kind: DocumentKindLabel.fromDb(row['kind'] as String),
      title: row['title'] as String? ?? '',
      specialty: row['specialty'] as String?,
      content: row['content'] as String?,
      steps: (row['steps'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      relatedInstrumentIds:
          (row['related_instrument_ids'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      createdBy: row['created_by'] as String?,
      updatedAt: row['updated_at'] != null ? DateTime.tryParse(row['updated_at'] as String) : null,
    );
  }
}
