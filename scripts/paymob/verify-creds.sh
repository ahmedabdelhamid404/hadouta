#!/usr/bin/env bash
# Verify Paymob credentials in umbrella .env.local actually work.
# Tests the NEW Unified Checkout API (/v1/intention/) since that's what we use.
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

if [ -z "$PAYMOB_SECRET_KEY" ]; then
  echo "❌ PAYMOB_SECRET_KEY not set in .env.local (new Unified Checkout API)"
  exit 1
fi

PAYMOB_BASE_URL="${PAYMOB_BASE_URL:-https://accept.paymob.com}"

echo "→ Paymob base: $PAYMOB_BASE_URL"
echo "→ Mode:        $([ "${PAYMOB_SECRET_KEY:0:11}" = "egy_sk_test" ] && echo "TEST/SANDBOX" || echo "LIVE")"
echo "→ Secret key:  ${PAYMOB_SECRET_KEY:0:14}…${PAYMOB_SECRET_KEY: -6}"
echo ""

# Probe by creating a tiny intention (1 EGP = 100 piastres). If the secret
# key is valid + integration_id is reachable, this returns 201 with a
# client_secret. If keys are bad, we get 401/403.
echo "1️⃣  Probing /v1/intention/..."
http_code=$(curl -s -o /tmp/paymob-verify-resp.json -w "%{http_code}" \
  --max-time 15 \
  -X POST "$PAYMOB_BASE_URL/v1/intention/" \
  -H "Authorization: Token $PAYMOB_SECRET_KEY" \
  -H "Content-Type: application/json" \
  -d "{
    \"amount\": 100,
    \"currency\": \"EGP\",
    \"payment_methods\": [${PAYMOB_INTEGRATION_ID_CARD:-0}],
    \"items\": [{\"name\": \"verify-test\", \"amount\": 100, \"description\": \"smoke test\", \"quantity\": 1}],
    \"billing_data\": {
      \"first_name\": \"Test\", \"last_name\": \"Verify\",
      \"phone_number\": \"+201000000000\", \"email\": \"verify@hadouta.com\"
    }
  }" || echo "000")

case "$http_code" in
  201|200)
    cs=$(grep -oE '"client_secret":"[^"]+' /tmp/paymob-verify-resp.json 2>/dev/null | sed 's/.*"client_secret":"//' | head -c 30 || echo "")
    if [ -n "$cs" ]; then
      echo "   ✓ HTTP $http_code — Unified Checkout intention created"
      echo "   ✓ client_secret: ${cs}…"
    else
      echo "   ⚠️  HTTP $http_code but no client_secret in response. Body:"
      cat /tmp/paymob-verify-resp.json | head -c 300; echo ""
    fi
    ;;
  401|403)
    echo "   ❌ HTTP $http_code — secret key wrong or revoked"
    cat /tmp/paymob-verify-resp.json | head -c 300; echo ""
    rm -f /tmp/paymob-verify-resp.json
    exit 1
    ;;
  *)
    echo "   ⚠️  HTTP $http_code. Body:"
    cat /tmp/paymob-verify-resp.json 2>/dev/null | head -c 400; echo ""
    rm -f /tmp/paymob-verify-resp.json
    exit 1
    ;;
esac

# 2. Coverage report
echo ""
echo "2️⃣  Configured fields:"
for var in PAYMOB_PUBLIC_KEY PAYMOB_INTEGRATION_ID_CARD PAYMOB_INTEGRATION_ID_VODAFONE_CASH PAYMOB_INTEGRATION_ID_INSTAPAY PAYMOB_HMAC_SECRET; do
  if [ -n "${!var}" ]; then
    val="${!var}"
    echo "   ✓ $var: ${val:0:8}…"
  else
    echo "   - $var: not set (payment method or feature unavailable)"
  fi
done

rm -f /tmp/paymob-verify-resp.json

echo ""
echo "✅ Paymob credential check complete."
