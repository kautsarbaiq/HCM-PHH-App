-- ============================================================================
-- PHH ONLY — samakan seluruh fungsi PHH dengan Home Cloud Asia (permintaan
-- boss 18/07, PHH akan diserahkan ke customer sungguhan).
--
-- JALANKAN DI PROJECT PHH: kghiryjutwjgfdtbjtuq
-- (Supabase Dashboard -> SQL Editor -> tempel semua -> Run)
--
-- Idempotent: aman dijalankan berulang. Tidak menghapus data yang sudah ada.
-- Ini gabungan security/12,13,14,15,16,17,18,19,20,21 yang sudah lebih dulu
-- diterapkan di HCA, dengan bagian khusus-HCA dibuang.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) MULTI-KOMUNITAS
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.communities (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code       text UNIQUE NOT NULL CHECK (code ~ '^[0-9]{3,6}$'),
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

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS community_id  uuid REFERENCES public.communities(id);
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS resident_type text NOT NULL DEFAULT 'owner';
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS ic_number     text;
ALTER TABLE public.houses   ADD COLUMN IF NOT EXISTS community_id  uuid REFERENCES public.communities(id);

ALTER TABLE public.announcements        ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);
ALTER TABLE public.events               ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);
ALTER TABLE public.polls                ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);
ALTER TABLE public.documents            ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);
ALTER TABLE public.forms                ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);
ALTER TABLE public.facilities           ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);
ALTER TABLE public.marketplace_services ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);
ALTER TABLE public.emergency_contacts   ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);
ALTER TABLE public.emergencies          ADD COLUMN IF NOT EXISTS community_id uuid REFERENCES public.communities(id);

CREATE OR REPLACE FUNCTION public.my_community() RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER AS
$$ SELECT community_id FROM public.profiles WHERE id = auth.uid() $$;

CREATE OR REPLACE FUNCTION public.check_community_code(p_code text)
RETURNS TABLE (id uuid, name text)
LANGUAGE sql STABLE SECURITY DEFINER AS
$$ SELECT id, name FROM public.communities WHERE code = p_code $$;
GRANT EXECUTE ON FUNCTION public.check_community_code(text) TO anon, authenticated;

-- Signup: resolve kode komunitas + owner/tenant dari metadata.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $function$
DECLARE v_comm uuid;
BEGIN
  SELECT c.id INTO v_comm FROM public.communities c
  WHERE c.code = COALESCE(NEW.raw_user_meta_data->>'community_code', '');

  INSERT INTO public.profiles (id, full_name, email, role, community_id, resident_type)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email,
    'resident',
    v_comm,
    CASE WHEN NEW.raw_user_meta_data->>'resident_type' = 'tenant' THEN 'tenant' ELSE 'owner' END
  );
  RETURN NEW;
END;
$function$;

-- Konten hanya terlihat bila global (NULL) atau milik komunitas si pembaca.
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

-- Stamp community_id otomatis saat insert (tanpa ini isolasi komunitas mati).
CREATE OR REPLACE FUNCTION public.stamp_community()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.community_id IS NULL THEN
    NEW.community_id := public.my_community();
  END IF;
  RETURN NEW;
END $$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['announcements','events','polls','documents',
                           'forms','facilities','marketplace_services',
                           'emergency_contacts','emergencies']
  LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS stamp_community_trg ON public.%I', t);
    EXECUTE format(
      'CREATE TRIGGER stamp_community_trg BEFORE INSERT ON public.%I
       FOR EACH ROW EXECUTE FUNCTION public.stamp_community()', t);
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- 2) VISITOR PASS: tipe kunjungan + masa berlaku + tamu event
-- ---------------------------------------------------------------------------
ALTER TABLE public.visitors ADD COLUMN IF NOT EXISTS entry_type    text NOT NULL DEFAULT 'single';
ALTER TABLE public.visitors ADD COLUMN IF NOT EXISTS valid_from    date;
ALTER TABLE public.visitors ADD COLUMN IF NOT EXISTS valid_to      date;
ALTER TABLE public.visitors ADD COLUMN IF NOT EXISTS visit_days    jsonb;
ALTER TABLE public.visitors ADD COLUMN IF NOT EXISTS time_window   text;
ALTER TABLE public.visitors ADD COLUMN IF NOT EXISTS event_id      uuid REFERENCES public.events(id) ON DELETE CASCADE;
ALTER TABLE public.visitors ADD COLUMN IF NOT EXISTS guest_contact text;
CREATE INDEX IF NOT EXISTS visitors_event_id_idx ON public.visitors(event_id);

ALTER TABLE public.visitors DROP CONSTRAINT IF EXISTS visitors_registration_type_check;
ALTER TABLE public.visitors ADD CONSTRAINT visitors_registration_type_check
  CHECK (registration_type = ANY (ARRAY['pre-registered'::text, 'walk-in'::text, 'event_guest'::text]));

-- ---------------------------------------------------------------------------
-- 3) EVENT: approval, RSVP guard, tamu luar
-- ---------------------------------------------------------------------------
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS status        text NOT NULL DEFAULT 'approved';
ALTER TABLE public.events ADD COLUMN IF NOT EXISTS admin_remarks text;

DROP POLICY IF EXISTS "resident_create_event" ON public.events;
CREATE POLICY "resident_create_event" ON public.events
  FOR INSERT TO authenticated WITH CHECK (created_by = auth.uid());

DROP TRIGGER IF EXISTS push_events ON public.events;
CREATE TRIGGER push_events
  AFTER INSERT OR UPDATE ON public.events
  FOR EACH ROW EXECUTE FUNCTION notify_send_push();

CREATE OR REPLACE FUNCTION public.toggle_event_rsvp(p_event_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $function$
DECLARE
  uid UUID := auth.uid();
  v_status text; v_comm uuid; v_capacity int; v_count int;
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;
  SELECT status, community_id, capacity,
         jsonb_array_length(coalesce(attendees, '[]'::jsonb))
    INTO v_status, v_comm, v_capacity, v_count
  FROM public.events WHERE id = p_event_id;
  IF v_status IS NULL THEN RAISE EXCEPTION 'event not found'; END IF;
  IF v_comm IS NOT NULL AND v_comm IS DISTINCT FROM public.my_community() THEN
    RAISE EXCEPTION 'event not found';
  END IF;
  IF v_status <> 'approved' THEN RAISE EXCEPTION 'This event is not open for RSVP.'; END IF;
  IF EXISTS (SELECT 1 FROM events WHERE id=p_event_id AND attendees ? uid::text) THEN
    UPDATE events SET attendees = attendees - uid::text WHERE id=p_event_id;
  ELSE
    IF v_capacity IS NOT NULL AND v_capacity > 0 AND v_count >= v_capacity THEN
      RAISE EXCEPTION 'This event is full.';
    END IF;
    UPDATE events SET attendees = attendees || to_jsonb(uid::text) WHERE id=p_event_id;
  END IF;
END $function$;

CREATE OR REPLACE FUNCTION public.event_attendee_names(p_event_id uuid)
RETURNS TABLE(full_name text) LANGUAGE sql SECURITY DEFINER AS $function$
  SELECT p.full_name
  FROM public.events e
  CROSS JOIN LATERAL jsonb_array_elements_text(coalesce(e.attendees, '[]'::jsonb)) AS a(uid)
  JOIN public.profiles p ON p.id::text = a.uid
  WHERE e.id = p_event_id AND auth.uid() IS NOT NULL
    AND (e.community_id IS NULL OR e.community_id = public.my_community()
         OR e.created_by = auth.uid())
  ORDER BY p.full_name;
$function$;

-- Halaman undangan publik (anon boleh panggil; hanya event approved).
CREATE OR REPLACE FUNCTION public.event_invite_info(p_event_id uuid)
RETURNS TABLE(title text, description text, event_date text, location text,
              host_name text, community_name text)
LANGUAGE sql SECURITY DEFINER AS $function$
  SELECT e.title, e.description, e.event_date::text, e.location,
         COALESCE(p.full_name, ''), COALESCE(c.name, '')
  FROM public.events e
  LEFT JOIN public.profiles p    ON p.id = e.created_by
  LEFT JOIN public.communities c ON c.id = e.community_id
  WHERE e.id = p_event_id AND e.status = 'approved';
$function$;

CREATE OR REPLACE FUNCTION public.event_guest_counts()
RETURNS TABLE(event_id uuid, guest_count bigint) LANGUAGE sql SECURITY DEFINER AS $function$
  SELECT v.event_id, count(*)::bigint
  FROM public.visitors v JOIN public.events e ON e.id = v.event_id
  WHERE v.registration_type = 'event_guest' AND v.event_id IS NOT NULL
    AND auth.uid() IS NOT NULL
    AND (e.community_id IS NULL OR e.community_id = public.my_community())
  GROUP BY v.event_id;
$function$;

CREATE OR REPLACE FUNCTION public.event_guest_names(p_event_id uuid)
RETURNS TABLE(visitor_name text) LANGUAGE sql SECURITY DEFINER AS $function$
  SELECT v.visitor_name
  FROM public.visitors v JOIN public.events e ON e.id = v.event_id
  WHERE v.event_id = p_event_id AND v.registration_type = 'event_guest'
    AND auth.uid() IS NOT NULL
    AND (e.community_id IS NULL OR e.community_id = public.my_community()
         OR e.created_by = auth.uid())
  ORDER BY v.created_at DESC;
$function$;

-- ---------------------------------------------------------------------------
-- 4) EMERGENCY: rumah + siapa yang menekan + catatan clear + privasi
-- ---------------------------------------------------------------------------
ALTER TABLE public.emergencies ADD COLUMN IF NOT EXISTS house_id      uuid REFERENCES public.houses(id);
ALTER TABLE public.emergencies ADD COLUMN IF NOT EXISTS cleared_by    uuid REFERENCES public.profiles(id);
ALTER TABLE public.emergencies ADD COLUMN IF NOT EXISTS cleared_at    timestamptz;
ALTER TABLE public.emergencies ADD COLUMN IF NOT EXISTS clear_remarks text;

DROP POLICY IF EXISTS "Anyone can view active emergencies" ON public.emergencies;
DROP POLICY IF EXISTS "scoped emergency read" ON public.emergencies;
CREATE POLICY "scoped emergency read" ON public.emergencies
  FOR SELECT TO authenticated
  USING (type = 'broadcast' OR triggered_by = auth.uid()
         OR public.is_admin() OR public.is_guard());

-- ---------------------------------------------------------------------------
-- 5) PARKING BAYS
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.parking_bays (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  house_id        uuid NOT NULL REFERENCES public.houses(id) ON DELETE CASCADE,
  bay_number      text NOT NULL,
  plate           text,
  vehicle_details text,
  vehicle_make    text,
  vehicle_model   text,
  vehicle_year    text,
  vehicle_color   text,
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

-- ---------------------------------------------------------------------------
-- 6) ADMIN: approve pendaftaran akun dari dalam app
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.admin_pending_signups()
RETURNS TABLE(user_id uuid, email text, full_name text, created_at timestamptz)
LANGUAGE sql SECURITY DEFINER AS $function$
  SELECT u.id, u.email::text,
         COALESCE(u.raw_user_meta_data->>'full_name', '')::text, u.created_at
  FROM auth.users u
  WHERE u.email_confirmed_at IS NULL AND u.deleted_at IS NULL AND public.is_admin()
  ORDER BY u.created_at DESC;
$function$;

CREATE OR REPLACE FUNCTION public.admin_approve_signup(p_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $function$
BEGIN
  IF NOT public.is_admin() THEN RAISE EXCEPTION 'admins only'; END IF;
  UPDATE auth.users SET email_confirmed_at = now()
   WHERE id = p_user_id AND email_confirmed_at IS NULL;
END $function$;

CREATE OR REPLACE FUNCTION public.admin_reject_signup(p_user_id uuid)
RETURNS void LANGUAGE plpgsql SECURITY DEFINER AS $function$
BEGIN
  IF NOT public.is_admin() THEN RAISE EXCEPTION 'admins only'; END IF;
  IF EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id AND email_confirmed_at IS NOT NULL) THEN
    RAISE EXCEPTION 'account is already active';
  END IF;
  DELETE FROM public.profiles WHERE id = p_user_id;
  DELETE FROM auth.users WHERE id = p_user_id;
END $function$;

-- ---------------------------------------------------------------------------
-- 7) PERBAIKAN BUG: resident harus bisa membaca rumah yang di-assign padanya
--    (sebelumnya profil menampilkan "House Address: Not assigned")
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS resident_read_own ON public.houses;
CREATE POLICY resident_read_own ON public.houses
  FOR SELECT
  USING (
    owner_id = auth.uid()
    OR id = (SELECT p.house_id FROM public.profiles p WHERE p.id = auth.uid())
  );

-- ---------------------------------------------------------------------------
-- 8) REALTIME untuk tabel baru
-- ---------------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND tablename='communities') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.communities;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND tablename='parking_bays') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.parking_bays;
  END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 9) DATA AWAL: komunitas default + form renovasi
--    Kode '001' dipakai resident saat mendaftar. Nama bisa diubah admin lewat
--    halaman Communities.
-- ---------------------------------------------------------------------------
INSERT INTO public.forms (title, description, is_active)
SELECT 'House Renovation Form',
       'Apply for permission to renovate your house. Management will review and respond.',
       true
WHERE NOT EXISTS (SELECT 1 FROM public.forms WHERE title = 'House Renovation Form');

INSERT INTO public.communities (code, name, address)
SELECT '001', 'PHH Housing', ''
WHERE NOT EXISTS (SELECT 1 FROM public.communities);

-- Semua data lama masuk ke komunitas pertama supaya login yang ada tetap jalan.
UPDATE public.profiles SET community_id = (SELECT id FROM public.communities ORDER BY created_at LIMIT 1)
WHERE community_id IS NULL;
UPDATE public.houses   SET community_id = (SELECT id FROM public.communities ORDER BY created_at LIMIT 1)
WHERE community_id IS NULL;

-- ============================================================================
-- SELESAI. Verifikasi cepat:
--   SELECT code, name FROM public.communities;
--   SELECT count(*) FROM public.parking_bays;
--   SELECT email, resident_type, community_id FROM public.profiles LIMIT 5;
-- ============================================================================
