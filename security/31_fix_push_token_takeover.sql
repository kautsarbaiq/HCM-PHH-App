-- ============================================================================
-- Client test 03/08: a NEWLY created account showed "Device not registered"
-- on a phone where a previous account had registered fine.
--
-- Root cause: `push_tokens` is keyed by TOKEN (one row per device), and its RLS
-- policy is USING (user_id = auth.uid()). The app upserts with
-- ON CONFLICT (token) DO UPDATE, so when a second user signs in on a phone that
-- already has a row, the UPDATE targets a row owned by the FIRST user — RLS
-- rejects it with "new row violates row-level security policy (USING
-- expression)" and the new user is never registered for push.
--
-- This affects every shared / re-used handset, not just testing.
--
-- Fix: a SECURITY DEFINER function that releases the token from whoever held it
-- and registers it to the caller. Safe by construction — the caller can only
-- ever register a token to THEMSELVES, and physically holding the device is
-- what entitles you to its notifications.
--
-- Run in BOTH SQL editors: PHH (kghiryjutwjgfdtbjtuq) AND HCA
-- (dogbmkricfvaizjgjanu). Idempotent.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.register_push_token(
  p_token    text,
  p_platform text DEFAULT 'unknown'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL OR coalesce(p_token, '') = '' THEN
    RETURN;
  END IF;

  -- Hand the device over from any previous owner (e.g. the phone was used by
  -- another resident before, or the app was reinstalled).
  DELETE FROM public.push_tokens WHERE token = p_token;

  INSERT INTO public.push_tokens (user_id, token, platform, updated_at)
  VALUES (auth.uid(), p_token, coalesce(p_platform, 'unknown'), now());
END $$;

GRANT EXECUTE ON FUNCTION public.register_push_token(text, text) TO authenticated;

-- Verify:
--   SELECT p.full_name, count(t.token)
--   FROM profiles p LEFT JOIN push_tokens t ON t.user_id = p.id
--   GROUP BY 1 ORDER BY 2 DESC;
