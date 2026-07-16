-- HCA (boss 16/07): the admin dashboard's "Recent Activities" becomes a real
-- "Needs your attention" feed — pending signups, event proposals, bookings,
-- and form submissions. Signup approval moves INTO the app: these SECURITY
-- DEFINER functions let an admin list/approve/reject unconfirmed accounts
-- without touching the Supabase dashboard ("Confirm email" stays ON; approval
-- = setting email_confirmed_at).

CREATE OR REPLACE FUNCTION public.admin_pending_signups()
RETURNS TABLE(user_id uuid, email text, full_name text, created_at timestamptz)
LANGUAGE sql
SECURITY DEFINER
AS $function$
  SELECT u.id,
         u.email::text,
         COALESCE(u.raw_user_meta_data->>'full_name', '')::text,
         u.created_at
  FROM auth.users u
  WHERE u.email_confirmed_at IS NULL
    AND u.deleted_at IS NULL
    AND public.is_admin()
  ORDER BY u.created_at DESC;
$function$;

CREATE OR REPLACE FUNCTION public.admin_approve_signup(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'admins only';
  END IF;
  UPDATE auth.users
     SET email_confirmed_at = now()
   WHERE id = p_user_id
     AND email_confirmed_at IS NULL;
END $function$;

-- Reject = remove the unconfirmed account entirely (it never became active).
CREATE OR REPLACE FUNCTION public.admin_reject_signup(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'admins only';
  END IF;
  -- Guard: only never-confirmed accounts can be rejected this way.
  IF EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id AND email_confirmed_at IS NOT NULL) THEN
    RAISE EXCEPTION 'account is already active';
  END IF;
  DELETE FROM public.profiles WHERE id = p_user_id;
  DELETE FROM auth.users WHERE id = p_user_id;
END $function$;
