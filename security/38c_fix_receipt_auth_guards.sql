-- ============================================================================
-- SECURITY FIX — run this immediately on BOTH projects.
--   PHH kghiryjutwjgfdtbjtuq   HCA dogbmkricfvaizjgjanu
--
-- WHAT WAS WRONG
--   Both functions from 38 guarded with a plain comparison against auth.uid(),
--   which is NULL for an unauthenticated caller:
--
--     IF v_role NOT IN ('admin','super_admin') THEN RAISE ...
--     IF v_owner <> auth.uid() AND v_owner <> my_household_id() THEN RAISE ...
--
--   In SQL, NULL NOT IN (...) is NULL, not TRUE — and an IF on a NULL
--   condition simply does not fire. So the guard was skipped entirely and
--   execution fell straight through to the UPDATE.
--
--   Proved by calling confirm_payment with only the anon key: it answered
--   204, not "Only management can confirm a payment". Nothing was changed
--   only because the billing id used was a dummy; with a real id an
--   unauthenticated caller could have marked any bill paid.
--
-- THE FIX
--   * refuse outright when auth.uid() IS NULL, before any other check
--   * compare with IS DISTINCT FROM, which is TRUE when one side is NULL
--     instead of returning NULL
--   * COALESCE the role so a missing profile cannot slip through
--   * raise when the UPDATE matched nothing, so a wrong id is an error rather
--     than a silent success
--
-- Idempotent. The last statement prints a result so you can see it ran.
-- ============================================================================

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
  v_caller uuid := auth.uid();
  v_owner  uuid;
  v_status text;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT b.resident_id, b.status INTO v_owner, v_status
  FROM public.billings b
  WHERE b.id = p_billing_id;

  IF v_owner IS NULL THEN
    RAISE EXCEPTION 'Bill not found';
  END IF;

  -- The bill may belong to the household's main account rather than the
  -- signed-in sub-login, so accept either. IS DISTINCT FROM, not <>: with <>
  -- a NULL on either side makes the whole condition NULL and the guard never
  -- fires.
  IF v_owner IS DISTINCT FROM v_caller
     AND v_owner IS DISTINCT FROM public.my_household_id() THEN
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

CREATE OR REPLACE FUNCTION public.confirm_payment(p_billing_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_caller uuid := auth.uid();
  v_role   text;
  v_hit    integer;
BEGIN
  IF v_caller IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  SELECT role INTO v_role FROM public.profiles WHERE id = v_caller;

  -- COALESCE so a caller with no profile row is treated as unauthorised
  -- rather than slipping past a NULL comparison.
  IF COALESCE(v_role, '') NOT IN ('admin', 'super_admin') THEN
    RAISE EXCEPTION 'Only management can confirm a payment';
  END IF;

  UPDATE public.billings
  SET status = 'paid',
      paid_at = now(),
      payment_confirmed_by = v_caller
  WHERE id = p_billing_id;

  GET DIAGNOSTICS v_hit = ROW_COUNT;
  IF v_hit = 0 THEN
    RAISE EXCEPTION 'Bill not found';
  END IF;
END;
$function$;

GRANT EXECUTE ON FUNCTION public.submit_payment_receipt(uuid, text)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.confirm_payment(uuid) TO authenticated;

-- Proof it ran: both must say true.
SELECT
  to_regprocedure('public.submit_payment_receipt(uuid,text)') IS NOT NULL
    AS submit_fixed,
  to_regprocedure('public.confirm_payment(uuid)') IS NOT NULL
    AS confirm_fixed;
