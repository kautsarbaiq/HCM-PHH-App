#!/usr/bin/env bash
# Vercel build for the web portal. Referenced from vercel.json, which has a
# 256-character limit on buildCommand — the real command lives here.
#
# FLUTTER_VERSION is the second place the SDK version lives (the first is the
# local checkout). Bump both together, or Vercel compiles against an SDK the
# project no longer supports and the deploy fails while local builds pass.
set -euo pipefail

FLUTTER_VERSION="3.47.2"
BRAND="${BRAND:-phh}"

git clone https://github.com/flutter/flutter.git --depth 1 -b "$FLUTTER_VERSION"
flutter/bin/flutter config --enable-web

# --pwa-strategy=none: no caching service worker. The admin portal gains
# nothing from offline support, and the default worker made management keep
# seeing the previous build until every tab of the site was closed.
flutter/bin/flutter build web --release --pwa-strategy=none \
  --dart-define=BRAND="$BRAND"

bash scripts/apply_web_brand.sh "$BRAND"
