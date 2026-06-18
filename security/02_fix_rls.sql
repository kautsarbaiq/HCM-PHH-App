-- ============================================================================
-- 02_fix_rls.sql  —  Restores intended Row Level Security on all app tables.
--
-- Strategy: for every known app table, ENABLE RLS and DROP every existing
-- policy, then recreate exactly the intended policy set. Dropping all policies
-- first guarantees no leftover permissive / anon policy can survive.
--
-- Idempotent: safe to run repeatedly. Transactional: all-or-nothing.
-- Mirrors the intent of supabase_schema.sql.
--
-- NOTE: covers the 13 documented tables. If 01_audit_rls.sql reveals additional
-- (ad-hoc) tables with rls_enabled = false, add them to `app_tables` below.
-- ============================================================================

BEGIN;

-- 0. Ensure the helper functions the policies depend on exist & are correct.
CREATE OR REPLACE FUNCTION public.get_user_role() RETURNS TEXT AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN AS $$
  SELECT EXISTS(SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.is_guard() RETURNS BOOLEAN AS $$
  SELECT EXISTS(SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'guard');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- 1. Enable RLS on every app table and strip ALL existing policies from them.
DO $$
DECLARE
  t   text;
  pol record;
  app_tables text[] := ARRAY[
    'profiles','houses','visitors','announcements','banners','billings',
    'feedback_tickets','facilities','facility_bookings','events','polls',
    'poll_votes','emergency_alerts'
  ];
BEGIN
  FOREACH t IN ARRAY app_tables LOOP
    IF EXISTS (
      SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public' AND c.relname = t AND c.relkind = 'r'
    ) THEN
      EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
      FOR pol IN
        SELECT policyname FROM pg_policies WHERE schemaname = 'public' AND tablename = t
      LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, t);
      END LOOP;
    ELSE
      RAISE NOTICE 'skipping missing table: %', t;
    END IF;
  END LOOP;
END $$;

-- 2. Recreate the intended policies.

-- profiles ------------------------------------------------------------------
CREATE POLICY "admin_all"       ON public.profiles FOR ALL    USING (public.is_admin());
CREATE POLICY "user_read_own"   ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "user_update_own" ON public.profiles FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE POLICY "guard_read_all"  ON public.profiles FOR SELECT USING (public.is_guard());

-- houses --------------------------------------------------------------------
CREATE POLICY "admin_all"         ON public.houses FOR ALL    USING (public.is_admin());
CREATE POLICY "guard_read"        ON public.houses FOR SELECT USING (public.is_guard());
CREATE POLICY "resident_read_own" ON public.houses FOR SELECT USING (owner_id = auth.uid());

-- visitors ------------------------------------------------------------------
CREATE POLICY "admin_all"         ON public.visitors FOR ALL    USING (public.is_admin());
CREATE POLICY "guard_read"        ON public.visitors FOR SELECT USING (public.is_guard());
CREATE POLICY "guard_insert"      ON public.visitors FOR INSERT WITH CHECK (public.is_guard());
CREATE POLICY "guard_update"      ON public.visitors FOR UPDATE USING (public.is_guard());
CREATE POLICY "resident_insert"   ON public.visitors FOR INSERT WITH CHECK (house_id IN (SELECT id FROM public.houses WHERE owner_id = auth.uid()) AND created_by = auth.uid());
CREATE POLICY "resident_read_own" ON public.visitors FOR SELECT USING (house_id IN (SELECT id FROM public.houses WHERE owner_id = auth.uid()));

-- announcements -------------------------------------------------------------
CREATE POLICY "admin_all" ON public.announcements FOR ALL    USING (public.is_admin());
CREATE POLICY "all_read"  ON public.announcements FOR SELECT USING (auth.uid() IS NOT NULL);

-- banners -------------------------------------------------------------------
CREATE POLICY "admin_all" ON public.banners FOR ALL    USING (public.is_admin());
CREATE POLICY "all_read"  ON public.banners FOR SELECT USING (auth.uid() IS NOT NULL AND is_active = true);

-- billings ------------------------------------------------------------------
CREATE POLICY "admin_all"         ON public.billings FOR ALL    USING (public.is_admin());
CREATE POLICY "resident_read_own" ON public.billings FOR SELECT USING (resident_id = auth.uid());

-- feedback_tickets ----------------------------------------------------------
CREATE POLICY "admin_all"         ON public.feedback_tickets FOR ALL    USING (public.is_admin());
CREATE POLICY "resident_insert"   ON public.feedback_tickets FOR INSERT WITH CHECK (created_by = auth.uid());
CREATE POLICY "resident_read_own" ON public.feedback_tickets FOR SELECT USING (created_by = auth.uid());

-- facilities ----------------------------------------------------------------
CREATE POLICY "all_read"  ON public.facilities FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "admin_all" ON public.facilities FOR ALL    USING (public.is_admin());

-- facility_bookings ---------------------------------------------------------
CREATE POLICY "admin_all"           ON public.facility_bookings FOR ALL    USING (public.is_admin());
CREATE POLICY "resident_insert"     ON public.facility_bookings FOR INSERT WITH CHECK (resident_id = auth.uid());
CREATE POLICY "resident_read_own"   ON public.facility_bookings FOR SELECT USING (resident_id = auth.uid());
CREATE POLICY "resident_update_own" ON public.facility_bookings FOR UPDATE USING (resident_id = auth.uid());

-- events --------------------------------------------------------------------
CREATE POLICY "all_read"  ON public.events FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "admin_all" ON public.events FOR ALL    USING (public.is_admin());

-- polls ---------------------------------------------------------------------
CREATE POLICY "all_read"  ON public.polls FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "admin_all" ON public.polls FOR ALL    USING (public.is_admin());

-- poll_votes ----------------------------------------------------------------
CREATE POLICY "resident_insert"   ON public.poll_votes FOR INSERT WITH CHECK (voter_id = auth.uid());
CREATE POLICY "resident_read_own" ON public.poll_votes FOR SELECT USING (voter_id = auth.uid());
CREATE POLICY "admin_all"         ON public.poll_votes FOR ALL    USING (public.is_admin());

-- emergency_alerts ----------------------------------------------------------
CREATE POLICY "admin_all"       ON public.emergency_alerts FOR ALL    USING (public.is_admin());
CREATE POLICY "resident_insert" ON public.emergency_alerts FOR INSERT WITH CHECK (triggered_by = auth.uid());
CREATE POLICY "all_read"        ON public.emergency_alerts FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "guard_read"      ON public.emergency_alerts FOR SELECT USING (public.is_guard());

COMMIT;
