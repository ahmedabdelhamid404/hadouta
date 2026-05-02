#!/usr/bin/env bash
# Verify Twilio credentials in umbrella .env.local actually work.
# Hits /Accounts/{sid}.json — 200 = creds valid, 401 = wrong, 404 = wrong sid.
# Run: bash scripts/twilio/verify-creds.sh

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
  echo "❌ TWILIO_ACCOUNT_SID + TWILIO_AUTH_TOKEN must both be set in .env.local"
  exit 1
fi

echo "→ Account SID: ${TWILIO_ACCOUNT_SID:0:6}…${TWILIO_ACCOUNT_SID: -4}"
echo "→ WhatsApp from: ${TWILIO_WHATSAPP_FROM:-<not set>}"
echo "→ SMS from:      ${TWILIO_SMS_FROM:-<not set>}"
echo ""

# 1. Probe Account info endpoint — confirms SID + token pair is valid
echo "1️⃣  Probing /Accounts/${TWILIO_ACCOUNT_SID}.json..."
http_code=$(curl -s -o /tmp/twilio-verify-resp.json -w "%{http_code}" \
  --max-time 10 \
  -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}" \
  "https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}.json" \
  || echo "000")

case "$http_code" in
  200)
    status=$(grep -oE '"status":"[^"]+' /tmp/twilio-verify-resp.json | head -1 | sed 's/.*"status":"//' || echo "?")
    type=$(grep -oE '"type":"[^"]+' /tmp/twilio-verify-resp.json | head -1 | sed 's/.*"type":"//' || echo "?")
    echo "   ✓ HTTP 200 — creds valid"
    echo "   Account status: $status"
    echo "   Account type:   $type   ($([ "$type" = "Trial" ] && echo "trial — only sends to VERIFIED phones; upgrade for full delivery" || echo "full account"))"
    ;;
  401)
    echo "   ❌ HTTP 401 — auth_token wrong"
    rm -f /tmp/twilio-verify-resp.json
    exit 1
    ;;
  404)
    echo "   ❌ HTTP 404 — Account SID not found (typo?)"
    rm -f /tmp/twilio-verify-resp.json
    exit 1
    ;;
  *)
    echo "   ❌ HTTP $http_code — unexpected"
    cat /tmp/twilio-verify-resp.json | head -c 300; echo ""
    rm -f /tmp/twilio-verify-resp.json
    exit 1
    ;;
esac

# 2. WhatsApp sender sanity check
echo ""
echo "2️⃣  WhatsApp sender format..."
case "$TWILIO_WHATSAPP_FROM" in
  whatsapp:+*)
    echo "   ✓ format OK: $TWILIO_WHATSAPP_FROM"
    if [ "$TWILIO_WHATSAPP_FROM" = "whatsapp:+14155238886" ]; then
      echo "   ℹ️  using Twilio shared sandbox number — only opted-in phones receive"
      echo "      messages. To test, send 'join <your-code>' from your WhatsApp to"
      echo "      +14155238886 first (find code at Twilio Console → Messaging →"
      echo "      Try It Out → Send a WhatsApp message)."
    fi
    ;;
  +*)
    echo "   ⚠️  TWILIO_WHATSAPP_FROM is missing the 'whatsapp:' prefix"
    echo "      Should be: whatsapp:$TWILIO_WHATSAPP_FROM"
    ;;
  *)
    echo "   ⚠️  TWILIO_WHATSAPP_FROM format unexpected: $TWILIO_WHATSAPP_FROM"
    ;;
esac

# 3. Verified caller IDs (so we know which phones can receive messages on trial)
echo ""
echo "3️⃣  Trial-account verified phones..."
verified=$(curl -s --max-time 10 \
  -u "${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}" \
  "https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/OutgoingCallerIds.json" 2>&1)
phone_count=$(echo "$verified" | grep -oE '"phone_number":"[^"]+' | wc -l)
echo "   $phone_count verified caller ID(s)"
if [ "$phone_count" = "0" ]; then
  echo "   ⚠️  No verified phones — trial account can ONLY send to phones you add at"
  echo "      Console → Phone Numbers → Verified Caller IDs. Add your test phone first."
fi

rm -f /tmp/twilio-verify-resp.json

echo ""
echo "✅ Twilio credential check complete."
