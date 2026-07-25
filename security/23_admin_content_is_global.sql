-- Boss report 20/07: services added on the web admin didn't show on the phone.
--
-- Root cause: stamp_community() stamps every new row with the CREATOR's
-- community. The admin account lives in community 001, but the boss's phone
-- account (mbabar) is in Canal Garden (005) — so everything management added
-- via the web was invisible on his phone. Admin pages have no community
-- picker, so the stamp was arbitrary, not a choice.
--
-- Fix: content created by an ADMIN stays community_id NULL = global, visible
-- to every community. Resident-created content keeps being stamped to the
-- resident's own community (isolation between communities still works).
--
-- Run in BOTH SQL editors: PHH (kghiryjutwjgfdtbjtuq) and HCA (mlyycbiojsyqatmwdhef).

CREATE OR REPLACE FUNCTION public.stamp_community()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NEW.community_id IS NULL AND NOT public.is_admin() THEN
    NEW.community_id := public.my_community();
  END IF;
  RETURN NEW;
END $$;

-- Data fix: the marketplace is an estate-wide vendor directory — make every
-- existing listing global so no community's residents see an empty page.
-- (On PHH rows are already NULL; this is a no-op there.)
UPDATE public.marketplace_services SET community_id = NULL;
