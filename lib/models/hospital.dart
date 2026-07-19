class Hospital {
  final String id;
  final String name;
  final String inviteCode;
  final String? cif;
  final String? ownerId;

  const Hospital({
    required this.id,
    required this.name,
    required this.inviteCode,
    this.cif,
    this.ownerId,
  });

  factory Hospital.fromRow(Map<String, dynamic> row) {
    return Hospital(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      inviteCode: row['invite_code'] as String? ?? '',
      cif: row['cif'] as String?,
      ownerId: row['owner_id'] as String?,
    );
  }
}

class HospitalMember {
  final String id;
  final String? displayName;
  final bool isAdmin;

  const HospitalMember({required this.id, this.displayName, required this.isAdmin});

  factory HospitalMember.fromRow(Map<String, dynamic> row) {
    return HospitalMember(
      id: row['id'] as String,
      displayName: row['display_name'] as String?,
      isAdmin: row['is_admin'] as bool? ?? false,
    );
  }
}
