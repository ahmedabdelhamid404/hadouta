#!/usr/bin/env bash
# Verify OpenAI API key in umbrella .env.local actually works.
# Hits /v1/chat/completions with a 1-token test prompt.
# Run: bash scripts/openai/verify-creds.sh

set -e

cd "$(dirname "$0")/../.."

if [ ! -f .env.local ]; then
  echo "❌ .env.local not found in umbrella."
  exit 1
fi

set -a
. <(grep -E '^OPENAI_' .env.local || true)
set +a

if [ -z "$OPENAI_API_KEY" ]; then
  echo "❌ OPENAI_API_KEY not set in .env.local"
  exit 1
fi

echo "→ API key: ${OPENAI_API_KEY:0:8}…${OPENAI_API_KEY: -4}"
echo ""

echo "1️⃣  Probing /v1/chat/completions (gpt-4o-mini, 1-token test)..."
http_code=$(curl -s -o /tmp/openai-verify-resp.json -w "%{http_code}" \
  --max-time 15 \
  -X POST "https://api.openai.com/v1/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${OPENAI_API_KEY}" \
  -d '{
    "model": "gpt-4o-mini",
    "max_tokens": 5,
    "messages": [{"role":"user","content":"ping"}]
  }' || echo "000")

case "$http_code" in
  200)
    echo "   ✓ HTTP 200 — creds valid + gpt-4o-mini reachable"
    ;;
  401)
    echo "   ❌ HTTP 401 — API key wrong or revoked"
    rm -f /tmp/openai-verify-resp.json
    exit 1
    ;;
  429)
    echo "   ⚠️  HTTP 429 — rate limited (account has tier-0 limits or out of credits)"
    cat /tmp/openai-verify-resp.json | head -c 300; echo ""
    rm -f /tmp/openai-verify-resp.json
    exit 1
    ;;
  *)
    echo "   ❌ HTTP $http_code — unexpected. Response:"
    cat /tmp/openai-verify-resp.json | head -c 400; echo ""
    rm -f /tmp/openai-verify-resp.json
    exit 1
    ;;
esac

rm -f /tmp/openai-verify-resp.json

echo ""
echo "✅ OpenAI credential check complete."
