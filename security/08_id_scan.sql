-- ============================================================================
-- HCM — Resident ID scans (OCR auto-fill feature)
-- Run ONCE in the Supabase SQL editor. Idempotent: safe to re-run.
-- Stores the fields extracted from a resident's scanned ID/license/passport.
-- The scanning itself is done by the `scan-id` Edge Function (Claude vision).
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.resident_id_scans (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  doc_type    text,
  full_name   text,
  id_number   text,
  nationality text,
  address     text,
  validity    text,
  class       text,
  image_url   text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.resident_id_scans ENABLE ROW LEVEL SECURITY;

-- A resident manages their own scans; admins can read everyone's.
DROP POLICY IF EXISTS "id_scans insert own" ON public.resident_id_scans;
CREATE POLICY "id_scans insert own" ON public.resident_id_scans
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "id_scans read own" ON public.resident_id_scans;
CREATE POLICY "id_scans read own" ON public.resident_id_scans
  FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "id_scans update own" ON public.resident_id_scans;
CREATE POLICY "id_scans update own" ON public.resident_id_scans
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "id_scans delete own" ON public.resident_id_scans;
CREATE POLICY "id_scans delete own" ON public.resident_id_scans
  FOR DELETE TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "id_scans admin read" ON public.resident_id_scans;
CREATE POLICY "id_scans admin read" ON public.resident_id_scans
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- Realtime so admin sees new scans live.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public'
      AND tablename = 'resident_id_scans'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.resident_id_scans;
  END IF;
END $$;

-- ============================================================================
-- Also required for the OCR to work (not SQL) — uses FREE Google Gemini:
--   1) Get a free Gemini API key at https://aistudio.google.com (format AIza...)
--   2) supabase secrets set GEMINI_API_KEY=AIza...
--   3) supabase functions deploy scan-id
--   4) the public `avatars` bucket already exists for the ID image.
-- ============================================================================
