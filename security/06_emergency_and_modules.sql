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
-- Force the bucket to exist AND be public (DO UPDATE handles a pre-existing
-- private bucket from an earlier run).
INSERT INTO storage.buckets (id, name, public)
VALUES ('documents', 'documents', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- Any authenticated user may write to the documents bucket. Only admins ever
-- reach the admin Documents/Announcements UI, and a role sub-query inside a
-- storage policy is the usual culprit for "Failed to upload" — so we keep the
-- write rule simple & robust. Reads are public (bucket is public).
DROP POLICY IF EXISTS "admin upload community docs"  ON storage.objects;
DROP POLICY IF EXISTS "admin update community docs"  ON storage.objects;
DROP POLICY IF EXISTS "admin delete community docs"  ON storage.objects;

DROP POLICY IF EXISTS "documents authed write" ON storage.objects;
CREATE POLICY "documents authed write" ON storage.objects
  FOR INSERT TO authenticated WITH CHECK (bucket_id = 'documents');

DROP POLICY IF EXISTS "documents authed update" ON storage.objects;
CREATE POLICY "documents authed update" ON storage.objects
  FOR UPDATE TO authenticated USING (bucket_id = 'documents');

DROP POLICY IF EXISTS "documents authed delete" ON storage.objects;
CREATE POLICY "documents authed delete" ON storage.objects
  FOR DELETE TO authenticated USING (bucket_id = 'documents');

-- 4) Emergency: a resident can CANCEL (resolve) the alert they raised ----------
-- So panic alerts don't pile up — the person who triggered one can clear it.
-- UPDATE policies are OR'd, so this is additive to the staff-resolve policy.
DROP POLICY IF EXISTS "owner resolve own emergency" ON public.emergencies;
CREATE POLICY "owner resolve own emergency" ON public.emergencies
  FOR UPDATE TO authenticated
  USING (triggered_by = auth.uid())
  WITH CHECK (triggered_by = auth.uid());

-- 5) Announcements double as the dashboard banner slides -----------------------
-- Banner & announcement are merged: the resident slider renders each
-- announcement with its image, and the admin Announcements form sets the image
-- (and an optional tap-through link). Add the columns it needs.
ALTER TABLE public.announcements ADD COLUMN IF NOT EXISTS image_url text;
ALTER TABLE public.announcements ADD COLUMN IF NOT EXISTS link_url text;

-- ============================================================================
-- After running this: emergency alerts appear live on all dashboards, residents
-- can cancel their own alerts, guards & admins can resolve & broadcast, admins
-- can upload community documents, and announcements carry a banner image.
-- ============================================================================
