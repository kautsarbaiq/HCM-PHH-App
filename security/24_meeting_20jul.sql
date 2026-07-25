-- ============================================================================
-- Meeting decisions 20 July 2026 — DB-side changes.
-- Run in BOTH SQL editors: PHH (kghiryjutwjgfdtbjtuq) AND HCA (mlyycbiojsyqatmwdhef).
-- Idempotent — safe to re-run.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- Point 1: House OWNER signups need management approval too (same as tenants).
--
-- Gate is an explicit profiles.approval_status so it does NOT depend on the
-- Supabase "Confirm email" dashboard toggle. Existing accounts are grandfathered
-- to 'approved'; only NEW self-signups start 'pending'.
-- ---------------------------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS approval_status text NOT NULL DEFAULT 'approved';

-- New self-signups (owner OR tenant) start pending. Admin-created accounts
-- (admin-create-owner edge fn) overwrite this to 'approved' straight after.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $function$
DECLARE v_comm uuid;
BEGIN
  SELECT c.id INTO v_comm FROM public.communities c
  WHERE c.code = COALESCE(NEW.raw_user_meta_data->>'community_code', '');

  INSERT INTO public.profiles (id, full_name, email, role, community_id, resident_type, approval_status)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email,
    'resident',
    v_comm,
    CASE WHEN NEW.raw_user_meta_data->>'resident_type' = 'tenant' THEN 'tenant' ELSE 'owner' END,
    'pending'
  );
  RETURN NEW;
END;
$function$;

-- Is the CURRENT user approved? (Used by the app login gate; available for RLS.)
CREATE OR REPLACE FUNCTION public.is_approved()
RETURNS boolean LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT COALESCE(
    (SELECT p.approval_status = 'approved' FROM public.profiles p WHERE p.id = auth.uid()),
    false);
$$;
GRANT EXECUTE ON FUNCTION public.is_approved() TO authenticated;

-- Pending signups for the admin attention feed — now owner/tenant aware.
DROP FUNCTION IF EXISTS public.admin_pending_signups();
CREATE OR REPLACE FUNCTION public.admin_pending_signups()
RETURNS TABLE(user_id uuid, email text, full_name text, resident_type text, created_at timestamptz)
LANGUAGE sql SECURITY DEFINER AS $function$
  SELECT p.id, p.email::text, COALESCE(p.full_name,'')::text,
         COALESCE(p.resident_type,'owner')::text, u.created_at
  FROM public.profiles p
  JOIN auth.users u ON u.id = p.id
  WHERE p.approval_status = 'pending'
    AND p.role = 'resident'
    AND u.deleted_at IS NULL
    AND public.is_admin()
  ORDER BY u.created_at DESC;
$function$;

CREATE OR REPLACE FUNCTION public.admin_approve_signup(p_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $function$
BEGIN
  IF NOT public.is_admin() THEN RAISE EXCEPTION 'admins only'; END IF;
  UPDATE public.profiles SET approval_status = 'approved' WHERE id = p_user_id;
  -- Also confirm the email, so login works even if "Confirm email" is ON.
  UPDATE auth.users SET email_confirmed_at = COALESCE(email_confirmed_at, now())
   WHERE id = p_user_id;
END $function$;

CREATE OR REPLACE FUNCTION public.admin_reject_signup(p_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $function$
BEGIN
  IF NOT public.is_admin() THEN RAISE EXCEPTION 'admins only'; END IF;
  IF EXISTS (SELECT 1 FROM public.profiles WHERE id = p_user_id AND approval_status = 'approved') THEN
    RAISE EXCEPTION 'account is already active';
  END IF;
  DELETE FROM public.profiles WHERE id = p_user_id;
  DELETE FROM auth.users WHERE id = p_user_id;
END $function$;

-- ---------------------------------------------------------------------------
-- Points 2 & 3: optional last-4 IC digits on a visitor pass / event guest pass.
-- ---------------------------------------------------------------------------
ALTER TABLE public.visitors
  ADD COLUMN IF NOT EXISTS ic_last4 text;

-- ---------------------------------------------------------------------------
-- Point 7: when a guard clears a panic alert they pick a resolution type
-- (false_alarm / attended). The community is notified of the STATUS only —
-- never the remarks. Notification is sent from send-push on the UPDATE.
-- ---------------------------------------------------------------------------
ALTER TABLE public.emergencies
  ADD COLUMN IF NOT EXISTS clear_type text;

-- The push trigger must also fire on UPDATE (clear), not just INSERT (raise).
DROP TRIGGER IF EXISTS push_emergencies ON public.emergencies;
CREATE TRIGGER push_emergencies AFTER INSERT OR UPDATE ON public.emergencies
  FOR EACH ROW EXECUTE FUNCTION public.notify_send_push();

-- ---------------------------------------------------------------------------
-- Verify (optional):
--   SELECT approval_status, count(*) FROM public.profiles GROUP BY 1;
--   SELECT * FROM public.admin_pending_signups();
-- ---------------------------------------------------------------------------
