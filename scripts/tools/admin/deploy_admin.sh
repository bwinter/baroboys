#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
ZONE="${ZONE:-us-west1-b}"
GCP_USER="${GCP_USER:-bwinter_sc81}"
MACHINE_NAME="${MACHINE_NAME:?MACHINE_NAME not set — use make admin-deploy-<GAME>}"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: GCP project not set. Run 'gcloud config set project ...' or export PROJECT." >&2
  exit 1
fi

REMOTE_COMMAND='sudo systemctl restart refresh-repo-startup.service && sudo systemctl restart admin-server-refresh.service && sudo systemctl restart admin-server-startup.service'

echo "Deploying admin code to $MACHINE_NAME in $ZONE..."
gcloud compute ssh "$GCP_USER@$MACHINE_NAME" \
  --project="$PROJECT" \
  --zone="$ZONE" \
  --command="$REMOTE_COMMAND"

echo "✅ Admin code deployed to $MACHINE_NAME."
