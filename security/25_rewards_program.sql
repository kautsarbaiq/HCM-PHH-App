-- ============================================================================
-- Meeting 20/07 — Point 9: REWARDS program for house owners.
--
-- A loyalty scheme: management registers PARTNER brands (cafés, restaurants…)
-- and discount OFFERS keyed to how many consecutive monthly bills the owner has
-- paid ON TIME. Owners see what their streak unlocks and CLAIM an offer; an
-- admin approves the claim and issues a voucher code. Admin may also grant an
-- offer to a specific owner manually.
--
-- Run in BOTH SQL editors: PHH (kghiryjutwjgfdtbjtuq) AND HCA (mlyycbiojsyqatmwdhef).
-- Idempotent — safe to re-run.
-- ============================================================================

-- ---- Partner brands ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reward_partners (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id uuid REFERENCES public.communities(id),
  name         text NOT NULL,
  category     text,
  is_active    boolean NOT NULL DEFAULT true,
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- ---- Discount offers (tiers) ------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reward_offers (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id     uuid REFERENCES public.communities(id),
  partner_id       uuid REFERENCES public.reward_partners(id) ON DELETE CASCADE,
  title            text NOT NULL,
  description      text,
  discount_percent integer NOT NULL DEFAULT 0,
  -- Consecutive on-time bills an owner needs to unlock this offer.
  min_streak       integer NOT NULL DEFAULT 0,
  is_active        boolean NOT NULL DEFAULT true,
  created_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS reward_offers_partner_idx ON public.reward_offers(partner_id);

-- ---- Claims / grants --------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.reward_claims (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  community_id  uuid REFERENCES public.communities(id),
  offer_id      uuid REFERENCES public.reward_offers(id) ON DELETE CASCADE,
  owner_id      uuid REFERENCES public.profiles(id) ON DELETE CASCADE,
  status        text NOT NULL DEFAULT 'pending', -- pending | approved | rejected
  voucher_code  text,
  admin_remarks text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  decided_at    timestamptz,
  decided_by    uuid REFERENCES public.profiles(id)
);
CREATE INDEX IF NOT EXISTS reward_claims_owner_idx ON public.reward_claims(owner_id);

-- ---------------------------------------------------------------------------
-- On-time payment streak: how many of the most recent DUE bills the owner paid
-- on/before the due date, unbroken. Bills not yet due and still unpaid (the
-- current cycle) are ignored; a late or overdue-unpaid bill ends the streak.
-- ---------------------------------------------------------------------------
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
    IF rec.status = 'paid' AND rec.paid_at IS NOT NULL
       AND rec.paid_at::date <= rec.due_date THEN
      streak := streak + 1;
    ELSE
      EXIT; -- late payment or overdue-unpaid → streak ends
    END IF;
  END LOOP;
  RETURN streak;
END $$;

CREATE OR REPLACE FUNCTION public.my_ontime_streak()
RETURNS integer LANGUAGE sql SECURITY DEFINER STABLE AS $$
  SELECT public.owner_ontime_streak(auth.uid());
$$;
GRANT EXECUTE ON FUNCTION public.my_ontime_streak() TO authenticated;
GRANT EXECUTE ON FUNCTION public.owner_ontime_streak(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- Stamp the creator's community on new reward rows (always — rewards are
-- managed per community, unlike the global admin content in migration 23).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.stamp_community_always()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.community_id IS NULL THEN
    NEW.community_id := public.my_community();
  END IF;
  RETURN NEW;
END $$;

DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['reward_partners','reward_offers','reward_claims'] LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS stamp_community_trg ON public.%I', t);
    EXECUTE format(
      'CREATE TRIGGER stamp_community_trg BEFORE INSERT ON public.%I
       FOR EACH ROW EXECUTE FUNCTION public.stamp_community_always()', t);
  END LOOP;
END $$;

-- ---------------------------------------------------------------------------
-- RLS
-- ---------------------------------------------------------------------------
ALTER TABLE public.reward_partners ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reward_offers   ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reward_claims   ENABLE ROW LEVEL SECURITY;

-- Partners & offers: everyone in the community can read; only admins write.
DO $$
DECLARE t text;
BEGIN
  FOREACH t IN ARRAY ARRAY['reward_partners','reward_offers'] LOOP
    EXECUTE format('DROP POLICY IF EXISTS "rw_read" ON public.%I', t);
    EXECUTE format(
      'CREATE POLICY "rw_read" ON public.%I FOR SELECT TO authenticated
       USING (community_id IS NULL OR community_id = public.my_community())', t);
    EXECUTE format('DROP POLICY IF EXISTS "rw_admin_write" ON public.%I', t);
    EXECUTE format(
      'CREATE POLICY "rw_admin_write" ON public.%I FOR ALL TO authenticated
       USING (public.is_admin()) WITH CHECK (public.is_admin())', t);
  END LOOP;
END $$;

-- Claims: owner sees & creates their own; admin sees & manages the community's.
DROP POLICY IF EXISTS "rc_owner_read" ON public.reward_claims;
CREATE POLICY "rc_owner_read" ON public.reward_claims FOR SELECT TO authenticated
  USING (owner_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "rc_owner_insert" ON public.reward_claims;
CREATE POLICY "rc_owner_insert" ON public.reward_claims FOR INSERT TO authenticated
  WITH CHECK (owner_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS "rc_admin_update" ON public.reward_claims;
CREATE POLICY "rc_admin_update" ON public.reward_claims FOR UPDATE TO authenticated
  USING (public.is_admin()) WITH CHECK (public.is_admin());

-- ---- Realtime ---------------------------------------------------------------
DO $$
BEGIN
  FOR i IN 1..1 LOOP
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND tablename='reward_claims') THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.reward_claims;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname='supabase_realtime' AND tablename='reward_offers') THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE public.reward_offers;
    END IF;
  END LOOP;
END $$;
