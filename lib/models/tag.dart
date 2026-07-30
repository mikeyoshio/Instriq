/// Etiqueta libre (tabla pública `tags`, Fase C) — compartida entre grupos,
/// como [Manufacturer]. Lo privado no es la etiqueta en sí, sino su relación
/// con una entidad concreta (ver `taggings` / [TagService]).
class Tag {
  final String id;
  final String name;

  const Tag({required this.id, required this.name});

  factory Tag.fromRow(Map<String, dynamic> row) {
    return Tag(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
    );
  }
}
