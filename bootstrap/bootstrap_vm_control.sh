#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
SA_NAME="vm-control"
SA_EMAIL="${SA_NAME}@${PROJECT}.iam.gserviceaccount.com"
ROLE_ID="vmController"
ROLE_NAME="projects/${PROJECT}/roles/${ROLE_ID}"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: GCP project not set. Run 'gcloud config set project ...' or export PROJECT."
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
gcloud services enable compute.googleapis.com run.googleapis.com cloudbuild.googleapis.com \
  artifactregistry.googleapis.com iam.googleapis.com cloudtasks.googleapis.com --project="$PROJECT"

if ! gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT" >/dev/null 2>&1; then
  gcloud iam service-accounts create "$SA_NAME" --project="$PROJECT" \
    --description="Cloud Run VM lifecycle controller and Discord interaction endpoint" \
    --display-name="VM Control"
fi

ROLE_PERMISSIONS="compute.instances.get,compute.instances.list,compute.instances.start"
if gcloud iam roles describe "$ROLE_ID" --project="$PROJECT" >/dev/null 2>&1; then
  gcloud iam roles update "$ROLE_ID" --project="$PROJECT" --title="VM Controller" \
    --description="Read and start configured game VMs" --permissions="$ROLE_PERMISSIONS" --stage=GA
else
  gcloud iam roles create "$ROLE_ID" --project="$PROJECT" --title="VM Controller" \
    --description="Read and start configured game VMs" --permissions="$ROLE_PERMISSIONS" --stage=GA
fi

gcloud projects add-iam-policy-binding "$PROJECT" --member="serviceAccount:$SA_EMAIL" \
  --role="$ROLE_NAME" --quiet

# Cloud Run enqueues the work, while Cloud Tasks uses the same identity for its
# authenticated callback to the public Discord endpoint.
gcloud projects add-iam-policy-binding "$PROJECT" --member="serviceAccount:$SA_EMAIL" \
  --role="roles/cloudtasks.enqueuer" --quiet

# The Cloud Run identity is also the identity Cloud Tasks uses to mint the
# worker's OIDC token; it therefore needs actAs on itself when creating tasks.
gcloud iam service-accounts add-iam-policy-binding "$SA_EMAIL" \
  --member="serviceAccount:$SA_EMAIL" --role="roles/iam.serviceAccountUser" --quiet

QUEUE_LOCATION="${TASKS_LOCATION:-us-west1}"
QUEUE_NAME="${TASKS_QUEUE:-vm-control}"
if ! gcloud tasks queues describe "$QUEUE_NAME" --location="$QUEUE_LOCATION" \
    --project="$PROJECT" >/dev/null 2>&1; then
  gcloud tasks queues create "$QUEUE_NAME" --location="$QUEUE_LOCATION" --project="$PROJECT"
fi

gcloud tasks queues update "$QUEUE_NAME" --location="$QUEUE_LOCATION" --project="$PROJECT" \
  --max-attempts=5 --max-retry-duration=600s --min-backoff=5s --max-backoff=60s \
  --max-doublings=3 --log-sampling-ratio=1.0

"$REPO_ROOT/scripts/tools/gcp/deploy_vm_control.sh"
