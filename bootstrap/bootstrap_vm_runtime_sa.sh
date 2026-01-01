#!/bin/bash
set -eux

# Login as your user.
if ! gcloud auth print-access-token >/dev/null 2>&1; then
    gcloud auth login
fi

PROJECT_ID="europan-world"
SA_NAME="vm-runtime"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Ensure IAM API is enabled
gcloud services enable iam.googleapis.com --project="$PROJECT_ID"

# Ensure the service account exists
if ! gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" > /dev/null 2>&1; then
  gcloud iam service-accounts create "$SA_NAME" \
    --project="$PROJECT_ID" \
    --description="VM runtime identity (logs, metrics, secrets)" \
    --display-name="VM Runtime"
fi

# Enable required services for the runtime behavior
gcloud services enable \
  secretmanager.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com \
  osconfig.googleapis.com \
  --project="$PROJECT_ID"

# Required roles for the VM runtime identity
REQUIRED_ROLES=(
  roles/logging.logWriter
  roles/monitoring.metricWriter
  roles/secretmanager.secretAccessor
)

for ROLE in "${REQUIRED_ROLES[@]}"; do
  echo "Binding $ROLE to $SA_EMAIL"
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$ROLE" \
    --quiet
done

# Bind the SA to the secret
echo "Binding $SA_EMAIL to roles/secretmanager.secretAccessor on github-deploy-key"
gcloud secrets add-iam-policy-binding github-deploy-key \
  --project="$PROJECT_ID" \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/secretmanager.secretAccessor" \
  --quiet