-- ============================================================================
-- Boss test 28/07 (point 9 NOT PASS): marking an invoice "Paid" did not raise
-- the owner's on-time streak. Root cause: the admin "mark as Paid" only set
-- status='paid' and left billings.paid_at NULL, but the streak needs a paid
-- date to judge on-time.
--
-- Fix (three parts):
--   1. A trigger stamps paid_at automatically whenever a bill becomes 'paid'
--      (and clears it when it goes back to unpaid) — works no matter which
--      screen updates the bill.
--   2. Backfill paid_at for bills already marked paid with no timestamp.
--   3. owner_ontime_streak treats a paid bill with no timestamp as on-time,
--      so nothing slips through.
--
-- Run in BOTH SQL editors: PHH (kghiryjutwjgfdtbjtuq) AND the new HCA project
-- (dogbmkricfvaizjgjanu). Idempotent.
-- ============================================================================

-- 1) Auto-stamp paid_at.
CREATE OR REPLACE FUNCTION public.billing_paid_stamp()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status = 'paid' AND NEW.paid_at IS NULL THEN
    NEW.paid_at := now();
  ELSIF NEW.status <> 'paid' THEN
    NEW.paid_at := NULL;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS billing_paid_stamp_trg ON public.billings;
CREATE TRIGGER billing_paid_stamp_trg
  BEFORE INSERT OR UPDATE ON public.billings
  FOR EACH ROW EXECUTE FUNCTION public.billing_paid_stamp();

-- 2) Backfill existing paid-but-untimed bills (assume paid around creation).
UPDATE public.billings
   SET paid_at = COALESCE(created_at, now())
 WHERE status = 'paid' AND paid_at IS NULL;

-- 3) Lenient streak: a paid bill with no timestamp still counts as on-time.
CREATE OR REPLACE FUNCTION public.owner_ontime_streak(p_uid uuid)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER STABLE AS $$
DECLARE rec record; streak int := 0;
BEGIN
  FOR rec IN
    SELECT status, due_date, paid_at
    FROM public.billings
    WHERE resident_id = p_uid
    ORDER BY due_date DESC
  LOOP
    IF rec.status <> 'paid' AND rec.due_date >= CURRENT_DATE THEN
      CONTINUE; -- current/future unpaid bill — neither counts nor breaks
    END IF;
    IF rec.status = 'paid'
       AND (rec.paid_at IS NULL OR rec.paid_at::date <= rec.due_date) THEN
      streak := streak + 1;
    ELSE
      EXIT; -- late payment or overdue-unpaid → streak ends
    END IF;
  END LOOP;
  RETURN streak;
END $$;

-- Verify:
--   SELECT title, status, due_date, paid_at FROM billings ORDER BY created_at DESC;
--   SELECT public.owner_ontime_streak('<owner-uuid>');
