#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
REGION="${REGION:-us-west1}"
SERVICE_NAME="${VM_CONTROL_SERVICE:-vm-control}"
SA_EMAIL="vm-control@${PROJECT}.iam.gserviceaccount.com"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: GCP project not set. Run 'gcloud config set project ...' or export PROJECT."
  exit 1
fi

gcloud run deploy "$SERVICE_NAME" --project="$PROJECT" --region="$REGION" \
  --source="$REPO_ROOT/cloud_run/vm_control" --service-account="$SA_EMAIL" \
  --set-env-vars="GCP_PROJECT=$PROJECT" --no-allow-unauthenticated --quiet

CALLER="$(gcloud config get-value account 2>/dev/null)"
if [[ "$CALLER" == *@* ]]; then
  if [[ "$CALLER" == *gserviceaccount.com ]]; then
    MEMBER="serviceAccount:$CALLER"
  else
    MEMBER="user:$CALLER"
  fi
  gcloud run services add-iam-policy-binding "$SERVICE_NAME" --project="$PROJECT" \
    --region="$REGION" --member="$MEMBER" --role=roles/run.invoker --quiet
fi

URL="$(gcloud run services describe "$SERVICE_NAME" --project="$PROJECT" --region="$REGION" \
  --format='value(status.url)')"
echo "✅ VM control deployed: $URL"
