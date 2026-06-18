-- ============================================================================
-- 05_verify_final.sql  —  READ-ONLY. Compact JSON confirmation of the end state.
-- Run after 04_harden_live.sql. Expected:
--   remaining_anon_read_leaks : []
--   rls_disabled_tables       : []
--   houses_policies           : admin_all(ALL), guard_read, resident_read_own
--   visitors_policies         : admin_all(ALL), guard_read/insert/update, resident_insert/read_own
--   emergencies_policies      : auth_read_emergencies, admin_all(ALL), Residents can create emergencies
-- ============================================================================
SELECT json_build_object(

  'remaining_anon_read_leaks', (
    SELECT COALESCE(json_agg(json_build_object(
      'table', tablename, 'policy', policyname, 'cmd', cmd, 'using', qual)), '[]'::json)
    FROM pg_policies
    WHERE schemaname='public' AND cmd IN ('SELECT','ALL')
      AND roles && ARRAY['anon','public']::name[]
      AND (qual IS NULL OR btrim(lower(qual))='true')
  ),

  'rls_disabled_tables', (
    SELECT COALESCE(json_agg(c.relname ORDER BY c.relname), '[]'::json)
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public' AND c.relkind='r' AND c.relrowsecurity=false
  ),

  'houses_policies', (
    SELECT COALESCE(json_agg(json_build_object(
      'policy', policyname, 'cmd', cmd, 'using', qual, 'check', with_check) ORDER BY cmd, policyname), '[]'::json)
    FROM pg_policies WHERE schemaname='public' AND tablename='houses'
  ),

  'visitors_policies', (
    SELECT COALESCE(json_agg(json_build_object(
      'policy', policyname, 'cmd', cmd, 'using', qual, 'check', with_check) ORDER BY cmd, policyname), '[]'::json)
    FROM pg_policies WHERE schemaname='public' AND tablename='visitors'
  ),

  'emergencies_policies', (
    SELECT COALESCE(json_agg(json_build_object(
      'policy', policyname, 'cmd', cmd, 'using', qual, 'check', with_check) ORDER BY cmd, policyname), '[]'::json)
    FROM pg_policies WHERE schemaname='public' AND tablename='emergencies'
  )

) AS verify;
