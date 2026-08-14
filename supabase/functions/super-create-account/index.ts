// Supabase Edge Function: super-create-account
// Boss batch 08/08 point 1 — the Super Admin portal creates the login accounts
// it manages. Only the service_role key may create auth users, so this runs
// server-side.
//
// Actions (POST body):
//   { action: "admin",    community_id, full_name, email, password }
//   { action: "merchant", community_id?, shop_name, full_name, email, password,
//                         category?, contact?, address? }
//   { action: "delete_user", user_id }
//
// Only a super_admin may call this. Creating a merchant also inserts the
// `merchants` row so the shop shows up in the portal immediately.
//
// Deploy:
//   supabase functions deploy super-create-account

import { createClient } from "npm:@supabase/supabase-js@2";

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
    // --- 1) authenticate + authorize -----------------------------------
    const token = (req.headers.get("Authorization") ?? "").replace(
      /^Bearer\s+/i,
      "",
    );
    if (!token) return json({ error: "Not authenticated" }, 401);

    const { data: userData, error: userErr } = await admin.auth.getUser(token);
    if (userErr || !userData?.user) {
      return json({ error: "Not authenticated" }, 401);
    }

    const { data: caller } = await admin
      .from("profiles")
      .select("role")
      .eq("id", userData.user.id)
      .maybeSingle();
    if (!caller || caller.role !== "super_admin") {
      return json({ error: "Only a super admin can do this" }, 403);
    }

    const body = await req.json();
    const action = (body.action ?? "").toString();

    // --- 2) delete -------------------------------------------------------
    if (action === "delete_user") {
      const targetId = (body.user_id ?? "").toString();
      if (!targetId) return json({ error: "user_id is required" }, 400);
      // Never let the super admin delete their own login by accident.
      if (targetId === userData.user.id) {
        return json({ error: "You cannot delete your own account" }, 400);
      }
      const { error } = await admin.auth.admin.deleteUser(targetId);
      if (error) return json({ error: error.message }, 400);
      return json({ ok: true }, 200);
    }

    // --- 3) shared input validation --------------------------------------
    const fullName = (body.full_name ?? "").toString().trim();
    const email = (body.email ?? "").toString().trim().toLowerCase();
    const password = (body.password ?? "").toString();
    const communityId = body.community_id
      ? body.community_id.toString()
      : null;

    if (fullName.length < 2) return json({ error: "Name is required" }, 400);
    if (!email) return json({ error: "Email is required" }, 400);
    if (password.length < 6) {
      return json({ error: "Password must be at least 6 characters" }, 400);
    }
    if (action !== "admin" && action !== "merchant") {
      return json({ error: `Unknown action '${action}'` }, 400);
    }
    if (action === "admin" && !communityId) {
      return json({ error: "community_id is required for an admin" }, 400);
    }

    const shopName = (body.shop_name ?? "").toString().trim();
    if (action === "merchant" && shopName.length < 2) {
      return json({ error: "Shop name is required" }, 400);
    }

    // --- 4) create the auth user -----------------------------------------
    const { data: created, error: createErr } = await admin.auth.admin
      .createUser({
        email,
        password,
        email_confirm: true,
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

    // --- 5) stamp the profile --------------------------------------------
    // handle_new_user seeds a base row as a resident; overwrite it with the
    // real role so the router sends them to the right portal.
    const { error: profErr } = await admin.from("profiles").upsert({
      id: newUserId,
      full_name: fullName,
      email,
      role: action === "admin" ? "admin" : "merchant",
      community_id: communityId,
      approval_status: "approved",
      status: "active",
    });
    if (profErr) {
      await admin.auth.admin.deleteUser(newUserId).catch(() => {});
      return json({ error: `Profile setup failed: ${profErr.message}` }, 500);
    }

    // --- 6) merchants also get their shop row ----------------------------
    if (action === "merchant") {
      const { error: shopErr } = await admin.from("merchants").insert({
        owner_id: newUserId,
        community_id: communityId,
        shop_name: shopName,
        category: body.category ? body.category.toString().trim() : null,
        contact: body.contact ? body.contact.toString().trim() : null,
        address: body.address ? body.address.toString().trim() : null,
        is_active: true,
      });
      if (shopErr) {
        await admin.auth.admin.deleteUser(newUserId).catch(() => {});
        return json({ error: `Shop setup failed: ${shopErr.message}` }, 500);
      }
    }

    return json({ ok: true, user_id: newUserId }, 200);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
