-- ============================================================================
-- HCM — Walk-in visitor ID OCR fields
-- Run ONCE in the Supabase SQL editor. Idempotent: safe to re-run.
-- The guard walk-in registration scans the visitor's driving license / IC with
-- the `scan-id` Edge Function (Gemini) and stores the extracted data here.
-- ============================================================================

ALTER TABLE public.visitors ADD COLUMN IF NOT EXISTS id_number  text;
ALTER TABLE public.visitors ADD COLUMN IF NOT EXISTS id_details jsonb;

-- No RLS changes needed: guards/admins already read+write visitors, and these
-- are just extra columns on the same rows.
