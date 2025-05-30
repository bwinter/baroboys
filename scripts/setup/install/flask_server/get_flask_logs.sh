#!/usr/bin/env bash
set -euo pipefail

REMOTE="bwinter_sc81@europa"
ZONE="us-west1-b"
PROJECT="europan-world"
SERVICE="baroboys-webhook.service"
LOG_LINES=200

echo "📡 Fetching logs for $SERVICE from $REMOTE..."

gcloud compute ssh "$REMOTE" --zone "$ZONE" --project "$PROJECT" --command "
  sudo journalctl -u $SERVICE --no-pager -n $LOG_LINES
"
