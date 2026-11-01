-- ============================================================================
-- CRITICAL SECURITY FIX — run on BOTH projects before anything else.
--   PHH kghiryjutwjgfdtbjtuq   HCA dogbmkricfvaizjgjanu
--
-- THE HOLE
--   security/02_fix_rls.sql:63
--     CREATE POLICY "user_update_own" ON public.profiles FOR UPDATE
--       USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
--
--   WITH CHECK pins WHICH ROW may be written. It says nothing about WHICH
--   COLUMNS. So any signed-in user can rewrite every column of their own
--   profile row — including `role`.
--
--   Signup is open and the anon key ships inside the APK, so the whole chain
--   is two HTTP calls:
--     POST  /auth/v1/signup
--     PATCH /rest/v1/profiles?id=eq.<self>   {"role":"super_admin"}
--   and the caller owns the database.
--
--   PROVEN on the live HCA project, not inferred: PATCHing `role` on a
--   resident account returned HTTP 200 with the row. The probe wrote
--   'resident' — the value already there, so nothing changed — but the write
--   was accepted, and 'super_admin' would have been accepted identically.
--
-- WHY NOT COLUMN PRIVILEGES
--   The obvious fix, REVOKE UPDATE (role, ...) FROM authenticated, breaks the
--   admin portal: in Supabase an admin is also the `authenticated` role, and
--   column privileges are checked before RLS policies, so the same REVOKE
--   that stops a resident also stops the office. Verified that the admin
--   pages really do write these columns directly from the client:
--   admin_repository.dart:153 (house_id, status) and :173 (on_duty, shift,
--   post) from residents_admin_page.dart and guards_admin_page.dart.
--
--   A BEFORE UPDATE trigger can see both OLD and NEW and can tell who is
--   calling, so it blocks the resident without touching the office.
--
-- WHAT STILL WORKS AFTER THIS
--   * a resident editing their own phone (the only self-write in the app:
--     profile_page.dart:728 -> updateMyProfile({'phone': ...}))
--   * admins and super admins changing anything, as today
--   * every Edge Function, which runs as service_role and has no auth.uid()
--
-- Idempotent. The last statement prints a result so you can see it ran.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.guard_profile_privileged_columns()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_caller uuid := auth.uid();
  v_role   text;
BEGIN
  -- service_role (Edge Functions, the dashboard, migrations) has no JWT, so
  -- auth.uid() is NULL. Those callers are trusted and pass straight through.
  IF v_caller IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT p.role INTO v_role FROM public.profiles p WHERE p.id = v_caller;

  -- COALESCE, not a bare IN: a caller with no profile row would otherwise
  -- compare as NULL, and an IF on NULL does not fire — the same mistake that
  -- left confirm_payment open in migration 38.
  IF COALESCE(v_role, '') IN ('admin', 'super_admin') THEN
    RETURN NEW;
  END IF;

  -- Everyone else may only touch their own harmless fields. IS DISTINCT FROM
  -- so a NULL on either side still counts as a change.
  IF NEW.id             IS DISTINCT FROM OLD.id
  OR NEW.role           IS DISTINCT FROM OLD.role
  OR NEW.approval_status IS DISTINCT FROM OLD.approval_status
  OR NEW.status         IS DISTINCT FROM OLD.status
  OR NEW.community_id   IS DISTINCT FROM OLD.community_id
  OR NEW.house_id       IS DISTINCT FROM OLD.house_id
  OR NEW.parent_user_id IS DISTINCT FROM OLD.parent_user_id
  OR NEW.resident_type  IS DISTINCT FROM OLD.resident_type
  OR NEW.deleted_at     IS DISTINCT FROM OLD.deleted_at
  OR NEW.email          IS DISTINCT FROM OLD.email
  OR NEW.created_at     IS DISTINCT FROM OLD.created_at
  OR NEW.on_duty        IS DISTINCT FROM OLD.on_duty
  OR NEW.shift          IS DISTINCT FROM OLD.shift
  OR NEW.post           IS DISTINCT FROM OLD.post
  OR NEW.position       IS DISTINCT FROM OLD.position
  THEN
    RAISE EXCEPTION
      'Only the management office can change that field on a profile';
  END IF;

  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS profiles_guard_privileged_columns ON public.profiles;
CREATE TRIGGER profiles_guard_privileged_columns
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.guard_profile_privileged_columns();

-- Proof it ran: must say true.
SELECT EXISTS (
  SELECT 1 FROM pg_trigger
  WHERE tgname = 'profiles_guard_privileged_columns'
    AND tgrelid = 'public.profiles'::regclass
) AS escalation_guard_installed;
