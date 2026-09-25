/// Espacio de trabajo dentro de un grupo (p. ej. "Traumatología",
/// "Neurocirugía", "Formación"). El contenido del grupo (técnicas,
/// protocolos, tarjetas de preferencia) cuelga de un espacio, no
/// directamente del grupo.
class Workspace {
  final String id;
  final String organizationId;
  final String name;
  final String? description;
  final String? createdBy;
  final DateTime? createdAt;
  final String? specialtyId;

  const Workspace({
    required this.id,
    required this.organizationId,
    required this.name,
    this.description,
    this.createdBy,
    this.createdAt,
    this.specialtyId,
  });

  Map<String, dynamic> toRow({required String organizationId}) => {
        'organization_id': organizationId,
        'name': name,
        'description': description,
        'specialty_id': specialtyId,
      };

  factory Workspace.fromRow(Map<String, dynamic> row) {
    return Workspace(
      id: row['id'] as String,
      organizationId: row['organization_id'] as String,
      name: row['name'] as String? ?? '',
      description: row['description'] as String?,
      createdBy: row['created_by'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
      specialtyId: row['specialty_id'] as String?,
    );
  }
}
