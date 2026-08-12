-- Correcció de schema_v34: 'revoke ... from public' no va fer res, perquè
-- aquestes funcions no depenien del grant implícit de PUBLIC -- tenien un
-- grant EXPLÍCIT i directe a anon/authenticated/service_role des de la
-- seva creació (verificat via pg_proc.proacl: cap entrada buida '=X/', totes
-- amb nom de rol explícit). Cal revocar-ho directament d'anon, el rol
-- realment problemàtic -- authenticated i service_role es queden intactes.

revoke execute on function add_team_member(p_team_id uuid, p_user_id uuid) from anon;
revoke execute on function approve_group_document_version(p_version_id uuid, p_review_comment text) from anon;
revoke execute on function approve_preference_card_version(p_version_id uuid, p_review_comment text) from anon;
revoke execute on function approve_public_document_version(p_version_id uuid, p_review_comment text) from anon;
revoke execute on function approve_public_tray_version(p_version_id uuid, p_review_comment text) from anon;
revoke execute on function approve_sterilization_method_version(p_version_id uuid, p_review_comment text) from anon;
revoke execute on function approve_technical_info_version(p_version_id uuid, p_review_comment text) from anon;
revoke execute on function approve_tray_version(p_version_id uuid, p_review_comment text) from anon;
revoke execute on function create_group_document(p_kind text, p_workspace_id uuid) from anon;
revoke execute on function create_preference_card(p_workspace_id uuid) from anon;
revoke execute on function create_public_document(p_kind text) from anon;
revoke execute on function create_public_tray() from anon;
revoke execute on function create_sterilization_method(p_instrument_ref_type text, p_instrument_ref_id text, p_organization_id uuid, p_workspace_id uuid, p_method text) from anon;
revoke execute on function create_team(p_name text) from anon;
revoke execute on function create_technical_info(p_instrument_ref_type text, p_instrument_ref_id text, p_organization_id uuid, p_workspace_id uuid) from anon;
revoke execute on function create_tray(p_workspace_id uuid) from anon;
revoke execute on function create_tray_preparation_session(p_tray_id uuid, p_item_results jsonb) from anon;
revoke execute on function delete_group_document(p_document_id uuid) from anon;
revoke execute on function delete_my_account() from anon;
revoke execute on function delete_team(p_team_id uuid) from anon;
revoke execute on function duplicate_tray(p_tray_id uuid) from anon;
revoke execute on function export_my_account_data() from anon;
revoke execute on function hospital_content_stats(p_hospital_id uuid) from anon;
revoke execute on function join_hospital_with_code(p_invite_code text, p_display_name text) from anon;
revoke execute on function log_login_event() from anon;
revoke execute on function organization_usage_stats(p_organization_id uuid) from anon;
revoke execute on function qc_tray_preparation_session(p_session_id uuid, p_passed boolean, p_notes text) from anon;
revoke execute on function record_usage_event(p_event_type text, p_ref_type text, p_ref_id text, p_query text) from anon;
revoke execute on function register_device_token(p_fcm_token text, p_platform text) from anon;
revoke execute on function register_hospital(p_name text, p_display_name text) from anon;
revoke execute on function reject_group_document_version(p_version_id uuid, p_review_comment text) from anon;
revoke execute on function reject_preference_card_version(p_version_id uuid, p_review_comment text) from anon;
revoke execute on function reject_public_document_version(p_version_id uuid, p_review_comment text) from anon;
revoke execute on function reject_public_tray_version(p_version_id uuid, p_review_comment text) from anon;
revoke execute on function reject_sterilization_method_version(p_version_id uuid, p_review_comment text) from anon;
revoke execute on function reject_technical_info_version(p_version_id uuid, p_review_comment text) from anon;
revoke execute on function reject_tray_version(p_version_id uuid, p_review_comment text) from anon;
revoke execute on function remove_hospital_member(p_user_id uuid) from anon;
revoke execute on function remove_team_member(p_team_id uuid, p_user_id uuid) from anon;
revoke execute on function remove_workspace_member_role(p_workspace_id uuid, p_user_id uuid) from anon;
revoke execute on function remove_workspace_team_role(p_workspace_id uuid, p_team_id uuid) from anon;
revoke execute on function restore_group_document_version(p_version_id uuid) from anon;
revoke execute on function restore_preference_card_version(p_version_id uuid) from anon;
revoke execute on function restore_sterilization_method_version(p_version_id uuid) from anon;
revoke execute on function restore_technical_info_version(p_version_id uuid) from anon;
revoke execute on function restore_tray_version(p_version_id uuid) from anon;
revoke execute on function review_community_photo(p_photo_id uuid, p_approve boolean, p_credit_name text, p_rejection_reason text) from anon;
revoke execute on function review_contributor_application(p_application_id uuid, p_approved boolean, p_notes text) from anon;
revoke execute on function set_contributor_level(p_user_id uuid, p_new_level text) from anon;
revoke execute on function set_hospital_admin(p_user_id uuid, p_is_admin boolean) from anon;
revoke execute on function set_workspace_member_role(p_workspace_id uuid, p_user_id uuid, p_role text) from anon;
revoke execute on function set_workspace_team_role(p_workspace_id uuid, p_team_id uuid, p_role text) from anon;
revoke execute on function submit_group_document_version_for_review(p_version_id uuid) from anon;
revoke execute on function submit_preference_card_version_for_review(p_version_id uuid) from anon;
revoke execute on function submit_public_document_version_for_review(p_version_id uuid) from anon;
revoke execute on function submit_public_tray_version_for_review(p_version_id uuid) from anon;
revoke execute on function submit_sterilization_method_version_for_review(p_version_id uuid) from anon;
revoke execute on function submit_technical_info_version_for_review(p_version_id uuid) from anon;
revoke execute on function submit_tray_version_for_review(p_version_id uuid) from anon;
revoke execute on function transfer_hospital_ownership(new_owner_id uuid) from anon;
revoke execute on function unregister_device_token(p_fcm_token text) from anon;
revoke execute on function update_my_contributor_profile(p_public_display_name text, p_public_bio text, p_show_organization boolean, p_is_public boolean) from anon;
revoke execute on function cleanup_knowledge_links() from anon, authenticated;
