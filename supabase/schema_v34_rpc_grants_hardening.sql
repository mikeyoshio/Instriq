-- Ronda de seguretat (2026-08-12): revocar l'EXECUTE per defecte (PUBLIC) de
-- totes les RPC d'acció que exigeixen un usuari autenticat real, seguint el
-- mateix patró ja aplicat a log_audit_event (schema_v31). Cada una d'aquestes
-- funcions ja es protegeix internament (auth.uid()/rol) -- verificat abans
-- d'aplicar aquesta migració -- així que el risc pràctic era baix, però calia
-- tancar-ho igualment: revoke all ... from public deixa fora anon i
-- authenticated per defecte; grant execute ... to authenticated ho retorna
-- només a qui té sessió real.
--
-- NO toca les funcions ajudants d'RLS (my_hospital_id, my_workspace_role,
-- my_is_*, can_access_*_photo): aquestes s'invoquen DES DE DINTRE de
-- policies que anon també avalua (p.ex. catàleg global, Biblioteca Pública
-- -- "organization_id is null or organization_id = my_hospital_id()"),
-- així que revocar-los-hi l'EXECUTE trencaria la lectura de convidat a tota
-- l'app -- comprovat abans de descartar-ho.

revoke all on function add_team_member(p_team_id uuid, p_user_id uuid) from public;
grant execute on function add_team_member(p_team_id uuid, p_user_id uuid) to authenticated;
revoke all on function approve_group_document_version(p_version_id uuid, p_review_comment text) from public;
grant execute on function approve_group_document_version(p_version_id uuid, p_review_comment text) to authenticated;
revoke all on function approve_preference_card_version(p_version_id uuid, p_review_comment text) from public;
grant execute on function approve_preference_card_version(p_version_id uuid, p_review_comment text) to authenticated;
revoke all on function approve_public_document_version(p_version_id uuid, p_review_comment text) from public;
grant execute on function approve_public_document_version(p_version_id uuid, p_review_comment text) to authenticated;
revoke all on function approve_public_tray_version(p_version_id uuid, p_review_comment text) from public;
grant execute on function approve_public_tray_version(p_version_id uuid, p_review_comment text) to authenticated;
revoke all on function approve_sterilization_method_version(p_version_id uuid, p_review_comment text) from public;
grant execute on function approve_sterilization_method_version(p_version_id uuid, p_review_comment text) to authenticated;
revoke all on function approve_technical_info_version(p_version_id uuid, p_review_comment text) from public;
grant execute on function approve_technical_info_version(p_version_id uuid, p_review_comment text) to authenticated;
revoke all on function approve_tray_version(p_version_id uuid, p_review_comment text) from public;
grant execute on function approve_tray_version(p_version_id uuid, p_review_comment text) to authenticated;
revoke all on function create_group_document(p_kind text, p_workspace_id uuid) from public;
grant execute on function create_group_document(p_kind text, p_workspace_id uuid) to authenticated;
revoke all on function create_preference_card(p_workspace_id uuid) from public;
grant execute on function create_preference_card(p_workspace_id uuid) to authenticated;
revoke all on function create_public_document(p_kind text) from public;
grant execute on function create_public_document(p_kind text) to authenticated;
revoke all on function create_public_tray() from public;
grant execute on function create_public_tray() to authenticated;
revoke all on function create_sterilization_method(p_instrument_ref_type text, p_instrument_ref_id text, p_organization_id uuid, p_workspace_id uuid, p_method text) from public;
grant execute on function create_sterilization_method(p_instrument_ref_type text, p_instrument_ref_id text, p_organization_id uuid, p_workspace_id uuid, p_method text) to authenticated;
revoke all on function create_team(p_name text) from public;
grant execute on function create_team(p_name text) to authenticated;
revoke all on function create_technical_info(p_instrument_ref_type text, p_instrument_ref_id text, p_organization_id uuid, p_workspace_id uuid) from public;
grant execute on function create_technical_info(p_instrument_ref_type text, p_instrument_ref_id text, p_organization_id uuid, p_workspace_id uuid) to authenticated;
revoke all on function create_tray(p_workspace_id uuid) from public;
grant execute on function create_tray(p_workspace_id uuid) to authenticated;
revoke all on function create_tray_preparation_session(p_tray_id uuid, p_item_results jsonb) from public;
grant execute on function create_tray_preparation_session(p_tray_id uuid, p_item_results jsonb) to authenticated;
revoke all on function delete_group_document(p_document_id uuid) from public;
grant execute on function delete_group_document(p_document_id uuid) to authenticated;
revoke all on function delete_my_account() from public;
grant execute on function delete_my_account() to authenticated;
revoke all on function delete_team(p_team_id uuid) from public;
grant execute on function delete_team(p_team_id uuid) to authenticated;
revoke all on function duplicate_tray(p_tray_id uuid) from public;
grant execute on function duplicate_tray(p_tray_id uuid) to authenticated;
revoke all on function export_my_account_data() from public;
grant execute on function export_my_account_data() to authenticated;
revoke all on function hospital_content_stats(p_hospital_id uuid) from public;
grant execute on function hospital_content_stats(p_hospital_id uuid) to authenticated;
revoke all on function join_hospital_with_code(p_invite_code text, p_display_name text) from public;
grant execute on function join_hospital_with_code(p_invite_code text, p_display_name text) to authenticated;
revoke all on function log_login_event() from public;
grant execute on function log_login_event() to authenticated;
revoke all on function organization_usage_stats(p_organization_id uuid) from public;
grant execute on function organization_usage_stats(p_organization_id uuid) to authenticated;
revoke all on function qc_tray_preparation_session(p_session_id uuid, p_passed boolean, p_notes text) from public;
grant execute on function qc_tray_preparation_session(p_session_id uuid, p_passed boolean, p_notes text) to authenticated;
revoke all on function record_usage_event(p_event_type text, p_ref_type text, p_ref_id text, p_query text) from public;
grant execute on function record_usage_event(p_event_type text, p_ref_type text, p_ref_id text, p_query text) to authenticated;
revoke all on function register_device_token(p_fcm_token text, p_platform text) from public;
grant execute on function register_device_token(p_fcm_token text, p_platform text) to authenticated;
revoke all on function register_hospital(p_name text, p_display_name text) from public;
grant execute on function register_hospital(p_name text, p_display_name text) to authenticated;
revoke all on function reject_group_document_version(p_version_id uuid, p_review_comment text) from public;
grant execute on function reject_group_document_version(p_version_id uuid, p_review_comment text) to authenticated;
revoke all on function reject_preference_card_version(p_version_id uuid, p_review_comment text) from public;
grant execute on function reject_preference_card_version(p_version_id uuid, p_review_comment text) to authenticated;
revoke all on function reject_public_document_version(p_version_id uuid, p_review_comment text) from public;
grant execute on function reject_public_document_version(p_version_id uuid, p_review_comment text) to authenticated;
revoke all on function reject_public_tray_version(p_version_id uuid, p_review_comment text) from public;
grant execute on function reject_public_tray_version(p_version_id uuid, p_review_comment text) to authenticated;
revoke all on function reject_sterilization_method_version(p_version_id uuid, p_review_comment text) from public;
grant execute on function reject_sterilization_method_version(p_version_id uuid, p_review_comment text) to authenticated;
revoke all on function reject_technical_info_version(p_version_id uuid, p_review_comment text) from public;
grant execute on function reject_technical_info_version(p_version_id uuid, p_review_comment text) to authenticated;
revoke all on function reject_tray_version(p_version_id uuid, p_review_comment text) from public;
grant execute on function reject_tray_version(p_version_id uuid, p_review_comment text) to authenticated;
revoke all on function remove_hospital_member(p_user_id uuid) from public;
grant execute on function remove_hospital_member(p_user_id uuid) to authenticated;
revoke all on function remove_team_member(p_team_id uuid, p_user_id uuid) from public;
grant execute on function remove_team_member(p_team_id uuid, p_user_id uuid) to authenticated;
revoke all on function remove_workspace_member_role(p_workspace_id uuid, p_user_id uuid) from public;
grant execute on function remove_workspace_member_role(p_workspace_id uuid, p_user_id uuid) to authenticated;
revoke all on function remove_workspace_team_role(p_workspace_id uuid, p_team_id uuid) from public;
grant execute on function remove_workspace_team_role(p_workspace_id uuid, p_team_id uuid) to authenticated;
revoke all on function restore_group_document_version(p_version_id uuid) from public;
grant execute on function restore_group_document_version(p_version_id uuid) to authenticated;
revoke all on function restore_preference_card_version(p_version_id uuid) from public;
grant execute on function restore_preference_card_version(p_version_id uuid) to authenticated;
revoke all on function restore_sterilization_method_version(p_version_id uuid) from public;
grant execute on function restore_sterilization_method_version(p_version_id uuid) to authenticated;
revoke all on function restore_technical_info_version(p_version_id uuid) from public;
grant execute on function restore_technical_info_version(p_version_id uuid) to authenticated;
revoke all on function restore_tray_version(p_version_id uuid) from public;
grant execute on function restore_tray_version(p_version_id uuid) to authenticated;
revoke all on function review_community_photo(p_photo_id uuid, p_approve boolean, p_credit_name text, p_rejection_reason text) from public;
grant execute on function review_community_photo(p_photo_id uuid, p_approve boolean, p_credit_name text, p_rejection_reason text) to authenticated;
revoke all on function review_contributor_application(p_application_id uuid, p_approved boolean, p_notes text) from public;
grant execute on function review_contributor_application(p_application_id uuid, p_approved boolean, p_notes text) to authenticated;
revoke all on function set_contributor_level(p_user_id uuid, p_new_level text) from public;
grant execute on function set_contributor_level(p_user_id uuid, p_new_level text) to authenticated;
revoke all on function set_hospital_admin(p_user_id uuid, p_is_admin boolean) from public;
grant execute on function set_hospital_admin(p_user_id uuid, p_is_admin boolean) to authenticated;
revoke all on function set_workspace_member_role(p_workspace_id uuid, p_user_id uuid, p_role text) from public;
grant execute on function set_workspace_member_role(p_workspace_id uuid, p_user_id uuid, p_role text) to authenticated;
revoke all on function set_workspace_team_role(p_workspace_id uuid, p_team_id uuid, p_role text) from public;
grant execute on function set_workspace_team_role(p_workspace_id uuid, p_team_id uuid, p_role text) to authenticated;
revoke all on function submit_group_document_version_for_review(p_version_id uuid) from public;
grant execute on function submit_group_document_version_for_review(p_version_id uuid) to authenticated;
revoke all on function submit_preference_card_version_for_review(p_version_id uuid) from public;
grant execute on function submit_preference_card_version_for_review(p_version_id uuid) to authenticated;
revoke all on function submit_public_document_version_for_review(p_version_id uuid) from public;
grant execute on function submit_public_document_version_for_review(p_version_id uuid) to authenticated;
revoke all on function submit_public_tray_version_for_review(p_version_id uuid) from public;
grant execute on function submit_public_tray_version_for_review(p_version_id uuid) to authenticated;
revoke all on function submit_sterilization_method_version_for_review(p_version_id uuid) from public;
grant execute on function submit_sterilization_method_version_for_review(p_version_id uuid) to authenticated;
revoke all on function submit_technical_info_version_for_review(p_version_id uuid) from public;
grant execute on function submit_technical_info_version_for_review(p_version_id uuid) to authenticated;
revoke all on function submit_tray_version_for_review(p_version_id uuid) from public;
grant execute on function submit_tray_version_for_review(p_version_id uuid) to authenticated;
revoke all on function transfer_hospital_ownership(new_owner_id uuid) from public;
grant execute on function transfer_hospital_ownership(new_owner_id uuid) to authenticated;
revoke all on function unregister_device_token(p_fcm_token text) from public;
grant execute on function unregister_device_token(p_fcm_token text) to authenticated;
revoke all on function update_my_contributor_profile(p_public_display_name text, p_public_bio text, p_show_organization boolean, p_is_public boolean) from public;
grant execute on function update_my_contributor_profile(p_public_display_name text, p_public_bio text, p_show_organization boolean, p_is_public boolean) to authenticated;

-- cleanup_knowledge_links: nomes s'invoca com a trigger, mai directament
-- via RPC (retorna trigger) -- revocar sense tornar a concedir a ningu.
revoke all on function cleanup_knowledge_links() from public;
