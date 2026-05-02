#!/usr/bin/env bash
# Verify Cloudinary credentials in umbrella .env.local actually work.
# Hits the /resources endpoint (auth-protected) — 200 = creds valid, 401 = creds wrong.
# Run: bash scripts/cloudinary/verify-creds.sh

set -e

cd "$(dirname "$0")/../.."

if [ ! -f .env.local ]; then
  echo "❌ .env.local not found in umbrella. Run from /home/ahmed/Desktop/hadouta."
  exit 1
fi

# Source CLOUDINARY_ vars only (don't leak other secrets)
set -a
. <(grep -E '^CLOUDINARY_' .env.local || true)
set +a

missing=0
for var in CLOUDINARY_CLOUD_NAME CLOUDINARY_API_KEY CLOUDINARY_API_SECRET; do
  if [ -z "${!var}" ]; then
    echo "❌ $var is not set in .env.local"
    missing=1
  fi
done

if [ "$missing" = "1" ]; then
  echo ""
  echo "Fill in the CLOUDINARY_* variables in /home/ahmed/Desktop/hadouta/.env.local first."
  echo "See .env.example for instructions on where to get each value."
  exit 1
fi

echo "→ Cloud name: $CLOUDINARY_CLOUD_NAME"
echo "→ API Key:    ${CLOUDINARY_API_KEY:0:6}…${CLOUDINARY_API_KEY: -3}"
echo ""

echo "1️⃣  Probing Cloudinary admin API..."
http_code=$(curl -s -o /tmp/cloudinary-verify-resp.json -w "%{http_code}" \
  --max-time 10 \
  -u "${CLOUDINARY_API_KEY}:${CLOUDINARY_API_SECRET}" \
  "https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD_NAME}/resources/image?max_results=1" \
  || echo "000")

case "$http_code" in
  200)
    echo "   ✓ HTTP 200 — creds valid + cloud_name reachable"
    ;;
  401)
    echo "   ❌ HTTP 401 — API key/secret is wrong, OR cloud_name doesn't match the keys"
    echo "   Recheck the 3 values in .env.local against your Cloudinary dashboard."
    rm -f /tmp/cloudinary-verify-resp.json
    exit 1
    ;;
  404)
    echo "   ❌ HTTP 404 — cloud_name '$CLOUDINARY_CLOUD_NAME' not found"
    echo "   Recheck CLOUDINARY_CLOUD_NAME — short string in your dashboard URL."
    rm -f /tmp/cloudinary-verify-resp.json
    exit 1
    ;;
  *)
    echo "   ❌ HTTP $http_code — unexpected. Response:"
    cat /tmp/cloudinary-verify-resp.json 2>/dev/null | head -c 300
    echo ""
    rm -f /tmp/cloudinary-verify-resp.json
    exit 1
    ;;
esac

echo ""
echo "2️⃣  Free tier usage..."
usage_code=$(curl -s -o /tmp/cloudinary-usage-resp.json -w "%{http_code}" \
  --max-time 10 \
  -u "${CLOUDINARY_API_KEY}:${CLOUDINARY_API_SECRET}" \
  "https://api.cloudinary.com/v1_1/${CLOUDINARY_CLOUD_NAME}/usage" \
  || echo "000")

if [ "$usage_code" = "200" ]; then
  storage_bytes=$(grep -oE '"storage":\{[^}]*"usage":[0-9]+' /tmp/cloudinary-usage-resp.json | grep -oE '[0-9]+$' || echo "0")
  bandwidth_bytes=$(grep -oE '"bandwidth":\{[^}]*"usage":[0-9]+' /tmp/cloudinary-usage-resp.json | grep -oE '[0-9]+$' || echo "0")
  storage_mb=$(awk "BEGIN { printf \"%.2f\", $storage_bytes / 1048576 }")
  bandwidth_mb=$(awk "BEGIN { printf \"%.2f\", $bandwidth_bytes / 1048576 }")
  echo "   Storage:   $storage_mb MB used / 25,600 MB free tier"
  echo "   Bandwidth: $bandwidth_mb MB used / 25,600 MB this month free"
fi

rm -f /tmp/cloudinary-verify-resp.json /tmp/cloudinary-usage-resp.json

echo ""
echo "✅ Cloudinary credential check complete."
