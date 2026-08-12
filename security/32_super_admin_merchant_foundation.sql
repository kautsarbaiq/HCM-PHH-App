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
