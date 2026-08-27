-- ===========================================================================
-- 34_billing_visible_to_household.sql
--
-- BUG (reported 26/08): "I create a Bill for the resident from the admin
-- panel, but it does not show inside the Resident Billing page."
--
-- Root cause: a bill is linked to ONE user (billings.resident_id), but a house
-- can have SEVERAL resident accounts. Verified on live data — house
-- d6e2624e-… has two owner accounts:
--     jay@gmail.com               -> holds both bills
--     resident@homecloudasia.com  -> saw 0 bills
-- RLS and the admin insert were both correct; the bill simply belonged to the
-- other account in the same house.
--
-- Fix: bills follow the HOUSE, which is how this app already scopes visitors
-- (visitors.house_id = profiles.house_id). Maintenance billing is per unit,
-- so everyone assigned to the unit should see the unit's bills.
--
-- Safe to re-run.
-- ===========================================================================

-- The house the signed-in user is assigned to. SECURITY DEFINER so the lookup
-- never depends on how `profiles` RLS happens to be written.
CREATE OR REPLACE FUNCTION public.my_house_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $function$
  SELECT p.house_id FROM public.profiles p WHERE p.id = auth.uid();
$function$;

GRANT EXECUTE ON FUNCTION public.my_house_id() TO authenticated;

DROP POLICY IF EXISTS resident_read_own ON public.billings;
CREATE POLICY resident_read_own ON public.billings
  FOR SELECT
  USING (
    -- the bill is addressed to me
    resident_id = auth.uid()
    -- …or to the main account of my household (family sub-logins, mig. 33)
    OR resident_id = public.my_household_id()
    -- …or it is a bill for the unit I live in
    OR (house_id IS NOT NULL AND house_id = public.my_house_id())
  );

-- Sanity check (run manually):
--   SELECT public.my_house_id();
--   SELECT count(*) FROM public.billings;
