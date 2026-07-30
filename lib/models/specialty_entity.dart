/// Fila de la tabla `specialties` (lista cerrada de 16, Fase C), 1:1 con el
/// enum [Specialty] de `lib/models/instrument.dart` por `slug`/`.name`.
/// Nombre deliberadamente distinto de `Specialty` para no colisionar con ese
/// enum: este modelo es el lado "fila de BD, con id y FK" del mismo concepto,
/// usado para `specialty_id` en trays/documentos/instrumental personalizado.
class SpecialtyEntity {
  final String id;
  final String slug;
  final String label;

  const SpecialtyEntity({
    required this.id,
    required this.slug,
    required this.label,
  });

  factory SpecialtyEntity.fromRow(Map<String, dynamic> row) {
    return SpecialtyEntity(
      id: row['id'] as String,
      slug: row['slug'] as String? ?? '',
      label: row['label'] as String? ?? '',
    );
  }
}
