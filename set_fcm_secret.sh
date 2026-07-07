#!/bin/bash
# Sets the FCM_SA_B64 secret from the Firebase service-account file in
# Downloads. Run from the project folder:
#   bash set_fcm_secret.sh                        → PHH project
#   bash set_fcm_secret.sh mlyycbiojsyqatmwdhef   → Home Cloud Asia project
set -e
cd "$(dirname "$0")"

files=("$HOME/Downloads"/hcm-phh-firebase-adminsdk*.json)
FILE="${files[0]}"
if [ ! -f "$FILE" ]; then
  echo "❌ File kunci hcm-phh-firebase-adminsdk*.json tidak ditemukan di Downloads."
  exit 1
fi
echo "Memakai file: $FILE"

B64="$(base64 -i "$FILE")"
if [ -z "$B64" ]; then
  echo "❌ base64 gagal (file kosong?)"
  exit 1
fi

if [ -n "$1" ]; then
  npx supabase secrets set FCM_SA_B64="$B64" --project-ref "$1"
else
  npx supabase secrets set FCM_SA_B64="$B64"
fi
echo "✅ Selesai — secret FCM_SA_B64 terisi (${#B64} karakter)."
