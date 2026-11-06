class HospitalGroup {
  final String id;
  final String name;
  final String groupCode;

  const HospitalGroup({required this.id, required this.name, required this.groupCode});

  factory HospitalGroup.fromRow(Map<String, dynamic> row) {
    return HospitalGroup(
      id: row['id'] as String,
      name: row['name'] as String? ?? '',
      groupCode: row['group_code'] as String? ?? '',
    );
  }
}
