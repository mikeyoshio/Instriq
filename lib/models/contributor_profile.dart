enum ContributorLevel { contributor, reviewer, editorialBoard }

ContributorLevel _levelFromRow(String value) {
  switch (value) {
    case 'reviewer':
      return ContributorLevel.reviewer;
    case 'editorial_board':
      return ContributorLevel.editorialBoard;
    case 'contributor':
    default:
      return ContributorLevel.contributor;
  }
}

String contributorLevelToRow(ContributorLevel level) {
  switch (level) {
    case ContributorLevel.reviewer:
      return 'reviewer';
    case ContributorLevel.editorialBoard:
      return 'editorial_board';
    case ContributorLevel.contributor:
      return 'contributor';
  }
}

enum ContributorProfileStatus { active, suspended, retired }

ContributorProfileStatus _statusFromRow(String value) {
  switch (value) {
    case 'suspended':
      return ContributorProfileStatus.suspended;
    case 'retired':
      return ContributorProfileStatus.retired;
    case 'active':
    default:
      return ContributorProfileStatus.active;
  }
}

class ContributorProfile {
  final String id;
  final String userId;
  final ContributorLevel level;
  final String? publicDisplayName;
  final String? publicBio;
  final bool showOrganization;
  final bool isPublic;
  final ContributorProfileStatus status;
  final String? approvedBy;
  final DateTime approvedAt;

  const ContributorProfile({
    required this.id,
    required this.userId,
    required this.level,
    this.publicDisplayName,
    this.publicBio,
    required this.showOrganization,
    required this.isPublic,
    required this.status,
    this.approvedBy,
    required this.approvedAt,
  });

  factory ContributorProfile.fromRow(Map<String, dynamic> row) {
    return ContributorProfile(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      level: _levelFromRow(row['level'] as String),
      publicDisplayName: row['public_display_name'] as String?,
      publicBio: row['public_bio'] as String?,
      showOrganization: row['show_organization'] as bool? ?? false,
      isPublic: row['is_public'] as bool? ?? false,
      status: _statusFromRow(row['status'] as String),
      approvedBy: row['approved_by'] as String?,
      approvedAt: DateTime.parse(row['approved_at'] as String),
    );
  }
}
