#!/bin/bash
# Apply per-brand static web branding (favicon, PWA icons, tab title) into
# build/web AFTER `flutter build web`. Usage: bash scripts/apply_web_brand.sh <phh|hca>
set -e
cd "$(dirname "$0")/.."
BRAND="${1:-phh}"
if [ ! -d "web_branding/$BRAND" ]; then
  echo "unknown brand: $BRAND (expected phh or hca)"; exit 1
fi
cp "web_branding/$BRAND/favicon.png" build/web/favicon.png
cp "web_branding/$BRAND/icons/"* build/web/icons/
node scripts/patch_web_brand.js "$BRAND"
