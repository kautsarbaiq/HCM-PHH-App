-- ============================================================================
-- 03_verify_rls.sql  —  Catalog-level pass/fail after the fix. READ-ONLY.
-- Expected result: ZERO rows. Any row returned is an outstanding finding.
-- (Pair this with the behavioural anon REST probe in security/anon_probe.sh.)
-- ============================================================================

-- Finding 1: any base table in `public` with RLS disabled.
SELECT 'RLS_DISABLED' AS finding, c.relname AS object, '' AS detail
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind = 'r' AND c.relrowsecurity = false

UNION ALL

-- Finding 2: any policy that lets the anon (or public) role read rows
-- permissively, i.e. a SELECT/ALL policy whose USING clause is true / absent.
SELECT 'ANON_PERMISSIVE_POLICY' AS finding,
       tablename || ' / ' || policyname AS object,
       'cmd=' || cmd || ' roles=' || array_to_string(roles, ',') AS detail
FROM pg_policies
WHERE schemaname = 'public'
  AND cmd IN ('SELECT', 'ALL')
  AND (roles && ARRAY['anon','public']::name[])
  AND (qual IS NULL OR btrim(lower(qual)) = 'true')

ORDER BY 1, 2;
