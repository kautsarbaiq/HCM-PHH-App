# Releasing HomeCloudAsia (HCA) to Play Store & App Store

This repository is **white-label**: one codebase builds two different apps,
**PHH Housing** and **HomeCloudAsia**. Only HomeCloudAsia is being published.
Read the "Do not get this wrong" section before building anything.

---

## Do not get this wrong

`--flavor hca` and `--dart-define=BRAND=hca` are **two separate switches**:

| Switch | Controls |
|---|---|
| `--flavor hca` | Android applicationId + app name |
| `--dart-define=BRAND=hca` | Supabase project, logo, web links |

Passing only the flavor produces an app **called** HomeCloudAsia that talks to
the **PHH database**. That is a data-leak-shaped mistake, not a cosmetic one.

**Always build through the script** — it pairs them for you:

```bash
./scripts/build_hca.sh aab   # Play Store artefact
./scripts/build_hca.sh apk   # test build
./scripts/build_hca.sh ios   # iOS archive
```

---

## App identity (already set in the repo)

| | Value |
|---|---|
| Android applicationId | `com.bluesoft.hcm_app` |
| Android app name | HomeCloudAsia |
| iOS bundle identifier | `com.bluesoft.homecloudasia` |
| iOS display name | Home Cloud Asia |
| Version | `1.0.0` (build 1) — from `pubspec.yaml` `version:` |
| Backend | Supabase project `dogbmkricfvaizjgjanu` (HCA's own) |

iOS bundle IDs cannot contain `_`, which is why iOS is
`com.bluesoft.homecloudasia` and not the Android `com.bluesoft.hcm_app`.
**If your Apple Developer account uses a different prefix, change it in Xcode
and tell the team — it must match the App ID you register.**

To bump the version for a later release, edit `version: 1.0.0+1` in
`pubspec.yaml` (`1.0.0` = versionName, `+1` = versionCode). Play Store rejects
a versionCode that has been uploaded before.

---

## ANDROID — what you must supply

### 1. A release keystore (required — Play rejects debug-signed uploads)

The repo is wired to sign with a real keystore, but **the keystore is not in
git and must never be**. Create one once and keep it safe forever: losing it
means you can never update the app again.

```bash
keytool -genkey -v -keystore ~/hca-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias hca
```

Then create `android/key.properties` (already gitignored):

```properties
storeFile=/Users/YOU/hca-release.jks
storePassword=<the store password you chose>
keyAlias=hca
keyPassword=<the key password you chose>
```

Without this file the build still succeeds but is **debug-signed** and Play
Console will refuse it. With the file present, signing is automatic.

Back up the `.jks` file **and** both passwords somewhere durable.

### 2. Build and upload

```bash
./scripts/build_hca.sh aab
# -> build/app/outputs/bundle/hcaRelease/app-hca-release.aab
```

Play Console → your app → Production → Create release → upload the `.aab`.

---

## iOS — what you must supply

You need a paid **Apple Developer Program** account ($99/yr) and a Mac with
Xcode. Nobody can upload to the App Store without one.

1. **Register the App ID** `com.bluesoft.homecloudasia` in the Apple Developer
   portal (or change the bundle id in Xcode to match your own prefix).
2. **Signing**: open `ios/Runner.xcworkspace` in Xcode → Runner target →
   Signing & Capabilities → select your Team. Let Xcode manage signing.
3. **Push notifications**: enable the *Push Notifications* capability, and see
   the Firebase step below — without it the app builds but push is dead.
4. Build and upload:
   ```bash
   ./scripts/build_hca.sh ios
   ```
   Then open `build/ios/archive/Runner.xcarchive` in Xcode Organizer →
   Distribute App → App Store Connect.

---

## Firebase / push notifications

Push runs on Firebase project **`hcm-phh`** (the project name is historical —
it serves both apps).

* **Android** — already configured. `android/app/google-services.json`
  contains `com.bluesoft.hcm_app`, so push works out of the box.
* **iOS — NOT configured yet.** You must:
  1. Firebase console → project `hcm-phh` → Add app → iOS →
     bundle id `com.bluesoft.homecloudasia`.
  2. Download `GoogleService-Info.plist` and add it to `ios/Runner/` in Xcode
     (tick "Copy items if needed" and the Runner target).
  3. Upload an **APNs key** (.p8) from the Apple Developer portal into
     Firebase → Project settings → Cloud Messaging.

  Until this is done, iOS builds and runs but receives no push notifications.

---

## Store listing — what both stores will ask for

Prepare these before you start the submission form:

* **Privacy policy URL** — mandatory on both stores. The app collects account
  and resident data, so a real hosted policy page is required.
* **App icon** 512×512 (Play) / 1024×1024 (App Store).
* **Screenshots** — phone screenshots for both stores.
* **Short + full description.**
* **Category**: Lifestyle or House & Home.
* **Contact email** and support URL.

### Permissions the app declares — you will be asked to justify these

| Permission | Used for |
|---|---|
| Camera | Scanning visitor / voucher QR codes, capturing guard evidence photos |
| Photo library | Uploading avatars, shop logos, tenancy agreement documents |
| Notifications | Emergency alerts, visitor arrivals, billing reminders |
| Internet | Talking to the Supabase backend |

### Data safety / privacy labels

The app collects: name, email address, phone number, home address (unit),
photos/documents uploaded by the user, and vehicle plate numbers. It does
**not** use advertising IDs and does not sell data. Data is stored in Supabase
and is linked to the user's account.

---

## Known gaps — read before promising a launch date

1. **iOS push is not set up.** See the Firebase section. Android push works.
2. **The release build has not been smoke-tested on a physical device.** R8
   code shrinking is enabled; it compiles cleanly, but install the APK from
   `./scripts/build_hca.sh apk` on a real phone and check login, QR scanning
   and push before submitting.
3. **Both brands' `.env` files ship inside the app.** `.env.phh` is bundled in
   the HCA build too. These contain only Supabase *anon* keys, which are
   designed to be public and are protected by row-level security — so this is
   untidy rather than dangerous, but worth cleaning up before launch.
4. **The launcher icon is shared by both flavors.** Currently it is the
   HomeCloudAsia logo, which is correct for this release, but a future PHH
   build would show the wrong icon.
