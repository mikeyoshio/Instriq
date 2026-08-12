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

  /// Perfil públic d'un altre col·laborador (docs/EPIC_COMMUNITY_GOVERNANCE.md
  /// §8) -- `null` si no existeix o no és públic (RLS `is_public = true`,
  /// `contributor_profiles_select`), en comptes de llançar.
  Future<ContributorProfile?> fetchPublicProfile(String userId) async {
    final row = await _client
        .from('contributor_profiles')
        .select()
        .eq('user_id', userId)
        .eq('is_public', true)
        .maybeSingle();
    return row == null ? null : ContributorProfile.fromRow(row);
  }

  /// Nom de l'organització d'un col·laborador, només si ell mateix ho ha triat
  /// mostrar (`show_organization`) -- mai una consulta directa a
  /// `profiles`/`organizations`, que no són llegibles entre organitzacions
  /// diferents (veure `get_public_contributor_organization`, schema_v33).
  Future<String?> fetchPublicOrganizationName(String userId) async {
    final result = await _client.rpc('get_public_contributor_organization', params: {'p_user_id': userId});
    return result as String?;
  }

  /// Etiquetes (àrees de col·laboració) d'un col·laborador -- mateix patró
  /// `taggings` que usa [TagPicker], en mode lectura.
  Future<List<String>> fetchAreaNames(String userId) async {
    final rows = await _client.from('taggings').select('tags(name)').eq('ref_type', 'contributor').eq('ref_id', userId);
    return (rows as List<dynamic>)
        .map((r) => ((r as Map<String, dynamic>)['tags'] as Map<String, dynamic>?)?['name'] as String?)
        .whereType<String>()
        .toList();
  }

  /// Contribucions publicades (tècniques/protocols + safates) d'un
  /// col·laborador a la Biblioteca Pública.
  Future<int> fetchPublishedContributionCount(String userId) async {
    final docs = await _client
        .from('public_document_versions')
        .select('id')
        .eq('author_id', userId)
        .eq('status', 'published')
        .count(CountOption.exact);
    final trays = await _client
        .from('public_tray_versions')
        .select('id')
        .eq('author_id', userId)
        .eq('status', 'published')
        .count(CountOption.exact);
    return docs.count + trays.count;
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
