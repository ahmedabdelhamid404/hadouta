#!/usr/bin/env bash
# Verify Google AI Studio API key in umbrella .env.local actually works.
# Hits Gemini API with a tiny test prompt. NOTE: API key must be from
# Google AI Studio (https://aistudio.google.com/app/apikey), NOT a Gemini
# Advanced consumer subscription.
# Run: bash scripts/google-ai/verify-creds.sh

set -e

cd "$(dirname "$0")/../.."

if [ ! -f .env.local ]; then
  echo "❌ .env.local not found in umbrella."
  exit 1
fi

set -a
. <(grep -E '^GOOGLE_AI_' .env.local || true)
set +a

if [ -z "$GOOGLE_AI_API_KEY" ]; then
  echo "❌ GOOGLE_AI_API_KEY not set in .env.local"
  echo "   Get one at https://aistudio.google.com/app/apikey (free tier; no card)"
  exit 1
fi

echo "→ API key: ${GOOGLE_AI_API_KEY:0:8}…${GOOGLE_AI_API_KEY: -4}"
echo ""

# Test with gemini-2.5-flash (text model — cheap quick auth test).
# We'll separately verify image generation works once we wire it.
echo "1️⃣  Probing Gemini API (gemini-2.5-flash, 1-token test)..."
http_code=$(curl -s -o /tmp/google-ai-verify-resp.json -w "%{http_code}" \
  --max-time 15 \
  -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GOOGLE_AI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{"parts":[{"text":"ping"}]}],
    "generationConfig": {"maxOutputTokens": 5}
  }' || echo "000")

case "$http_code" in
  200)
    echo "   ✓ HTTP 200 — creds valid + Gemini API reachable"
    ;;
  400)
    echo "   ⚠️  HTTP 400 — request format issue (creds may still be OK)"
    cat /tmp/google-ai-verify-resp.json | head -c 400; echo ""
    ;;
  401|403)
    echo "   ❌ HTTP $http_code — API key wrong, revoked, or you're using a"
    echo "      Gemini Advanced consumer subscription instead of an API key."
    echo "      Get an API key at https://aistudio.google.com/app/apikey"
    cat /tmp/google-ai-verify-resp.json | head -c 300; echo ""
    rm -f /tmp/google-ai-verify-resp.json
    exit 1
    ;;
  *)
    echo "   ❌ HTTP $http_code. Response:"
    cat /tmp/google-ai-verify-resp.json | head -c 400; echo ""
    rm -f /tmp/google-ai-verify-resp.json
    exit 1
    ;;
esac

# Bonus: probe Nano Banana availability (gemini-2.5-flash-image) — this is
# the model we'll actually use for illustrations.
echo ""
echo "2️⃣  Checking Nano Banana availability (gemini-2.5-flash-image)..."
nb_code=$(curl -s -o /tmp/google-ai-nb-resp.json -w "%{http_code}" \
  --max-time 15 \
  -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key=${GOOGLE_AI_API_KEY}" \
  -H "Content-Type: application/json" \
  -d '{
    "contents": [{"parts":[{"text":"a tiny test sketch"}]}]
  }' || echo "000")

if [ "$nb_code" = "200" ]; then
  echo "   ✓ Nano Banana (gemini-2.5-flash-image) accessible"
elif [ "$nb_code" = "404" ]; then
  echo "   ⚠️  HTTP 404 — model name may differ in your region; try"
  echo "      gemini-2.5-flash-image-preview when wiring the illustration code"
else
  echo "   ⚠️  HTTP $nb_code — non-blocking (we'll handle in code)"
fi

rm -f /tmp/google-ai-verify-resp.json /tmp/google-ai-nb-resp.json

echo ""
echo "✅ Google AI Studio credential check complete."
