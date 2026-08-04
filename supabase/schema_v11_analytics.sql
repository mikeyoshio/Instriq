-- Fase E (version minima/realista) de la evolucion de Instriq: dashboard de
-- COBERTURA DE CONOCIMIENTO DOCUMENTADO por especialidad. Esto NO es un
-- dashboard de uso/engagement: el progreso de aprendizaje (flashcards/quiz)
-- vive hoy solo en shared_preferences local del dispositivo, no en Supabase,
-- asi que no hay forma honesta de medir "que se consulta mas". Lo que si
-- podemos medir con datos reales ya existentes es cuanto contenido tiene
-- documentado cada hospital: tecnicas/protocolos publicados vs en
-- borrador/revision por especialidad, tarjetas de preferencia, espacios de
-- trabajo y miembros por rol. Pensado tambien como material de venta ante
-- una administracion publica que quiere ver gestion del conocimiento, no
-- solo consulta. Ejecutar despues de schema_v9_gdpr.sql (usa
-- my_hospital_id()/my_is_hospital_admin() de schema_v3 y my_workspace_role()
-- de schema_v7).

-- Solo conteos agregados (nunca contenido individual identificable de una
-- persona concreta) -- por eso no hace falta restringirlo a admin: no
-- expone nada que ya no sea visible de forma dispersa a cualquier miembro
-- del hospital. Quien hizo cada cosa ya lo cubre la auditoria de la Fase D,
-- que es tarea aparte y no se toca aqui.

create or replace function hospital_content_stats(p_hospital_id uuid)
returns json
language plpgsql
security definer
stable
set search_path = public
as $$
declare
  v_result json;
begin
  -- Solo un miembro del propio hospital puede pedir sus estadisticas.
  if p_hospital_id is null or p_hospital_id <> my_hospital_id() then
    raise exception 'No autorizado';
  end if;

  select json_build_object(
    -- Cobertura de contenido por especialidad. La especialidad es el campo
    -- de texto libre historico en group_document_versions.specialty (la
    -- lista cerrada real vive en la tabla `specialties`, 1:1 con el enum
    -- Specialty de lib/models/instrument.dart, ver schema_v19). Se
    -- agrupa por el valor tal cual esta guardado (incluye null como "Sin
    -- especialidad" para no perder documentos antiguos sin clasificar).
    'by_specialty', (
      select coalesce(json_agg(row_to_json(t) order by t.published_count desc, t.specialty), '[]'::json)
      from (
        select
          coalesce(specialty_key, 'Sin especialidad') as specialty,
          count(*) filter (where kind_flag = 'published') as published_count,
          count(*) filter (where kind_flag = 'draft_review') as draft_review_count
        from (
          -- Una fila por documento publicado (version aprobada vigente).
          select gd.id as doc_id, gdv.specialty as specialty_key, 'published' as kind_flag
          from group_documents gd
          join group_document_versions gdv on gdv.id = gd.published_version_id
          where gd.hospital_id = p_hospital_id

          union all

          -- Una fila por documento con contenido pendiente (borrador o en
          -- revision). Se toma la version pendiente mas reciente de cada
          -- documento para no contar el mismo documento varias veces.
          -- IMPORTANTE: el DISTINCT ON + ORDER BY va en su propia subconsulta
          -- entre parentesis -- sin ellos, Postgres aplica ese ORDER BY al
          -- UNION ALL completo, donde gd/gdv ya no estan en scope (error
          -- 42P01 "missing FROM-clause entry for table gd").
          select doc_id, specialty_key, 'draft_review' as kind_flag
          from (
            select distinct on (gd.id) gd.id as doc_id, gdv.specialty as specialty_key
            from group_documents gd
            join group_document_versions gdv on gdv.document_id = gd.id
            where gd.hospital_id = p_hospital_id
              and gdv.status in ('draft', 'in_review')
            order by gd.id, gdv.version_number desc
          ) latest_pending
        ) x
        group by specialty_key
      ) t
    ),
    'totals', json_build_object(
      'workspaces_count', (
        select count(*) from workspaces where hospital_id = p_hospital_id
      ),
      'preference_cards_count', (
        -- Sin desglose por especialidad: preference_cards no tiene ese
        -- campo (es una tarjeta por procedimiento/cirujano, no por
        -- especialidad quirurgica).
        select count(*) from preference_cards where hospital_id = p_hospital_id
      ),
      'members_by_role', json_build_object(
        -- El rol "administrator" es a nivel de organizacion (profiles.is_admin),
        -- no por espacio: coincide con el criterio de my_workspace_role().
        'administrator', (
          select count(*) from profiles
          where hospital_id = p_hospital_id and is_admin = true
        ),
        -- reader/editor/approver son por espacio (workspace_members); se
        -- cuentan personas distintas que tengan ese rol en al menos un
        -- espacio del hospital (una misma persona puede tener roles
        -- distintos en espacios distintos y contar en mas de una columna).
        'reader', (
          select count(distinct wm.user_id)
          from workspace_members wm
          join workspaces w on w.id = wm.workspace_id
          where w.hospital_id = p_hospital_id and wm.role = 'reader'
        ),
        'editor', (
          select count(distinct wm.user_id)
          from workspace_members wm
          join workspaces w on w.id = wm.workspace_id
          where w.hospital_id = p_hospital_id and wm.role = 'editor'
        ),
        'approver', (
          select count(distinct wm.user_id)
          from workspace_members wm
          join workspaces w on w.id = wm.workspace_id
          where w.hospital_id = p_hospital_id and wm.role = 'approver'
        )
      )
    )
  ) into v_result;

  return v_result;
end;
$$;
