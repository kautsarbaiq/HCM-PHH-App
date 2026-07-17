-- HCA (boss 16/07): outside guests who register via the WhatsApp invite must
-- show up in the event's attendance (they weren't counted because they're
-- visitors, not RSVPs). Community-scoped, SECURITY DEFINER so residents can
-- read the counts/names without direct access to visitors.

-- Guest count per event (for the "X/N attending" display).
CREATE OR REPLACE FUNCTION public.event_guest_counts()
RETURNS TABLE(event_id uuid, guest_count bigint)
LANGUAGE sql
SECURITY DEFINER
AS $function$
  SELECT v.event_id, count(*)::bigint
  FROM public.visitors v
  JOIN public.events e ON e.id = v.event_id
  WHERE v.registration_type = 'event_guest'
    AND v.event_id IS NOT NULL
    AND auth.uid() IS NOT NULL
    AND (e.community_id IS NULL OR e.community_id = public.my_community())
  GROUP BY v.event_id;
$function$;

-- Guest names for a specific event (shown in the attendees popup).
CREATE OR REPLACE FUNCTION public.event_guest_names(p_event_id uuid)
RETURNS TABLE(visitor_name text)
LANGUAGE sql
SECURITY DEFINER
AS $function$
  SELECT v.visitor_name
  FROM public.visitors v
  JOIN public.events e ON e.id = v.event_id
  WHERE v.event_id = p_event_id
    AND v.registration_type = 'event_guest'
    AND auth.uid() IS NOT NULL
    AND (e.community_id IS NULL
         OR e.community_id = public.my_community()
         OR e.created_by = auth.uid())
  ORDER BY v.created_at DESC;
$function$;
