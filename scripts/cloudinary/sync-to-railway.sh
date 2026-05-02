#!/usr/bin/env bash
# Push Cloudinary credentials from umbrella .env.local → Railway production env
# (hadouta-backend service).
# Run: bash scripts/cloudinary/sync-to-railway.sh

set -e

cd "$(dirname "$0")/../.."

if [ ! -f .env.local ]; then
  echo "❌ .env.local not found in umbrella."
  exit 1
fi

set -a
. <(grep -E '^CLOUDINARY_' .env.local || true)
set +a

missing=0
for var in CLOUDINARY_CLOUD_NAME CLOUDINARY_API_KEY CLOUDINARY_API_SECRET; do
  if [ -z "${!var}" ]; then
    echo "❌ $var not set in .env.local"
    missing=1
  fi
done
[ "$missing" = "1" ] && exit 1

cd hadouta-backend

project=$(railway status --json 2>/dev/null | grep -oE '"name":\s*"[^"]+"' | head -1 | grep -oE '"[^"]+"$' | tr -d '"' || true)
if [ "$project" != "hadouta-backend" ]; then
  echo "❌ Not linked to hadouta-backend Railway project. Run: railway link"
  exit 1
fi

echo "→ Pushing CLOUDINARY_* vars to Railway hadouta-backend production env..."

push_var() {
  local key="$1"
  local value="$2"
  railway variables --set "${key}=${value}" --skip-deploys >/dev/null
  echo "   ✓ $key"
}

push_var CLOUDINARY_CLOUD_NAME "$CLOUDINARY_CLOUD_NAME"
push_var CLOUDINARY_API_KEY "$CLOUDINARY_API_KEY"
push_var CLOUDINARY_API_SECRET "$CLOUDINARY_API_SECRET"

echo ""
echo "✅ CLOUDINARY_* synced to Railway. Trigger redeploy with: railway up"
