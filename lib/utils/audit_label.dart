import '../l10n/app_localizations.dart';
import '../models/audit_entry.dart';

/// Texto legible de `entry.action` (ver `supabase/schema_v10_audit.sql` y
/// las migraciones posteriores que añaden acciones nuevas a `audit_log`).
/// Única fuente de verdad: antes vivía duplicado en `audit_log_screen.dart`
/// y `home_dashboard_panel.dart`, y cada copia cubría un subconjunto
/// distinto de acciones -- cualquier acción no contemplada caía al valor
/// crudo de la base de datos (p. ej. "tray_preparation_qc") en vez de un
/// texto traducido.
String auditActionLabel(AppLocalizations l10n, AuditEntry entry) {
  switch (entry.action) {
    case 'user_signed_in':
      return l10n.auditActionUserSignedIn;
    case 'document_version_approved':
      return l10n.auditActionDocumentVersionApproved;
    case 'document_version_rejected':
      return l10n.auditActionDocumentVersionRejected;
    case 'document_version_submitted':
      return l10n.auditActionDocumentVersionSubmitted;
    case 'document_created':
      return l10n.auditActionDocumentCreated;
    case 'document_deleted':
      return l10n.auditActionDocumentDeleted;
    case 'document_duplicated':
      return l10n.auditActionDocumentDuplicated;
    case 'workspace_member_role_changed':
      return l10n.auditActionWorkspaceMemberRoleChanged;
    case 'hospital_ownership_transferred':
      return l10n.auditActionHospitalOwnershipTransferred;
    case 'hospital_admin_changed':
      return l10n.auditActionHospitalAdminChanged;
    case 'preference_card_created':
      return l10n.auditActionPreferenceCardCreated;
    case 'preference_card_version_submitted':
      return l10n.auditActionPreferenceCardVersionSubmitted;
    case 'preference_card_version_approved':
      return l10n.auditActionPreferenceCardVersionApproved;
    case 'preference_card_version_rejected':
      return l10n.auditActionPreferenceCardVersionRejected;
    case 'preference_card_duplicated':
      return l10n.auditActionPreferenceCardDuplicated;
    case 'custom_instrument_created':
      return l10n.auditActionCustomInstrumentCreated;
    case 'custom_instrument_deleted':
      return l10n.auditActionCustomInstrumentDeleted;
    case 'custom_instrument_duplicated':
      return l10n.auditActionCustomInstrumentDuplicated;
    case 'custom_instrument_version_submitted':
      return l10n.auditActionCustomInstrumentVersionSubmitted;
    case 'custom_instrument_version_approved':
      return l10n.auditActionCustomInstrumentVersionApproved;
    case 'custom_instrument_version_rejected':
      return l10n.auditActionCustomInstrumentVersionRejected;
    case 'tray_created':
      return l10n.auditActionTrayCreated;
    case 'tray_duplicated':
      return l10n.auditActionTrayDuplicated;
    case 'tray_adopted':
      return l10n.auditActionTrayAdopted;
    case 'tray_stopped_following_upstream':
      return l10n.auditActionTrayStoppedFollowingUpstream;
    case 'tray_updated_from_upstream':
      return l10n.auditActionTrayUpdatedFromUpstream;
    case 'tray_version_submitted':
      return l10n.auditActionTrayVersionSubmitted;
    case 'tray_version_approved':
      return l10n.auditActionTrayVersionApproved;
    case 'tray_version_rejected':
      return l10n.auditActionTrayVersionRejected;
    case 'tray_preparation_created':
      return l10n.auditActionTrayPreparationCreated;
    case 'tray_preparation_qc':
      return entry.metadata['passed'] == true
          ? l10n.auditActionTrayPreparationQcPassed
          : l10n.auditActionTrayPreparationQcFailed;
    case 'sterilization_method_created':
      return l10n.auditActionSterilizationMethodCreated;
    case 'sterilization_method_version_submitted':
      return l10n.auditActionSterilizationMethodVersionSubmitted;
    case 'sterilization_method_version_approved':
      return l10n.auditActionSterilizationMethodVersionApproved;
    case 'sterilization_method_version_rejected':
      return l10n.auditActionSterilizationMethodVersionRejected;
    case 'sterilization_method_version_restored':
      return l10n.auditActionSterilizationMethodVersionRestored;
    case 'technical_info_created':
      return l10n.auditActionTechnicalInfoCreated;
    case 'technical_info_version_submitted':
      return l10n.auditActionTechnicalInfoVersionSubmitted;
    case 'technical_info_version_approved':
      return l10n.auditActionTechnicalInfoVersionApproved;
    case 'technical_info_version_rejected':
      return l10n.auditActionTechnicalInfoVersionRejected;
    case 'technical_info_version_restored':
      return l10n.auditActionTechnicalInfoVersionRestored;
    case 'invitation_sent':
      return l10n.auditActionInvitationSent;
    case 'invitation_revoked':
      return l10n.auditActionInvitationRevoked;
    case 'invitation_accepted':
      return l10n.auditActionInvitationAccepted;
    case 'community_photo_approved':
      return l10n.auditActionCommunityPhotoApproved;
    case 'community_photo_rejected':
      return l10n.auditActionCommunityPhotoRejected;
    case 'catalog_content_report_resolved':
      return l10n.auditActionCatalogContentReportResolved;
    case 'contributor_application_approved':
      return l10n.auditActionContributorApplicationApproved;
    case 'contributor_application_rejected':
      return l10n.auditActionContributorApplicationRejected;
    case 'contributor_level_changed':
      return l10n.auditActionContributorLevelChanged;
    default:
      return entry.action;
  }
}

String _roleLabel(AppLocalizations l10n, String? role) {
  switch (role) {
    case 'reader':
      return l10n.workspaceRoleReaderLabel;
    case 'editor':
      return l10n.workspaceRoleEditorLabel;
    case 'approver':
      return l10n.workspaceRoleApproverLabel;
    case 'administrator':
      return l10n.workspaceRoleAdministratorLabel;
    default:
      return l10n.auditNoRoleLabel;
  }
}

/// Texto secundario sobre qué entidad fue la acción, a partir de
/// `entry.metadata`/`entry.entityType`. `null` cuando los metadatos
/// guardados no incluyen nada legible (p. ej. solo un uuid de referencia) --
/// deliberadamente no se inventa una descripción que no tenemos.
String? auditEntityDescription(AppLocalizations l10n, AuditEntry entry) {
  final metadata = entry.metadata;
  switch (entry.entityType) {
    case 'group_document_version':
      final title = metadata['title'] as String?;
      return (title != null && title.isNotEmpty) ? title : l10n.auditDocumentUntitledLabel;
    case 'group_document':
      final title = metadata['title'] as String?;
      final kind = metadata['kind'] as String?;
      final kindLabel =
          kind == 'protocol' ? l10n.auditKindProtocolLabel : (kind == 'technique' ? l10n.auditKindTechniqueLabel : null);
      if (title != null && title.isNotEmpty) return title;
      return kindLabel;
    case 'custom_instrument':
      final name = metadata['name'] as String?;
      return (name != null && name.isNotEmpty) ? name : null;
    case 'workspace_member':
      final previousRole = metadata['previous_role'] as String?;
      final newRole = metadata['new_role'] as String?;
      if (newRole == null) return l10n.auditAccessRemovedDescription(_roleLabel(l10n, previousRole));
      if (previousRole == null) return l10n.auditAssignedAsRoleDescription(_roleLabel(l10n, newRole));
      return l10n.auditRoleChangeDescription(_roleLabel(l10n, previousRole), _roleLabel(l10n, newRole));
    case 'hospital':
      return l10n.auditHospitalOwnerDescription;
    case 'invitation':
      final email = metadata['email'] as String?;
      final role = metadata['role'] as String?;
      if (email == null || email.isEmpty) return null;
      return role != null ? l10n.auditInvitationSentDescription(email, _roleLabel(l10n, role)) : email;
    case 'contributor_profile':
      final level = metadata['new_level'] as String?;
      return level != null ? l10n.auditContributorLevelDescription(level) : null;
    default:
      return null;
  }
}
