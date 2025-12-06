#!/usr/bin/env bash
set -euo pipefail

REMOTE="bwinter_sc81@europa"
ZONE="us-west1-c"
PROJECT="europan-world"

echo "🚀 Updating Game on $REMOTE..."

gcloud compute ssh "$REMOTE" \
  --zone "$ZONE" \
  --project "$PROJECT" \
  --command "/usr/bin/sudo bash -euxc ' \
    systemctl restart game-startup.service
  '"

echo "✅ Game updated."
