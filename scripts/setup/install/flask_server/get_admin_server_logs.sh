#!/usr/bin/env bash
set -euo pipefail

REMOTE="bwinter_sc81@europa"
ZONE="us-west1-c"
PROJECT="europan-world"
SERVICE="admin-server.service"
LOG_LINES=200

echo "📡 Fetching logs for $SERVICE from $REMOTE..."

gcloud compute ssh "$REMOTE" --zone "$ZONE" --project "$PROJECT" --command "
  /usr/bin/sudo journalctl -u $SERVICE --no-pager -n $LOG_LINES
"
