-- HCA boss feedback 15/07 (events round):
-- 1) Push notifications for the event-approval flow: proposal → admins,
--    approve/reject → the proposer. Reuses notify_send_push() (security/11);
--    the send-push Edge Function gained a matching "events" case and must be
--    redeployed: npx supabase functions deploy send-push --project-ref mlyycbiojsyqatmwdhef
-- 2) RSVP guard: only an APPROVED event accepts RSVPs. A rejected/pending
--    event no longer collects attendees even via direct RPC calls.

DROP TRIGGER IF EXISTS push_events ON public.events;
CREATE TRIGGER push_events
  AFTER INSERT OR UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION notify_send_push();

CREATE OR REPLACE FUNCTION public.toggle_event_rsvp(p_event_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
DECLARE
  uid UUID := auth.uid();
  v_status text;
  v_comm uuid;
  v_capacity int;
  v_count int;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;
  SELECT status, community_id, capacity,
         jsonb_array_length(coalesce(attendees, '[]'::jsonb))
    INTO v_status, v_comm, v_capacity, v_count
  FROM public.events WHERE id = p_event_id;
  IF v_status IS NULL THEN
    RAISE EXCEPTION 'event not found';
  END IF;
  -- A resident of another community can't RSVP by guessing the event id
  -- (the function is SECURITY DEFINER, so RLS alone doesn't protect it).
  IF v_comm IS NOT NULL AND v_comm IS DISTINCT FROM public.my_community() THEN
    RAISE EXCEPTION 'event not found';
  END IF;
  IF v_status <> 'approved' THEN
    RAISE EXCEPTION 'This event is not open for RSVP.';
  END IF;
  IF EXISTS (SELECT 1 FROM events WHERE id=p_event_id AND attendees ? uid::text) THEN
    UPDATE events SET attendees = attendees - uid::text WHERE id=p_event_id;
  ELSE
    -- Capacity is a hard limit when set (>0); cancelling is always allowed.
    IF v_capacity IS NOT NULL AND v_capacity > 0 AND v_count >= v_capacity THEN
      RAISE EXCEPTION 'This event is full.';
    END IF;
    UPDATE events SET attendees = attendees || to_jsonb(uid::text) WHERE id=p_event_id;
  END IF;
END $function$;

-- 3) Attendee names popup: residents can't SELECT other profiles directly
--    (directory_read only exposes committee/guards), so a narrow SECURITY
--    DEFINER RPC returns just the full names of one event's attendees —
--    community-scoped, no other profile fields exposed.
CREATE OR REPLACE FUNCTION public.event_attendee_names(p_event_id uuid)
RETURNS TABLE(full_name text)
LANGUAGE sql
SECURITY DEFINER
AS $function$
  SELECT p.full_name
  FROM public.events e
  CROSS JOIN LATERAL jsonb_array_elements_text(coalesce(e.attendees, '[]'::jsonb)) AS a(uid)
  JOIN public.profiles p ON p.id::text = a.uid
  WHERE e.id = p_event_id
    AND auth.uid() IS NOT NULL
    AND (
      e.community_id IS NULL
      OR e.community_id = public.my_community()
      OR e.created_by = auth.uid()
    )
  ORDER BY p.full_name;
$function$;
