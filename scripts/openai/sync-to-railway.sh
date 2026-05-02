#!/usr/bin/env bash
# Push OpenAI API key from umbrella .env.local → Railway production env.
# Run: bash scripts/openai/sync-to-railway.sh

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

cd hadouta-backend

project=$(railway status --json 2>/dev/null | grep -oE '"name":\s*"[^"]+"' | head -1 | grep -oE '"[^"]+"$' | tr -d '"' || true)
if [ "$project" != "hadouta-backend" ]; then
  echo "❌ Not linked to hadouta-backend Railway project. Run: railway link"
  exit 1
fi

echo "→ Pushing OPENAI_API_KEY to Railway hadouta-backend production env..."
railway variables --set "OPENAI_API_KEY=${OPENAI_API_KEY}" --skip-deploys >/dev/null
echo "   ✓ OPENAI_API_KEY"

echo ""
echo "✅ OpenAI synced. Trigger redeploy with: railway up"
