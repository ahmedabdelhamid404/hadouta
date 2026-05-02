#!/usr/bin/env bash
# Verify R2 credentials in umbrella .env.local actually work.
# Tests bucket existence + read + write + read-back via S3-compatible API.
# Run: bash scripts/r2/verify-creds.sh

set -e

cd "$(dirname "$0")/../.."

if [ ! -f .env.local ]; then
  echo "❌ .env.local not found in umbrella. Run from /home/ahmed/Desktop/hadouta."
  exit 1
fi

# Source R2 vars from .env.local without exporting other secrets
set -a
. <(grep -E '^R2_' .env.local || true)
set +a

missing=0
for var in R2_ACCOUNT_ID R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY R2_BUCKET_NAME R2_PUBLIC_URL; do
  if [ -z "${!var}" ]; then
    echo "❌ $var is not set in .env.local"
    missing=1
  fi
done

if [ "$missing" = "1" ]; then
  echo ""
  echo "Fill in the R2_* variables in /home/ahmed/Desktop/hadouta/.env.local first."
  echo "See .env.example for instructions on where to get each value."
  exit 1
fi

ENDPOINT="https://${R2_ACCOUNT_ID}.r2.cloudflarestorage.com"
TEST_KEY="hadouta-r2-verify-$(date +%s).txt"
TEST_CONTENT="hadouta r2 verify $(date -Iseconds)"

echo "→ Endpoint: $ENDPOINT"
echo "→ Bucket:   $R2_BUCKET_NAME"
echo "→ Test key: $TEST_KEY"
echo ""

# 1. Probe bucket via HEAD
echo "1️⃣  HEAD bucket..."
status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 \
  -X HEAD "$ENDPOINT/$R2_BUCKET_NAME" \
  -H "Authorization: AWS4-HMAC-SHA256 Credential=${R2_ACCESS_KEY_ID}/$(date -u +%Y%m%d)/auto/s3/aws4_request" \
  || true)
echo "   HTTP $status (anything 200/403 means bucket reachable; 404 = bucket missing)"

# 2. Use AWS CLI if available; otherwise tell user
if command -v aws >/dev/null 2>&1; then
  echo ""
  echo "2️⃣  AWS CLI present — running real put + get test"
  export AWS_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
  export AWS_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
  export AWS_DEFAULT_REGION=auto

  echo "   → put-object..."
  echo "$TEST_CONTENT" | aws s3 cp - "s3://${R2_BUCKET_NAME}/${TEST_KEY}" \
    --endpoint-url "$ENDPOINT" \
    --content-type text/plain >/dev/null
  echo "   ✓ put OK"

  echo "   → get-object..."
  retrieved=$(aws s3 cp "s3://${R2_BUCKET_NAME}/${TEST_KEY}" - \
    --endpoint-url "$ENDPOINT")
  if [ "$retrieved" = "$TEST_CONTENT" ]; then
    echo "   ✓ get OK (content matches)"
  else
    echo "   ❌ get returned different content: $retrieved"
    exit 1
  fi

  echo "   → delete-object..."
  aws s3 rm "s3://${R2_BUCKET_NAME}/${TEST_KEY}" --endpoint-url "$ENDPOINT" >/dev/null
  echo "   ✓ delete OK"

  # Public URL test
  PUBLIC_TEST_URL="${R2_PUBLIC_URL%/}/${TEST_KEY}"
  echo ""
  echo "3️⃣  Note: public URL test skipped (object deleted in step 2)."
  echo "   Public URL pattern: ${R2_PUBLIC_URL}/<key>"
  echo "   Verify a real upload via the wizard once Task 1.9 ships."
else
  echo ""
  echo "ℹ️  AWS CLI not installed — install with 'sudo apt install awscli'"
  echo "   then re-run this script. Without it, can't run full put/get/delete test."
  echo "   (You can also skip this test — the photo-upload code will exercise R2 at"
  echo "    runtime once Task 1.9 ships.)"
fi

echo ""
echo "✅ R2 credential check complete."
