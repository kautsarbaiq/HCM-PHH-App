-- HCA ONLY — community codes are 3–6 digits (boss uses 001/002 style; the
-- PDF said 6-digit — allow both). Also rename the demo community's code.
ALTER TABLE public.communities DROP CONSTRAINT IF EXISTS communities_code_check;
ALTER TABLE public.communities
  ADD CONSTRAINT communities_code_check CHECK (code ~ '^[0-9]{3,6}$');

UPDATE public.communities SET code = '001' WHERE code = '100001';
