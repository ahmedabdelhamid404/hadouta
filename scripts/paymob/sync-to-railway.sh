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

# Required: API_KEY (everything else can come later if specific payment
# methods aren't approved yet)
if [ -z "$PAYMOB_API_KEY" ]; then
  echo "❌ PAYMOB_API_KEY not set in .env.local"
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

push_var PAYMOB_API_KEY "$PAYMOB_API_KEY"
push_var PAYMOB_INTEGRATION_ID_CARD "$PAYMOB_INTEGRATION_ID_CARD"
push_var PAYMOB_INTEGRATION_ID_VODAFONE_CASH "$PAYMOB_INTEGRATION_ID_VODAFONE_CASH"
push_var PAYMOB_INTEGRATION_ID_INSTAPAY "$PAYMOB_INTEGRATION_ID_INSTAPAY"
push_var PAYMOB_HMAC_SECRET "$PAYMOB_HMAC_SECRET"
push_var PAYMOB_IFRAME_ID "$PAYMOB_IFRAME_ID"
push_var PAYMOB_BASE_URL "${PAYMOB_BASE_URL:-https://accept.paymob.com/api}"

echo ""
echo "✅ PAYMOB_* synced to Railway. Trigger redeploy with: railway up"
