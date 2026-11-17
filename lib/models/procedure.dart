/// Tipus de contingut que un [Procedure] pot agrupar. El valor de base de
/// dades és el de la columna `procedure_items.item_type` (schema_v68).
enum ProcedureItemType { tray, groupDocument, preferenceCard }

extension ProcedureItemTypeDb on ProcedureItemType {
  String get dbValue => switch (this) {
        ProcedureItemType.tray => 'tray',
        ProcedureItemType.groupDocument => 'group_document',
        ProcedureItemType.preferenceCard => 'preference_card',
      };

  static ProcedureItemType fromDb(String value) => switch (value) {
        'tray' => ProcedureItemType.tray,
        'group_document' => ProcedureItemType.groupDocument,
        'preference_card' => ProcedureItemType.preferenceCard,
        _ => throw ArgumentError('Tipus d\'element de procediment desconegut: $value'),
      };
}

class ProcedureItem {
  final ProcedureItemType type;
  final String itemId;
  final int position;

  const ProcedureItem({required this.type, required this.itemId, this.position = 0});

  factory ProcedureItem.fromRow(Map<String, dynamic> row) {
    return ProcedureItem(
      type: ProcedureItemTypeDb.fromDb(row['item_type'] as String),
      itemId: row['item_id'] as String,
      position: row['position'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toRpc() => {'item_type': type.dbValue, 'item_id': itemId};
}

/// Un procediment (p.ex. "Colecistectomia laparoscòpica") d'un espai de
/// treball: un índex lleuger que agrupa safates, tècniques/protocols i
/// targetes de preferència que ja existeixen i ja passen la seva pròpia
/// revisió. Sense versionat (decisió del propietari, schema_v68).
class Procedure {
  final String id;
  final String organizationId;
  final String workspaceId;
  final String? specialtyId;
  final String name;
  final String? description;
  final List<ProcedureItem> items;
  final DateTime? updatedAt;

  const Procedure({
    required this.id,
    required this.organizationId,
    required this.workspaceId,
    this.specialtyId,
    required this.name,
    this.description,
    this.items = const [],
    this.updatedAt,
  });

  /// [row] pot portar els ítems incrustats (`procedure_items(...)`, select de
  /// PostgREST) o no; en tots dos casos queden ordenats per `position`.
  factory Procedure.fromRow(Map<String, dynamic> row) {
    final rawItems = row['procedure_items'] as List<dynamic>? ?? const [];
    final items = rawItems.map((e) => ProcedureItem.fromRow(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
    return Procedure(
      id: row['id'] as String,
      organizationId: row['organization_id'] as String,
      workspaceId: row['workspace_id'] as String,
      specialtyId: row['specialty_id'] as String?,
      name: row['name'] as String? ?? '',
      description: row['description'] as String?,
      items: items,
      updatedAt: row['updated_at'] != null ? DateTime.tryParse(row['updated_at'] as String) : null,
    );
  }

  List<String> idsOf(ProcedureItemType type) => [
        for (final i in items)
          if (i.type == type) i.itemId,
      ];
}

/// Què es mostra a la pàgina d'un cas: el que porta la pròpia cita té
/// prioritat (excepció puntual d'aquell dia) i el procediment completa la
/// resta, sense duplicats. Funció pura perquè la regla es pugui provar.
List<String> caseItemIds({required String? fromSlot, required List<String> fromProcedure}) {
  return [
    if (fromSlot != null) fromSlot,
    for (final id in fromProcedure)
      if (id != fromSlot) id,
  ];
}
