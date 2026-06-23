-- ============================================================================
-- HCM — emergency live-feed + admin modules backend setup
-- Run ONCE in the Supabase SQL editor. Idempotent: safe to re-run.
-- Covers: emergency broadcast/resolve + realtime, and the E-Document bucket.
-- Everything else (events/polls/forms/contacts/guards/marketplace/facilities/
-- bookings admin CRUD) already works under the existing admin_all RLS — no SQL.
-- ============================================================================

-- 1) Emergency: guards & admins can RESOLVE an alert -----------------------------
-- The active-emergency banner shows on the resident, admin and guard dashboards
-- (SELECT already allowed for every authenticated user via auth_read_emergencies).
-- Admin can already UPDATE via admin_all; this adds guards so they can resolve too.
-- INSERT (panic + admin/guard broadcast) already works: the existing
-- "Residents can create emergencies" policy allows any authenticated user to
-- insert a row where triggered_by = their own uid.
DROP POLICY IF EXISTS "staff resolve emergencies" ON public.emergencies;
CREATE POLICY "staff resolve emergencies" ON public.emergencies
  FOR UPDATE TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('guard', 'admin'))
  )
  WITH CHECK (
    EXISTS (SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role IN ('guard', 'admin'))
  );

-- 2) Emergency: enable Realtime so the feed pushes live ------------------------
-- The app subscribes via supabase.from('emergencies').stream(...). Without the
-- table in the realtime publication, alerts only appear after a manual refresh.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'emergencies'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.emergencies;
  END IF;
END $$;

-- 3) E-Document: public storage bucket for rule/regulation files ----------------
-- The admin "Documents" page uploads PDFs here and saves the public URL into
-- documents.file_url (this is what fixes resident downloads). Bucket is PUBLIC,
-- so residents read via getPublicUrl with no SELECT policy needed.
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "admin upload community docs" ON storage.objects;
CREATE POLICY "admin upload community docs" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'documents'
    AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS "admin update community docs" ON storage.objects;
CREATE POLICY "admin update community docs" ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'documents'
    AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

DROP POLICY IF EXISTS "admin delete community docs" ON storage.objects;
CREATE POLICY "admin delete community docs" ON storage.objects
  FOR DELETE TO authenticated
  USING (
    bucket_id = 'documents'
    AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================================
-- After running this: emergency alerts appear live on all dashboards, guards &
-- admins can resolve & broadcast, and admins can upload community documents.
-- ============================================================================
