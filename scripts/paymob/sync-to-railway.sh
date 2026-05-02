#!/usr/bin/env bash
# Push Paymob credentials from umbrella .env.local → Railway production env
# (hadouta-backend service).
# Run: bash scripts/paymob/sync-to-railway.sh

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
  echo "❌ PAYMOB_SECRET_KEY not set — required for Unified Checkout API."
  exit 1
fi

cd hadouta-backend

project=$(railway status --json 2>/dev/null | grep -oE '"name":\s*"[^"]+"' | head -1 | grep -oE '"[^"]+"$' | tr -d '"' || true)
if [ "$project" != "hadouta-backend" ]; then
  echo "❌ Not linked to hadouta-backend Railway project. Run: railway link"
  exit 1
fi

echo "→ Pushing PAYMOB_* vars to Railway hadouta-backend production env..."

push_var() {
  local key="$1"
  local value="$2"
  if [ -z "$value" ]; then
    echo "   - $key: skipped (empty)"
    return
  fi
  railway variables --set "${key}=${value}" --skip-deploys >/dev/null
  echo "   ✓ $key"
}

push_var PAYMOB_SECRET_KEY "$PAYMOB_SECRET_KEY"
push_var PAYMOB_PUBLIC_KEY "$PAYMOB_PUBLIC_KEY"
push_var PAYMOB_API_KEY "$PAYMOB_API_KEY"
push_var PAYMOB_INTEGRATION_ID_CARD "$PAYMOB_INTEGRATION_ID_CARD"
push_var PAYMOB_INTEGRATION_ID_VODAFONE_CASH "$PAYMOB_INTEGRATION_ID_VODAFONE_CASH"
push_var PAYMOB_INTEGRATION_ID_INSTAPAY "$PAYMOB_INTEGRATION_ID_INSTAPAY"
push_var PAYMOB_HMAC_SECRET "$PAYMOB_HMAC_SECRET"
push_var PAYMOB_IFRAME_ID "$PAYMOB_IFRAME_ID"
push_var PAYMOB_BASE_URL "${PAYMOB_BASE_URL:-https://accept.paymob.com}"

echo ""
echo "✅ PAYMOB_* synced to Railway. Trigger redeploy with: railway up"
