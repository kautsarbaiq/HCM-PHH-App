// Supabase Edge Function: delete-my-account
//
// App Store guideline 5.1.1(v) and Play's data-deletion policy both require an
// account created in the app to be deletable from inside the app. Only the
// service_role key can touch auth.users, so this runs server-side.
//
// Request (POST, no body needed):
//   Authorization: Bearer <the caller's access token>
//
// What it does, in order:
//   1. deletes the avatar file and any uploaded documents from storage
//   2. deletes push tokens, so the phone stops receiving notifications
//   3. blanks every personal field on the profile and stamps deleted_at
//   4. does the same for the caller's sub-logins (wife/child accounts) —
//      they only exist because the parent account does
//   5. soft-deletes the auth user, which blocks sign-in for good
//
// WHY NOT A HARD DELETE: see security/36_account_deletion.sql. 22 foreign keys
// into profiles are RESTRICT, and the rows behind them (bills, visitor logs)
// are the community's records, not the individual's, so they are kept —
// stripped of anything identifying.
//
// Deploy:
//   supabase functions deploy delete-my-account

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

/** Blanks the identifying columns and marks the row as deleted. */
async function anonymise(userId: string) {
  await admin
    .from("profiles")
    .update({
      full_name: "Deleted account",
      email: null,
      phone: null,
      avatar_url: null,
      status: "inactive",
      // Detach from the house and community. Almost every admin and directory
      // list is scoped by one of these, so clearing them removes the dead row
      // from those screens without having to touch 18 separate queries — and
      // it cannot be forgotten the way a client-side filter can. Billing and
      // visitor history keep their OWN house_id, so nothing is orphaned.
      house_id: null,
      community_id: null,
      deleted_at: new Date().toISOString(),
    })
    .eq("id", userId);
}

async function purgeStorage(userId: string) {
  for (const bucket of ["avatars", "resident_documents"]) {
    try {
      const { data } = await admin.storage.from(bucket).list(userId);
      if (data?.length) {
        await admin.storage
          .from(bucket)
          .remove(data.map((f) => `${userId}/${f.name}`));
      }
      // Older uploads were written flat as "<uid>.<ext>" rather than in a
      // per-user folder; remove those too or the photo outlives the account.
      const { data: root } = await admin.storage.from(bucket).list("");
      const strays = (root ?? [])
        .filter((f) => f.name.startsWith(userId))
        .map((f) => f.name);
      if (strays.length) {
        await admin.storage.from(bucket).remove(strays);
      }
    } catch (_) {
      // A missing bucket must not block the deletion the user asked for.
    }
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (req.method !== "POST") return json({ error: "Use POST" }, 405);

  try {
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

    const { data: me } = await admin
      .from("profiles")
      .select("role, deleted_at")
      .eq("id", callerId)
      .maybeSingle();

    if (me?.deleted_at) {
      // Already gone — treat as success so a retry from a flaky phone is safe.
      return json({ ok: true, already: true }, 200);
    }

    // A super admin removing themselves could leave the platform with nobody
    // able to administer it. Refuse rather than orphan the whole tenant.
    if (me?.role === "super_admin") {
      const { count } = await admin
        .from("profiles")
        .select("id", { count: "exact", head: true })
        .eq("role", "super_admin")
        .is("deleted_at", null);
      if ((count ?? 0) <= 1) {
        return json({
          error:
            "This is the only super admin account. Assign another super " +
            "admin before deleting this one.",
        }, 409);
      }
    }

    // Sub-logins (wife / child) exist only under the parent account.
    const { data: subs } = await admin
      .from("profiles")
      .select("id")
      .eq("parent_user_id", callerId)
      .is("deleted_at", null);

    const ids = [callerId, ...(subs ?? []).map((s) => s.id as string)];

    for (const id of ids) {
      await purgeStorage(id);
      await admin.from("push_tokens").delete().eq("user_id", id);
      await anonymise(id);
      // shouldSoftDelete = true: keeps the auth row so the community's
      // billing and visitor history stays referentially intact, while GoTrue
      // refuses every future sign-in.
      await admin.auth.admin.deleteUser(id, true);
    }

    return json({ ok: true, deleted: ids.length }, 200);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
