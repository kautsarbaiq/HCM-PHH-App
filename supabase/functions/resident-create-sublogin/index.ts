// Supabase Edge Function: resident-create-sublogin
// Boss batch 08/08 point 5 — a resident creates a login for their wife/child.
// Only the service_role key may create auth users, so this runs server-side.
//
// Actions (POST body):
//   { action: "create", full_name, email, password }
//   { action: "delete", user_id }
//
// Rules enforced here:
//   * caller must be an approved resident
//   * a sub-login cannot create further sub-logins (no chains)
//   * max 5 sub-logins per household
//   * the new account inherits house_id / community_id / resident_type from
//     the parent and is approved immediately (the parent already was), so both
//     logins land on the same interface and see the same data
//   * delete only works on the caller's OWN sub-logins
//
// Deploy:
//   supabase functions deploy resident-create-sublogin

import { createClient } from "npm:@supabase/supabase-js@2";

const MAX_SUB_LOGINS = 5;

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "content-type": "application/json" },
  });
}

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // --- 1) authenticate the caller ------------------------------------
    const token = (req.headers.get("Authorization") ?? "").replace(
      /^Bearer\s+/i,
      "",
    );
    if (!token) return json({ error: "Not authenticated" }, 401);

    const { data: userData, error: userErr } = await admin.auth.getUser(token);
    if (userErr || !userData?.user) {
      return json({ error: "Not authenticated" }, 401);
    }
    const callerId = userData.user.id;

    const { data: parent } = await admin
      .from("profiles")
      .select(
        "role, approval_status, house_id, community_id, resident_type, parent_user_id",
      )
      .eq("id", callerId)
      .maybeSingle();

    if (!parent || parent.role !== "resident") {
      return json({ error: "Only a resident can create a family login" }, 403);
    }
    if ((parent.approval_status ?? "approved") !== "approved") {
      return json({ error: "Your account is not approved yet" }, 403);
    }
    if (parent.parent_user_id) {
      return json(
        { error: "A family login cannot create further logins" },
        403,
      );
    }

    const body = await req.json();
    const action = (body.action ?? "create").toString();

    // --- 2) delete --------------------------------------------------------
    if (action === "delete") {
      const targetId = (body.user_id ?? "").toString();
      if (!targetId) return json({ error: "user_id is required" }, 400);

      const { data: target } = await admin
        .from("profiles")
        .select("parent_user_id")
        .eq("id", targetId)
        .maybeSingle();
      if (!target || target.parent_user_id !== callerId) {
        return json({ error: "That is not your family login" }, 403);
      }

      const { error: delErr } = await admin.auth.admin.deleteUser(targetId);
      if (delErr) return json({ error: delErr.message }, 400);
      return json({ ok: true }, 200);
    }

    // --- 3) create --------------------------------------------------------
    const fullName = (body.full_name ?? "").toString().trim();
    const email = (body.email ?? "").toString().trim().toLowerCase();
    const password = (body.password ?? "").toString();

    if (fullName.length < 2) return json({ error: "Name is required" }, 400);
    if (!email) return json({ error: "Email is required" }, 400);
    if (password.length < 6) {
      return json({ error: "Password must be at least 6 characters" }, 400);
    }

    const { count } = await admin
      .from("profiles")
      .select("id", { count: "exact", head: true })
      .eq("parent_user_id", callerId);
    if ((count ?? 0) >= MAX_SUB_LOGINS) {
      return json(
        { error: `You can create at most ${MAX_SUB_LOGINS} family logins` },
        400,
      );
    }

    const { data: created, error: createErr } = await admin.auth.admin
      .createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: {
          full_name: fullName,
          resident_type: parent.resident_type ?? "owner",
        },
      });
    if (createErr || !created?.user) {
      const msg = createErr?.message ?? "Failed to create account";
      if (/already.*registered|exists/i.test(msg)) {
        return json({ error: "That email is already registered" }, 409);
      }
      return json({ error: msg }, 400);
    }
    const newUserId = created.user.id;

    // handle_new_user seeds a base row; stamp the inherited household fields
    // so the sub-login opens on exactly the same data as the main account.
    const { error: profErr } = await admin.from("profiles").upsert({
      id: newUserId,
      full_name: fullName,
      email,
      role: "resident",
      resident_type: parent.resident_type ?? "owner",
      house_id: parent.house_id,
      community_id: parent.community_id,
      approval_status: "approved",
      parent_user_id: callerId,
    });
    if (profErr) {
      await admin.auth.admin.deleteUser(newUserId).catch(() => {});
      return json({ error: `Profile setup failed: ${profErr.message}` }, 500);
    }

    return json({ ok: true, user_id: newUserId }, 200);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
