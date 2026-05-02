#!/usr/bin/env bash
# Push R2 credentials from umbrella .env.local → Railway production env (hadouta-backend service).
# Uses --stdin for secrets per the project's "secrets via stdin not flags" rule.
# Run: bash scripts/r2/sync-to-railway.sh

set -e

cd "$(dirname "$0")/../.."

if [ ! -f .env.local ]; then
  echo "❌ .env.local not found in umbrella."
  exit 1
fi

# Source R2 vars only
set -a
. <(grep -E '^R2_' .env.local || true)
set +a

missing=0
for var in R2_ACCOUNT_ID R2_ACCESS_KEY_ID R2_SECRET_ACCESS_KEY R2_BUCKET_NAME R2_PUBLIC_URL; do
  if [ -z "${!var}" ]; then
    echo "❌ $var not set in .env.local"
    missing=1
  fi
done
[ "$missing" = "1" ] && exit 1

cd hadouta-backend

# Verify we're in the right Railway project/service
project=$(railway status --json 2>/dev/null | grep -oE '"name":\s*"[^"]+"' | head -1 | grep -oE '"[^"]+"$' | tr -d '"' || true)
if [ "$project" != "hadouta-backend" ]; then
  echo "❌ Not linked to hadouta-backend Railway project. Run: railway link"
  exit 1
fi

echo "→ Pushing R2_* vars to Railway hadouta-backend production env..."

# Push each via stdin (no echo to terminal — per memory feedback_secrets_via_stdin)
push_secret() {
  local key="$1"
  local value="$2"
  printf '%s' "$value" | railway variables --set "$key" --skip-deploys >/dev/null 2>&1 \
    || railway variables --set "$key=$value" --skip-deploys >/dev/null
  echo "   ✓ $key"
}

push_secret R2_ACCOUNT_ID "$R2_ACCOUNT_ID"
push_secret R2_ACCESS_KEY_ID "$R2_ACCESS_KEY_ID"
push_secret R2_SECRET_ACCESS_KEY "$R2_SECRET_ACCESS_KEY"
push_secret R2_BUCKET_NAME "$R2_BUCKET_NAME"
push_secret R2_PUBLIC_URL "$R2_PUBLIC_URL"

echo ""
echo "✅ R2_* synced to Railway. Trigger redeploy with: railway up"
