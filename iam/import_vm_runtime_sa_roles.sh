#!/bin/bash
set -eux

PROJECT_ID="europan-world"
SA_NAME="vm-runtime"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Map of GCP roles → Terraform resource names
declare -A ROLE_MAP=(
  ["roles/logging.logWriter"]="vm_runtime_log_writer"
  ["roles/monitoring.metricWriter"]="vm_runtime_monitoring_writer"
  ["roles/secretmanager.secretAccessor"]="vm_runtime_secret_accessor"
)

for ROLE in "${!ROLE_MAP[@]}"; do
  TF_RESOURCE="${ROLE_MAP[$ROLE]}"
  IMPORT_ID="${PROJECT_ID}/${ROLE}/serviceAccount:${SA_EMAIL}"
  echo "Importing $TF_RESOURCE ($ROLE) into Terraform state"
  terraform import "google_project_iam_member.${TF_RESOURCE}" "$IMPORT_ID"
done

# Secret-level binding
SECRET_ID="github-deploy-key"
TF_SECRET_RESOURCE="vm_runtime_github_deploy_access"
IMPORT_ID="${PROJECT_ID}/${SECRET_ID}/roles/secretmanager.secretAccessor/serviceAccount:${SA_EMAIL}"
echo "Importing $TF_SECRET_RESOURCE for secret $SECRET_ID"
terraform import "google_secret_manager_secret_iam_member.${TF_SECRET_RESOURCE}" "$IMPORT_ID"
