#!/usr/bin/env bash
# PostHog — list recent events in the Hadouta project.
# Reads POSTHOG_PERSONAL_API_KEY + POSTHOG_HOST + POSTHOG_PROJECT_ID from .env.local.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UMBRELLA_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

if [[ -f "$UMBRELLA_ROOT/.env.local" ]]; then
  set -a
  source "$UMBRELLA_ROOT/.env.local"
  set +a
fi

: "${POSTHOG_PERSONAL_API_KEY:?POSTHOG_PERSONAL_API_KEY not set in .env.local}"
: "${POSTHOG_HOST:?POSTHOG_HOST not set in .env.local}"
: "${POSTHOG_PROJECT_ID:?POSTHOG_PROJECT_ID not set in .env.local}"

LIMIT="${1:-20}"

curl -s -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
  "$POSTHOG_HOST/api/projects/$POSTHOG_PROJECT_ID/events/?limit=$LIMIT" |
  jq -r '.results[] | "\(.timestamp)  \(.event)  distinct_id=\(.distinct_id)  \(.properties.$current_url // "")"'
