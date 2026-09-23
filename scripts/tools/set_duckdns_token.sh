#!/usr/bin/env bash
set -euxo pipefail

# Stores the DuckDNS update token used by the VM boot-time updater.
SECRET_NAME="duckdns-token"
PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: PROJECT not set and no gcloud default project."
  exit 1
fi

read -s -rp "Enter DuckDNS token: " SECRET_VALUE
echo
if [[ -z "$SECRET_VALUE" ]]; then
  echo "ERROR: No DuckDNS token provided."
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
