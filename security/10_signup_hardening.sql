-- ============================================================================
-- HCM — Signup hardening
-- Run ONCE in the Supabase SQL editor. Idempotent: safe to re-run.
--
-- The old handle_new_user() copied `role` from the signup metadata, which let
-- ANYONE register themselves as admin by crafting the signup request.
-- New accounts are ALWAYS residents; admins/guards are promoted by an admin.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
  INSERT INTO public.profiles (id, full_name, email, role)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', ''),
    NEW.email,
    'resident'  -- never trust a role sent by the client
  );
  RETURN NEW;
END;
$function$;
