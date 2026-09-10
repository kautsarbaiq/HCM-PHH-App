#!/usr/bin/env python3
"""Creates the owner + resident pair Google Play reviewers need to test the app.

WHY A SCRIPT
    Doing this by hand means the web admin portal for the owner, then signing
    into the phone as that owner to add the family login. Two devices, two
    portals. This does both in one command.

    It deliberately does NOT invent the passwords — you pass them in. Login
    credentials should only ever exist where you put them.

WHAT IT CREATES
    1. an OWNER account, attached to a house, approved, house marked occupied
    2. a RESIDENT account as that owner's family login, inheriting the same
       house and community so the reviewer sees real screens, not empty ones

    This mirrors what `admin-create-owner` and `resident-create-sublogin` do
    server-side, so the accounts are indistinguishable from ones made in-app.

USAGE
    export SUPABASE_URL=https://dogbmkricfvaizjgjanu.supabase.co
    export SUPABASE_SERVICE_ROLE_KEY=<service role key>
    export OWNER_PASSWORD='...'          # you choose these
    export RESIDENT_PASSWORD='...'

    python3 scripts/make_test_accounts.py \
        --owner-email play.owner@example.com \
        --resident-email play.resident@example.com

    Add --house-id <uuid> to pin a specific house, otherwise it picks a vacant
    one (and tells you which).

AFTERWARDS
    Reviewers are likely to try Delete Account — it is the feature the stores
    require. A deleted account is blocked permanently, so create TWO pairs and
    give Google one spare, or expect to re-run this between review rounds.
"""

import argparse
import json
import os
import sys
import urllib.error
import urllib.request

MIN_PASSWORD = 6


def _env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        sys.exit(f"error: {name} is not set. See the header of this file.")
    return value.rstrip("/") if name.endswith("URL") else value


def _api(base: str, key: str, path: str, method="GET", body=None, prefer=None):
    url = f"{base}{path}"
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("apikey", key)
    req.add_header("Authorization", f"Bearer {key}")
    req.add_header("Content-Type", "application/json")
    if prefer:
        req.add_header("Prefer", prefer)
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else None
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode(errors="replace")
        raise SystemExit(f"error: {method} {path} -> HTTP {exc.code}\n  {detail}")


def create_auth_user(base, key, email, password, full_name, resident_type):
    """Same call the edge functions make: pre-confirmed so there is no email step."""
    created = _api(
        base, key, "/auth/v1/admin/users", "POST",
        {
            "email": email,
            "password": password,
            "email_confirm": True,
            "user_metadata": {
                "full_name": full_name,
                "resident_type": resident_type,
            },
        },
    )
    return created["id"]


def upsert_profile(base, key, row):
    _api(
        base, key, "/rest/v1/profiles", "POST", [row],
        prefer="resolution=merge-duplicates,return=minimal",
    )


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--owner-email", required=True)
    ap.add_argument("--resident-email", required=True)
    ap.add_argument("--owner-name", default="Play Test Owner")
    ap.add_argument("--resident-name", default="Play Test Resident")
    ap.add_argument("--house-id", default=None)
    args = ap.parse_args()

    base = _env("SUPABASE_URL")
    key = _env("SUPABASE_SERVICE_ROLE_KEY")
    owner_pw = _env("OWNER_PASSWORD")
    resident_pw = _env("RESIDENT_PASSWORD")

    for label, pw in (("OWNER_PASSWORD", owner_pw),
                      ("RESIDENT_PASSWORD", resident_pw)):
        if len(pw) < MIN_PASSWORD:
            sys.exit(f"error: {label} must be at least {MIN_PASSWORD} characters")

    # --- pick the house -------------------------------------------------
    if args.house_id:
        houses = _api(
            base, key,
            f"/rest/v1/houses?id=eq.{args.house_id}"
            "&select=id,house_number,community_id,owner_id",
        )
        if not houses:
            sys.exit(f"error: no house with id {args.house_id}")
    else:
        # Prefer a house nobody owns, so a real resident's data is never shown
        # to a Play reviewer.
        houses = _api(
            base, key,
            "/rest/v1/houses?owner_id=is.null"
            "&select=id,house_number,community_id,owner_id&limit=1",
        )
        if not houses:
            sys.exit(
                "error: every house already has an owner.\n"
                "  Create an empty house for testing, or pass --house-id."
            )
    house = houses[0]
    if house.get("owner_id") and not args.house_id:
        sys.exit("error: chosen house already has an owner")

    print(f"house      : {house.get('house_number')}  ({house['id']})")
    community_id = house.get("community_id")

    # --- owner ----------------------------------------------------------
    owner_id = create_auth_user(
        base, key, args.owner_email.lower(), owner_pw,
        args.owner_name, "owner",
    )
    upsert_profile(base, key, {
        "id": owner_id,
        "full_name": args.owner_name,
        "email": args.owner_email.lower(),
        "role": "resident",
        "resident_type": "owner",
        "house_id": house["id"],
        "community_id": community_id,
        "approval_status": "approved",
    })
    _api(
        base, key, f"/rest/v1/houses?id=eq.{house['id']}", "PATCH",
        {"owner_id": owner_id, "status": "occupied"}, prefer="return=minimal",
    )
    print(f"owner      : {args.owner_email}  ({owner_id})")

    # --- resident (family login under that owner) -----------------------
    resident_id = create_auth_user(
        base, key, args.resident_email.lower(), resident_pw,
        args.resident_name, "owner",
    )
    upsert_profile(base, key, {
        "id": resident_id,
        "full_name": args.resident_name,
        "email": args.resident_email.lower(),
        "role": "resident",
        "resident_type": "owner",
        "house_id": house["id"],
        "community_id": community_id,
        "approval_status": "approved",
        "parent_user_id": owner_id,
    })
    print(f"resident   : {args.resident_email}  ({resident_id})")

    # --- verify, rather than assume -------------------------------------
    check = _api(
        base, key,
        f"/rest/v1/profiles?id=in.({owner_id},{resident_id})"
        "&select=email,role,resident_type,house_id,community_id,"
        "approval_status,parent_user_id,deleted_at",
    )
    print("\nverification:")
    ok = True
    for row in check:
        problems = []
        if row["approval_status"] != "approved":
            problems.append("not approved")
        if row["house_id"] != house["id"]:
            problems.append("wrong house")
        if row.get("deleted_at"):
            problems.append("marked deleted")
        ok = ok and not problems
        state = "OK" if not problems else "PROBLEM: " + ", ".join(problems)
        print(f"  {row['email']:<34} {row['role']:<9} {state}")

    print(
        "\nGive Google BOTH logins. Reviewers often test Delete Account, and a\n"
        "deleted account can never sign in again — keep a spare pair ready."
    )
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
