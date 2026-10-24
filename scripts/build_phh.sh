#!/usr/bin/env bash
# Builds the PHH Housing release artefacts.
#
# WHY THIS SCRIPT EXISTS
#   `--flavor phh` and `--dart-define=BRAND=phh` are two separate switches.
#   The flavor sets the Android applicationId and app name; the dart-define
#   selects the Supabase project, logo and web URL. Passing only the flavor
#   produces an app CALLED PHH Housing that talks to whichever project the
#   default brand points at. Always build through this script so the two can
#   never drift apart.
#
#   This is the PHH twin of build_hca.sh — keep the two in step.
#
# USAGE
#   ./scripts/build_phh.sh aab     # Play Store upload artefact (default)
#   ./scripts/build_phh.sh apk     # sideloadable APK for testing
#   ./scripts/build_phh.sh ios     # iOS archive (macOS + Xcode only)
set -euo pipefail

FLUTTER="${FLUTTER:-flutter}"
TARGET="${1:-aab}"
BRAND_ARGS=(--dart-define=BRAND=phh)

cd "$(dirname "$0")/.."

echo "==> Resolving dependencies"
"$FLUTTER" pub get

case "$TARGET" in
  aab)
    "$FLUTTER" build appbundle --release --flavor phh "${BRAND_ARGS[@]}"
    echo
    echo "Upload this to Play Console:"
    echo "  build/app/outputs/bundle/phhRelease/app-phh-release.aab"
    ;;
  apk)
    "$FLUTTER" build apk --release --flavor phh "${BRAND_ARGS[@]}"
    echo
    echo "Sideload / share this for testing:"
    echo "  build/app/outputs/flutter-apk/app-phh-release.apk"
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
