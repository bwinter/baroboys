#!/usr/bin/env bash
set -euo pipefail

REMOTE="bwinter_sc81@europa"
ZONE="us-west1-b"
PROJECT="europan-world"
ROOT_REPO_PATH="/root/baroboys"
SCRIPT_PATH="$ROOT_REPO_PATH/scripts/setup/install/service/flask_webhooks.sh"
SERVICE="baroboys-webhook.service"

echo "🚀 Updating Flask service on $REMOTE (as root)..."

gcloud compute ssh "$REMOTE" --zone "$ZONE" --project "$PROJECT" --command "
  sudo bash -c '
    set -eux
    cd $ROOT_REPO_PATH
    ./scripts/setup/clone_repo.sh || git pull
    $SCRIPT_PATH
    systemctl restart $SERVICE
  '
"

echo "✅ Flask server updated and restarted."
