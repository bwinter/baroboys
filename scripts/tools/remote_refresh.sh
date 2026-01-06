#!/usr/bin/env bash
set -euxo pipefail

PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: GCP project not set. Run 'gcloud config set project ...' or export PROJECT."
  exit 1
fi

REMOTE="bwinter_sc81@europa"
ZONE="us-west1-c"
SERVICE="game-startup.service"

echo "🚀 Updating Game on $REMOTE..."

gcloud compute ssh "$REMOTE" \
  --zone "$ZONE" \
  --project "$PROJECT" \
  --command "/usr/bin/sudo bash -euxc ' \
    systemctl restart $SERVICE
  '"

echo "✅ Game updated."
