-- ============================================================================
-- HCM — "REALIZE" FOUNDATION
-- Run the WHOLE file in the Supabase SQL Editor (BEGIN…COMMIT, idempotent).
-- Prereq: security/02_fix_rls.sql already applied (is_admin()/is_guard() exist).
-- This adds: storage buckets, facility seed, events/polls reconciliation + seed,
-- content tables (contacts/docs/forms/marketplace), directory columns, and the
-- RSVP/vote RPC functions. Re-runnable safely.
-- ============================================================================
BEGIN;

-- ---------- 1. STORAGE BUCKETS (guard photos + profile avatars) -------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('avatars','avatars',true), ('guard_evidence','guard_evidence',false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "avatars_read"   ON storage.objects;
DROP POLICY IF EXISTS "avatars_write"  ON storage.objects;
DROP POLICY IF EXISTS "avatars_update" ON storage.objects;
DROP POLICY IF EXISTS "evidence_read"  ON storage.objects;
DROP POLICY IF EXISTS "evidence_write" ON storage.objects;
CREATE POLICY "avatars_read"   ON storage.objects FOR SELECT USING (bucket_id='avatars');
CREATE POLICY "avatars_write"  ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id='avatars');
CREATE POLICY "avatars_update" ON storage.objects FOR UPDATE TO authenticated USING (bucket_id='avatars');
CREATE POLICY "evidence_write" ON storage.objects FOR INSERT TO authenticated WITH CHECK (bucket_id='guard_evidence' AND (public.is_guard() OR public.is_admin()));
CREATE POLICY "evidence_read"  ON storage.objects FOR SELECT TO authenticated USING (bucket_id='guard_evidence' AND (public.is_guard() OR public.is_admin()));

-- ---------- 2. DIRECTORY columns on profiles (committee + guard shifts) ------
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS position TEXT;     -- committee role, e.g. 'Chairperson'
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS shift    TEXT;     -- guard shift, e.g. 'Day 7AM-7PM'
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS post     TEXT;     -- guard post, e.g. 'Main Gate'
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS on_duty  BOOLEAN NOT NULL DEFAULT FALSE;

-- Let any logged-in user read committee members & guards for the Directory
-- (in addition to the existing user_read_own / admin_all / guard_read_all).
DROP POLICY IF EXISTS directory_read ON profiles;
CREATE POLICY directory_read ON profiles FOR SELECT
  USING (auth.uid() IS NOT NULL AND (position IS NOT NULL OR role = 'guard'));

-- ---------- 3. EVENTS / POLLS reconciliation (JSONB attendees / voters) ------
ALTER TABLE events ADD COLUMN IF NOT EXISTS attendees JSONB NOT NULL DEFAULT '[]';
ALTER TABLE events ADD COLUMN IF NOT EXISTS capacity  INT   NOT NULL DEFAULT 100;
ALTER TABLE polls  ADD COLUMN IF NOT EXISTS voters    JSONB NOT NULL DEFAULT '[]';

-- ---------- 4. CONTENT TABLES (Grup C) --------------------------------------
CREATE TABLE IF NOT EXISTS emergency_contacts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL, phone TEXT NOT NULL, hours TEXT, category TEXT,
  sort_order INT NOT NULL DEFAULT 0, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL, category TEXT, file_url TEXT, file_size TEXT,
  is_public BOOLEAN NOT NULL DEFAULT TRUE, created_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS forms (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL, description TEXT, category TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS form_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  form_id UUID NOT NULL REFERENCES forms(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id),
  status TEXT NOT NULL DEFAULT 'pending', data JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS marketplace_services (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_name TEXT NOT NULL, category TEXT, phone TEXT, description TEXT,
  rating NUMERIC(2,1) NOT NULL DEFAULT 5.0, is_verified BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS resident_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id),
  title TEXT NOT NULL, reference_code TEXT, document_type TEXT, file_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Grants for the API roles (RLS still gates rows).
GRANT SELECT, INSERT, UPDATE, DELETE ON emergency_contacts, documents, forms, form_submissions, marketplace_services, resident_documents TO authenticated;

-- RLS for content tables: everyone logged-in reads; admin manages.
ALTER TABLE emergency_contacts   ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents            ENABLE ROW LEVEL SECURITY;
ALTER TABLE forms                ENABLE ROW LEVEL SECURITY;
ALTER TABLE form_submissions     ENABLE ROW LEVEL SECURITY;
ALTER TABLE marketplace_services ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS all_read ON emergency_contacts;   CREATE POLICY all_read ON emergency_contacts FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS admin_all ON emergency_contacts;  CREATE POLICY admin_all ON emergency_contacts FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS all_read ON documents;            CREATE POLICY all_read ON documents FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS admin_all ON documents;           CREATE POLICY admin_all ON documents FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS all_read ON forms;                CREATE POLICY all_read ON forms FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS admin_all ON forms;               CREATE POLICY admin_all ON forms FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS all_read ON marketplace_services; CREATE POLICY all_read ON marketplace_services FOR SELECT USING (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS admin_all ON marketplace_services;CREATE POLICY admin_all ON marketplace_services FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
DROP POLICY IF EXISTS resident_own ON form_submissions; CREATE POLICY resident_own ON form_submissions FOR ALL USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
DROP POLICY IF EXISTS admin_all ON form_submissions;    CREATE POLICY admin_all ON form_submissions FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());
ALTER TABLE resident_documents ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS resident_own ON resident_documents; CREATE POLICY resident_own ON resident_documents FOR SELECT USING (user_id = auth.uid());
DROP POLICY IF EXISTS admin_all ON resident_documents;    CREATE POLICY admin_all ON resident_documents FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ---------- 5. SEED DATA -----------------------------------------------------
DO $$
DECLARE admin_id UUID := (SELECT id FROM profiles WHERE role='admin' LIMIT 1);
BEGIN
  IF NOT EXISTS (SELECT 1 FROM facilities) THEN
    INSERT INTO facilities (name, description, icon_name, is_active, max_capacity) VALUES
      ('Swimming Pool','Outdoor 25m lap pool','swimming',true,30),
      ('Gymnasium','Fully-equipped fitness center','gym',true,20),
      ('BBQ Pit','Covered barbecue area','bbq',true,15),
      ('Tennis Court','Hard-surface court','tennis',true,4),
      ('Multipurpose Hall','Events & functions hall','hall',true,100),
      ('Children Playground','Outdoor play area','playground',true,25);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM events) THEN
    INSERT INTO events (title, description, location, event_date, capacity, created_by) VALUES
      ('Community Town Hall','Quarterly residents meeting','Multipurpose Hall', NOW()+INTERVAL '7 days', 100, admin_id),
      ('Weekend Family BBQ','Open BBQ for all residents','BBQ Pit', NOW()+INTERVAL '3 days', 50, admin_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM polls) THEN
    INSERT INTO polls (question, description, options, is_active, expires_at, created_by) VALUES
      ('Should we install EV charging stations?','Vote on the proposed EV charging project',
       '[{"label":"Yes","votes":0},{"label":"No","votes":0},{"label":"Need more info","votes":0}]'::jsonb,
       true, NOW()+INTERVAL '14 days', admin_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM emergency_contacts) THEN
    INSERT INTO emergency_contacts (name, phone, hours, category, sort_order) VALUES
      ('Management Office','+60 3-1234 5678','Mon-Fri 9AM-6PM','management',1),
      ('Guard House','+60 3-1234 5000','24 Hours','security',2),
      ('Maintenance Team','+60 3-1234 5001','Daily 8AM-8PM','maintenance',3),
      ('TNB (Electricity)','15454','24 Hours','utility',4),
      ('Air Selangor (Water)','15300','24 Hours','utility',5);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM documents) THEN
    INSERT INTO documents (title, category, file_size, created_by) VALUES
      ('House Rules & Regulations','Rules','320 KB', admin_id),
      ('Fire Safety Guidelines','Safety','512 KB', admin_id),
      ('Parking Policy 2026','Policy','210 KB', admin_id),
      ('Annual Financial Report','Finance','1.2 MB', admin_id),
      ('Pet Ownership Policy','Policy','180 KB', admin_id);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM forms) THEN
    INSERT INTO forms (title, description, category) VALUES
      ('Renovation Request','Apply for unit renovation approval','renovation'),
      ('Move-In / Move-Out Notice','Notify management of moving','moving'),
      ('Visitor Vehicle Pass','Request a long-term vehicle pass','vehicle'),
      ('Pet Registration','Register a pet in your unit','pet');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM marketplace_services) THEN
    INSERT INTO marketplace_services (business_name, category, phone, description, rating) VALUES
      ('CleanPro Services','Cleaning','+60 12-300 1001','Home & unit cleaning',4.8),
      ('PipeFix Plumbing','Plumbing','+60 12-300 1002','Leak & pipe repairs',4.6),
      ('SparkElec','Electrician','+60 12-300 1003','Electrical works',4.9),
      ('CoolAir AC','Air-Cond','+60 12-300 1004','AC service & repair',4.7),
      ('GreenScape','Landscaping','+60 12-300 1005','Garden & plants',4.5),
      ('MoveEasy','Moving','+60 12-300 1006','Moving & transport',4.4);
  END IF;

  IF NOT EXISTS (SELECT 1 FROM resident_documents) THEN
    INSERT INTO resident_documents (user_id, title, reference_code, document_type)
    SELECT p.id, d.title, d.code, d.dtype
    FROM profiles p
    CROSS JOIN (VALUES ('Unit Deed','DOC-882XX482','deed'),
                       ('Tenancy Agreement','AGR-XX9-1318','tenancy'),
                       ('Pet License','PET-XXX1929','pet')) AS d(title, code, dtype)
    WHERE p.email = 'resident@hcm.com';
  END IF;

  -- Directory demo: make the guard on-duty and give the resident a committee role.
  UPDATE profiles SET shift='Day 7AM-7PM', post='Main Gate', on_duty=true WHERE email='guard@hcm.com';
  UPDATE profiles SET position='Resident Representative' WHERE email='resident@hcm.com';
END $$;

-- ---------- 6. RPC: event RSVP toggle + poll vote (atomic JSONB) -------------
CREATE OR REPLACE FUNCTION public.toggle_event_rsvp(p_event_id UUID)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE uid UUID := auth.uid();
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;
  IF EXISTS (SELECT 1 FROM events WHERE id=p_event_id AND attendees ? uid::text) THEN
    UPDATE events SET attendees = attendees - uid::text WHERE id=p_event_id;
  ELSE
    UPDATE events SET attendees = attendees || to_jsonb(uid::text) WHERE id=p_event_id;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.submit_poll_vote(p_poll_id UUID, p_option_index INT)
RETURNS VOID LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE uid UUID := auth.uid();
BEGIN
  IF uid IS NULL THEN RAISE EXCEPTION 'authentication required'; END IF;
  IF EXISTS (SELECT 1 FROM polls WHERE id=p_poll_id AND voters ? uid::text) THEN
    RAISE EXCEPTION 'you have already voted';
  END IF;
  UPDATE polls
     SET voters  = voters || to_jsonb(uid::text),
         options = jsonb_set(options, ARRAY[p_option_index::text,'votes'],
                             to_jsonb(COALESCE((options->p_option_index->>'votes')::int,0)+1))
   WHERE id=p_poll_id;
END $$;

GRANT EXECUTE ON FUNCTION public.toggle_event_rsvp(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.submit_poll_vote(UUID, INT) TO authenticated;

COMMIT;

-- Quick check after running (optional):
--   SELECT count(*) FROM facilities;            -- 6
--   SELECT count(*) FROM emergency_contacts;    -- 5
--   SELECT id, name FROM storage.buckets;       -- avatars, guard_evidence
