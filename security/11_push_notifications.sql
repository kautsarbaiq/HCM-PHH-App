-- ============================================================================
-- HCM — Push notifications (Firebase Cloud Messaging)
-- Run ONCE in the Supabase SQL editor. Idempotent: safe to re-run.
--
-- 1) push_tokens: one row per device, written by the app after login.
-- 2) Webhook triggers: on relevant table changes, call the `send-push`
--    edge function, which decides who to notify and sends via FCM.
--
-- Also required (not SQL):
--   a) Firebase console → Project settings → Service accounts →
--      "Generate new private key" → save the .json file.
--   b) In the project folder:
--        npx supabase secrets set FCM_SA_B64="$(base64 -i <that-file>.json)"
--        npx supabase functions deploy send-push
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.push_tokens (
  token      text PRIMARY KEY,
  user_id    uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  platform   text,
  updated_at timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE public.push_tokens ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "push_tokens own" ON public.push_tokens;
CREATE POLICY "push_tokens own" ON public.push_tokens
  FOR ALL TO authenticated
  USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Webhooks → send-push edge function.
-- The Authorization header carries the PUBLIC anon key (required because the
-- function verifies JWTs); the function itself uses the service role key from
-- its own environment.
-- ---------------------------------------------------------------------------

DO $$
DECLARE
  fn_url  text := 'https://kghiryjutwjgfdtbjtuq.supabase.co/functions/v1/send-push';
  fn_hdrs text := '{"Content-Type":"application/json","Authorization":"Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtnaGlyeWp1dHdqZ2ZkdGJqdHVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODEwNTczMjUsImV4cCI6MjA5NjYzMzMyNX0.fMxKxqBtv29cb3Y-3LULiavgW3SYxsMpuB7VNxV31ME"}';
BEGIN
  EXECUTE 'DROP TRIGGER IF EXISTS push_visitors ON public.visitors';
  EXECUTE format(
    'CREATE TRIGGER push_visitors AFTER INSERT OR UPDATE ON public.visitors
     FOR EACH ROW EXECUTE FUNCTION supabase_functions.http_request(%L, %L, %L, %L, %L)',
    fn_url, 'POST', fn_hdrs, '{}', '5000');

  EXECUTE 'DROP TRIGGER IF EXISTS push_bookings ON public.bookings';
  EXECUTE format(
    'CREATE TRIGGER push_bookings AFTER INSERT OR UPDATE ON public.bookings
     FOR EACH ROW EXECUTE FUNCTION supabase_functions.http_request(%L, %L, %L, %L, %L)',
    fn_url, 'POST', fn_hdrs, '{}', '5000');

  EXECUTE 'DROP TRIGGER IF EXISTS push_billings ON public.billings';
  EXECUTE format(
    'CREATE TRIGGER push_billings AFTER INSERT ON public.billings
     FOR EACH ROW EXECUTE FUNCTION supabase_functions.http_request(%L, %L, %L, %L, %L)',
    fn_url, 'POST', fn_hdrs, '{}', '5000');

  EXECUTE 'DROP TRIGGER IF EXISTS push_announcements ON public.announcements';
  EXECUTE format(
    'CREATE TRIGGER push_announcements AFTER INSERT ON public.announcements
     FOR EACH ROW EXECUTE FUNCTION supabase_functions.http_request(%L, %L, %L, %L, %L)',
    fn_url, 'POST', fn_hdrs, '{}', '5000');

  EXECUTE 'DROP TRIGGER IF EXISTS push_emergencies ON public.emergencies';
  EXECUTE format(
    'CREATE TRIGGER push_emergencies AFTER INSERT ON public.emergencies
     FOR EACH ROW EXECUTE FUNCTION supabase_functions.http_request(%L, %L, %L, %L, %L)',
    fn_url, 'POST', fn_hdrs, '{}', '5000');

  EXECUTE 'DROP TRIGGER IF EXISTS push_form_submissions ON public.form_submissions';
  EXECUTE format(
    'CREATE TRIGGER push_form_submissions AFTER INSERT OR UPDATE ON public.form_submissions
     FOR EACH ROW EXECUTE FUNCTION supabase_functions.http_request(%L, %L, %L, %L, %L)',
    fn_url, 'POST', fn_hdrs, '{}', '5000');
END $$;
