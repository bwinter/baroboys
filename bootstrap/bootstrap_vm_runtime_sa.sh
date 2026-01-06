#!/usr/bin/env bash
set -euxo pipefail

# Login as your user.
if ! gcloud auth print-access-token >/dev/null 2>&1; then
    gcloud auth login
fi

PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: GCP project not set. Run 'gcloud config set project ...' or export PROJECT."
  exit 1
fi

SA_NAME="vm-runtime"
SA_EMAIL="${SA_NAME}@${PROJECT}.iam.gserviceaccount.com"

# Ensure IAM API is enabled
gcloud services enable iam.googleapis.com --project="$PROJECT"

# Ensure the service account exists
if ! gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT" > /dev/null 2>&1; then
  gcloud iam service-accounts create "$SA_NAME" \
    --project="$PROJECT" \
    --description="VM runtime identity (logs, metrics, secrets)" \
    --display-name="VM Runtime"
fi

# Enable required services for the runtime behavior
gcloud services enable \
  secretmanager.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com \
  osconfig.googleapis.com \
  --project="$PROJECT"

# Required roles for the VM runtime identity
REQUIRED_ROLES=(
  roles/logging.logWriter
  roles/monitoring.metricWriter
  roles/secretmanager.secretAccessor
)

for ROLE in "${REQUIRED_ROLES[@]}"; do
  echo "Binding $ROLE to $SA_EMAIL"
  gcloud projects add-iam-policy-binding "$PROJECT" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$ROLE" \
    --quiet
done

# Bind the SA to the secret
echo "Binding $SA_EMAIL to roles/secretmanager.secretAccessor on github-deploy-key"
gcloud secrets add-iam-policy-binding github-deploy-key \
  --project="$PROJECT" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/secretmanager.secretAccessor" \
  --quiet