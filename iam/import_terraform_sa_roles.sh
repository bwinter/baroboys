#!/bin/bash
set -eux

PROJECT_ID="europan-world"
SA_NAME="terraform"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

ROLES=(
  "roles/compute.admin"
  "roles/iam.serviceAccountUser"
  "roles/iam.serviceAccountAdmin"
  "roles/resourcemanager.projectIamAdmin"
)

TF_RESOURCES=(
  "terraform_compute_admin"
  "terraform_iam_service_account_user"
  "terraform_iam_service_account_admin"
  "terraform_project_iam_admin"
)

for i in "${!ROLES[@]}"; do
  ROLE="${ROLES[$i]}"
  TF_RESOURCE="${TF_RESOURCES[$i]}"
  IMPORT_ID="${PROJECT_ID}/${ROLE}/serviceAccount:${SA_EMAIL}"
  echo "Importing $TF_RESOURCE ($ROLE) into Terraform state"
  terraform import "google_project_iam_member.${TF_RESOURCE}" "$IMPORT_ID"
done
