-- ============================================================================
-- 00_audit_oneshot.sql  —  READ-ONLY. For the Supabase SQL Editor.
-- Returns ONE row / ONE cell of JSON so the whole audit can be copied at once
-- (the editor only shows the last statement's grid, so everything is folded
--  into a single query). Nothing here changes data or schema.
-- ============================================================================
SELECT json_build_object(

  -- Headline: is RLS actually enabled on the two leaking tables?
  'headline', json_build_object(
    'houses_rls_enabled',   (SELECT c.relrowsecurity FROM pg_class c
                               JOIN pg_namespace n ON n.oid=c.relnamespace
                               WHERE n.nspname='public' AND c.relname='houses'),
    'visitors_rls_enabled', (SELECT c.relrowsecurity FROM pg_class c
                               JOIN pg_namespace n ON n.oid=c.relnamespace
                               WHERE n.nspname='public' AND c.relname='visitors')
  ),

  -- Every base table in public: RLS on/off, forced, and policy count.
  'tables', (
    SELECT json_agg(json_build_object(
      'table', c.relname,
      'rls_enabled', c.relrowsecurity,
      'rls_forced', c.relforcerowsecurity,
      'policy_count', (SELECT count(*) FROM pg_policies p
                         WHERE p.schemaname='public' AND p.tablename=c.relname)
    ) ORDER BY c.relrowsecurity, c.relname)
    FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
    WHERE n.nspname='public' AND c.relkind='r'
  ),

  -- Every policy: which command, which roles, and the USING / CHECK expressions.
  'policies', (
    SELECT json_agg(json_build_object(
      'table', tablename, 'policy', policyname, 'cmd', cmd,
      'roles', roles, 'using', qual, 'check', with_check
    ) ORDER BY tablename, cmd, policyname)
    FROM pg_policies WHERE schemaname='public'
  ),

  -- Table-level GRANTs to anon / authenticated / public.
  'anon_grants', (
    SELECT json_agg(json_build_object(
      'table', table_name, 'grantee', grantee, 'privilege', privilege_type
    ) ORDER BY table_name, grantee, privilege_type)
    FROM information_schema.role_table_grants
    WHERE table_schema='public'
      AND lower(grantee::text) IN ('anon','authenticated','public')
  ),

  -- Helper functions the policies depend on.
  'helper_functions', (
    SELECT json_agg(json_build_object(
      'name', p.proname, 'security_definer', p.prosecdef,
      'returns', pg_get_function_result(p.oid)
    ) ORDER BY p.proname)
    FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
    WHERE n.nspname='public' AND p.proname IN ('is_admin','is_guard','get_user_role')
  )

) AS audit;
