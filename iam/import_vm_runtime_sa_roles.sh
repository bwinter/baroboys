#!/bin/bash
set -eux

PROJECT_ID="europan-world"
SA_NAME="vm-runtime"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# Roles and corresponding Terraform resource names
ROLES=(
  "roles/logging.logWriter"
  "roles/monitoring.metricWriter"
  "roles/secretmanager.secretAccessor"
)

TF_RESOURCES=(
  "vm_runtime_log_writer"
  "vm_runtime_monitoring_writer"
  "vm_runtime_secret_accessor"
)

# Loop over roles and import
for i in "${!ROLES[@]}"; do
  ROLE="${ROLES[$i]}"
  TF_RESOURCE="${TF_RESOURCES[$i]}"
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
