#!/usr/bin/env bash
set -euxo pipefail

# Sets the server password in GCP Secret Manager.
# One secret (server-password) is used everywhere: game join, admin panel (via
# htpasswd derived at boot), and RCON. No separate secrets needed.

SECRET_NAME="server-password"
PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: PROJECT not set and no gcloud default project."
  exit 1
fi

read -s -rp "Enter server password: " SECRET_VALUE
echo
if [[ -z "$SECRET_VALUE" ]]; then
  echo "ERROR: No password provided."
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
  --data-file=<(echo "$SECRET_VALUE")
echo "✅ $SECRET_NAME set"
