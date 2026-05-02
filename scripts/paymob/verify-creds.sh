#!/usr/bin/env bash
# Verify Paymob credentials in umbrella .env.local actually work.
# Hits the /auth/tokens endpoint — 200 = api_key valid, 401 = wrong.
# Run: bash scripts/paymob/verify-creds.sh

set -e

cd "$(dirname "$0")/../.."

if [ ! -f .env.local ]; then
  echo "❌ .env.local not found in umbrella."
  exit 1
fi

set -a
. <(grep -E '^PAYMOB_' .env.local || true)
set +a

if [ -z "$PAYMOB_API_KEY" ]; then
  echo "❌ PAYMOB_API_KEY not set in .env.local"
  echo "   Paymob merchant onboarding takes 3-7 days. Once your account is"
  echo "   approved, fill in the 6 PAYMOB_* values per the instructions in"
  echo "   /home/ahmed/Desktop/hadouta/.env.local."
  exit 1
fi

PAYMOB_BASE_URL="${PAYMOB_BASE_URL:-https://accept.paymob.com/api}"

echo "→ Paymob base: $PAYMOB_BASE_URL"
echo "→ API key:     ${PAYMOB_API_KEY:0:8}…${PAYMOB_API_KEY: -4}"
echo ""

# 1. Test auth_token request — first step of any Paymob flow
echo "1️⃣  Probing /auth/tokens..."
http_code=$(curl -s -o /tmp/paymob-verify-resp.json -w "%{http_code}" \
  --max-time 15 \
  -X POST "$PAYMOB_BASE_URL/auth/tokens" \
  -H "Content-Type: application/json" \
  -d "{\"api_key\":\"${PAYMOB_API_KEY}\"}" \
  || echo "000")

case "$http_code" in
  201|200)
    token=$(grep -oE '"token":"[^"]+' /tmp/paymob-verify-resp.json 2>/dev/null | head -1 | sed 's/.*"token":"//' || echo "")
    if [ -n "$token" ]; then
      echo "   ✓ HTTP $http_code — auth_token returned (${token:0:20}…)"
    else
      echo "   ⚠️  HTTP $http_code but no token in response. Body:"
      cat /tmp/paymob-verify-resp.json | head -c 300; echo ""
    fi
    ;;
  400|401)
    echo "   ❌ HTTP $http_code — API key wrong or account not yet approved"
    cat /tmp/paymob-verify-resp.json | head -c 300; echo ""
    rm -f /tmp/paymob-verify-resp.json
    exit 1
    ;;
  *)
    echo "   ❌ HTTP $http_code — unexpected. Response:"
    cat /tmp/paymob-verify-resp.json 2>/dev/null | head -c 300; echo ""
    rm -f /tmp/paymob-verify-resp.json
    exit 1
    ;;
esac

# 2. Sanity-check integration IDs are present (don't probe — that needs an
# actual order to test against and we don't want to spam Paymob's API).
echo ""
echo "2️⃣  Checking integration ID coverage..."
for var in PAYMOB_INTEGRATION_ID_CARD PAYMOB_INTEGRATION_ID_VODAFONE_CASH PAYMOB_INTEGRATION_ID_INSTAPAY PAYMOB_IFRAME_ID PAYMOB_HMAC_SECRET; do
  if [ -n "${!var}" ]; then
    echo "   ✓ $var: ${!var:0:6}…"
  else
    echo "   ⚠️  $var is empty — payment method will be unavailable"
  fi
done

rm -f /tmp/paymob-verify-resp.json

echo ""
echo "✅ Paymob auth check complete."
