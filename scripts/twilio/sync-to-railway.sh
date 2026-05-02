#!/usr/bin/env bash
# Push Twilio credentials from umbrella .env.local → Railway production env
# (hadouta-backend service).
# Run: bash scripts/twilio/sync-to-railway.sh

set -e

cd "$(dirname "$0")/../.."

if [ ! -f .env.local ]; then
  echo "❌ .env.local not found in umbrella."
  exit 1
fi

set -a
. <(grep -E '^TWILIO_' .env.local || true)
set +a

if [ -z "$TWILIO_ACCOUNT_SID" ] || [ -z "$TWILIO_AUTH_TOKEN" ]; then
  echo "❌ TWILIO_ACCOUNT_SID + TWILIO_AUTH_TOKEN required."
  exit 1
fi

cd hadouta-backend

project=$(railway status --json 2>/dev/null | grep -oE '"name":\s*"[^"]+"' | head -1 | grep -oE '"[^"]+"$' | tr -d '"' || true)
if [ "$project" != "hadouta-backend" ]; then
  echo "❌ Not linked to hadouta-backend Railway project. Run: railway link"
  exit 1
fi

echo "→ Pushing TWILIO_* vars to Railway hadouta-backend production env..."

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

push_var TWILIO_ACCOUNT_SID "$TWILIO_ACCOUNT_SID"
push_var TWILIO_AUTH_TOKEN "$TWILIO_AUTH_TOKEN"
push_var TWILIO_WHATSAPP_FROM "$TWILIO_WHATSAPP_FROM"
push_var TWILIO_SMS_FROM "$TWILIO_SMS_FROM"
push_var TWILIO_MESSAGING_SERVICE_SID "$TWILIO_MESSAGING_SERVICE_SID"

echo ""
echo "✅ TWILIO_* synced to Railway. Trigger redeploy with: railway up"
