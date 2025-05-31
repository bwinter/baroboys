#!/usr/bin/env bash
set -euo pipefail

REMOTE="bwinter_sc81@europa"
ZONE="us-west1-b"
PROJECT="europan-world"
ROOT_REPO_PATH="/root/baroboys"

echo "🚀 Updating Game on $REMOTE..."

gcloud compute ssh "$REMOTE" \
  --zone "$ZONE" \
  --project "$PROJECT" \
  --command "/usr/bin/sudo bash -euxc ' \
    cd $ROOT_REPO_PATH && \
    ./scripts/setup/startup.sh
  '"

echo "✅ Game updated."
