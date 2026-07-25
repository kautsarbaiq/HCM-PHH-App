-- ============================================================================
-- Moving a brand to a NEW Supabase project / account (currently: HCA — the
-- old HCA project is mlyycbiojsyqatmwdhef; PHH is NOT being moved).
--
-- The push trigger notify_send_push() (security/11) HARDCODES the source
-- project's URL + anon key. After cloning the database into a new project you
-- MUST repoint it, or every push notification will be sent to the OLD project.
--
-- Run this in the NEW project's SQL editor AFTER restoring the dump.
-- 1) Replace <NEW_PROJECT_REF> with the new project ref (the sub-domain).
-- 2) Replace <NEW_ANON_KEY> with the new project's anon public key.
-- ============================================================================

-- pg_net powers the outbound HTTP call; make sure it is enabled on the new DB.
CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE OR REPLACE FUNCTION public.notify_send_push()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  PERFORM net.http_post(
    url := 'https://<NEW_PROJECT_REF>.supabase.co/functions/v1/send-push',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer <NEW_ANON_KEY>'
    ),
    body := jsonb_build_object(
      'type', TG_OP,
      'table', TG_TABLE_NAME,
      'record',     CASE WHEN TG_OP IN ('INSERT','UPDATE') THEN to_jsonb(NEW) END,
      'old_record', CASE WHEN TG_OP IN ('UPDATE','DELETE') THEN to_jsonb(OLD) END
    )
  );
  RETURN COALESCE(NEW, OLD);
END $$;

-- Sanity check afterwards:
--   SELECT prosrc FROM pg_proc WHERE proname = 'notify_send_push';
