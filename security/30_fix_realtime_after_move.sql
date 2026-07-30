-- ============================================================================
-- Boss retest 29/07 (point 7): the Guard/Security Portal does not update in
-- real time — a new panic alert doesn't appear, and a resolved alert doesn't
-- disappear, until the app is closed and reopened.
--
-- Root cause: the migration to the new HCA project cloned the `public` schema
-- with pg_dump, but the `supabase_realtime` PUBLICATION is a database-level
-- object that a schema dump does NOT carry over. On the new project the
-- publication ended up EMPTY, so Realtime delivered no changes for any table.
--
-- Fix:
--   1. Re-add every table the app subscribes to, to supabase_realtime.
--   2. Set REPLICA IDENTITY FULL on the tables whose Realtime UPDATE/DELETE
--      events must pass an RLS check that references non-PK columns (otherwise
--      those events are silently dropped) — emergencies is the reported one.
--
-- Run in the new HCA project (dogbmkricfvaizjgjanu). Harmless to run on PHH
-- too (ADD is guarded, so already-published tables are skipped). Idempotent.
-- ============================================================================

DO $$
DECLARE
  t text;
  tabs text[] := ARRAY[
    'announcements','billings','bookings','communities','documents',
    'emergencies','emergency_contacts','events','facilities','form_submissions',
    'forms','houses','marketplace_services','parking_bays','polls','profiles',
    'resident_documents','resident_id_scans','tickets','visitors',
    'reward_offers','reward_claims','push_tokens'
  ];
BEGIN
  FOREACH t IN ARRAY tabs LOOP
    -- only add real, existing tables that aren't already published
    IF EXISTS (SELECT 1 FROM information_schema.tables
               WHERE table_schema='public' AND table_name=t)
       AND NOT EXISTS (SELECT 1 FROM pg_publication_tables
               WHERE pubname='supabase_realtime' AND schemaname='public' AND tablename=t)
    THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
    END IF;
  END LOOP;
END $$;

-- UPDATE/DELETE realtime under RLS needs the full old row for the policy check.
ALTER TABLE public.emergencies     REPLICA IDENTITY FULL;
ALTER TABLE public.visitors        REPLICA IDENTITY FULL;
ALTER TABLE public.bookings        REPLICA IDENTITY FULL;
ALTER TABLE public.billings        REPLICA IDENTITY FULL;
ALTER TABLE public.events          REPLICA IDENTITY FULL;
ALTER TABLE public.form_submissions REPLICA IDENTITY FULL;
ALTER TABLE public.reward_claims   REPLICA IDENTITY FULL;

-- Verify:
--   SELECT tablename FROM pg_publication_tables
--    WHERE pubname='supabase_realtime' ORDER BY 1;
