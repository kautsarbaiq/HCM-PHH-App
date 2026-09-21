// Supabase Edge Function: admin-manage-account
//
// Two things the management office could previously only do by hand in the
// Supabase dashboard:
//
//   { action: "create_guard",   full_name, email, password, phone? }
//   { action: "reset_password", user_id, new_password }
//
// Both need the service_role key (creating auth users, changing someone else's
// password), so they run here rather than in the app.
//
// WHO MAY DO WHAT
//   * caller must be an admin or super_admin
//   * create_guard: the guard lands in the caller's own community. An admin
//     cannot create a guard for a community they do not manage.
//   * reset_password:
//       - admin       -> residents and guards in their own community only
//       - super_admin -> residents, guards and admins
//       - nobody may reset a super_admin this way, and nobody may reset their
//         own password here (use the in-app "change password" for that, which
//         requires knowing the current one)
//
// Deploy:
//   supabase functions deploy admin-manage-account

import { createClient } from "npm:@supabase/supabase-js@2";

const MIN_PASSWORD = 6;

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
  if (req.method !== "POST") return json({ error: "Use POST" }, 405);

  try {
    // --- 1) who is calling ------------------------------------------------
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

    const { data: caller } = await admin
      .from("profiles")
      .select("role, community_id")
      .eq("id", callerId)
      .maybeSingle();

    const callerRole = caller?.role;
    if (callerRole !== "admin" && callerRole !== "super_admin") {
      return json({ error: "Only management can do this" }, 403);
    }

    const body = await req.json();
    const action = (body.action ?? "").toString();

    // --- 2) create a guard ----------------------------------------------
    if (action === "create_guard") {
      const fullName = (body.full_name ?? "").toString().trim();
      const email = (body.email ?? "").toString().trim().toLowerCase();
      const password = (body.password ?? "").toString();
      const phone = body.phone ? body.phone.toString().trim() : null;

      if (fullName.length < 2) return json({ error: "Name is required" }, 400);
      if (!email) return json({ error: "Email is required" }, 400);
      if (password.length < MIN_PASSWORD) {
        return json(
          { error: `Password must be at least ${MIN_PASSWORD} characters` },
          400,
        );
      }
      if (!caller?.community_id) {
        return json(
          { error: "Your account is not linked to a community" },
          400,
        );
      }

      const { data: created, error: createErr } = await admin.auth.admin
        .createUser({
          email,
          password,
          email_confirm: true, // no inbox step — the office hands over the login
          user_metadata: { full_name: fullName },
        });
      if (createErr || !created?.user) {
        const msg = createErr?.message ?? "Failed to create account";
        if (/already.*registered|exists/i.test(msg)) {
          return json({ error: "That email is already registered" }, 409);
        }
        return json({ error: msg }, 400);
      }
      const newUserId = created.user.id;

      // handle_new_user seeds a base row; stamp the guard-specific fields.
      const { error: profErr } = await admin.from("profiles").upsert({
        id: newUserId,
        full_name: fullName,
        email,
        phone,
        role: "guard",
        community_id: caller.community_id,
        approval_status: "approved",
      });
      if (profErr) {
        await admin.auth.admin.deleteUser(newUserId).catch(() => {});
        return json({ error: `Profile setup failed: ${profErr.message}` }, 500);
      }

      return json({ ok: true, user_id: newUserId }, 200);
    }

    // --- 3) reset someone's password -------------------------------------
    if (action === "reset_password") {
      const targetId = (body.user_id ?? "").toString().trim();
      const newPassword = (body.new_password ?? "").toString();

      if (!targetId) return json({ error: "user_id is required" }, 400);
      if (newPassword.length < MIN_PASSWORD) {
        return json(
          { error: `Password must be at least ${MIN_PASSWORD} characters` },
          400,
        );
      }
      if (targetId === callerId) {
        return json(
          { error: "Use Change Password in your profile for your own account" },
          400,
        );
      }

      const { data: target } = await admin
        .from("profiles")
        .select("role, community_id, deleted_at")
        .eq("id", targetId)
        .maybeSingle();
      if (!target) return json({ error: "Account not found" }, 404);
      if (target.deleted_at) {
        return json({ error: "That account has been deleted" }, 410);
      }

      const allowed = callerRole === "super_admin"
        ? ["resident", "guard", "admin", "merchant"]
        : ["resident", "guard", "merchant"];
      if (!allowed.includes(target.role)) {
        return json({ error: "You cannot reset that account's password" }, 403);
      }
      if (
        callerRole === "admin" &&
        target.community_id !== caller?.community_id
      ) {
        return json({ error: "That account is not in your community" }, 403);
      }

      const { error: updErr } = await admin.auth.admin.updateUserById(
        targetId,
        { password: newPassword },
      );
      if (updErr) return json({ error: updErr.message }, 400);

      return json({ ok: true }, 200);
    }

    return json({ error: `Unknown action "${action}"` }, 400);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
