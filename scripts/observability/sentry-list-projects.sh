#!/usr/bin/env bash
# Sentry — list all projects in the org with their platforms + slugs.
# Useful for confirming hadouta-backend got created when you set it up.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UMBRELLA_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ -f "$UMBRELLA_ROOT/.env.local" ]]; then
  set -a
  source "$UMBRELLA_ROOT/.env.local"
  set +a
fi

: "${SENTRY_AUTH_TOKEN:?SENTRY_AUTH_TOKEN not set in .env.local}"
: "${SENTRY_ORG_SLUG:?SENTRY_ORG_SLUG not set in .env.local}"

curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
  "https://sentry.io/api/0/organizations/$SENTRY_ORG_SLUG/projects/" |
  jq -r '.[] | "\(.slug)\t\(.platform // "—")\t(id: \(.id))"'
