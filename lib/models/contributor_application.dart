enum ContributorApplicationStatus { pending, approved, rejected }

ContributorApplicationStatus _statusFromRow(String value) {
  switch (value) {
    case 'approved':
      return ContributorApplicationStatus.approved;
    case 'rejected':
      return ContributorApplicationStatus.rejected;
    case 'pending':
    default:
      return ContributorApplicationStatus.pending;
  }
}

class ContributorApplication {
  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String? country;
  final String? organizationName;
  final String? professionalRole;
  final int? yearsExperience;
  final String? linkedinUrl;
  final String? certifications;
  final String? publicationsOrTeaching;
  final String motivationLetter;
  final ContributorApplicationStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final DateTime createdAt;

  const ContributorApplication({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    this.country,
    this.organizationName,
    this.professionalRole,
    this.yearsExperience,
    this.linkedinUrl,
    this.certifications,
    this.publicationsOrTeaching,
    required this.motivationLetter,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNotes,
    required this.createdAt,
  });

  factory ContributorApplication.fromRow(Map<String, dynamic> row) {
    return ContributorApplication(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      fullName: row['full_name'] as String,
      email: row['email'] as String,
      country: row['country'] as String?,
      organizationName: row['organization_name'] as String?,
      professionalRole: row['professional_role'] as String?,
      yearsExperience: row['years_experience'] as int?,
      linkedinUrl: row['linkedin_url'] as String?,
      certifications: row['certifications'] as String?,
      publicationsOrTeaching: row['publications_or_teaching'] as String?,
      motivationLetter: row['motivation_letter'] as String,
      status: _statusFromRow(row['status'] as String),
      reviewedBy: row['reviewed_by'] as String?,
      reviewedAt: row['reviewed_at'] == null ? null : DateTime.parse(row['reviewed_at'] as String),
      reviewNotes: row['review_notes'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
