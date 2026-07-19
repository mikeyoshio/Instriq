/// Espacio de trabajo dentro de un grupo (p. ej. "Traumatología",
/// "Neurocirugía", "Formación"). El contenido del grupo (técnicas,
/// protocolos, tarjetas de preferencia) cuelga de un espacio, no
/// directamente del grupo.
class Workspace {
  final String id;
  final String hospitalId;
  final String name;
  final String? description;
  final String? createdBy;
  final DateTime? createdAt;

  const Workspace({
    required this.id,
    required this.hospitalId,
    required this.name,
    this.description,
    this.createdBy,
    this.createdAt,
  });

  Map<String, dynamic> toRow({required String hospitalId}) => {
        'hospital_id': hospitalId,
        'name': name,
        'description': description,
      };

  factory Workspace.fromRow(Map<String, dynamic> row) {
    return Workspace(
      id: row['id'] as String,
      hospitalId: row['hospital_id'] as String,
      name: row['name'] as String? ?? '',
      description: row['description'] as String?,
      createdBy: row['created_by'] as String?,
      createdAt: row['created_at'] != null ? DateTime.tryParse(row['created_at'] as String) : null,
    );
  }
}
