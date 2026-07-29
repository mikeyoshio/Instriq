// Edge Function: send-push
//
// Disparada por un Database Webhook de Supabase configurado a mano por el
// usuario en el dashboard (Database -> Webhooks) sobre INSERT en la tabla
// `audit_log` (ver supabase/schema_v12_push_notifications.sql para el
// razonamiento completo de por que se reusa audit_log como disparador en
// vez de crear un mecanismo paralelo).
//
// Payload esperado (formato estandar de un Database Webhook de Supabase):
//   { type: 'INSERT', table: 'audit_log', schema: 'public',
//     record: { ...fila nueva de audit_log... }, old_record: null }
//
// Variables de entorno usadas:
//   - SUPABASE_URL                (ya disponible por defecto)
//   - SUPABASE_SERVICE_ROLE_KEY   (ya disponible por defecto)
//   - FCM_SERVICE_ACCOUNT_JSON    (secret que debe anadir el usuario en
//                                  Edge Functions -> Secrets: el JSON
//                                  completo del service account de Firebase
//                                  del proyecto instriq-53015. Nunca se
//                                  escribe ese valor en este archivo.)

import { createClient, type SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";
import { SignJWT, importPKCS8 } from "https://esm.sh/jose@5";

const FCM_PROJECT_ID = "instriq-53015";
const FCM_SEND_URL = `https://fcm.googleapis.com/v1/projects/${FCM_PROJECT_ID}/messages:send`;
const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";
const TOKEN_URL = "https://oauth2.googleapis.com/token";

interface AuditLogRecord {
  id: string;
  hospital_id: string | null;
  actor_id: string | null;
  action: string;
  entity_type: string | null;
  entity_id: string | null;
  workspace_id: string | null;
  metadata: Record<string, unknown> | null;
  created_at: string;
}

interface WebhookPayload {
  type: string;
  table: string;
  schema: string;
  record: AuditLogRecord;
  old_record: AuditLogRecord | null;
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
  [key: string]: unknown;
}

interface NotificationPlan {
  title: string;
  body: string;
  recipientUserIds: string[];
}

const RELEVANT_ACTIONS = new Set([
  "document_version_submitted",
  "document_version_approved",
  "document_version_rejected",
]);

Deno.serve(async (req: Request) => {
  try {
    const payload = (await req.json()) as WebhookPayload;
    const record = payload?.record;

    if (!record || !RELEVANT_ACTIONS.has(record.action)) {
      return jsonResponse({ ok: true, skipped: true, reason: "action no relevante" });
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      return jsonResponse({ ok: false, error: "faltan SUPABASE_URL/SUPABASE_SERVICE_ROLE_KEY" }, 200);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false },
    });

    const plan = await resolveNotificationPlan(admin, record);
    if (!plan || plan.recipientUserIds.length === 0) {
      return jsonResponse({ ok: true, skipped: true, reason: "sin destinatarios" });
    }

    const { data: tokenRows, error: tokenError } = await admin
      .from("device_tokens")
      .select("id, fcm_token, user_id")
      .in("user_id", plan.recipientUserIds);

    if (tokenError) {
      return jsonResponse({ ok: false, error: `error leyendo device_tokens: ${tokenError.message}` }, 200);
    }

    if (!tokenRows || tokenRows.length === 0) {
      return jsonResponse({ ok: true, skipped: true, reason: "destinatarios sin device_tokens" });
    }

    const serviceAccountJson = Deno.env.get("FCM_SERVICE_ACCOUNT_JSON");
    if (!serviceAccountJson) {
      return jsonResponse({ ok: false, error: "falta el secret FCM_SERVICE_ACCOUNT_JSON" }, 200);
    }
    const serviceAccount = JSON.parse(serviceAccountJson) as ServiceAccount;
    const accessToken = await getFcmAccessToken(serviceAccount);

    const data: Record<string, string> = {
      entity_type: record.entity_type ?? "",
      entity_id: record.entity_id ?? "",
      workspace_id: record.workspace_id ?? "",
    };

    let sent = 0;
    let failed = 0;
    const deadTokenIds: string[] = [];

    for (const row of tokenRows) {
      const result = await sendFcmMessage(accessToken, row.fcm_token, plan.title, plan.body, data);
      if (result.ok) {
        sent += 1;
      } else {
        failed += 1;
        if (result.deadToken) {
          deadTokenIds.push(row.id as string);
        }
      }
    }

    if (deadTokenIds.length > 0) {
      await admin.from("device_tokens").delete().in("id", deadTokenIds);
    }

    return jsonResponse({
      ok: true,
      action: record.action,
      recipients: plan.recipientUserIds.length,
      tokens_total: tokenRows.length,
      sent,
      failed,
      tokens_cleaned: deadTokenIds.length,
    });
  } catch (error) {
    // Nunca devolvemos un status de error: un Database Webhook reintenta
    // indefinidamente ante un fallo no 2xx, y esto no es una operacion
    // critica que merezca reintentos infinitos.
    return jsonResponse({ ok: false, error: String(error) }, 200);
  }
});

async function resolveNotificationPlan(
  admin: SupabaseClient,
  record: AuditLogRecord,
): Promise<NotificationPlan | null> {
  const metadataTitle =
    typeof record.metadata?.title === "string" ? (record.metadata!.title as string) : undefined;

  if (record.action === "document_version_submitted") {
    if (!record.workspace_id) return null;

    const recipientIds = new Set<string>();

    const { data: approvers } = await admin
      .from("workspace_members")
      .select("user_id")
      .eq("workspace_id", record.workspace_id)
      .eq("role", "approver");
    for (const row of approvers ?? []) {
      recipientIds.add(row.user_id as string);
    }

    if (record.hospital_id) {
      const { data: admins } = await admin
        .from("profiles")
        .select("id")
        .eq("hospital_id", record.hospital_id)
        .eq("is_admin", true);
      for (const row of admins ?? []) {
        recipientIds.add(row.id as string);
      }
    }

    if (record.actor_id) {
      recipientIds.delete(record.actor_id);
    }

    return {
      title: "Nuevo contenido en revision",
      body: metadataTitle ?? "Hay una version nueva esperando tu revision.",
      recipientUserIds: Array.from(recipientIds),
    };
  }

  if (record.action === "document_version_approved" || record.action === "document_version_rejected") {
    if (!record.entity_id) return null;

    const { data: version } = await admin
      .from("group_document_versions")
      .select("author_id")
      .eq("id", record.entity_id)
      .maybeSingle();

    const authorId = version?.author_id as string | null | undefined;
    if (!authorId || authorId === record.actor_id) {
      return null;
    }

    const title =
      record.action === "document_version_approved"
        ? "Tu contenido fue aprobado"
        : "Tu contenido necesita cambios";

    return {
      title,
      body: metadataTitle ?? "Revisa el estado de tu contenido.",
      recipientUserIds: [authorId],
    };
  }

  return null;
}

async function getFcmAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const privateKey = await importPKCS8(serviceAccount.private_key, "RS256");

  const assertion = await new SignJWT({ scope: FCM_SCOPE })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setIssuer(serviceAccount.client_email)
    .setAudience(TOKEN_URL)
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(privateKey);

  const response = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(`No se pudo obtener el access token de FCM: ${response.status} ${text}`);
  }

  const body = (await response.json()) as { access_token: string };
  return body.access_token;
}

async function sendFcmMessage(
  accessToken: string,
  fcmToken: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<{ ok: boolean; deadToken?: boolean }> {
  const response = await fetch(FCM_SEND_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token: fcmToken,
        notification: { title, body },
        data,
      },
    }),
  });

  if (response.ok) {
    return { ok: true };
  }

  const errorBody = await response.json().catch(() => null) as
    | { error?: { status?: string; details?: Array<{ errorCode?: string }> } }
    | null;

  const status = errorBody?.error?.status;
  const errorCode = errorBody?.error?.details?.[0]?.errorCode;
  const deadToken = status === "NOT_FOUND" || status === "UNREGISTERED" || errorCode === "UNREGISTERED";

  return { ok: false, deadToken };
}

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
