-- ============================================================================
-- 04_harden_live.sql  —  Phase 2. Closes the remaining issues the live-DB audit
-- found that 02_fix_rls.sql did not cover. Idempotent & transactional.
--
-- Findings addressed:
--  1. `emergencies` (the table the APP actually uses; `emergency_alerts` is dead)
--     had a permissive policy "Anyone can view active emergencies" USING(true)
--     -> readable by anon. Latent PII leak (table just happens to be empty now).
--  2. `houses` / `visitors` had ad-hoc "Public insert/update/delete" policies
--     (USING auth.role() = 'authenticated') -> ANY logged-in user could modify or
--     DELETE any house/visitor. Re-asserted here to the intended model. Verified
--     against the app: residents never write houses/visitors (admin/guard only),
--     so this breaks no feature.
--
-- NOT touched (confirmed safe from anon — all policies are auth.uid()-scoped):
--   bookings, tickets  (also ad-hoc duplicates; functional, no anon leak)
-- ============================================================================

BEGIN;

-- Ensure helper functions exist (audit confirmed they do; re-assert for safety).
CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN AS $$
  SELECT EXISTS(SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION public.is_guard() RETURNS BOOLEAN AS $$
  SELECT EXISTS(SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'guard');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- 1. Re-assert houses + visitors to the intended model (drop ALL policies first so
--    no leftover "Public *" policy can survive, then recreate the correct set).
DO $$
DECLARE pol record; t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['houses','visitors'] LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);
    FOR pol IN SELECT policyname FROM pg_policies WHERE schemaname='public' AND tablename=t LOOP
      EXECUTE format('DROP POLICY IF EXISTS %I ON public.%I', pol.policyname, t);
    END LOOP;
  END LOOP;
END $$;

-- houses: admin manages; guard reads all; resident reads only their own house.
CREATE POLICY "admin_all"         ON public.houses FOR ALL    USING (public.is_admin());
CREATE POLICY "guard_read"        ON public.houses FOR SELECT USING (public.is_guard());
CREATE POLICY "resident_read_own" ON public.houses FOR SELECT USING (owner_id = auth.uid());

-- visitors: admin all; guard read/insert/update (check-in/out);
--           resident pre-registers for own house + reads own house's visitors.
CREATE POLICY "admin_all"         ON public.visitors FOR ALL    USING (public.is_admin());
CREATE POLICY "guard_read"        ON public.visitors FOR SELECT USING (public.is_guard());
CREATE POLICY "guard_insert"      ON public.visitors FOR INSERT WITH CHECK (public.is_guard());
CREATE POLICY "guard_update"      ON public.visitors FOR UPDATE USING (public.is_guard());
CREATE POLICY "resident_insert"   ON public.visitors FOR INSERT WITH CHECK (house_id IN (SELECT id FROM public.houses WHERE owner_id = auth.uid()) AND created_by = auth.uid());
CREATE POLICY "resident_read_own" ON public.visitors FOR SELECT USING (house_id IN (SELECT id FROM public.houses WHERE owner_id = auth.uid()));

-- 2. emergencies: remove the anon-readable USING(true) policy; allow any
--    authenticated user to read (matches the in-app emergency feed), admin to
--    manage. The existing "Residents can create emergencies" INSERT policy
--    (WITH CHECK auth.uid() = triggered_by) is correct and left in place.
ALTER TABLE public.emergencies ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Anyone can view active emergencies" ON public.emergencies;
DROP POLICY IF EXISTS "auth_read_emergencies" ON public.emergencies;
CREATE POLICY "auth_read_emergencies" ON public.emergencies FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS "admin_all" ON public.emergencies;
CREATE POLICY "admin_all" ON public.emergencies FOR ALL USING (public.is_admin());

COMMIT;
