// Edge Function: send-invitation-email
//
// Disparada por un Database Webhook de Supabase configurado a mano por el
// usuario en el dashboard (Database -> Webhooks) sobre INSERT en la tabla
// `invitations` (ver supabase/schema_v41_invitations.sql para el
// razonamiento completo). Mismo patron que send-push/index.ts: el webhook se
// configura en el dashboard, no hay trigger SQL que llame a esta funcion.
// "Reenviar" invitacion se resuelve en el cliente (revoke + create de nuevo,
// ver InvitationService.resend) -- reutiliza este mismo INSERT en vez de
// necesitar un segundo evento de webhook sobre UPDATE.
//
// Payload esperado (formato estandar de un Database Webhook de Supabase):
//   { type: 'INSERT', table: 'invitations', schema: 'public',
//     record: { ...fila nueva de invitations... }, old_record: null }
//
// Variables de entorno usadas:
//   - SUPABASE_URL                (ya disponible por defecto)
//   - SUPABASE_SERVICE_ROLE_KEY   (ya disponible por defecto)
//   - RESEND_API_KEY              (secret NUEVO que debe anadir el usuario en
//                                  Edge Functions -> Secrets: distinto del
//                                  SMTP que ya usa Supabase Auth para sus
//                                  propios correos de confirmacion/reset --
//                                  este es solo para el envio directo via
//                                  API de Resend que hace esta funcion.
//                                  Nunca se escribe ese valor en este archivo.)
//   - WEBHOOK_SHARED_SECRET       (secret compartido con el trigger `invitations`
//                                  -- ver schema_v43_security_hardening.sql.
//                                  Sin esto, cualquiera con la anon key
//                                  publica podia llamar a este endpoint
//                                  directamente con un payload fabricado y
//                                  hacer que Instriq enviase un correo real
//                                  desde hola@instriq.org con contenido casi
//                                  libre -- relay de phishing/spam con
//                                  dominio legitimo.)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const RESEND_SEND_URL = "https://api.resend.com/emails";
const FROM_ADDRESS = "Instriq <hola@instriq.org>";
// Enlace en forma hash (#/invite/...): la app Flutter Web no usa
// usePathUrlStrategy(), asi que esta es la unica forma que el router actual
// resuelve sin configuracion de servidor adicional (ver router.dart).
const APP_BASE_URL = "https://app.instriq.org";

interface InvitationRecord {
  id: string;
  organization_id: string;
  workspace_id: string;
  email: string;
  role: string;
  token: string;
  status: string;
  invited_by_name: string | null;
}

interface WebhookPayload {
  type: string;
  table: string;
  schema: string;
  record: InvitationRecord;
  old_record: InvitationRecord | null;
}

const ROLE_LABELS: Record<string, string> = {
  reader: "Lector/a",
  editor: "Editor/a",
  approver: "Aprovador/a",
};

Deno.serve(async (req: Request) => {
  try {
    const expectedSecret = Deno.env.get("WEBHOOK_SHARED_SECRET");
    const providedSecret = req.headers.get("x-webhook-secret");
    if (!expectedSecret || providedSecret !== expectedSecret) {
      return jsonResponse({ ok: false, error: "unauthorized" }, 401);
    }

    const payload = (await req.json()) as WebhookPayload;
    const record = payload?.record;
    if (!record) {
      return jsonResponse({ ok: true, skipped: true, reason: "sin registro" });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    const resendApiKey = Deno.env.get("RESEND_API_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse({ ok: false, error: "faltan SUPABASE_URL/SUPABASE_SERVICE_ROLE_KEY" }, 200);
    }
    if (!resendApiKey) {
      return jsonResponse({ ok: false, error: "falta el secret RESEND_API_KEY" }, 200);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, { auth: { persistSession: false } });

    // Defensa en profundidad: aunque ya se exige el secreto compartido de
    // arriba, no confiamos en el resto del payload del webhook para el
    // contenido del correo -- se vuelve a leer la fila real de `invitations`
    // por su id y se usan solo esos valores (nunca los del payload) para
    // email/rol/token/estado. Así, aunque algo llegase a construir un POST
    // con el secreto correcto pero datos inventados, el correo real solo
    // puede reflejar una invitación que de verdad existe y sigue pendiente.
    const { data: invitation, error: invitationError } = await admin
      .from("invitations")
      .select("id, organization_id, workspace_id, email, role, token, status, invited_by_name")
      .eq("id", record.id)
      .maybeSingle();

    if (invitationError || !invitation || invitation.status !== "pending") {
      return jsonResponse({ ok: true, skipped: true, reason: "no es una invitacion pendiente nueva" });
    }

    const [{ data: org }, { data: workspace }] = await Promise.all([
      admin.from("organizations").select("name").eq("id", invitation.organization_id).maybeSingle(),
      admin.from("workspaces").select("name").eq("id", invitation.workspace_id).maybeSingle(),
    ]);

    const orgName = (org?.name as string | undefined) ?? "tu organización";
    const workspaceName = (workspace?.name as string | undefined) ?? "un espacio de trabajo";
    const roleLabel = ROLE_LABELS[invitation.role as string] ?? invitation.role;
    const inviterName = (invitation.invited_by_name as string | null)?.trim()
      ? (invitation.invited_by_name as string)
      : "Alguien de tu equipo";
    const inviteUrl = `${APP_BASE_URL}/#/invite/${invitation.token}`;

    const subject = `${inviterName} te ha invitado a ${workspaceName} en Instriq`;
    const html = buildEmailHtml({ inviterName, orgName, workspaceName, roleLabel, inviteUrl });

    const response = await fetch(RESEND_SEND_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: FROM_ADDRESS,
        to: [invitation.email],
        subject,
        html,
      }),
    });

    if (!response.ok) {
      const text = await response.text();
      return jsonResponse({ ok: false, error: `Resend respondio ${response.status}: ${text}` }, 200);
    }

    return jsonResponse({ ok: true, invitation_id: invitation.id });
  } catch (error) {
    // Nunca devolvemos un status de error: un Database Webhook reintenta
    // indefinidamente ante un fallo no 2xx, y esto no es una operacion
    // critica que merezca reintentos infinitos.
    return jsonResponse({ ok: false, error: String(error) }, 200);
  }
});

function buildEmailHtml(params: {
  inviterName: string;
  orgName: string;
  workspaceName: string;
  roleLabel: string;
  inviteUrl: string;
}): string {
  const { inviterName, orgName, workspaceName, roleLabel, inviteUrl } = params;
  return `
    <div style="font-family: -apple-system, Helvetica, Arial, sans-serif; max-width: 480px; margin: 0 auto; color: #201c17;">
      <p>Hola,</p>
      <p><strong>${escapeHtml(inviterName)}</strong> te ha invitado a unirte a <strong>${escapeHtml(workspaceName)}</strong>, dentro de <strong>${escapeHtml(orgName)}</strong>, en Instriq — con el rol de <strong>${escapeHtml(roleLabel)}</strong>.</p>
      <p style="margin: 28px 0;">
        <a href="${inviteUrl}" style="background:#a34e1c; color:#fff; padding:12px 20px; border-radius:8px; text-decoration:none; font-weight:600;">Ver invitación</a>
      </p>
      <p style="color:#6e6459; font-size: 13px;">Si no esperabas este correo, puedes ignorarlo con tranquilidad.</p>
    </div>
  `;
}

function escapeHtml(value: string): string {
  const map: Record<string, string> = { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" };
  return value.replace(/[&<>"']/g, (c) => map[c]);
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
