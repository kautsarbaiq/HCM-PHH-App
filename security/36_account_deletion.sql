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
