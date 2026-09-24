#!/usr/bin/env bash
set -euo pipefail

# Stores the Discord bot token used for guild command registration and the
# eventual Discord interaction service. Never commit or print this value.
SECRET_NAME="discord-bot-token"
PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: PROJECT not set and no gcloud default project."
  exit 1
fi

read -s -rp "Enter Discord bot token: " SECRET_VALUE
echo
if [[ -z "$SECRET_VALUE" ]]; then
  echo "ERROR: No Discord bot token provided."
  exit 1
fi

if gcloud secrets describe "$SECRET_NAME" --project="$PROJECT" >/dev/null 2>&1; then
  echo "Updating '$SECRET_NAME'..."
else
  echo "Creating '$SECRET_NAME'..."
  gcloud secrets create "$SECRET_NAME" \
    --project="$PROJECT" \
    --replication-policy=automatic
fi

gcloud secrets versions add "$SECRET_NAME" \
  --project="$PROJECT" \
  --data-file=<(printf '%s' "$SECRET_VALUE")
echo "✅ $SECRET_NAME set"
