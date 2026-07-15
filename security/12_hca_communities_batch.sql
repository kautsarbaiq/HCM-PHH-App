-- ============================================================================
-- HCA ONLY — Multi-community foundation + 15/07 update batch (points 2,3,7,
-- 8,9,10-12,14,15,17). Run on the HOME CLOUD ASIA project (mlyycbiojsyqatmwdhef).
-- Idempotent: safe to re-run. Do NOT run on PHH.
-- ============================================================================

-- 1) Communities: one row per condo/apartment complex. The 6-digit code is
--    what residents type at signup to join the right community.
CREATE TABLE IF NOT EXISTS public.communities (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code       text UNIQUE NOT NULL CHECK (code ~ '^[0-9]{6}$'),
  name       text NOT NULL,
  address    text,
  created_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.communities ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "communities read" ON public.communities;
CREATE POLICY "communities read" ON public.communities
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "communities admin write" ON public.communities;
CREATE POLICY "communities admin write" ON public.communities
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));

-- 2) Profile & house membership + owner/tenant type (point 17).
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS resident_type text NOT NULL DEFAULT 'owner';
ALTER TABLE public.houses   ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);

-- 3) Community scoping on shared-content tables (NULL = visible to everyone,
--    which keeps all existing rows working).
ALTER TABLE public.announcements        ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);
ALTER TABLE public.events               ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);
ALTER TABLE public.polls                ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);
ALTER TABLE public.documents            ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);
ALTER TABLE public.forms                ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);
ALTER TABLE public.facilities           ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);
ALTER TABLE public.marketplace_services ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);
ALTER TABLE public.emergency_contacts   ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);
ALTER TABLE public.emergencies          ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);

-- Helper: the caller's community (used by scoping policies).
CREATE OR REPLACE FUNCTION public.my_community() RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER AS
$$ SELECT community_id FROM public.profiles WHERE id = auth.uid() $$;

-- Anon-safe signup helper: validate a community code and return its name.
CREATE OR REPLACE FUNCTION public.check_community_code(p_code text)
RETURNS TABLE (id uuid, name text)
LANGUAGE sql STABLE SECURITY DEFINER AS
$$ SELECT id, name FROM public.communities WHERE code = p_code $$;
GRANT EXECUTE ON FUNCTION public.check_community_code(text) TO anon, authenticated;

-- 4) Signup trigger: resolve community code from metadata + owner/tenant.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $function$
DECLARE
  v_comm uuid;
BEGIN
  SELECT c.id INTO v_comm
  FROM public.communities c
  WHERE c.code = COALESCE(NEW.raw_user_meta_data->>'community_code', '');

  INSERT INTO public.profiles (id, full_name, email, role, community_id, resident_type)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email,
    'resident',  -- never trust a role sent by the client
    v_comm,
    CASE WHEN NEW.raw_user_meta_data->>'resident_type' = 'tenant'
         THEN 'tenant' ELSE 'owner' END
  );
  RETURN NEW;
END;
$function$;

-- 5) Community-scoped resident reads: content is visible when it is global
--    (community_id IS NULL) or belongs to the caller's community.
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['announcements','events','polls','documents',
                           'forms','facilities','marketplace_services',
                           'emergency_contacts']
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS "all_read" ON public.%I', t);
    EXECUTE format('DROP POLICY IF EXISTS "community_read" ON public.%I', t);
    EXECUTE format(
      'CREATE POLICY "community_read" ON public.%I FOR SELECT TO authenticated
       USING (community_id IS NULL OR community_id = public.my_community())', t);
  END LOOP;
END $$;

-- 6) Visitor pass validity (point 7).
ALTER TABLE public.visitors ADD COLUMN IF NOT EXISTS entry_type  text NOT NULL DEFAULT 'single';
ALTER TABLE public.visitors ADD COLUMN IF NOT EXISTS valid_from  date;
ALTER TABLE public.visitors ADD COLUMN IF NOT EXISTS valid_to    date;
ALTER TABLE public.visitors ADD COLUMN IF NOT EXISTS visit_days  jsonb;
ALTER TABLE public.visitors ADD COLUMN IF NOT EXISTS time_window text;

-- 7) Event approval flow (point 8). Existing rows stay approved.
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS status        text NOT NULL DEFAULT 'approved';
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS admin_remarks text;
DROP POLICY IF EXISTS "resident_create_event" ON public.events;
CREATE POLICY "resident_create_event" ON public.events
  FOR INSERT TO authenticated
  WITH CHECK (created_by = auth.uid());

-- 8) Emergency history + guard clearing details (points 10-12).
ALTER TABLE public.emergencies ADD COLUMN IF NOT EXISTS house_id      uuid REFERENCES public.houses(id);
ALTER TABLE public.emergencies ADD COLUMN IF NOT EXISTS cleared_by    uuid REFERENCES public.profiles(id);
ALTER TABLE public.emergencies ADD COLUMN IF NOT EXISTS cleared_at    timestamptz;
ALTER TABLE public.emergencies ADD COLUMN IF NOT EXISTS clear_remarks text;

-- 9) Parking bays (points 14-15).
CREATE TABLE IF NOT EXISTS public.parking_bays (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  house_id        uuid NOT NULL REFERENCES public.houses(id) ON DELETE CASCADE,
  bay_number      text NOT NULL,
  plate           text,
  vehicle_details text,
  created_at      timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.parking_bays ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "parking read" ON public.parking_bays;
CREATE POLICY "parking read" ON public.parking_bays
  FOR SELECT TO authenticated USING (true);
DROP POLICY IF EXISTS "parking admin all" ON public.parking_bays;
CREATE POLICY "parking admin all" ON public.parking_bays
  FOR ALL TO authenticated
  USING (EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'));
DROP POLICY IF EXISTS "parking resident update own" ON public.parking_bays;
CREATE POLICY "parking resident update own" ON public.parking_bays
  FOR UPDATE TO authenticated
  USING (house_id = (SELECT house_id FROM public.profiles WHERE id = auth.uid()))
  WITH CHECK (house_id = (SELECT house_id FROM public.profiles WHERE id = auth.uid()));

-- Realtime for the new tables.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND tablename='communities') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.communities;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND tablename='parking_bays') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.parking_bays;
  END IF;
END $$;

-- 10) House renovation form (point 9).
INSERT INTO public.forms (title, description, is_active)
SELECT 'House Renovation Form',
       'Apply for permission to renovate your house. Management will review and respond.',
       true
WHERE NOT EXISTS (SELECT 1 FROM public.forms WHERE title = 'House Renovation Form');

-- 11) Demo community + link existing demo data so current logins keep working.
INSERT INTO public.communities (code, name, address)
SELECT '100001', 'Home Cloud Asia Residence', 'Kuala Lumpur'
WHERE NOT EXISTS (SELECT 1 FROM public.communities WHERE code = '100001');

UPDATE public.profiles SET community_id = (SELECT id FROM public.communities WHERE code='100001')
WHERE community_id IS NULL;
UPDATE public.houses SET community_id = (SELECT id FROM public.communities WHERE code='100001')
WHERE community_id IS NULL;
