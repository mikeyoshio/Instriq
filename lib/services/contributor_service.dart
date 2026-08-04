import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/contributor_application.dart';
import '../models/contributor_profile.dart';

/// EPIC 9 (primer tram) -- candidatura de col·laborador i perfil de
/// comunitat. Eix de permisos nou i paral·lel a `ProfileService`/
/// `WorkspaceRole` (mai una extensio d'aquest), vegeu
/// docs/EPIC_COMMUNITY_GOVERNANCE.md i docs/ADR_001_KNOWLEDGE_GOVERNANCE.md.
class ContributorService {
  ContributorService._();
  static final ContributorService instance = ContributorService._();

  SupabaseClient get _client => Supabase.instance.client;

  ContributorProfile? _myProfile;
  ContributorProfile? get myProfile => _myProfile;

  bool get isEditorialBoard =>
      _myProfile?.level == ContributorLevel.editorialBoard &&
      _myProfile?.status == ContributorProfileStatus.active;

  void clear() => _myProfile = null;

  Future<void> loadMyProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      _myProfile = null;
      return;
    }
    final row = await _client.from('contributor_profiles').select().eq('user_id', userId).maybeSingle();
    _myProfile = row == null ? null : ContributorProfile.fromRow(row);
  }

  Future<ContributorApplication?> fetchMyLatestApplication() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final rows = await _client
        .from('contributor_applications')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1);
    if (rows.isEmpty) return null;
    return ContributorApplication.fromRow(rows.first);
  }

  Future<void> submitApplication({
    required String fullName,
    required String email,
    String? country,
    String? organizationName,
    String? professionalRole,
    int? yearsExperience,
    String? linkedinUrl,
    String? certifications,
    String? publicationsOrTeaching,
    required String motivationLetter,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('Cal haver iniciat sessio per candidatar-se');
    await _client.from('contributor_applications').insert({
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'country': country,
      'organization_name': organizationName,
      'professional_role': professionalRole,
      'years_experience': yearsExperience,
      'linkedin_url': linkedinUrl,
      'certifications': certifications,
      'publications_or_teaching': publicationsOrTeaching,
      'motivation_letter': motivationLetter,
    });
  }

  Future<List<ContributorApplication>> fetchPendingApplications() async {
    final rows = await _client
        .from('contributor_applications')
        .select()
        .eq('status', 'pending')
        .order('created_at', ascending: true);
    return rows.map(ContributorApplication.fromRow).toList();
  }

  Future<void> reviewApplication(String applicationId, bool approved, {String? notes}) async {
    await _client.rpc('review_contributor_application', params: {
      'p_application_id': applicationId,
      'p_approved': approved,
      'p_notes': notes,
    });
  }

  Future<void> updateMyProfile({
    String? publicDisplayName,
    String? publicBio,
    bool? showOrganization,
    bool? isPublic,
  }) async {
    await _client.rpc('update_my_contributor_profile', params: {
      'p_public_display_name': publicDisplayName,
      'p_public_bio': publicBio,
      'p_show_organization': showOrganization,
      'p_is_public': isPublic,
    });
    await loadMyProfile();
  }
}
