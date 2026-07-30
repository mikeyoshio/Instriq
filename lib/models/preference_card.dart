class PreferenceCardItem {
  final String? instrumentId;
  final String customName;
  final String? note;

  const PreferenceCardItem({
    this.instrumentId,
    required this.customName,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'instrumentId': instrumentId,
        'customName': customName,
        'note': note,
      };

  factory PreferenceCardItem.fromJson(Map<String, dynamic> json) {
    return PreferenceCardItem(
      instrumentId: json['instrumentId'] as String?,
      customName: json['customName'] as String? ?? '',
      note: json['note'] as String?,
    );
  }
}

class PreferenceCard {
  final String id;
  final String workspaceId;

  /// FK a `surgeons` (Fase C) — el antiguo campo de texto libre
  /// `surgeon_name` ya no existe en la BD. Nullable porque una tarjeta
  /// puede guardarse sin cirujano asignado todavía; el nombre se resuelve
  /// vía [SurgeonService] (caché por grupo), no se guarda aquí.
  final String? surgeonId;
  final String procedureName;
  final List<PreferenceCardItem> items;
  final String? generalNotes;
  final bool validated;

  /// true si la tarjeta se creó/editó sin conexión y está esperando en
  /// [SyncQueueService] a subirse. Nunca se envía al servidor (no aparece en
  /// [toRow]) — es solo para que la UI muestre "Pendiente de sincronizar".
  final bool pendingSync;

  const PreferenceCard({
    required this.id,
    required this.workspaceId,
    this.surgeonId,
    required this.procedureName,
    required this.items,
    this.generalNotes,
    this.validated = false,
    this.pendingSync = false,
  });

  PreferenceCard copyWith({
    String? surgeonId,
    bool clearSurgeonId = false,
    String? procedureName,
    List<PreferenceCardItem>? items,
    String? generalNotes,
    bool? validated,
    bool? pendingSync,
  }) {
    return PreferenceCard(
      id: id,
      workspaceId: workspaceId,
      surgeonId: clearSurgeonId ? null : (surgeonId ?? this.surgeonId),
      procedureName: procedureName ?? this.procedureName,
      items: items ?? this.items,
      generalNotes: generalNotes ?? this.generalNotes,
      validated: validated ?? this.validated,
      pendingSync: pendingSync ?? this.pendingSync,
    );
  }

  /// Payload para insert/update en Supabase (sin id ni columnas gestionadas por la BD).
  Map<String, dynamic> toRow({required String organizationId}) => {
        'organization_id': organizationId,
        'workspace_id': workspaceId,
        'surgeon_id': surgeonId,
        'procedure_name': procedureName,
        'items': items.map((i) => i.toJson()).toList(),
        'general_notes': generalNotes,
        'validated': validated,
      };

  factory PreferenceCard.fromRow(Map<String, dynamic> row) {
    final rawItems = row['items'] as List<dynamic>? ?? [];
    return PreferenceCard(
      id: row['id'] as String,
      workspaceId: row['workspace_id'] as String,
      surgeonId: row['surgeon_id'] as String?,
      procedureName: row['procedure_name'] as String? ?? '',
      items: rawItems
          .map((e) => PreferenceCardItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      generalNotes: row['general_notes'] as String?,
      validated: row['validated'] as bool? ?? false,
      pendingSync: row['pending_sync'] as bool? ?? false,
    );
  }

  /// Fila completa para [OfflineCacheService] (a diferencia de [toRow],
  /// incluye `id` y `pending_sync` para poder reconstruir el objeto entero).
  Map<String, dynamic> toCacheRow() => {
        'id': id,
        'workspace_id': workspaceId,
        'surgeon_id': surgeonId,
        'procedure_name': procedureName,
        'items': items.map((i) => i.toJson()).toList(),
        'general_notes': generalNotes,
        'validated': validated,
        'pending_sync': pendingSync,
      };
}
