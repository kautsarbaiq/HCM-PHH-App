-- ============================================================================
-- Payment receipts (boss request, PHH screenshots 4 & 5).
--
-- THE PROBLEM
--   "Pay Now" tells the resident online payment is not connected to a provider,
--   which is a dead end. Residents already pay by bank transfer; there is just
--   no way to prove it, and no way for the office to see the proof.
--
-- THE FLOW THE BOSS ASKED FOR
--   resident uploads receipt  ->  status becomes 'submitted'
--   office sees a receipt icon in Billings, opens it, marks the bill 'paid'
--
--   'submitted' is deliberately a separate state from 'paid': money has been
--   claimed, not confirmed. Only a human in the office moves it to 'paid',
--   so an uploaded photo can never by itself clear a debt.
--
-- RUN IN BOTH PROJECTS:
--   HCA  dogbmkricfvaizjgjanu
--   PHH  kghiryjutwjgfdtbjtuq
--
-- ORDER MATTERS ON PHH: submit_payment_receipt() calls my_household_id(),
-- which PHH does not have yet. Run security/37_PHH_catchup_33_to_36.sql there
-- FIRST, or this file fails at the function body.
--
-- Idempotent: safe to run more than once. Deletes no data.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- 1) Columns
-- ---------------------------------------------------------------------------
ALTER TABLE public.billings
  ADD COLUMN IF NOT EXISTS receipt_url text,
  ADD COLUMN IF NOT EXISTS receipt_uploaded_at timestamptz,
  -- Who actually confirmed the money arrived. Keeps the audit trail when a
  -- dispute comes up months later: a receipt photo is a claim, this is the
  -- decision.
  ADD COLUMN IF NOT EXISTS payment_confirmed_by uuid REFERENCES public.profiles(id);

COMMENT ON COLUMN public.billings.receipt_url IS
  'Storage path (not a public URL) of the resident''s payment proof in the '
  'payment_receipts bucket. Read through a signed URL.';

-- The office filters on this constantly ("show me what needs checking").
CREATE INDEX IF NOT EXISTS billings_submitted_idx
  ON public.billings (status)
  WHERE status = 'submitted';

-- ---------------------------------------------------------------------------
-- 2) Storage bucket — PRIVATE
--    A receipt shows a bank account and a name. It must never be readable by
--    guessing a URL, so this bucket is private and the app uses signed URLs.
-- ---------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('payment_receipts', 'payment_receipts', false)
ON CONFLICT (id) DO UPDATE SET public = false;

-- Residents upload into a folder named after their own user id, so one
-- resident can never read or overwrite another's receipt.
DROP POLICY IF EXISTS receipts_owner_insert ON storage.objects;
CREATE POLICY receipts_owner_insert ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'payment_receipts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

DROP POLICY IF EXISTS receipts_owner_read ON storage.objects;
CREATE POLICY receipts_owner_read ON storage.objects
  FOR SELECT TO authenticated
  USING (
    bucket_id = 'payment_receipts'
    AND (
      (storage.foldername(name))[1] = auth.uid()::text
      -- Management must be able to open any receipt to verify it.
      OR EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id = auth.uid() AND p.role IN ('admin', 'super_admin')
      )
    )
  );

-- A resident may replace their own receipt (wrong photo, unreadable scan)
-- but only while the office has not yet confirmed the payment.
DROP POLICY IF EXISTS receipts_owner_update ON storage.objects;
CREATE POLICY receipts_owner_update ON storage.objects
  FOR UPDATE TO authenticated
  USING (
    bucket_id = 'payment_receipts'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- ---------------------------------------------------------------------------
-- 3) Submitting a receipt
--    SECURITY DEFINER so a resident can move their own bill to 'submitted'
--    without being granted a general UPDATE on billings — otherwise the same
--    grant would let them set it to 'paid' themselves.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.submit_payment_receipt(
  p_billing_id uuid,
  p_receipt_path text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_owner uuid;
  v_status text;
BEGIN
  SELECT b.resident_id, b.status INTO v_owner, v_status
  FROM public.billings b
  WHERE b.id = p_billing_id;

  IF v_owner IS NULL THEN
    RAISE EXCEPTION 'Bill not found';
  END IF;

  -- The bill may belong to the household's main account rather than the
  -- signed-in sub-login, so accept either (mirrors the billings read policy).
  IF v_owner <> auth.uid() AND v_owner <> public.my_household_id() THEN
    RAISE EXCEPTION 'That bill does not belong to you';
  END IF;

  IF v_status = 'paid' THEN
    RAISE EXCEPTION 'This bill is already marked paid';
  END IF;

  UPDATE public.billings
  SET receipt_url = p_receipt_path,
      receipt_uploaded_at = now(),
      status = 'submitted'
  WHERE id = p_billing_id;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.submit_payment_receipt(uuid, text)
  TO authenticated;

-- ---------------------------------------------------------------------------
-- 4) Confirming payment — management only
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.confirm_payment(p_billing_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_role text;
BEGIN
  SELECT role INTO v_role FROM public.profiles WHERE id = auth.uid();
  IF v_role NOT IN ('admin', 'super_admin') THEN
    RAISE EXCEPTION 'Only management can confirm a payment';
  END IF;

  UPDATE public.billings
  SET status = 'paid',
      paid_at = now(),
      payment_confirmed_by = auth.uid()
  WHERE id = p_billing_id;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.confirm_payment(uuid) TO authenticated;
