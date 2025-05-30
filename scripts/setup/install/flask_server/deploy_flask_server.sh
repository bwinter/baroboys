#!/usr/bin/env bash
set -euo pipefail

REMOTE="bwinter_sc81@europa"
ZONE="us-west1-b"
PROJECT="europan-world"
ROOT_REPO_PATH="/root/baroboys"

echo "🚀 Updating Flask + Nginx on $REMOTE..."

gcloud compute ssh "$REMOTE" \
  --zone "$ZONE" \
  --project "$PROJECT" \
  --command "sudo bash -euxc ' \
    cd $ROOT_REPO_PATH && \
    ./scripts/setup/clone_repo.sh || git pull && \
    ./scripts/setup/install/service/flask_webhooks.sh && \
    systemctl restart baroboys-webhook.service && \
    ./scripts/setup/install/apt_nginx.sh && \
    nginx -t && systemctl reload nginx \
  '"

echo "✅ Flask and Nginx updated."
