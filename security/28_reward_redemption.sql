-- ============================================================================
-- Boss 28/07: close the rewards loop — how the RESTAURANT redeems a voucher.
--
-- Flow: owner claims an offer -> management approves -> owner gets a voucher
-- with a QR code. At the shop the owner shows the QR; the shop scans it with
-- any phone camera, which opens a PUBLIC verify page (no app/login needed),
-- shows the voucher details, and lets them tap "Redeem". Once redeemed the
-- voucher is marked used and cannot be reused.
--
-- The QR encodes a URL carrying an unguessable voucher_token (uuid) — the token
-- is the bearer credential, so the public verify/redeem RPCs are safe to expose
-- to anon (only someone holding the voucher can present the token).
--
-- Run in BOTH SQL editors: PHH (kghiryjutwjgfdtbjtuq) AND the new HCA project
-- (dogbmkricfvaizjgjanu). Idempotent.
-- ============================================================================

ALTER TABLE public.reward_claims
  ADD COLUMN IF NOT EXISTS voucher_token uuid,
  ADD COLUMN IF NOT EXISTS redeemed_at   timestamptz;

-- Auto-issue an unguessable token the moment a claim becomes 'approved'.
CREATE OR REPLACE FUNCTION public.reward_claim_token()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.status = 'approved' AND NEW.voucher_token IS NULL THEN
    NEW.voucher_token := gen_random_uuid();
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS reward_claim_token_trg ON public.reward_claims;
CREATE TRIGGER reward_claim_token_trg
  BEFORE INSERT OR UPDATE ON public.reward_claims
  FOR EACH ROW EXECUTE FUNCTION public.reward_claim_token();

-- Backfill tokens for vouchers approved before this migration.
UPDATE public.reward_claims
   SET voucher_token = gen_random_uuid()
 WHERE voucher_token IS NULL AND status = 'approved';

-- ---------------------------------------------------------------------------
-- PUBLIC voucher lookup — the shop scans the QR (no account). Returns enough
-- to display + the current state (approved/redeemed).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.reward_voucher_info(p_token uuid)
RETURNS TABLE(
  offer_title      text,
  discount_percent integer,
  partner_name     text,
  partner_logo     text,
  owner_name       text,
  status           text,
  voucher_code     text,
  redeemed_at      timestamptz
) LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT o.title, o.discount_percent, p.name, p.logo_url,
         COALESCE(pr.full_name, 'Resident'), c.status, c.voucher_code, c.redeemed_at
  FROM public.reward_claims c
  JOIN public.reward_offers   o ON o.id = c.offer_id
  JOIN public.reward_partners p ON p.id = o.partner_id
  LEFT JOIN public.profiles  pr ON pr.id = c.owner_id
  WHERE c.voucher_token = p_token;
$$;
GRANT EXECUTE ON FUNCTION public.reward_voucher_info(uuid) TO anon, authenticated;

-- ---------------------------------------------------------------------------
-- PUBLIC redeem — the shop taps "Redeem". Marks the voucher used exactly once.
-- Returns {ok, error?, redeemed_at?}.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.redeem_voucher(p_token uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE c public.reward_claims%rowtype;
BEGIN
  SELECT * INTO c FROM public.reward_claims WHERE voucher_token = p_token;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_found');
  END IF;
  IF c.status <> 'approved' THEN
    RETURN jsonb_build_object('ok', false, 'error', 'not_active');
  END IF;
  IF c.redeemed_at IS NOT NULL THEN
    RETURN jsonb_build_object('ok', false, 'error', 'already',
                              'redeemed_at', c.redeemed_at);
  END IF;
  UPDATE public.reward_claims SET redeemed_at = now() WHERE id = c.id;
  RETURN jsonb_build_object('ok', true, 'redeemed_at', now());
END $$;
GRANT EXECUTE ON FUNCTION public.redeem_voucher(uuid) TO anon, authenticated;

-- Verify:
--   SELECT voucher_token, status, redeemed_at FROM reward_claims;
