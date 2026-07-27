-- ============================================================================
-- Boss feedback 27/07: reward partner (company) needs a LOGO / picture, not
-- just a name. Logos are uploaded to the public 'avatars' bucket under the
-- 'reward-logos/' prefix (existing policies already allow authenticated write
-- + public read), and the URL is stored here.
--
-- Run in BOTH SQL editors: PHH (kghiryjutwjgfdtbjtuq) AND the new HCA project
-- (dogbmkricfvaizjgjanu).
-- ============================================================================
ALTER TABLE public.reward_partners
  ADD COLUMN IF NOT EXISTS logo_url text;
