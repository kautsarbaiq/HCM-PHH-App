// Supabase Edge Function: admin-create-owner
// HCA point 16 — an admin creates a login account for a house owner.
// Only the service_role key may create auth users, so this runs server-side.
//
// Flow:
//   1) Verify the caller (from their JWT) is an admin.
//   2) Create the auth user with email + password (email pre-confirmed) and
//      metadata { full_name, resident_type: 'owner' } so the handle_new_user
//      trigger seeds a base profile row.
//   3) Stamp that profile with phone / ic_number / house_id / resident_type and
//      the admin's own community_id, and link houses.owner_id.
//
// The Flutter app calls it with supabase.functions.invoke('admin-create-owner',
// body: { house_id, full_name, email, password, phone, ic_number }).
//
// Setup:
//   supabase functions deploy admin-create-owner

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
    // --- 1) authenticate + authorize the caller -------------------------
    const authHeader = req.headers.get("Authorization") ?? "";
    const token = authHeader.replace(/^Bearer\s+/i, "");
    if (!token) return json({ error: "Not authenticated" }, 401);

    const { data: userData, error: userErr } = await admin.auth.getUser(token);
    if (userErr || !userData?.user) {
      return json({ error: "Not authenticated" }, 401);
    }
    const callerId = userData.user.id;

    const { data: callerProfile } = await admin
      .from("profiles")
      .select("role, community_id")
      .eq("id", callerId)
      .maybeSingle();
    if (!callerProfile || callerProfile.role !== "admin") {
      return json({ error: "Only an admin can create owner accounts" }, 403);
    }

    // --- 2) validate input ---------------------------------------------
    const body = await req.json();
    const houseId = (body.house_id ?? "").toString().trim();
    const fullName = (body.full_name ?? "").toString().trim();
    const email = (body.email ?? "").toString().trim().toLowerCase();
    const password = (body.password ?? "").toString();
    const phone = body.phone ? body.phone.toString().trim() : null;
    const icNumber = body.ic_number ? body.ic_number.toString().trim() : null;

    if (!fullName) return json({ error: "Full name is required" }, 400);
    if (!email) return json({ error: "Email is required" }, 400);
    if (password.length < 6) {
      return json({ error: "Password must be at least 6 characters" }, 400);
    }

    // Resolve which community the owner belongs to: prefer the house's
    // community, else fall back to the admin's own community.
    let communityId: string | null = callerProfile.community_id ?? null;
    if (houseId) {
      const { data: house } = await admin
        .from("houses")
        .select("community_id")
        .eq("id", houseId)
        .maybeSingle();
      if (house?.community_id) communityId = house.community_id;
    }

    // --- 3) create the auth user ---------------------------------------
    const { data: created, error: createErr } = await admin.auth.admin
      .createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { full_name: fullName, resident_type: "owner" },
      });
    if (createErr || !created?.user) {
      const msg = createErr?.message ?? "Failed to create account";
      // Friendlier message for the most common case.
      if (/already.*registered|exists/i.test(msg)) {
        return json({ error: "That email is already registered" }, 409);
      }
      return json({ error: msg }, 400);
    }
    const newUserId = created.user.id;

    // --- 4) stamp the profile + link the house -------------------------
    // handle_new_user already inserted a base row; fill in the rest. Use
    // upsert in case the trigger is ever absent.
    const { error: profErr } = await admin.from("profiles").upsert({
      id: newUserId,
      full_name: fullName,
      email,
      phone,
      ic_number: icNumber,
      role: "resident",
      resident_type: "owner",
      house_id: houseId || null,
      community_id: communityId,
    });
    if (profErr) {
      // Roll back the auth user so the admin can retry cleanly.
      await admin.auth.admin.deleteUser(newUserId).catch(() => {});
      return json({ error: `Profile setup failed: ${profErr.message}` }, 500);
    }

    if (houseId) {
      await admin
        .from("houses")
        .update({ owner_id: newUserId, status: "occupied" })
        .eq("id", houseId);
    }

    return json({ ok: true, user_id: newUserId }, 200);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
