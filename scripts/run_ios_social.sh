#!/usr/bin/env bash
# Runs the iOS app with all dart-defines loaded from project root `.env`.
# Setup: cp .env.example .env   then edit keys (`.env` is gitignored)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="${ROOT}/.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Missing ${ENV_FILE}"
  echo "Copy .env.example to .env and set TMDB_API_KEY / OMDB_API_KEY."
  exit 1
fi

flutter run \
  --dart-define-from-file="${ENV_FILE}"
