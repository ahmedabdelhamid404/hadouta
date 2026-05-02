#!/usr/bin/env bash
# Verify Anthropic API key in umbrella .env.local actually works.
# Hits /v1/messages with a 1-token test prompt — 200 = creds valid, 401 = wrong.
# Run: bash scripts/anthropic/verify-creds.sh

set -e

cd "$(dirname "$0")/../.."

if [ ! -f .env.local ]; then
  echo "❌ .env.local not found in umbrella."
  exit 1
fi

set -a
. <(grep -E '^ANTHROPIC_' .env.local || true)
set +a

if [ -z "$ANTHROPIC_API_KEY" ]; then
  echo "❌ ANTHROPIC_API_KEY not set in .env.local"
  exit 1
fi

echo "→ API key: ${ANTHROPIC_API_KEY:0:14}…${ANTHROPIC_API_KEY: -4}"
echo ""

echo "1️⃣  Probing /v1/messages (1-token test)..."
http_code=$(curl -s -o /tmp/anthropic-verify-resp.json -w "%{http_code}" \
  --max-time 15 \
  -X POST "https://api.anthropic.com/v1/messages" \
  -H "Content-Type: application/json" \
  -H "x-api-key: ${ANTHROPIC_API_KEY}" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-haiku-4-5",
    "max_tokens": 5,
    "messages": [{"role":"user","content":"ping"}]
  }' || echo "000")

case "$http_code" in
  200)
    echo "   ✓ HTTP 200 — creds valid + claude-haiku-4-5 reachable"
    ;;
  401)
    echo "   ❌ HTTP 401 — API key wrong or revoked"
    rm -f /tmp/anthropic-verify-resp.json
    exit 1
    ;;
  *)
    echo "   ❌ HTTP $http_code — unexpected. Response:"
    cat /tmp/anthropic-verify-resp.json | head -c 400; echo ""
    rm -f /tmp/anthropic-verify-resp.json
    exit 1
    ;;
esac

rm -f /tmp/anthropic-verify-resp.json

echo ""
echo "✅ Anthropic credential check complete."
