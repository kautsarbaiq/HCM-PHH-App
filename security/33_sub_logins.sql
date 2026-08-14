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
