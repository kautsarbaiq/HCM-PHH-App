// Supabase Edge Function: event-guest-register
// HCA (boss voice note 16/07) — an OUTSIDE guest registers for an approved
// community event via a public link and instantly receives a QR gate pass.
//
// The pass is a normal `visitors` row on the HOST's house (registration_type
// 'event_guest'), so the guard's existing QR check-in flow works unchanged.
//
// Anon-callable: the app invokes it WITHOUT a user session (guests have no
// account). Uses the service role internally; visitors RLS stays closed.
//
// Body: { event_id, name, phone?, email?, vehicle_plate? }
// → { qr_token, visitor_name, event_title, event_date, location }
//
// Optional e-mail confirmation: set the RESEND_API_KEY + RESEND_FROM secrets
// (Resend.com, verified domain) and guests who leave an e-mail get the pass
// mailed to them too. Without the secrets the on-screen QR is the pass.
//
// Deploy: npx supabase functions deploy event-guest-register --project-ref mlyycbiojsyqatmwdhef --use-api

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
    const body = await req.json();
    const eventId = (body.event_id ?? "").toString().trim();
    const name = (body.name ?? "").toString().trim();
    const phone = (body.phone ?? "").toString().trim();
    const email = (body.email ?? "").toString().trim().toLowerCase();
    const plate = (body.vehicle_plate ?? "").toString().trim();

    if (!eventId) return json({ error: "event_id is required" }, 400);
    if (name.length < 2) return json({ error: "Please enter your name" }, 400);
    if (!phone && !email) {
      return json(
        { error: "Please leave a WhatsApp number or e-mail address" },
        400,
      );
    }

    // --- the event must exist, be approved, and not be over -----------------
    const { data: event } = await admin
      .from("events")
      .select("id, title, event_date, location, status, created_by")
      .eq("id", eventId)
      .maybeSingle();
    if (!event || event.status !== "approved") {
      return json({ error: "This invitation is not available." }, 404);
    }
    const eventDate = new Date(event.event_date);
    if (eventDate.getTime() < Date.now() - 24 * 60 * 60 * 1000) {
      return json({ error: "This event has already taken place." }, 410);
    }

    // --- host's house: guest passes hang off the host like normal visitors --
    const { data: host } = await admin
      .from("profiles")
      .select("house_id")
      .eq("id", event.created_by)
      .maybeSingle();
    if (!host?.house_id) {
      return json(
        { error: "The event host has no house assigned — contact the host." },
        409,
      );
    }

    const contact = [phone, email].filter(Boolean).join(" / ");

    // --- same guest registering twice gets their existing pass back ---------
    const { data: existing } = await admin
      .from("visitors")
      .select("qr_token, visitor_name")
      .eq("event_id", eventId)
      .eq("guest_contact", contact)
      .maybeSingle();
    if (existing?.qr_token) {
      return json({
        qr_token: existing.qr_token,
        visitor_name: existing.visitor_name,
        event_title: event.title,
        event_date: event.event_date,
        location: event.location ?? "",
        already_registered: true,
      }, 200);
    }

    // --- create the pass -----------------------------------------------------
    const qrToken = `eg-${crypto.randomUUID()}`;
    const { error: insErr } = await admin.from("visitors").insert({
      visitor_name: name,
      purpose: `Event: ${event.title}`,
      vehicle_plate: plate || null,
      house_id: host.house_id,
      qr_token: qrToken,
      status: "expected",
      expected_at: event.event_date,
      created_by: event.created_by,
      registration_type: "event_guest",
      entry_type: "single",
      event_id: eventId,
      guest_contact: contact,
    });
    if (insErr) {
      return json({ error: `Registration failed: ${insErr.message}` }, 500);
    }

    // --- optional e-mail confirmation (needs RESEND_API_KEY + RESEND_FROM) --
    const resendKey = Deno.env.get("RESEND_API_KEY");
    const resendFrom = Deno.env.get("RESEND_FROM");
    if (resendKey && resendFrom && email) {
      const passUrl =
        `https://home-cloudasia.vercel.app/#/event-invite/${eventId}?pass=${qrToken}&n=${encodeURIComponent(name)}`;
      const qrImg =
        `https://api.qrserver.com/v1/create-qr-code/?size=280x280&data=${encodeURIComponent(qrToken)}`;
      await fetch("https://api.resend.com/emails", {
        method: "POST",
        headers: {
          authorization: `Bearer ${resendKey}`,
          "content-type": "application/json",
        },
        body: JSON.stringify({
          from: resendFrom,
          to: [email],
          subject: `Your gate pass — ${event.title}`,
          html:
            `<p>Hi ${name},</p><p>You're registered for <b>${event.title}</b> ` +
            `on ${eventDate.toLocaleString()}${event.location ? ` at ${event.location}` : ""}.</p>` +
            `<p>Show this QR code at the main gate:</p>` +
            `<p><img src="${qrImg}" width="280" height="280" alt="QR gate pass"/></p>` +
            `<p>Or open your pass anytime: <a href="${passUrl}">${passUrl}</a></p>`,
        }),
      }).catch(() => {}); // e-mail failure must not break the registration
    }

    return json({
      qr_token: qrToken,
      visitor_name: name,
      event_title: event.title,
      event_date: event.event_date,
      location: event.location ?? "",
    }, 200);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
