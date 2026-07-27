enum GroupDocumentVersionStatus { draft, inReview, published, archived }

/// Un paso de un protocolo/técnica, con categoría de texto libre opcional
/// (ej. "Preoperatorio", "Anestesia"...). No es un enum: Instriq documenta
/// tanto checklists de seguridad (categorías tipo OMS) como técnicas
/// quirúrgicas paso a paso donde esas categorías fijas no encajan.
///
/// Compatibilidad hacia atrás: el jsonb de `steps` guardaba antes un array
/// de strings planos. [ProtocolStep.fromDynamic] interpreta ese formato
/// antiguo como un paso sin categoría, así que el contenido existente en
/// Supabase sigue funcionando sin migración ni pérdida de datos.
class ProtocolStep {
  final String? category;
  final String text;

  const ProtocolStep({this.category, required this.text});

  Map<String, dynamic> toJson() => {
        'category': category,
        'text': text,
      };

  factory ProtocolStep.fromDynamic(dynamic value) {
    if (value is String) {
      return ProtocolStep(text: value);
    }
    if (value is Map) {
      final map = value.cast<String, dynamic>();
      return ProtocolStep(
        category: map['category'] as String?,
        text: map['text'] as String? ?? '',
      );
    }
    return ProtocolStep(text: value.toString());
  }
}

extension GroupDocumentVersionStatusLabel on GroupDocumentVersionStatus {
  String get label {
    switch (this) {
      case GroupDocumentVersionStatus.draft:
        return 'Borrador';
      case GroupDocumentVersionStatus.inReview:
        return 'En revisión';
      case GroupDocumentVersionStatus.published:
        return 'Publicada';
      case GroupDocumentVersionStatus.archived:
        return 'Archivada';
    }
  }

  String get dbValue {
    switch (this) {
      case GroupDocumentVersionStatus.draft:
        return 'draft';
      case GroupDocumentVersionStatus.inReview:
        return 'in_review';
      case GroupDocumentVersionStatus.published:
        return 'published';
      case GroupDocumentVersionStatus.archived:
        return 'archived';
    }
  }

  static GroupDocumentVersionStatus fromDb(String value) {
    switch (value) {
      case 'draft':
        return GroupDocumentVersionStatus.draft;
      case 'in_review':
        return GroupDocumentVersionStatus.inReview;
      case 'published':
        return GroupDocumentVersionStatus.published;
      case 'archived':
        return GroupDocumentVersionStatus.archived;
      default:
        throw ArgumentError('Estado de versión desconocido: $value');
    }
  }
}

/// Una versión concreta del contenido de un [GroupDocument]. El contenido
/// (título, pasos, instrumental relacionado...) vive aquí, no en la cabecera:
/// cada edición crea una versión nueva en vez de sobrescribir la anterior.
class GroupDocumentVersion {
  final String id;
  final String documentId;
  final int versionNumber;
  final GroupDocumentVersionStatus status;
  final String title;
  final String? specialty;
  final String? content;
  final List<ProtocolStep> steps;
  final List<String> relatedInstrumentIds;
  final String? authorId;
  final String? comment;
  final String? basedOnVersionId;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime? createdAt;

  const GroupDocumentVersion({
    required this.id,
    required this.documentId,
    required this.versionNumber,
    required this.status,
    required this.title,
    this.specialty,
    this.content,
    this.steps = const [],
    this.relatedInstrumentIds = const [],
    this.authorId,
    this.comment,
    this.basedOnVersionId,
    this.approvedBy,
    this.approvedAt,
    this.createdAt,
  });

  Map<String, dynamic> toRow() => {
        'title': title,
        'specialty': specialty,
        'content': content,
        'steps': steps.map((s) => s.toJson()).toList(),
        'related_instrument_ids': relatedInstrumentIds,
        'comment': comment,
      };

  /// [clearSpecialty]/[clearContent]: al ser campos nullable, pasar `null`
  /// en [specialty]/[content] no basta para vaciarlos (se confundiría con
  /// "no lo toques") — hay que pedirlo explícitamente.
  GroupDocumentVersion copyWith({
    String? title,
    String? specialty,
    bool clearSpecialty = false,
    String? content,
    bool clearContent = false,
    List<ProtocolStep>? steps,
    List<String>? relatedInstrumentIds,
    String? comment,
  }) {
    return GroupDocumentVersion(
      id: id,
      documentId: documentId,
      versionNumber: versionNumber,
      status: status,
      title: title ?? this.title,
      specialty: clearSpecialty ? null : (specialty ?? this.specialty),
      content: clearContent ? null : (content ?? this.content),
      steps: steps ?? this.steps,
      relatedInstrumentIds: relatedInstrumentIds ?? this.relatedInstrumentIds,
      authorId: authorId,
      comment: comment ?? this.comment,
      basedOnVersionId: basedOnVersionId,
      approvedBy: approvedBy,
      approvedAt: approvedAt,
      createdAt: createdAt,
    );
  }

  factory GroupDocumentVersion.fromRow(Map<String, dynamic> row) {
    return GroupDocumentVersion(
      id: row['id'] as String,
      documentId: row['document_id'] as String,
      versionNumber: row['version_number'] as int,
      status: GroupDocumentVersionStatusLabel.fromDb(row['status'] as String),
      title: row['title'] as String? ?? '',
      specialty: row['specialty'] as String?,
      content: row['content'] as String?,
      steps: (row['steps'] as List<dynamic>? ?? []).map(ProtocolStep.fromDynamic).toList(),
      relatedInstrumentIds:
          (row['related_instrument_ids'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      authorId: row['author_id'] as String?,
      comment: row['comment'] as String?,
      basedOnVersionId: row['based_on_version_id'] as String?,
      approvedBy: row['approved_by'] as String?,
      approvedAt: row['approved_at'] != null ? DateTime.tryParse(row['approved_at'] as String) : null,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
    );
  }
}
