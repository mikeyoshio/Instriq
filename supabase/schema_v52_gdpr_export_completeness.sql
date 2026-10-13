-- GDPR audit (2026-10): export_my_account_data() (schema_v9, last touched by
-- the hospital->organization rename in schema_v20) never grew past its
-- original scope as the product added more personal data: trays, custom
-- instruments, learning progress/quiz scores, and contributor application/
-- profile data are all real personal data tied to auth.uid(), none of them
-- reachable via the "export my data" feature (Art. 20 data portability).
-- Deletion (delete_my_account(), schema_v9/v51) was already correct for all
-- of these via on delete cascade/set null -- only the export side had
-- fallen behind.

create or replace function export_my_account_data()
returns json
language plpgsql
security definer
set search_path = public
as $$
declare
  v_result json;
begin
  select json_build_object(
    'profile', (
      select json_build_object(
        'display_name', p.display_name,
        'organization_name', o.name,
        'is_admin', p.is_admin,
        'is_owner', o.owner_id = p.id,
        'created_at', p.created_at,
        'quiz_best_scores', p.quiz_best_scores
      )
      from profiles p
      left join organizations o on o.id = p.organization_id
      where p.id = auth.uid()
    ),
    'workspace_roles', (
      select coalesce(json_agg(json_build_object(
        'workspace', w.name,
        'role', wm.role
      )), '[]'::json)
      from workspace_members wm
      join workspaces w on w.id = wm.workspace_id
      where wm.user_id = auth.uid()
    ),
    'documents_authored', (
      select coalesce(json_agg(json_build_object(
        'kind', gd.kind,
        'workspace', w.name,
        'title', gdv.title,
        'status', gdv.status,
        'version_number', gdv.version_number,
        'created_at', gdv.created_at
      )), '[]'::json)
      from group_document_versions gdv
      join group_documents gd on gd.id = gdv.document_id
      join workspaces w on w.id = gd.workspace_id
      where gdv.author_id = auth.uid()
    ),
    'documents_approved', (
      select coalesce(json_agg(json_build_object(
        'kind', gd.kind,
        'workspace', w.name,
        'title', gdv.title,
        'version_number', gdv.version_number,
        'approved_at', gdv.approved_at
      )), '[]'::json)
      from group_document_versions gdv
      join group_documents gd on gd.id = gdv.document_id
      join workspaces w on w.id = gd.workspace_id
      where gdv.approved_by = auth.uid()
    ),
    'preference_cards_created', (
      select coalesce(json_agg(json_build_object(
        'workspace', w.name,
        'surgeon_name', pc.surgeon_name,
        'procedure_name', pc.procedure_name,
        'created_at', pc.created_at
      )), '[]'::json)
      from preference_cards pc
      join workspaces w on w.id = pc.workspace_id
      where pc.created_by = auth.uid()
    ),
    'trays_authored', (
      select coalesce(json_agg(json_build_object(
        'workspace', w.name,
        'name', tv.name,
        'status', tv.status,
        'version_number', tv.version_number,
        'created_at', tv.created_at
      )), '[]'::json)
      from tray_versions tv
      join trays t on t.id = tv.tray_id
      join workspaces w on w.id = t.workspace_id
      where tv.author_id = auth.uid()
    ),
    'trays_approved', (
      select coalesce(json_agg(json_build_object(
        'workspace', w.name,
        'name', tv.name,
        'version_number', tv.version_number,
        'approved_at', tv.approved_at
      )), '[]'::json)
      from tray_versions tv
      join trays t on t.id = tv.tray_id
      join workspaces w on w.id = t.workspace_id
      where tv.approved_by = auth.uid()
    ),
    'custom_instruments_authored', (
      select coalesce(json_agg(json_build_object(
        'workspace', w.name,
        'name', civ.name,
        'status', civ.status,
        'version_number', civ.version_number,
        'created_at', civ.created_at
      )), '[]'::json)
      from custom_instrument_versions civ
      join custom_instruments ci on ci.id = civ.custom_instrument_id
      join workspaces w on w.id = ci.workspace_id
      where civ.author_id = auth.uid()
    ),
    'custom_instruments_approved', (
      select coalesce(json_agg(json_build_object(
        'workspace', w.name,
        'name', civ.name,
        'version_number', civ.version_number,
        'approved_at', civ.approved_at
      )), '[]'::json)
      from custom_instrument_versions civ
      join custom_instruments ci on ci.id = civ.custom_instrument_id
      join workspaces w on w.id = ci.workspace_id
      where civ.approved_by = auth.uid()
    ),
    'learning_progress', (
      select coalesce(json_agg(json_build_object(
        'ref_type', lp.ref_type,
        'ref_id', lp.ref_id,
        'learned_at', lp.learned_at,
        'box', lp.box,
        'next_review_at', lp.next_review_at
      )), '[]'::json)
      from learning_progress lp
      where lp.user_id = auth.uid()
    ),
    'contributor_application', (
      select json_build_object(
        'full_name', ca.full_name,
        'email', ca.email,
        'country', ca.country,
        'organization_name', ca.organization_name,
        'professional_role', ca.professional_role,
        'years_experience', ca.years_experience,
        'linkedin_url', ca.linkedin_url,
        'certifications', ca.certifications,
        'publications_or_teaching', ca.publications_or_teaching,
        'motivation_letter', ca.motivation_letter,
        'status', ca.status,
        'created_at', ca.created_at
      )
      from contributor_applications ca
      where ca.user_id = auth.uid()
      order by ca.created_at desc
      limit 1
    ),
    'contributor_profile', (
      select json_build_object(
        'level', cp.level,
        'public_display_name', cp.public_display_name,
        'public_bio', cp.public_bio,
        'show_organization', cp.show_organization,
        'is_public', cp.is_public,
        'status', cp.status,
        'approved_at', cp.approved_at
      )
      from contributor_profiles cp
      where cp.user_id = auth.uid()
    )
  ) into v_result;

  return v_result;
end;
$$;
