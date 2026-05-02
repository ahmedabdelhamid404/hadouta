#!/usr/bin/env bash
# Sentry — list recent unresolved issues across all Hadouta projects.
# Reads SENTRY_AUTH_TOKEN + SENTRY_ORG_SLUG from .env.local at the umbrella root.
# See docs/operations/observability-runbook.md for context.

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

PROJECT="${1:-hadouta-web}"
LIMIT="${2:-10}"

curl -s -H "Authorization: Bearer $SENTRY_AUTH_TOKEN" \
  "https://sentry.io/api/0/projects/$SENTRY_ORG_SLUG/$PROJECT/issues/?query=is:unresolved&limit=$LIMIT&statsPeriod=24h" |
  jq -r '.[] | "\(.lastSeen)  \(.level | ascii_upcase)  [\(.count) ev / \(.userCount) users]  \(.title)"'
