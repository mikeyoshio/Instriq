// Edge Function: surgical-agenda-ics
//
// UNICO endpoint publico sin sesion de este proyecto. Un cliente de
// calendario (Outlook, Calendario de iPhone, Google Calendar) lo consulta
// periodicamente mediante una URL `webcal://` o `https://` que lleva un
// token opaco como credencial en la query string (`?token=...`) -- un
// cliente de calendario nunca manda cabecera `Authorization`, asi que no hay
// sesion ni JWT de Supabase posible aqui. El token es el unico secreto: se
// valida contra `surgeon_ics_tokens` (tabla con RLS activo y cero politicas,
// ver schema_v64_surgical_agenda.sql -- solo el cliente service-role puede
// leerla, igual que esta funcion).
//
// PASO DE DESPLIEGUE MANUAL (lo hace el usuario, no esta funcion): por
// defecto las Edge Functions de Supabase exigen un JWT valido en cada
// request, y un cliente de calendario real nunca lo envia. Hay que
// desplegar explicitamente con:
//
//   supabase functions deploy surgical-agenda-ics --no-verify-jwt
//
// (o anadir a `supabase/config.toml` una seccion
// `[functions.surgical-agenda-ics]` con `verify_jwt = false`). Sin este
// paso, el feed devolvera 401 antes de llegar siquiera a este codigo y no
// funcionara nunca desde Outlook/iPhone/Google Calendar.
//
// Restriccion de diseno central de este archivo: el campo `notes` de
// `surgical_slots` es texto libre que podria contener informacion de
// paciente y NUNCA debe leerse ni exponerse aqui -- ni en una query, ni en
// el ICS generado. Todo lo que sale hacia el calendario personal del
// cirujano se construye solo a partir de `procedure_name`, el titulo de la
// tecnica/protocolo enlazada (si existe) y `location`.
//
// Variables de entorno usadas:
//   - SUPABASE_URL                (ya disponible por defecto)
//   - SUPABASE_SERVICE_ROLE_KEY   (ya disponible por defecto)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const DAY_MS = 24 * 60 * 60 * 1000;
const WINDOW_PAST_DAYS = 30;
const WINDOW_FUTURE_DAYS = 365;

interface SurgicalSlotRow {
  id: string;
  procedure_name: string | null;
  document_id: string | null;
  location: string | null;
  starts_at: string;
  ends_at: string;
}

Deno.serve(async (req: Request) => {
  try {
    const token = new URL(req.url).searchParams.get("token");
    if (!token) {
      return new Response("Falta el parametro token", { status: 400 });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const { data: tokenRow } = await admin
      .from("surgeon_ics_tokens")
      .select("surgeon_id")
      .eq("token", token)
      .maybeSingle();

    if (!tokenRow) {
      return new Response("Token no valido", { status: 404 });
    }

    const surgeonId = tokenRow.surgeon_id as string;

    const { data: surgeon } = await admin
      .from("surgeons")
      .select("name")
      .eq("id", surgeonId)
      .maybeSingle();

    const surgeonName = (surgeon?.name as string | undefined) ?? "Cirujano";

    const now = new Date();
    const rangeStart = new Date(now.getTime() - WINDOW_PAST_DAYS * DAY_MS).toISOString();
    const rangeEnd = new Date(now.getTime() + WINDOW_FUTURE_DAYS * DAY_MS).toISOString();

    const { data: slots } = await admin
      .from("surgical_slots")
      .select("id, procedure_name, document_id, location, starts_at, ends_at")
      .eq("surgeon_id", surgeonId)
      .eq("status", "scheduled")
      .gte("starts_at", rangeStart)
      .lte("starts_at", rangeEnd)
      .order("starts_at");

    const slotRows = (slots ?? []) as SurgicalSlotRow[];

    const documentTitleById = await resolveDocumentTitles(admin, slotRows);

    const dtstamp = formatIcsDate(now);
    const lines: string[] = [
      "BEGIN:VCALENDAR",
      "VERSION:2.0",
      "PRODID:-//Instriq//Surgical Agenda//ES",
      "METHOD:PUBLISH",
      `X-WR-CALNAME:Agenda quirurgica - ${escapeIcsText(surgeonName)}`,
    ];

    for (const slot of slotRows) {
      const summary =
        slot.procedure_name ??
        (slot.document_id ? documentTitleById.get(slot.document_id) : undefined) ??
        "Cirugia programada";

      lines.push(
        "BEGIN:VEVENT",
        `UID:${slot.id}@instriq.org`,
        `DTSTAMP:${dtstamp}`,
        `DTSTART:${formatIcsDate(slot.starts_at)}`,
        `DTEND:${formatIcsDate(slot.ends_at)}`,
        `SUMMARY:${escapeIcsText(summary)}`,
      );
      if (slot.location) {
        lines.push(`LOCATION:${escapeIcsText(slot.location)}`);
      }
      lines.push("END:VEVENT");
    }

    lines.push("END:VCALENDAR");

    const icsBody = lines.join("\r\n") + "\r\n";

    return new Response(icsBody, {
      headers: {
        "Content-Type": "text/calendar; charset=utf-8",
        "Content-Disposition": 'inline; filename="agenda.ics"',
      },
    });
  } catch (_error) {
    return new Response("Error generando la agenda", { status: 500 });
  }
});

// Resuelve el titulo real de la tecnica/protocolo enlazado via
// group_documents.published_version_id -> group_document_versions.title
// (el titulo vive en la version publicada desde schema_v5, no en
// group_documents directamente). Dos selects "in (...)" acotados a los
// document_id realmente usados por los slots de esta respuesta -- sin
// resolver nada si ningun slot tiene document_id.
async function resolveDocumentTitles(
  admin: ReturnType<typeof createClient>,
  slots: SurgicalSlotRow[],
): Promise<Map<string, string>> {
  const documentIds = Array.from(
    new Set(slots.map((s) => s.document_id).filter((id): id is string => !!id)),
  );
  if (documentIds.length === 0) return new Map();

  const { data: documents } = await admin
    .from("group_documents")
    .select("id, published_version_id")
    .in("id", documentIds);

  const publishedVersionIdByDocumentId = new Map<string, string>();
  for (const doc of documents ?? []) {
    if (doc.published_version_id) {
      publishedVersionIdByDocumentId.set(doc.id as string, doc.published_version_id as string);
    }
  }

  const versionIds = Array.from(publishedVersionIdByDocumentId.values());
  if (versionIds.length === 0) return new Map();

  const { data: versions } = await admin
    .from("group_document_versions")
    .select("id, title")
    .in("id", versionIds);

  const titleByVersionId = new Map<string, string>();
  for (const version of versions ?? []) {
    titleByVersionId.set(version.id as string, version.title as string);
  }

  const titleByDocumentId = new Map<string, string>();
  for (const [documentId, versionId] of publishedVersionIdByDocumentId) {
    const title = titleByVersionId.get(versionId);
    if (title) titleByDocumentId.set(documentId, title);
  }
  return titleByDocumentId;
}

// Escapado simple segun RFC 5545 (§3.3.11): coma, punto y coma, barra
// invertida y salto de linea llevan "\" delante.
function escapeIcsText(value: string): string {
  return value
    .replace(/\\/g, "\\\\")
    .replace(/,/g, "\\,")
    .replace(/;/g, "\\;")
    .replace(/\n/g, "\\n");
}

function formatIcsDate(value: string | Date): string {
  const date = typeof value === "string" ? new Date(value) : value;
  return date.toISOString().replace(/[-:]/g, "").split(".")[0] + "Z";
}
