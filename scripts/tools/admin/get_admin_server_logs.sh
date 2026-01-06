#!/usr/bin/env bash
set -euxo pipefail

PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: PROJECT not set and no gcloud default project."
  exit 1
fi

REMOTE="bwinter_sc81@europa"
ZONE="us-west1-c"
SERVICE="admin-server.service"
LOG_LINES=200

echo "📡 Fetching logs for $SERVICE from $REMOTE..."

gcloud compute ssh "$REMOTE" \
  --zone "$ZONE" \
  --project "$PROJECT" \
  --command "/usr/bin/sudo journalctl -u $SERVICE --no-pager -n $LOG_LINES"