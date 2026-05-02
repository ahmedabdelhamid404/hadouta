#!/usr/bin/env bash
# Wipe all Cloudinary resources from the configured account.
# DESTRUCTIVE — only run when you want a clean slate.
#
# This is a thin wrapper around the TypeScript implementation in
# hadouta-backend/src/scripts/cloudinary-clear-all.ts (the SDK-based
# approach because Cloudinary's bulk-delete REST endpoint doesn't
# accept the ?all=true syntax).

set -e

cd "$(dirname "$0")/../../hadouta-backend"

if [ ! -f .env ]; then
  echo "❌ hadouta-backend/.env missing. Sync from umbrella .env.local:"
  echo "   grep '^CLOUDINARY_' /home/ahmed/Desktop/hadouta/.env.local >> hadouta-backend/.env"
  exit 1
fi

pnpm tsx src/scripts/cloudinary-clear-all.ts
