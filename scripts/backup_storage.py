#!/usr/bin/env python3
"""Backs up every file in Supabase Storage to a local folder.

WHY THIS EXISTS
    Supabase's database backups do NOT include Storage objects — only their
    metadata rows. Point-in-Time Recovery does not cover them either. So every
    resident photo, avatar and uploaded document currently has no backup at
    all: if a file is deleted, it is gone permanently.

    This script is the missing piece. It walks every bucket, downloads what has
    changed since the last run, and writes a manifest so the next run only
    fetches new or modified files.

USAGE
    export SUPABASE_URL=https://<project>.supabase.co
    export SUPABASE_SERVICE_ROLE_KEY=<service role key>
    python3 scripts/backup_storage.py /Volumes/Backup/hca-storage

    The destination should be somewhere that survives this laptop — an external
    drive, or a folder that syncs to Google Drive / Dropbox. Backing up to the
    same machine that runs the app protects against nothing.

WHY THE SERVICE ROLE KEY
    The anon key only sees what RLS allows, which is a subset — resident
    documents come back empty. A backup that silently skips the private files
    is worse than no backup, because it looks like it worked.

    The key is read from the environment on purpose. Never paste it into this
    file: anything committed to git is effectively public forever.
"""

import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.request

LIST_PAGE = 100
RETRIES = 3


def _env(name: str) -> str:
    value = os.environ.get(name, "").strip()
    if not value:
        sys.exit(
            f"error: {name} is not set.\n"
            "  export SUPABASE_URL=https://<project>.supabase.co\n"
            "  export SUPABASE_SERVICE_ROLE_KEY=<service role key>"
        )
    return value.rstrip("/")


def _request(url: str, key: str, method="GET", body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header("apikey", key)
    req.add_header("Authorization", f"Bearer {key}")
    if data is not None:
        req.add_header("Content-Type", "application/json")

    last = None
    for attempt in range(RETRIES):
        try:
            with urllib.request.urlopen(req, timeout=120) as resp:
                return resp.read()
        except urllib.error.HTTPError as exc:
            # 4xx will not fix itself; fail loudly rather than retry-looping.
            if 400 <= exc.code < 500:
                raise
            last = exc
        except (urllib.error.URLError, TimeoutError) as exc:
            last = exc
        time.sleep(2 ** attempt)
    raise last


def list_buckets(base: str, key: str):
    raw = _request(f"{base}/storage/v1/bucket", key)
    return [b["name"] for b in json.loads(raw)]


def walk(base: str, key: str, bucket: str, prefix: str = ""):
    """Yields (path, metadata) for every file under prefix, recursing folders."""
    offset = 0
    while True:
        raw = _request(
            f"{base}/storage/v1/object/list/{bucket}",
            key,
            method="POST",
            body={"prefix": prefix, "limit": LIST_PAGE, "offset": offset},
        )
        entries = json.loads(raw)
        if not entries:
            return
        for entry in entries:
            name = entry.get("name")
            if not name:
                continue
            path = f"{prefix}{name}"
            # Storage returns folders as entries with a null id.
            if entry.get("id") is None:
                yield from walk(base, key, bucket, f"{path}/")
            else:
                yield path, entry
        if len(entries) < LIST_PAGE:
            return
        offset += LIST_PAGE


def fingerprint(meta: dict) -> str:
    """Identifies a version of a file so unchanged ones are not re-downloaded."""
    inner = meta.get("metadata") or {}
    etag = (inner.get("eTag") or "").strip('"')
    if etag:
        return etag
    # Some objects carry no eTag; fall back to size + last-modified.
    return f"{inner.get('size')}-{meta.get('updated_at')}"


def main() -> int:
    if len(sys.argv) < 2:
        sys.exit(f"usage: {sys.argv[0]} <destination folder>")

    base = _env("SUPABASE_URL")
    key = _env("SUPABASE_SERVICE_ROLE_KEY")
    dest = os.path.abspath(sys.argv[1])
    os.makedirs(dest, exist_ok=True)

    manifest_path = os.path.join(dest, "manifest.json")
    try:
        with open(manifest_path) as fh:
            manifest = json.load(fh)
    except (FileNotFoundError, json.JSONDecodeError):
        manifest = {}

    project = base.split("//")[-1].split(".")[0]
    print(f"project     : {project}")
    print(f"destination : {dest}")

    buckets = list_buckets(base, key)
    print(f"buckets     : {', '.join(buckets) or '(none)'}\n")

    new = changed = skipped = failed = 0
    seen = set()

    for bucket in buckets:
        for path, meta in walk(base, key, bucket):
            rel = f"{bucket}/{path}"
            seen.add(rel)
            stamp = fingerprint(meta)
            target = os.path.join(dest, bucket, *path.split("/"))

            if manifest.get(rel) == stamp and os.path.exists(target):
                skipped += 1
                continue

            try:
                blob = _request(
                    f"{base}/storage/v1/object/{bucket}/{path}", key
                )
            except Exception as exc:  # noqa: BLE001 - report and keep going
                print(f"  FAILED {rel}: {exc}")
                failed += 1
                continue

            os.makedirs(os.path.dirname(target), exist_ok=True)
            # Write to a temp name first so an interrupted run cannot leave a
            # truncated file that the next run would treat as complete.
            tmp = target + ".part"
            with open(tmp, "wb") as fh:
                fh.write(blob)
            os.replace(tmp, target)

            if rel in manifest:
                changed += 1
                print(f"  updated {rel}")
            else:
                new += 1
                print(f"  new     {rel}")
            manifest[rel] = stamp

    # Files deleted upstream stay in the backup on purpose — that is the whole
    # point of a backup — but record them so the report is honest.
    removed = [k for k in manifest if k not in seen]

    with open(manifest_path, "w") as fh:
        json.dump(manifest, fh, indent=1, sort_keys=True)

    total = len(seen)
    print(
        f"\ndone: {total} file(s) in storage — "
        f"{new} new, {changed} updated, {skipped} unchanged, {failed} failed"
    )
    if removed:
        print(
            f"note: {len(removed)} file(s) are in the backup but no longer in "
            "storage (kept)"
        )
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
