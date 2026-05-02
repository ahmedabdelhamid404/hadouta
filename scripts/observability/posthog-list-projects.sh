#!/usr/bin/env bash
# PostHog — list all projects in the org with their IDs + frontend project keys.
# Useful for finding the phc_ project key for NEXT_PUBLIC_POSTHOG_KEY.

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

curl -s -H "Authorization: Bearer $POSTHOG_PERSONAL_API_KEY" \
  "$POSTHOG_HOST/api/projects/" |
  jq -r '.results[] | "\(.id)\t\(.name)\t\(.api_token)"'
