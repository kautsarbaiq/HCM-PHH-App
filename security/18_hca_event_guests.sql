-- HCA (boss voice note 16/07): invite OUTSIDE guests to an approved event.
-- The host shares a public link; the guest registers (name / contact /
-- vehicle) and instantly gets a QR gate pass. Guest passes are ordinary
-- `visitors` rows tied to the host's house, so the guard's existing QR
-- check-in flow works untouched.

-- 1) Tie guest passes to their event + keep the guest's contact for the
--    confirmation message.
ALTER TABLE public.visitors
  ADD COLUMN IF NOT EXISTS event_id uuid REFERENCES public.events(id) ON DELETE CASCADE,
  ADD COLUMN IF NOT EXISTS guest_contact text;

CREATE INDEX IF NOT EXISTS visitors_event_id_idx ON public.visitors(event_id);

-- 2) Public invite-page info: anon-callable, exposes ONLY an approved event's
--    basics (nothing else leaks; unguessable uuid acts as the invite token).
CREATE OR REPLACE FUNCTION public.event_invite_info(p_event_id uuid)
RETURNS TABLE(
  title text,
  description text,
  event_date text,
  location text,
  host_name text,
  community_name text
)
LANGUAGE sql
SECURITY DEFINER
AS $function$
  SELECT e.title,
         e.description,
         e.event_date::text,
         e.location,
         COALESCE(p.full_name, ''),
         COALESCE(c.name, '')
  FROM public.events e
  LEFT JOIN public.profiles p ON p.id = e.created_by
  LEFT JOIN public.communities c ON c.id = e.community_id
  WHERE e.id = p_event_id
    AND e.status = 'approved';
$function$;

-- Registration itself goes through the `event-guest-register` Edge Function
-- (service role) — no anon INSERT policy is opened on visitors.
