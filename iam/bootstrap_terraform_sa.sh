#!/bin/bash
set -eux

# Login as your user.
gcloud auth login

PROJECT_ID="europan-world"
SA_NAME="terraform"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Ensure IAM API is enabled
gcloud services enable iam.googleapis.com --project="$PROJECT_ID"

# Create the SA if missing
if ! gcloud iam service-accounts describe "$SA_EMAIL" --project="$PROJECT_ID" > /dev/null 2>&1; then
  gcloud iam service-accounts create "$SA_NAME" \
    --project="$PROJECT_ID" \
    --description="Terraform deployer" \
    --display-name="Terraform"
fi

# Enable required project services
gcloud services enable \
  compute.googleapis.com \
  logging.googleapis.com \
  monitoring.googleapis.com \
  osconfig.googleapis.com \
  --project="$PROJECT_ID"

# Assign necessary roles
REQUIRED_ROLES=(
  roles/compute.admin
  roles/iam.serviceAccountUser
  roles/iam.serviceAccountAdmin
  roles/resourcemanager.projectIamAdmin
  roles/secretmanager.secretAccessor
)

for ROLE in "${REQUIRED_ROLES[@]}"; do
  echo "Binding $ROLE to $SA_EMAIL"
  gcloud projects add-iam-policy-binding "$PROJECT_ID" \
    --member="serviceAccount:$SA_EMAIL" \
    --role="$ROLE" \
    --quiet
done

# Optional: regenerate Terraform key file if not present
KEY_PATH=".secrets/europan-world-terraform-key.json"

mkdir -p "$(dirname "$KEY_PATH")"

if [ ! -f "$KEY_PATH" ]; then
  echo "🔑 Creating new key file for $SA_EMAIL"
  gcloud iam service-accounts keys create "$KEY_PATH" \
    --iam-account="$SA_EMAIL" \
    --project="$PROJECT_ID"

  chmod 600 "$KEY_PATH"
else
  echo "✅ Key already exists at $KEY_PATH — skipping"
fi
