#!/usr/bin/env bash
# Builds the HomeCloudAsia release artefacts.
#
# WHY THIS SCRIPT EXISTS
#   `--flavor hca` and `--dart-define=BRAND=hca` are two separate switches.
#   The flavor sets the Android applicationId and app name; the dart-define
#   selects the Supabase project, logo and web URL. Passing only the flavor
#   produces an app CALLED HomeCloudAsia that talks to the PHH database.
#   Always build through this script so the two can never drift apart.
#
# USAGE
#   ./scripts/build_hca.sh aab     # Play Store upload artefact (default)
#   ./scripts/build_hca.sh apk     # sideloadable APK for testing
#   ./scripts/build_hca.sh ios     # iOS archive (macOS + Xcode only)
set -euo pipefail

FLUTTER="${FLUTTER:-flutter}"
TARGET="${1:-aab}"
BRAND_ARGS=(--dart-define=BRAND=hca)

cd "$(dirname "$0")/.."

echo "==> Cleaning stale build output"
"$FLUTTER" pub get

case "$TARGET" in
  aab)
    "$FLUTTER" build appbundle --release --flavor hca "${BRAND_ARGS[@]}"
    echo
    echo "Upload this to Play Console:"
    echo "  build/app/outputs/bundle/hcaRelease/app-hca-release.aab"
    ;;
  apk)
    "$FLUTTER" build apk --release --flavor hca "${BRAND_ARGS[@]}"
    echo
    echo "Sideload / share this for testing:"
    echo "  build/app/outputs/flutter-apk/app-hca-release.apk"
    ;;
  ios)
    # iOS has no Flutter flavors here — the brand comes only from the define.
    "$FLUTTER" build ipa --release "${BRAND_ARGS[@]}"
    echo
    echo "Open the archive in Xcode Organizer to upload:"
    echo "  build/ios/archive/Runner.xcarchive"
    ;;
  *)
    echo "Unknown target '$TARGET'. Use: aab | apk | ios" >&2
    exit 1
    ;;
esac
