-- ============================================================================
-- 01_audit_rls.sql  —  READ-ONLY diagnostics for the anon-read PII leak.
-- Run in Supabase SQL Editor, or:  psql "<conn>" -f security/01_audit_rls.sql
-- Nothing here modifies data or schema.
-- ============================================================================

-- A. Every base table in `public`: is RLS enabled / forced, and how many policies.
--    Tables with rls_enabled = false are exposed to the anon key (Supabase grants
--    anon broad table privileges and relies ENTIRELY on RLS to filter rows).
SELECT
  c.relname                                  AS table_name,
  c.relrowsecurity                           AS rls_enabled,
  c.relforcerowsecurity                      AS rls_forced,
  (SELECT count(*) FROM pg_policies p
     WHERE p.schemaname = 'public' AND p.tablename = c.relname) AS policy_count
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind = 'r'
ORDER BY c.relrowsecurity ASC, c.relname;   -- RLS-disabled tables float to the top

-- B. All policies in `public` (the USING/CHECK expressions and the roles they target).
--    A permissive read policy reachable by anon would have cmd SELECT/ALL,
--    roles including anon or public, and qual = true / NULL.
SELECT
  tablename,
  policyname,
  cmd,
  roles,
  qual        AS using_expr,
  with_check  AS check_expr
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, cmd, policyname;

-- C. Table-level GRANTs to the anon / authenticated / public roles.
--    (Supabase normally grants these; RLS is what actually protects the rows.)
SELECT
  table_name,
  grantee,
  string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privileges
FROM information_schema.role_table_grants
WHERE table_schema = 'public'
  AND grantee IN ('anon', 'authenticated', 'public')
GROUP BY table_name, grantee
ORDER BY table_name, grantee;

-- D. Helper functions the policies depend on (must exist & be SECURITY DEFINER).
SELECT p.proname, p.prosecdef AS security_definer, pg_get_function_result(p.oid) AS returns
FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public' AND p.proname IN ('is_admin','is_guard','get_user_role')
ORDER BY p.proname;
