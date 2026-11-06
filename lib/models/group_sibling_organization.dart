/// Organització germana del mateix [HospitalGroup]. Deliberadament separat
/// de [Hospital]: només porta columnes segures per a mostrar a qualsevol
/// membre del grup (mai `inviteCode`/`cif`/`ownerId`, que [Hospital] sí
/// porta per a la pròpia organització).
class GroupSiblingOrganization {
  final String id;
  final String name;
  final String orgType;

  const GroupSiblingOrganization({required this.id, required this.name, required this.orgType});

  factory GroupSiblingOrganization.fromRow(Map<String, dynamic> row) {
    return GroupSiblingOrganization(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      orgType: row['org_type'] as String? ?? 'hospital',
    );
  }
}
