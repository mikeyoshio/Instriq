/// Cirujano/a de un grupo (tabla `surgeons`, Fase C) — privado del
/// `organization_id` que lo da de alta, a diferencia del catálogo compartido
/// de [Manufacturer]. Sustituye al antiguo campo de texto libre
/// `preference_cards.surgeon_name` (ya eliminado de la BD).
class Surgeon {
  final String id;
  final String organizationId;
  final String name;

  const Surgeon({
    required this.id,
    required this.organizationId,
    required this.name,
  });

  factory Surgeon.fromRow(Map<String, dynamic> row) {
    return Surgeon(
      id: row['id'] as String,
      organizationId: row['organization_id'] as String,
      name: row['name'] as String? ?? '',
    );
  }
}
