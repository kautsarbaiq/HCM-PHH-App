-- ============================================================================
-- HCM — pre-launch backend setup
-- Run ONCE in the Supabase SQL editor. Idempotent: safe to re-run.
-- Covers everything the recent app changes need to work end-to-end.
-- ============================================================================

-- 1) Resident <-> house ownership ------------------------------------------------
-- Backfill houses.owner_id from profiles.house_id. The visitors INSERT policy
-- and the house-based billing form key off houses.owner_id, so without this an
-- admin-assigned resident can't pre-register a visitor and can't be billed.
UPDATE houses h
SET owner_id = p.id
FROM profiles p
WHERE p.house_id = h.id
  AND h.owner_id IS NULL;

-- 2) Full house address column ---------------------------------------------------
ALTER TABLE houses ADD COLUMN IF NOT EXISTS address text;

-- 3) Visitor evidence photos -----------------------------------------------------
-- guard_evidence is a PRIVATE bucket; the app reads photos via signed URLs.
-- Allow guards & admins to SELECT objects so signing succeeds.
DROP POLICY IF EXISTS "staff read guard_evidence" ON storage.objects;
CREATE POLICY "staff read guard_evidence" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'guard_evidence'
    AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role IN ('guard','admin'))
  );

-- 4) Resident personal documents (table) ----------------------------------------
CREATE TABLE IF NOT EXISTS resident_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  created_at timestamptz DEFAULT now()
);
ALTER TABLE resident_documents ADD COLUMN IF NOT EXISTS user_id uuid REFERENCES profiles(id);
ALTER TABLE resident_documents ADD COLUMN IF NOT EXISTS document_type text;
ALTER TABLE resident_documents ADD COLUMN IF NOT EXISTS reference_code text;
ALTER TABLE resident_documents ADD COLUMN IF NOT EXISTS file_url text;
ALTER TABLE resident_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "res_docs insert own" ON resident_documents;
CREATE POLICY "res_docs insert own" ON resident_documents
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "res_docs read own" ON resident_documents;
CREATE POLICY "res_docs read own" ON resident_documents
  FOR SELECT TO authenticated USING (user_id = auth.uid());

DROP POLICY IF EXISTS "res_docs admin read" ON resident_documents;
CREATE POLICY "res_docs admin read" ON resident_documents
  FOR SELECT TO authenticated
  USING (EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin'));

-- 5) Resident documents storage bucket (private) + policies ----------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('resident_documents', 'resident_documents', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "res_doc upload own" ON storage.objects;
CREATE POLICY "res_doc upload own" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'resident_documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "res_doc read own" ON storage.objects;
CREATE POLICY "res_doc read own" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'resident_documents'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS "res_doc admin read" ON storage.objects;
CREATE POLICY "res_doc admin read" ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'resident_documents'
    AND EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'admin')
  );

-- ============================================================================
-- Also verify (not SQL-fixable here):
--   * admin@hcm.com still has profiles.role = 'admin'
--   * Supabase Auth email-confirmation setting matches the sign-up UX
-- ============================================================================
