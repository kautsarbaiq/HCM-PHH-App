-- ============================================================================
-- PHH ONLY — catch PHH up with migrations 32-36, applied to HCA only.
--
-- PHH residents see this on the Profile page:
--   Could not find the function public.my_sub_logins  (PGRST202)
--
-- WHY THE FIRST VERSION OF THIS FILE FAILED
--   It bundled 33-36 and assumed migration 32 had already run on PHH, because
--   33 says so in its own comments. It had not. 33 creates LANGUAGE sql
--   functions that read profiles.parent_user_id, and a SQL function validates
--   its column references at CREATE time — so the whole script aborted on the
--   very first statement and nothing was created.
--
--   Verified missing on PHH before writing this: profiles.parent_user_id,
--   profiles.tenancy_doc_url, the merchants and community_modules tables, and
--   the reward_offers columns from 32. (announcements.link_url was already
--   there.) Migration 32 is brand-neutral and idempotent, so it is included
--   here in full rather than cherry-picked.
--
-- RUN IN THE PHH PROJECT: kghiryjutwjgfdtbjtuq
-- (Supabase Dashboard -> SQL Editor -> paste all -> Run)
--
-- Idempotent: safe to run more than once. Deletes no data.
--
-- AFTER THIS: run security/38_payment_receipts.sql (it calls my_household_id(),
-- which only exists once this file has run), then deploy these Edge Functions
-- to PHH — all three are 404 there:
--   resident-create-sublogin, delete-my-account, admin-manage-account
-- ============================================================================

-- ===========================================================================
-- from security/32_super_admin_merchant_foundation.sql
-- ===========================================================================
-- ============================================================================
-- Boss batch 08/08 — FOUNDATION for the multi-tenant hierarchy in the diagram:
--
--     SUPER ADMIN  ->  COMPANY (admin account)  ->  Residents
--
-- The app already scopes content by `communities` + `community_id`, so a
-- "company" IS a community. What was missing: a super-admin role above the
-- per-company admins, per-company module switches, a merchant role, and the
-- signup/tenancy fields. This migration adds all of it.
--
-- Covers points 1, 2, 3 (role gate), 5 (sub-logins), 8-9 (tenancy doc).
--
-- Run in BOTH SQL editors: PHH (kghiryjutwjgfdtbjtuq) AND HCA
-- (dogbmkricfvaizjgjanu). Idempotent.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) ROLES: super_admin (above everything) and merchant (shop owner).
--    Existing roles stay: admin | guard | resident.
--    profiles.role has a CHECK constraint listing the allowed values, so it has
--    to be widened before the new roles can be assigned.
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_role_check
  CHECK (role = ANY (ARRAY['super_admin','admin','guard','resident','merchant']));

CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT COALESCE(
    (SELECT p.role = 'super_admin' FROM public.profiles p WHERE p.id = auth.uid()),
    false);
$$;
GRANT EXECUTE ON FUNCTION public.is_super_admin() TO authenticated;

CREATE OR REPLACE FUNCTION public.is_merchant()
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT COALESCE(
    (SELECT p.role = 'merchant' FROM public.profiles p WHERE p.id = auth.uid()),
    false);
$$;
GRANT EXECUTE ON FUNCTION public.is_merchant() TO authenticated;

-- A super admin is an admin everywhere — keep existing admin policies working.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT COALESCE(
    (SELECT p.role IN ('admin','super_admin') FROM public.profiles p
      WHERE p.id = auth.uid()),
    false);
$$;

-- ---------------------------------------------------------------------------
-- 2) POINT 1: per-company MODULE switches. Empty/absent row = everything on,
--    so existing communities are unaffected until a super admin changes them.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.community_modules (
  community_id uuid PRIMARY KEY REFERENCES public.communities(id) ON DELETE CASCADE,
  -- module key -> enabled?  e.g. {"events": true, "rewards": false}
  modules      jsonb NOT NULL DEFAULT '{}'::jsonb,
  updated_at   timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.community_modules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cm_read" ON public.community_modules;
CREATE POLICY "cm_read" ON public.community_modules FOR SELECT TO authenticated
  USING (community_id = public.my_community() OR public.is_admin());

DROP POLICY IF EXISTS "cm_super_write" ON public.community_modules;
CREATE POLICY "cm_super_write" ON public.community_modules FOR ALL TO authenticated
  USING (public.is_super_admin()) WITH CHECK (public.is_super_admin());

-- What the signed-in user's community has switched off (app reads this).
CREATE OR REPLACE FUNCTION public.my_modules()
RETURNS jsonb LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT COALESCE(
    (SELECT m.modules FROM public.community_modules m
      WHERE m.community_id = public.my_community()),
    '{}'::jsonb);
$$;
GRANT EXECUTE ON FUNCTION public.my_modules() TO authenticated;

-- ---------------------------------------------------------------------------
-- 3) POINT 2: MERCHANTS — shop profile + offers live here. A merchant belongs
--    to the community whose residents can use their vouchers.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.merchants (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id     uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  community_id uuid REFERENCES public.communities(id),
  shop_name    text NOT NULL,
  category     text,
  logo_url     text,
  photos       jsonb NOT NULL DEFAULT '[]'::jsonb,  -- array of image URLs
  address      text,
  location     text,                                 -- map link / coordinates
  contact      text,
  description  text,
  is_active    boolean NOT NULL DEFAULT true,
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS merchants_owner_idx ON public.merchants(owner_id);

ALTER TABLE public.merchants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "m_read" ON public.merchants;
CREATE POLICY "m_read" ON public.merchants FOR SELECT TO authenticated
  USING (community_id IS NULL OR community_id = public.my_community()
         OR owner_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "m_owner_write" ON public.merchants;
CREATE POLICY "m_owner_write" ON public.merchants FOR ALL TO authenticated
  USING (owner_id = auth.uid() OR public.is_admin())
  WITH CHECK (owner_id = auth.uid() OR public.is_admin());

-- Link the existing reward offers to a merchant, and carry the extra fields
-- the boss listed (voucher count, product names, validity window).
ALTER TABLE public.reward_offers
  ADD COLUMN IF NOT EXISTS merchant_id     uuid REFERENCES public.merchants(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS voucher_count   integer,
  ADD COLUMN IF NOT EXISTS products        text,
  ADD COLUMN IF NOT EXISTS starts_on       date,
  ADD COLUMN IF NOT EXISTS ends_on         date;

-- Merchants manage their own offers.
DROP POLICY IF EXISTS "ro_merchant_write" ON public.reward_offers;
CREATE POLICY "ro_merchant_write" ON public.reward_offers FOR ALL TO authenticated
  USING (
    public.is_admin()
    OR merchant_id IN (SELECT id FROM public.merchants WHERE owner_id = auth.uid())
  )
  WITH CHECK (
    public.is_admin()
    OR merchant_id IN (SELECT id FROM public.merchants WHERE owner_id = auth.uid())
  );

-- Merchants must see the claims for their own offers (redemption list).
DROP POLICY IF EXISTS "rc_merchant_read" ON public.reward_claims;
CREATE POLICY "rc_merchant_read" ON public.reward_claims FOR SELECT TO authenticated
  USING (
    owner_id = auth.uid()
    OR public.is_admin()
    OR offer_id IN (
      SELECT o.id FROM public.reward_offers o
      JOIN public.merchants m ON m.id = o.merchant_id
      WHERE m.owner_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------------
-- 4) POINT 5: sub-logins. A family member's account points at the main
--    resident, and inherits their house/community so they see the same data.
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS parent_user_id uuid REFERENCES public.profiles(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS profiles_parent_idx ON public.profiles(parent_user_id);

-- ---------------------------------------------------------------------------
-- 5) POINTS 8-9: tenancy agreement captured at signup, reviewed by admin.
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS tenancy_doc_url text;

-- Pending-signup list now carries the tenancy document so the admin can check
-- it before activating the account.
DROP FUNCTION IF EXISTS public.admin_pending_signups();
CREATE OR REPLACE FUNCTION public.admin_pending_signups()
RETURNS TABLE(user_id uuid, email text, full_name text, resident_type text,
              tenancy_doc_url text, created_at timestamptz)
LANGUAGE sql SECURITY DEFINER AS $function$
  SELECT p.id, p.email::text, COALESCE(p.full_name,'')::text,
         COALESCE(p.resident_type,'owner')::text, p.tenancy_doc_url, u.created_at
  FROM public.profiles p
  JOIN auth.users u ON u.id = p.id
  WHERE p.approval_status = 'pending'
    AND p.role = 'resident'
    AND u.deleted_at IS NULL
    AND public.is_admin()
  ORDER BY u.created_at DESC;
$function$;

-- ---------------------------------------------------------------------------
-- 6) POINT 11: announcements can carry a redirect link behind the wallpaper.
-- ---------------------------------------------------------------------------
ALTER TABLE public.announcements
  ADD COLUMN IF NOT EXISTS link_url text;

-- ---------------------------------------------------------------------------
-- 7) Realtime for the new tables
-- ---------------------------------------------------------------------------
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['merchants','community_modules'] LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables
                   WHERE pubname='supabase_realtime' AND tablename=t) THEN
      EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
    END IF;
  END LOOP;
END $$;

-- Verify:
--   SELECT role, count(*) FROM profiles GROUP BY 1;
--   SELECT * FROM community_modules;


-- ===========================================================================
-- from security/33_sub_logins.sql
-- ===========================================================================
-- ===========================================================================
-- 33_sub_logins.sql — Boss batch 08/08 POINT 5
--
--   "All Resident App main login to create a sub login for his wife or child
--    by adding login password with their name, then both will have same
--    interface and view."
--
-- The column profiles.parent_user_id already exists (migration 32). This file
-- adds the pieces that make a sub-login actually behave like the main account:
--
--   1) my_household_id()  — the account whose data this login should see
--                           (itself, or its parent when it is a sub-login).
--   2) billings RLS       — the only resident-facing table keyed strictly by
--                           auth.uid(); widened to the household so a wife or
--                           child sees the same bills. Visitors, bookings and
--                           community content are already house/community
--                           scoped, so they are shared automatically.
--   3) my_sub_logins()    — a resident can list the accounts they created
--                           (profiles RLS only exposes a resident's own row).
--
-- Creating and deleting the accounts themselves needs the service_role key and
-- lives in the `resident-create-sublogin` edge function.
--
-- Safe to re-run.
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- 1) Household resolution
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.my_household_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $function$
  SELECT COALESCE(p.parent_user_id, p.id)
  FROM public.profiles p
  WHERE p.id = auth.uid();
$function$;

GRANT EXECUTE ON FUNCTION public.my_household_id() TO authenticated;

-- True when the current login was created as a family sub-account. The app
-- uses it to hide "add sub login" from a sub-login (no chains).
CREATE OR REPLACE FUNCTION public.is_sub_login()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $function$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.parent_user_id IS NOT NULL
  );
$function$;

GRANT EXECUTE ON FUNCTION public.is_sub_login() TO authenticated;

-- ---------------------------------------------------------------------------
-- 2) Bills follow the household, not the individual login
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS resident_read_own ON public.billings;
CREATE POLICY resident_read_own ON public.billings
  FOR SELECT
  USING (
    resident_id = auth.uid()
    OR resident_id = public.my_household_id()
  );

-- Same for the resident's own uploaded documents, so the household shares one
-- document shelf instead of the sub-login seeing an empty screen.
DROP POLICY IF EXISTS "res_docs read own" ON public.resident_documents;
CREATE POLICY "res_docs read own" ON public.resident_documents
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR user_id = public.my_household_id()
  );

-- ---------------------------------------------------------------------------
-- 3) Listing the sub-logins a resident created
-- ---------------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.my_sub_logins();
CREATE OR REPLACE FUNCTION public.my_sub_logins()
RETURNS TABLE(user_id uuid, full_name text, email text, created_at timestamptz)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $function$
  SELECT p.id,
         COALESCE(p.full_name, '')::text,
         COALESCE(p.email, '')::text,
         u.created_at
  FROM public.profiles p
  JOIN auth.users u ON u.id = p.id
  WHERE p.parent_user_id = auth.uid()
    AND u.deleted_at IS NULL
  ORDER BY u.created_at;
$function$;

GRANT EXECUTE ON FUNCTION public.my_sub_logins() TO authenticated;

-- ---------------------------------------------------------------------------
-- 4) Sanity check (run manually)
-- ---------------------------------------------------------------------------
-- SELECT public.my_household_id(), public.is_sub_login();
-- SELECT * FROM public.my_sub_logins();


-- ===========================================================================
-- from security/34_billing_visible_to_household.sql
-- ===========================================================================
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


-- ===========================================================================
-- from security/35_reward_tiers.sql
-- ===========================================================================
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


-- ===========================================================================
-- from security/36_account_deletion.sql
-- ===========================================================================
-- App Store / Play Store requirement: an account created in the app must be
-- deletable from inside the app.
--
-- WHY THIS IS NOT A PLAIN `DELETE FROM profiles`
--   profiles.id references auth.users(id) ON DELETE CASCADE, but 22 of the 27
--   foreign keys pointing AT profiles(id) have no ON DELETE rule, so they are
--   RESTRICT. The moment a resident has a single bill, booking or visitor row,
--   deleting the auth user fails at the database level.
--
--   Wiping those rows instead is not an option either: billings and visitor
--   logs are the community's own financial and security records, and the
--   management company has to keep them.
--
-- WHAT WE DO INSTEAD
--   Erase every piece of personal data and make the login permanently
--   unusable, while the community's transactional rows stay intact but no
--   longer carry a name, email, phone or photo. This is the retention pattern
--   the stores accept: the account is gone and the person is unidentifiable.
--
--   The auth row itself is soft-deleted through the Admin API
--   (deleteUser(id, shouldSoftDelete = true)) by the delete-my-account edge
--   function, which blocks sign-in while keeping referential integrity.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

COMMENT ON COLUMN public.profiles.deleted_at IS
  'Set when the user deleted their own account from the app. Personal fields '
  'are blanked at the same time. Never reuse this row for a new sign-up.';

-- Every list in the app filters on this, so keep it cheap.
CREATE INDEX IF NOT EXISTS profiles_deleted_at_idx
  ON public.profiles (deleted_at)
  WHERE deleted_at IS NULL;

-- A deleted account must not keep receiving push notifications.
-- (The edge function deletes the rows; this is the backstop for any that are
-- written afterwards by a client that has not signed out yet.)
CREATE OR REPLACE FUNCTION public.reject_push_token_for_deleted_account()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
BEGIN
  IF EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = NEW.user_id AND p.deleted_at IS NOT NULL
  ) THEN
    RETURN NULL;  -- silently drop, the client is about to be signed out
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS push_tokens_block_deleted ON public.push_tokens;
CREATE TRIGGER push_tokens_block_deleted
  BEFORE INSERT OR UPDATE ON public.push_tokens
  FOR EACH ROW EXECUTE FUNCTION public.reject_push_token_for_deleted_account();


