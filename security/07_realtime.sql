-- ============================================================================
-- HCM — enable Supabase Realtime on all app tables
-- Run ONCE in the Supabase SQL editor. Idempotent: safe to re-run.
-- After this, any insert/update/delete (from web OR mobile) is pushed live to
-- every connected client, so screens update instantly with no refresh/restart.
-- (This is Supabase's built-in WebSocket Realtime — no Socket.IO server needed.)
-- ============================================================================

DO $$
DECLARE
  t text;
BEGIN
  FOREACH t IN ARRAY ARRAY[
    'announcements','billings','bookings','events','polls','visitors',
    'documents','forms','form_submissions','marketplace_services',
    'emergency_contacts','facilities','houses','profiles','resident_documents',
    'tickets','banners','emergencies'
  ]
  LOOP
    -- only add if the table isn't already in the realtime publication
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = t
    ) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
    END IF;
  END LOOP;
END $$;

-- Verify which tables are now realtime-enabled:
--   SELECT tablename FROM pg_publication_tables
--   WHERE pubname='supabase_realtime' AND schemaname='public' ORDER BY tablename;
