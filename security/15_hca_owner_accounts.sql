-- HCA point 16: admin-created house-owner login accounts.
-- Adds an IC number column to profiles so the admin-entered identity-card
-- number is stored with the owner's profile. Applied to the HCA database only
-- (PHH is a separate database and is untouched).

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS ic_number text;

-- The actual account creation is done by the `admin-create-owner` Edge Function
-- using the service_role key (only the service role may create auth users).
-- The function verifies the caller is an admin, creates the auth user, then
-- stamps the resulting profile with full_name / phone / ic_number / house_id /
-- resident_type='owner' and the admin's community_id, and links the house's
-- owner_id. No extra RLS is needed because the function bypasses RLS.
