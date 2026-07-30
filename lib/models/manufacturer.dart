/// Fabricante de instrumental (tabla pública `manufacturers`, Fase C). Es un
/// catálogo compartido entre todos los grupos, no un dato privado de un
/// hospital/workspace: cualquier usuaria/o autenticado puede darlo de alta
/// (ver [ManufacturerService.createOrGet]).
class Manufacturer {
  final String id;
  final String name;
  final String? website;

  const Manufacturer({
    required this.id,
    required this.name,
    this.website,
  });

  factory Manufacturer.fromRow(Map<String, dynamic> row) {
    return Manufacturer(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      website: row['website'] as String?,
    );
  }
}
