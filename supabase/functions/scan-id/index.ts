// Supabase Edge Function: scan-id
// OCR / structured extraction of an ID document (driving license, IC, passport)
// using Google Gemini vision (free tier). Returns strict JSON.
//
// Setup:
//   1) Get a FREE Gemini API key at https://aistudio.google.com  (format: AIza...)
//   2) supabase secrets set GEMINI_API_KEY=AIza...
//   3) supabase functions deploy scan-id
//
// The Flutter app calls it with supabase.functions.invoke('scan-id',
// body: { imageBase64, mediaType }) and expects { fields: { ... } } back.

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

// Gemini model — Flash is free-tier, fast, and supports vision + JSON output.
const MODEL = "gemini-2.0-flash";

// Gemini response schema (types are UPPERCASE per the Gemini Schema enum).
const RESPONSE_SCHEMA = {
  type: "OBJECT",
  properties: {
    doc_type: { type: "STRING" },
    full_name: { type: "STRING" },
    id_number: { type: "STRING" },
    nationality: { type: "STRING" },
    address: { type: "STRING" },
    validity: { type: "STRING" },
    class: { type: "STRING" },
  },
  required: [
    "doc_type",
    "full_name",
    "id_number",
    "nationality",
    "address",
    "validity",
    "class",
  ],
};

function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "content-type": "application/json" },
  });
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) {
      return json({ error: "GEMINI_API_KEY secret is not set" }, 500);
    }

    const { imageBase64, mediaType } = await req.json();
    if (!imageBase64 || typeof imageBase64 !== "string") {
      return json({ error: "imageBase64 (base64 string) is required" }, 400);
    }

    const url =
      `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`;

    const resp = await fetch(url, {
      method: "POST",
      headers: {
        "content-type": "application/json",
        // Works for both classic (AIza...) and new (AQ...) Gemini API keys.
        "x-goog-api-key": apiKey,
      },
      body: JSON.stringify({
        contents: [
          {
            role: "user",
            parts: [
              {
                inline_data: {
                  mime_type: mediaType ?? "image/jpeg",
                  data: imageBase64,
                },
              },
              {
                text:
                  "This is a photo of an ID document (driving license, identity card, or passport). " +
                  "Extract the fields. Copy every value exactly as printed on the document. " +
                  "If a field is not visible or not present, use an empty string.",
              },
            ],
          },
        ],
        generationConfig: {
          response_mime_type: "application/json",
          response_schema: RESPONSE_SCHEMA,
        },
      }),
    });

    const data = await resp.json();
    if (!resp.ok) {
      return json({ error: "gemini_error", detail: data }, 502);
    }

    // With response_mime_type=application/json, the text part is valid JSON.
    const text = data?.candidates?.[0]?.content?.parts?.[0]?.text ?? "{}";
    let fields: Record<string, string> = {};
    try {
      fields = JSON.parse(text);
    } catch (_) {
      fields = {};
    }

    return json({ fields }, 200);
  } catch (e) {
    return json({ error: String(e) }, 500);
  }
});
