class Hospital {
  final String id;
  final String name;
  final String inviteCode;

  const Hospital({required this.id, required this.name, required this.inviteCode});

  factory Hospital.fromRow(Map<String, dynamic> row) {
    return Hospital(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      inviteCode: row['invite_code'] as String? ?? '',
    );
  }
}
