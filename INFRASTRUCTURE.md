# Infrastructure checklist (HomeCloudAsia)

Four things, cheapest and most urgent first. Only item 1 is code — the rest are
account actions that need a card or a login, so they cannot be scripted here.

---

## 1. Storage backup — FREE, and the biggest gap today

**Supabase does not back up uploaded files.** Daily backups and Point-in-Time
Recovery cover the database only; Storage objects have their metadata rows
backed up but not the files themselves. Right now every resident photo, avatar
and uploaded document would be lost permanently if deleted.

`scripts/backup_storage.py` closes that. No dependencies — plain Python 3.

```bash
export SUPABASE_URL=https://dogbmkricfvaizjgjanu.supabase.co
export SUPABASE_SERVICE_ROLE_KEY=<service role key from the dashboard>
python3 scripts/backup_storage.py /Volumes/Backup/hca-storage
```

Point it somewhere that **survives this laptop** — an external drive, or a
folder that syncs to Google Drive / Dropbox. A backup living on the same
machine as everything else protects against nothing.

The first run downloads everything. Later runs only fetch files that are new or
changed, so it is cheap to run often. It never deletes from the backup: a file
removed upstream stays in the copy, which is the point.

**Never put the service role key in a file that git tracks.** It is read from
the environment for exactly that reason.

### Running it automatically (macOS)

```bash
crontab -e
```

Add one line — 2am daily:

```
0 2 * * * cd "/Users/macbookpro/Documents/Magang bule soft/HCM app" && SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... /usr/bin/python3 scripts/backup_storage.py /Volumes/Backup/hca-storage >> /tmp/hca-backup.log 2>&1
```

Check `/tmp/hca-backup.log` occasionally. A backup nobody verifies is a backup
that quietly stopped working months ago.

---

## 2. `app.homecloudasia.com` → Vercel — FREE, do this next

The web portal still runs on `home-cloudasia.vercel.app`, an address Vercel
owns, not us. That address is **printed inside voucher QR codes**. If we ever
leave Vercel, every already-printed QR code stops resolving forever, and no app
update can fix it — the paper is already out there.

`homecloudasia.com` is registered at GoDaddy and uses GoDaddy's own nameservers
(`NS43/NS44.DOMAINCONTROL.COM`), so the record can be added directly there.

1. **Vercel** → project → Settings → Domains → Add `app.homecloudasia.com`.
   Vercel shows a CNAME target **unique to that project**, something like
   `d1d4fc829fe7bc7c.vercel-dns-017.com`. The old generic `cname.vercel-dns.com`
   is no longer what Vercel hands out — copy whatever the dashboard shows.
2. **GoDaddy** → Domain → DNS → Add record:
   - Type `CNAME`, Name `app`, Value = the target from step 1.
3. Wait for it to verify. SSL is issued automatically.

The marketing site on the apex domain is untouched by this.

Then rebuild once so the app stops emitting Vercel links:

```bash
flutter build apk --release --flavor hca --dart-define=BRAND=hca --dart-define=WEB_BASE_URL=https://app.homecloudasia.com
```

No code change is needed — `Brand.webBaseUrl` already reads that flag.

⚠️ The domain expires **2027-07-03**. Turn on auto-renew. If it lapses, the
printed QR codes die with it.

---

## 3. Supabase Custom Domain — $10/month, needs a paid plan

Gives `api.homecloudasia.com` instead of `dogbmkricfvaizjgjanu.supabase.co`,
so moving Supabase projects no longer forces an app rebuild and a store review.

Real cost: **$10/month per project, and it requires a paid plan** — Pro is
$25/month. On the Free plan the true figure is $35/month, not $10.

⚠️ **This alone does not remove the rebuild.** The anon key is a JWT signed by
the project's own secret, and it carries the project ref inside it:

```json
{ "iss": "supabase", "ref": "dogbmkricfvaizjgjanu", "role": "anon" }
```

A new project issues a new key even behind the same domain. To actually migrate
without rebuilding, the old **JWT secret must be copied into the new project**
as well. Custom domain + JWT secret carried over — both, or neither works.

---

## 4. Point-in-Time Recovery — $100/month per 7 days retention

Restores the database to any moment, losing at most 2 minutes of data.

This protects against the failure that is by far the most likely: a bad
migration, an accidental delete, corrupted data. Note that a hot standby
database does **not** protect against those — it would replicate the mistake
faithfully and instantly.

Requires at least the Small compute add-on.

---

## What is NOT possible, and why

The original plan — a live database and a synced backup database, switching the
domain over on failure — cannot be built on Supabase:

- A custom domain attaches to **one** project. It cannot be repointed to
  another project as a failover mechanism.
- **Logins would not survive the switch.** User accounts and passwords live in
  the database's `auth` schema, and there is no supported way to replicate that
  between two Supabase projects. Users would reach the backup and be unable to
  sign in. Working around it means copying password hashes between projects,
  which is fragile and a security risk in itself.
- **Read Replicas** are read-only, live inside the *same* project, and
  explicitly cannot serve Auth, Storage or Realtime.
- Supabase confirms it does **not** offer automatic cross-region failover
  outside Enterprise plans.

If the business genuinely needs a hot standby, that is an Enterprise
conversation with Supabase — it cannot be assembled from two normal projects.

Sources: [Read Replicas](https://supabase.com/docs/guides/platform/read-replicas)
· [Backups & PITR](https://supabase.com/docs/guides/platform/backups)
· [Custom Domains](https://supabase.com/docs/guides/platform/custom-domains)
· [Pricing](https://supabase.com/pricing)
