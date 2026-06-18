#!/usr/bin/env bash
# ============================================================================
# anon_probe.sh — Behavioural test of the anon-read leak. READ-ONLY.
# Hits the live REST API with ONLY the public anon key (no user session) and
# reports, per table, whether rows come back (LEAK) or an empty set (OK).
#
# Usage:  bash security/anon_probe.sh
# Reads SUPABASE_URL / SUPABASE_ANON_KEY from .env. Keys are never printed.
# ============================================================================
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a
URL="$SUPABASE_URL"; KEY="$SUPABASE_ANON_KEY"

TABLES=(profiles houses visitors announcements banners billings
        feedback_tickets facilities facility_bookings events polls
        poll_votes emergency_alerts)

echo "Anon probe (no user session) -> $URL"
printf "%-20s | %-4s | %s\n" "TABLE" "HTTP" "RESULT"
printf -- "---------------------+------+----------------------------\n"
leaks=0
for t in "${TABLES[@]}"; do
  resp=$(curl -s -w $'\n%{http_code}' "$URL/rest/v1/$t?select=*&limit=2" \
           -H "apikey: $KEY" -H "Authorization: Bearer $KEY")
  code=$(printf '%s' "$resp" | tail -n1)
  body=$(printf '%s' "$resp" | sed '$d')
  if [ "$body" = "[]" ]; then
    verdict="OK (empty [])"
  elif printf '%s' "$body" | grep -q '^\['; then
    verdict="*** LEAK: rows returned ***"; leaks=$((leaks+1))
  else
    verdict=$(printf '%s' "$body" | tr -d '\n' | cut -c1-40)
  fi
  printf "%-20s | %-4s | %s\n" "$t" "$code" "$verdict"
done
echo ""
if [ "$leaks" -eq 0 ]; then
  echo "PASS: no table returned rows to the anon key."
else
  echo "FAIL: $leaks table(s) leaked rows to the anon key."
  exit 1
fi
