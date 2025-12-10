#!/bin/bash
set -eux

PROJECT_ID="europan-world"
SA_NAME="terraform"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Map of GCP roles → Terraform resource names
declare -A ROLE_MAP=(
  ["roles/compute.admin"]="terraform_compute_admin"
  ["roles/iam.serviceAccountUser"]="terraform_iam_service_account_user"
  ["roles/iam.serviceAccountAdmin"]="terraform_iam_service_account_admin"
  ["roles/resourcemanager.projectIamAdmin"]="terraform_project_iam_admin"
)

for ROLE in "${!ROLE_MAP[@]}"; do
  TF_RESOURCE="${ROLE_MAP[$ROLE]}"
  IMPORT_ID="${PROJECT_ID}/${ROLE}/serviceAccount:${SA_EMAIL}"
  echo "Importing $TF_RESOURCE ($ROLE) into Terraform state"
  terraform import "google_project_iam_member.${TF_RESOURCE}" "$IMPORT_ID"
done
