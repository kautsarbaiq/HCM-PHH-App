-- ==============================================================================
-- HCM APP - SUPABASE POSTGRESQL SCHEMA & RLS POLICIES
-- Paste this entire script into your Supabase SQL Editor and click "Run"
-- ==============================================================================

-- 1. PROFILES (Extends Supabase Auth)
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  avatar_url TEXT,
  role TEXT NOT NULL CHECK (role IN ('admin', 'resident', 'guard')),
  house_id UUID, -- Will be a foreign key to houses later
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Auto-create profile on signup
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'role', 'resident')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Helper Functions
CREATE OR REPLACE FUNCTION get_user_role() RETURNS TEXT AS $$
  SELECT role FROM profiles WHERE id = auth.uid();
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_admin() RETURNS BOOLEAN AS $$
  SELECT EXISTS(SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_guard() RETURNS BOOLEAN AS $$
  SELECT EXISTS(SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'guard');
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- 2. HOUSES
CREATE TABLE houses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  house_number TEXT NOT NULL UNIQUE,
  house_type TEXT NOT NULL DEFAULT 'Type A',
  status TEXT NOT NULL DEFAULT 'vacant' CHECK (status IN ('occupied', 'vacant')),
  owner_id UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add foreign key constraint to profiles after houses is created
ALTER TABLE profiles ADD CONSTRAINT profiles_house_id_fkey FOREIGN KEY (house_id) REFERENCES houses(id);

-- 3. VISITORS
CREATE TABLE visitors (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  visitor_name TEXT NOT NULL,
  purpose TEXT DEFAULT 'Guest',
  vehicle_plate TEXT,
  house_id UUID NOT NULL REFERENCES houses(id),
  qr_token TEXT UNIQUE DEFAULT encode(gen_random_bytes(32), 'hex'),
  status TEXT NOT NULL DEFAULT 'expected' CHECK (status IN ('expected', 'checked_in', 'checked_out', 'cancelled')),
  expected_at TIMESTAMPTZ,
  checked_in_at TIMESTAMPTZ,
  checked_out_at TIMESTAMPTZ,
  created_by UUID NOT NULL REFERENCES profiles(id),
  checked_in_by UUID REFERENCES profiles(id),
  visitor_photo_url TEXT,
  vehicle_photo_url TEXT,
  license_photo_url TEXT,
  registration_type TEXT NOT NULL DEFAULT 'pre-registered' CHECK (registration_type IN ('pre-registered', 'walk-in')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_visitors_qr_token ON visitors(qr_token);
CREATE INDEX idx_visitors_house_id ON visitors(house_id);

-- 4. ANNOUNCEMENTS
CREATE TABLE announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  is_urgent BOOLEAN NOT NULL DEFAULT FALSE,
  created_by UUID NOT NULL REFERENCES profiles(id),
  published_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 5. BANNERS
CREATE TABLE banners (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  image_url TEXT NOT NULL,
  link_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  sort_order INT NOT NULL DEFAULT 0,
  created_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 6. BILLINGS
CREATE TABLE billings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_number TEXT NOT NULL UNIQUE,
  house_id UUID NOT NULL REFERENCES houses(id),
  resident_id UUID NOT NULL REFERENCES profiles(id),
  title TEXT NOT NULL,
  amount DECIMAL(12,2) NOT NULL,
  due_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'unpaid' CHECK (status IN ('unpaid', 'paid', 'overdue')),
  paid_at TIMESTAMPTZ,
  payment_method TEXT,
  period TEXT,
  created_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 7. FEEDBACK TICKETS
CREATE TABLE feedback_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_number TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'resolved', 'closed')),
  category TEXT DEFAULT 'general',
  created_by UUID NOT NULL REFERENCES profiles(id),
  assigned_to UUID REFERENCES profiles(id),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 8. FACILITIES & BOOKINGS
CREATE TABLE facilities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  icon_name TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  max_capacity INT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE facility_bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  facility_id UUID NOT NULL REFERENCES facilities(id),
  resident_id UUID NOT NULL REFERENCES profiles(id),
  booking_date DATE NOT NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  status TEXT NOT NULL DEFAULT 'confirmed' CHECK (status IN ('pending', 'confirmed', 'cancelled', 'completed')),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 9. EVENTS
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  location TEXT,
  event_date TIMESTAMPTZ NOT NULL,
  end_date TIMESTAMPTZ,
  image_url TEXT,
  created_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 10. POLLS
CREATE TABLE polls (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  question TEXT NOT NULL,
  description TEXT,
  options JSONB NOT NULL DEFAULT '[]',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  expires_at TIMESTAMPTZ,
  created_by UUID NOT NULL REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE poll_votes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id UUID NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
  voter_id UUID NOT NULL REFERENCES profiles(id),
  option_index INT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(poll_id, voter_id)
);

-- 11. EMERGENCY ALERTS
CREATE TABLE emergency_alerts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  alert_type TEXT NOT NULL CHECK (alert_type IN ('panic', 'evacuation', 'roll_call', 'custom')),
  message TEXT,
  triggered_by UUID NOT NULL REFERENCES profiles(id),
  house_id UUID REFERENCES houses(id),
  is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
  resolved_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ==============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- Profiles
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_all" ON profiles FOR ALL USING (is_admin());
CREATE POLICY "user_read_own" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "user_update_own" ON profiles FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE POLICY "guard_read_all" ON profiles FOR SELECT USING (is_guard());

-- Houses
ALTER TABLE houses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_all" ON houses FOR ALL USING (is_admin());
CREATE POLICY "guard_read" ON houses FOR SELECT USING (is_guard());
CREATE POLICY "resident_read_own" ON houses FOR SELECT USING (owner_id = auth.uid());

-- Visitors
ALTER TABLE visitors ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_all" ON visitors FOR ALL USING (is_admin());
CREATE POLICY "guard_read" ON visitors FOR SELECT USING (is_guard());
CREATE POLICY "guard_insert" ON visitors FOR INSERT WITH CHECK (is_guard());
CREATE POLICY "guard_update" ON visitors FOR UPDATE USING (is_guard());
CREATE POLICY "resident_insert" ON visitors FOR INSERT WITH CHECK (house_id IN (SELECT id FROM houses WHERE owner_id = auth.uid()) AND created_by = auth.uid());
CREATE POLICY "resident_read_own" ON visitors FOR SELECT USING (house_id IN (SELECT id FROM houses WHERE owner_id = auth.uid()));

-- Announcements
ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_all" ON announcements FOR ALL USING (is_admin());
CREATE POLICY "all_read" ON announcements FOR SELECT USING (auth.uid() IS NOT NULL);

-- Banners
ALTER TABLE banners ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_all" ON banners FOR ALL USING (is_admin());
CREATE POLICY "all_read" ON banners FOR SELECT USING (auth.uid() IS NOT NULL AND is_active = true);

-- Billings
ALTER TABLE billings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_all" ON billings FOR ALL USING (is_admin());
CREATE POLICY "resident_read_own" ON billings FOR SELECT USING (resident_id = auth.uid());

-- Feedback Tickets
ALTER TABLE feedback_tickets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_all" ON feedback_tickets FOR ALL USING (is_admin());
CREATE POLICY "resident_insert" ON feedback_tickets FOR INSERT WITH CHECK (created_by = auth.uid());
CREATE POLICY "resident_read_own" ON feedback_tickets FOR SELECT USING (created_by = auth.uid());

-- Facilities
ALTER TABLE facilities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "all_read" ON facilities FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "admin_all" ON facilities FOR ALL USING (is_admin());

-- Facility Bookings
ALTER TABLE facility_bookings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_all" ON facility_bookings FOR ALL USING (is_admin());
CREATE POLICY "resident_insert" ON facility_bookings FOR INSERT WITH CHECK (resident_id = auth.uid());
CREATE POLICY "resident_read_own" ON facility_bookings FOR SELECT USING (resident_id = auth.uid());
CREATE POLICY "resident_update_own" ON facility_bookings FOR UPDATE USING (resident_id = auth.uid());

-- Events
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "all_read" ON events FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "admin_all" ON events FOR ALL USING (is_admin());

-- Polls
ALTER TABLE polls ENABLE ROW LEVEL SECURITY;
CREATE POLICY "all_read" ON polls FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "admin_all" ON polls FOR ALL USING (is_admin());

-- Poll Votes
ALTER TABLE poll_votes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "resident_insert" ON poll_votes FOR INSERT WITH CHECK (voter_id = auth.uid());
CREATE POLICY "resident_read_own" ON poll_votes FOR SELECT USING (voter_id = auth.uid());
CREATE POLICY "admin_all" ON poll_votes FOR ALL USING (is_admin());

-- Emergency Alerts
ALTER TABLE emergency_alerts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "admin_all" ON emergency_alerts FOR ALL USING (is_admin());
CREATE POLICY "resident_insert" ON emergency_alerts FOR INSERT WITH CHECK (triggered_by = auth.uid());
CREATE POLICY "all_read" ON emergency_alerts FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "guard_read" ON emergency_alerts FOR SELECT USING (is_guard());
