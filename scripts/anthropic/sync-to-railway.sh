#!/usr/bin/env bash
# Push Anthropic API key from umbrella .env.local → Railway production env.
# Run: bash scripts/anthropic/sync-to-railway.sh

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

cd hadouta-backend

project=$(railway status --json 2>/dev/null | grep -oE '"name":\s*"[^"]+"' | head -1 | grep -oE '"[^"]+"$' | tr -d '"' || true)
if [ "$project" != "hadouta-backend" ]; then
  echo "❌ Not linked to hadouta-backend Railway project. Run: railway link"
  exit 1
fi

echo "→ Pushing ANTHROPIC_API_KEY to Railway hadouta-backend production env..."
railway variables --set "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}" --skip-deploys >/dev/null
echo "   ✓ ANTHROPIC_API_KEY"

echo ""
echo "✅ Anthropic synced. Trigger redeploy with: railway up"
