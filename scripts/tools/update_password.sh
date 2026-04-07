#!/usr/bin/env bash
set -euxo pipefail

# Updates all password secrets to the same value.
# Secrets: server-password (game join + admin panel), rcon-password (VRising RCON).
# nginx htpasswd is derived from server-password at boot — no separate secret needed.

PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: PROJECT not set and no gcloud default project."
  exit 1
fi

SECRETS=(server-password rcon-password)

read -s -rp "Enter password for all secrets: " SECRET_VALUE
echo
if [[ -z "$SECRET_VALUE" ]]; then
  echo "ERROR: No password provided."
  exit 1
fi

for SECRET_NAME in "${SECRETS[@]}"; do
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
  echo "✅ $SECRET_NAME updated"
done
