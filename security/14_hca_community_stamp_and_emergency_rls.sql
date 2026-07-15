-- ============================================================================
-- HCA ONLY — audit fixes (community isolation + emergency privacy).
-- Run on the Home Cloud Asia project. Idempotent. Do NOT run on PHH.
-- ============================================================================

-- FIX E: stamp the creator's community_id on new content so community read
-- scoping actually isolates communities (until now every row was NULL =
-- "global", so every community saw every other community's content).
CREATE OR REPLACE FUNCTION public.stamp_community()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.community_id IS NULL THEN
    NEW.community_id := public.my_community();
  END IF;
  RETURN NEW;
END $$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['announcements','events','polls','documents',
                           'forms','facilities','marketplace_services',
                           'emergency_contacts','emergencies']
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS stamp_community_trg ON public.%I', t);
    EXECUTE format(
      'CREATE TRIGGER stamp_community_trg BEFORE INSERT ON public.%I
       FOR EACH ROW EXECUTE FUNCTION public.stamp_community()', t);
  END LOOP;
END $$;

-- FIX F: emergencies had a single SELECT policy `USING (true)` — any logged-in
-- resident could read every alert row (incl. panic subtitles that embed
-- "House N — Full Name"). Scope reads: residents see broadcasts + their own;
-- staff (admin/guard) see everything (needed for the banner + history report).
DROP POLICY IF EXISTS "Anyone can view active emergencies" ON public.emergencies;
DROP POLICY IF EXISTS "scoped emergency read" ON public.emergencies;
CREATE POLICY "scoped emergency read" ON public.emergencies
  FOR SELECT TO authenticated
  USING (
    type = 'broadcast'
    OR triggered_by = auth.uid()
    OR public.is_admin()
    OR public.is_guard()
  );
