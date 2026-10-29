-- Auditoria de madurez (2026-10-29), dimensiones seguridad/privacidad:
-- 2 hallazgos reales, ambos corregidos aqui.
--
-- 1. export_my_account_data() (schema_v9, ampliada una vez en schema_v52)
--    ha vuelto a quedarse corta -- segunda vez documentada. Faltaban
--    favorites, recent_views, device_tokens, la autoria de
--    instrument_incidents (reported_by/resolved_by/verified_by), y las
--    tablas nuevas de la sesion anterior (content_follows,
--    team_quizzes.created_by, app_feedback, editorial_comments.author_id
--    para los ref_type privados). El patron "se nos olvida la tabla
--    nueva" ya se repitio una vez -- de ahi el checklist explicito debajo,
--    para que la proxima tabla con datos personales se añada aqui sin
--    depender de acordarse.
--
-- 2. app_feedback.message no tenia limite de longitud, a diferencia de
--    feature_suggestions.description (mismo tipo de endpoint anonimo,
--    schema_v46), que si lo tiene como mitigacion documentada. Mismo
--    limite aplicado aqui (app_feedback puede justificar algo mas largo
--    que una sugerencia corta, pero sigue acotado).

alter table app_feedback drop constraint if exists app_feedback_message_check;
alter table app_feedback add constraint app_feedback_message_check
  check (char_length(trim(message)) between 1 and 2000);

-- CHECKLIST -- toda tabla nueva con una columna que identifique a un
-- usuario (user_id/author_id/created_by/reported_by/resolved_by/
-- verified_by/client de login...) debe anadir aqui su propia entrada en
-- el json_build_object, el mismo dia que se cree esa tabla, no despues.
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
    ),
    -- A partir de aqui, lo anadido en la auditoria de madurez 2026-10-29.
    'favorites', (
      select coalesce(json_agg(json_build_object(
        'ref_type', f.ref_type,
        'ref_id', f.ref_id,
        'created_at', f.created_at
      )), '[]'::json)
      from favorites f
      where f.user_id = auth.uid()
    ),
    'recent_views', (
      select coalesce(json_agg(json_build_object(
        'ref_type', rv.ref_type,
        'ref_id', rv.ref_id,
        'viewed_at', rv.viewed_at
      )), '[]'::json)
      from recent_views rv
      where rv.user_id = auth.uid()
    ),
    -- Sin el fcm_token en si (es un identificador tecnico de dispositivo,
    -- no un dato de portabilidad util) -- solo la plataforma y las fechas.
    'device_tokens', (
      select coalesce(json_agg(json_build_object(
        'platform', dt.platform,
        'created_at', dt.created_at,
        'updated_at', dt.updated_at
      )), '[]'::json)
      from device_tokens dt
      where dt.user_id = auth.uid()
    ),
    'content_follows', (
      select coalesce(json_agg(json_build_object(
        'ref_type', cf.ref_type,
        'ref_id', cf.ref_id,
        'created_at', cf.created_at
      )), '[]'::json)
      from content_follows cf
      where cf.user_id = auth.uid()
    ),
    'instrument_incidents_reported', (
      select coalesce(json_agg(json_build_object(
        'instrument_ref_type', ii.instrument_ref_type,
        'instrument_ref_id', ii.instrument_ref_id,
        'severity', ii.severity,
        'status', ii.status,
        'description', ii.description,
        'created_at', ii.created_at
      )), '[]'::json)
      from instrument_incidents ii
      where ii.reported_by = auth.uid()
    ),
    'instrument_incidents_resolved', (
      select coalesce(json_agg(json_build_object(
        'instrument_ref_type', ii.instrument_ref_type,
        'instrument_ref_id', ii.instrument_ref_id,
        'root_cause', ii.root_cause,
        'corrective_action', ii.corrective_action,
        'resolved_at', ii.resolved_at
      )), '[]'::json)
      from instrument_incidents ii
      where ii.resolved_by = auth.uid()
    ),
    'instrument_incidents_verified', (
      select coalesce(json_agg(json_build_object(
        'instrument_ref_type', ii.instrument_ref_type,
        'instrument_ref_id', ii.instrument_ref_id,
        'verification_notes', ii.verification_notes,
        'verified_at', ii.verified_at
      )), '[]'::json)
      from instrument_incidents ii
      where ii.verified_by = auth.uid()
    ),
    'team_quizzes_created', (
      select coalesce(json_agg(json_build_object(
        'team', t.name,
        'title', tq.title,
        'instrument_count', jsonb_array_length(tq.instrument_ids),
        'created_at', tq.created_at
      )), '[]'::json)
      from team_quizzes tq
      join teams t on t.id = tq.team_id
      where tq.created_by = auth.uid()
    ),
    'app_feedback_submitted', (
      select coalesce(json_agg(json_build_object(
        'category', af.category,
        'message', af.message,
        'created_at', af.created_at
      )), '[]'::json)
      from app_feedback af
      where af.user_id = auth.uid()
    ),
    'editorial_comments_authored', (
      select coalesce(json_agg(json_build_object(
        'ref_type', ec.ref_type,
        'ref_id', ec.ref_id,
        'body', ec.body,
        'resolved', ec.resolved,
        'created_at', ec.created_at
      )), '[]'::json)
      from editorial_comments ec
      where ec.author_id = auth.uid()
    )
  ) into v_result;

  return v_result;
end;
$$;
