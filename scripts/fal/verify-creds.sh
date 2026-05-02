#!/usr/bin/env bash
# Verify fal.ai API key in umbrella .env.local actually works.
# Hits /queue/submit/ via Key auth — 200 = creds valid, 401 = wrong.
# Run: bash scripts/fal/verify-creds.sh

set -e

cd "$(dirname "$0")/../.."

if [ ! -f .env.local ]; then
  echo "❌ .env.local not found in umbrella."
  exit 1
fi

set -a
. <(grep -E '^FAL_' .env.local || true)
set +a

if [ -z "$FAL_API_KEY" ]; then
  echo "❌ FAL_API_KEY not set in .env.local"
  exit 1
fi

echo "→ API key: ${FAL_API_KEY:0:8}…${FAL_API_KEY: -4}"
echo ""

# Probe by hitting the FLUX schnell endpoint (cheapest, fastest model) with
# a tiny prompt. Real Nano Banana Pro is more expensive — don't burn credits
# on verification; the schnell call validates auth equivalently.
echo "1️⃣  Probing /queue/submit/fal-ai/flux/schnell (auth test)..."
http_code=$(curl -s -o /tmp/fal-verify-resp.json -w "%{http_code}" \
  --max-time 30 \
  -X POST "https://queue.fal.run/fal-ai/flux/schnell" \
  -H "Content-Type: application/json" \
  -H "Authorization: Key ${FAL_API_KEY}" \
  -d '{"prompt":"a tiny test","num_inference_steps":1,"num_images":1}' \
  || echo "000")

case "$http_code" in
  200|202)
    request_id=$(grep -oE '"request_id":"[^"]+' /tmp/fal-verify-resp.json | head -1 | sed 's/.*"request_id":"//' || echo "?")
    echo "   ✓ HTTP $http_code — auth valid, request enqueued"
    echo "   request_id: $request_id"
    echo "   (small fal.ai credit usage; cancel via fal.ai dashboard if you want)"
    ;;
  401|403)
    echo "   ❌ HTTP $http_code — API key wrong or revoked"
    cat /tmp/fal-verify-resp.json | head -c 300; echo ""
    rm -f /tmp/fal-verify-resp.json
    exit 1
    ;;
  *)
    echo "   ❌ HTTP $http_code. Response:"
    cat /tmp/fal-verify-resp.json | head -c 400; echo ""
    rm -f /tmp/fal-verify-resp.json
    exit 1
    ;;
esac

rm -f /tmp/fal-verify-resp.json

echo ""
echo "✅ fal.ai credential check complete."
