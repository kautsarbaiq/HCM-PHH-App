// Supabase Edge Function: send-push
// Called by database webhooks (security/11_push_notifications.sql) whenever a
// relevant row changes. Decides WHO should be notified, looks up their device
// tokens in push_tokens, and sends via Firebase Cloud Messaging (HTTP v1).
//
// Setup:
//   1) Firebase console → Project settings → Service accounts →
//      Generate new private key → download the .json
//   2) npx supabase secrets set FCM_SA_B64="$(base64 -i that-file.json)"
//   3) npx supabase functions deploy send-push

import { createClient } from "npm:@supabase/supabase-js@2";

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

// ---------------------------------------------------------------------------
// FCM auth: service-account JWT → OAuth access token (cached ~50 min).
// ---------------------------------------------------------------------------

let cachedToken: { value: string; exp: number } | null = null;

function b64url(data: Uint8Array | string): string {
  const bytes = typeof data === "string"
    ? new TextEncoder().encode(data)
    : data;
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToDer(pem: string): Uint8Array {
  const b64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\s/g, "");
  const bin = atob(b64);
  const bytes = new Uint8Array(bin.length);
  for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
  return bytes;
}

function getServiceAccount(): { client_email: string; private_key: string; project_id: string } {
  const raw = Deno.env.get("FCM_SA_B64");
  if (!raw) throw new Error("FCM_SA_B64 secret is not set");
  return JSON.parse(atob(raw.replace(/\s/g, "")));
}

async function getAccessToken(): Promise<{ token: string; projectId: string }> {
  const sa = getServiceAccount();
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.exp > now + 60) {
    return { token: cachedToken.value, projectId: sa.project_id };
  }

  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = b64url(JSON.stringify({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  }));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = new Uint8Array(
    await crypto.subtle.sign(
      "RSASSA-PKCS1-v1_5",
      key,
      new TextEncoder().encode(`${header}.${claims}`),
    ),
  );
  const jwt = `${header}.${claims}.${b64url(sig)}`;

  const resp = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  const data = await resp.json();
  if (!resp.ok) throw new Error(`oauth failed: ${JSON.stringify(data)}`);
  cachedToken = { value: data.access_token, exp: now + (data.expires_in ?? 3600) };
  return { token: data.access_token, projectId: sa.project_id };
}

// ---------------------------------------------------------------------------
// Recipient lookup helpers (service role — bypasses RLS).
// ---------------------------------------------------------------------------

async function userIdsByRole(role: string): Promise<string[]> {
  const { data } = await supabase.from("profiles").select("id").eq("role", role);
  return (data ?? []).map((r: { id: string }) => r.id);
}

async function residentsOfHouse(houseId: string): Promise<string[]> {
  const { data } = await supabase
    .from("profiles")
    .select("id")
    .eq("house_id", houseId);
  return (data ?? []).map((r: { id: string }) => r.id);
}

async function everyone(): Promise<string[]> {
  const { data } = await supabase.from("profiles").select("id");
  return (data ?? []).map((r: { id: string }) => r.id);
}

// ---------------------------------------------------------------------------
// Event → notification rules.
// ---------------------------------------------------------------------------

type Payload = {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: Record<string, unknown> | null;
  old_record: Record<string, unknown> | null;
};

async function buildNotification(
  p: Payload,
): Promise<{ userIds: string[]; title: string; body: string } | null> {
  const r = (p.record ?? {}) as Record<string, string>;
  const old = (p.old_record ?? {}) as Record<string, string>;

  switch (p.table) {
    case "visitors": {
      const guards = await userIdsByRole("guard");
      const admins = await userIdsByRole("admin");
      const house = r.house_id ? await residentsOfHouse(r.house_id) : [];
      if (p.type === "INSERT") {
        return {
          userIds: [...house, ...guards, ...admins],
          title: "New visitor registered",
          body: `${r.visitor_name ?? "A visitor"} is registered for your house.`,
        };
      }
      if (p.type === "UPDATE" && old.status !== r.status) {
        if (r.status === "checked_in") {
          return {
            userIds: [...house, ...admins],
            title: "Visitor checked in",
            body: `${r.visitor_name ?? "A visitor"} has entered.`,
          };
        }
        if (r.status === "checked_out") {
          return {
            userIds: [...house, ...admins],
            title: "Visitor checked out",
            body: `${r.visitor_name ?? "A visitor"} has left.`,
          };
        }
      }
      return null;
    }

    case "bookings": {
      if (p.type === "INSERT") {
        return {
          userIds: await userIdsByRole("admin"),
          title: "New facility booking",
          body: `${r.facility_name ?? "A facility"} on ${r.date ?? ""} ${r.time ?? ""} — waiting for approval.`,
        };
      }
      if (p.type === "UPDATE" && old.status !== r.status && r.booked_by) {
        const s = (r.status ?? "").toLowerCase();
        if (s === "confirmed" || s === "approved") {
          return {
            userIds: [r.booked_by],
            title: "Booking approved ✓",
            body: `Your ${r.facility_name ?? "facility"} booking on ${r.date ?? ""} is confirmed.`,
          };
        }
        if (s === "cancelled" || s === "rejected") {
          return {
            userIds: [r.booked_by],
            title: "Booking rejected",
            body: `Your ${r.facility_name ?? "facility"} booking on ${r.date ?? ""} was rejected.`,
          };
        }
      }
      return null;
    }

    case "billings": {
      if (p.type === "INSERT" && r.resident_id) {
        return {
          userIds: [r.resident_id],
          title: "New bill received",
          body: `${r.title ?? "A bill"} — RM ${r.amount ?? ""}. Due ${r.due_date ?? ""}.`,
        };
      }
      return null;
    }

    case "announcements": {
      if (p.type === "INSERT") {
        return {
          userIds: await everyone(),
          title: r.is_urgent === "true" || (r.is_urgent as unknown) === true
            ? "🔴 Urgent announcement"
            : "New announcement",
          body: r.title ?? "",
        };
      }
      return null;
    }

    case "emergencies": {
      if (p.type === "INSERT") {
        return {
          userIds: await everyone(),
          title: `🚨 ${r.title ?? "Emergency"}`,
          body: r.subtitle ?? "Emergency alert — open the app.",
        };
      }
      return null;
    }

    case "form_submissions": {
      if (p.type === "INSERT") {
        return {
          userIds: await userIdsByRole("admin"),
          title: "New form submission",
          body: "A resident submitted a form — review it in the admin portal.",
        };
      }
      if (p.type === "UPDATE" && old.status !== r.status && r.user_id) {
        return {
          userIds: [r.user_id],
          title: `Form ${r.status ?? "updated"}`,
          body: `Your form submission was ${r.status ?? "updated"}.`,
        };
      }
      return null;
    }
  }
  return null;
}

// ---------------------------------------------------------------------------

Deno.serve(async (req: Request) => {
  try {
    const payload = (await req.json()) as Payload;
    const note = await buildNotification(payload);
    if (!note || note.userIds.length === 0) {
      return new Response(JSON.stringify({ skipped: true }), { status: 200 });
    }

    const userIds = [...new Set(note.userIds)];
    const { data: tokenRows } = await supabase
      .from("push_tokens")
      .select("token")
      .in("user_id", userIds);
    const tokens = (tokenRows ?? []).map((t: { token: string }) => t.token);
    if (tokens.length === 0) {
      return new Response(JSON.stringify({ sent: 0 }), { status: 200 });
    }

    const { token: accessToken, projectId } = await getAccessToken();
    let sent = 0;
    await Promise.all(tokens.map(async (t) => {
      const resp = await fetch(
        `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
        {
          method: "POST",
          headers: {
            authorization: `Bearer ${accessToken}`,
            "content-type": "application/json",
          },
          body: JSON.stringify({
            message: {
              token: t,
              notification: { title: note.title, body: note.body },
              android: { priority: "HIGH" },
            },
          }),
        },
      );
      if (resp.ok) {
        sent++;
      } else {
        const err = await resp.json().catch(() => ({}));
        const code = err?.error?.details?.[0]?.errorCode ?? err?.error?.status;
        // Stale/uninstalled device — drop the token.
        if (code === "UNREGISTERED" || resp.status === 404) {
          await supabase.from("push_tokens").delete().eq("token", t);
        }
      }
    }));

    return new Response(JSON.stringify({ sent, of: tokens.length }), {
      status: 200,
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
