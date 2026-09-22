#!/usr/bin/env bash
set -euo pipefail

# Fetches status.json from a running game VM and pretty-prints it.
# Requires: MACHINE_NAME (set by Makefile via make game-status-<GAME>)

PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
ZONE="${ZONE:-us-west1-c}"

: "${MACHINE_NAME:?MACHINE_NAME not set}"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: PROJECT not set and no gcloud default project."
  exit 1
fi

IP=$(gcloud compute instances describe "$MACHINE_NAME" \
  --zone="$ZONE" --project="$PROJECT" \
  --format='value(networkInterfaces[0].accessConfigs[0].natIP)' 2>/dev/null)

if [[ -z "$IP" ]]; then
  echo "ERROR: Could not get IP for $MACHINE_NAME — is the VM running?"
  exit 1
fi

PASSWORD=$(gcloud secrets versions access latest \
  --secret=server-password --project="$PROJECT" --quiet)

RESPONSE=$(curl -sf --max-time 10 \
  -u "Hex:${PASSWORD}" \
  "http://${IP}:8080/status.json" 2>/dev/null) || {
  echo "ERROR: Could not reach status endpoint at $IP:8080"
  echo "  VM may still be booting, or nginx/auth may be misconfigured."
  exit 1
}

if command -v jq >/dev/null 2>&1; then
  echo "$RESPONSE" | jq .
else
  echo "$RESPONSE"
fi
