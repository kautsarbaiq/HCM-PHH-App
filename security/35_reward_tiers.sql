-- ===========================================================================
-- 35_reward_tiers.sql — three membership levels (client mockup 27/08)
--
--   SILVER    paid on time for 3 consecutive months
--   GOLD      paid on time for 6 consecutive months
--   PLATINUM  paid a full year's maintenance fee in advance
--
-- The tier is computed in SQL, not in the apps, so the web portal, the
-- resident app and the merchant app can never disagree about someone's level.
--
-- Silver/Gold reuse the existing on-time streak (migration 25). Platinum is a
-- different shape of commitment — paying ahead — so it is measured as the
-- number of ALREADY-PAID bills whose due date is still in the future.
--
-- Safe to re-run.
-- ===========================================================================

-- How many months a resident has already settled in advance.
CREATE OR REPLACE FUNCTION public.owner_prepaid_months(p_uid uuid)
RETURNS integer
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $function$
  SELECT count(*)::int
  FROM public.billings
  WHERE resident_id = p_uid
    AND status = 'paid'
    AND due_date > CURRENT_DATE;
$function$;

-- Tier for a given resident: 'platinum' | 'gold' | 'silver' | 'none'.
CREATE OR REPLACE FUNCTION public.owner_reward_tier(p_uid uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $function$
DECLARE
  v_streak  int := public.owner_ontime_streak(p_uid);
  v_prepaid int := public.owner_prepaid_months(p_uid);
BEGIN
  IF v_prepaid >= 12 THEN
    RETURN 'platinum';
  ELSIF v_streak >= 6 THEN
    RETURN 'gold';
  ELSIF v_streak >= 3 THEN
    RETURN 'silver';
  END IF;
  RETURN 'none';
END $function$;

-- Everything the apps need for the tier card, in one round trip.
DROP FUNCTION IF EXISTS public.my_reward_tier();
CREATE OR REPLACE FUNCTION public.my_reward_tier()
RETURNS TABLE(tier text, streak integer, prepaid_months integer)
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $function$
  SELECT public.owner_reward_tier(auth.uid()),
         public.owner_ontime_streak(auth.uid()),
         public.owner_prepaid_months(auth.uid());
$function$;

GRANT EXECUTE ON FUNCTION public.owner_prepaid_months(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.owner_reward_tier(uuid)   TO authenticated;
GRANT EXECUTE ON FUNCTION public.my_reward_tier()          TO authenticated;

-- Sanity check (run manually):
--   SELECT * FROM public.my_reward_tier();
