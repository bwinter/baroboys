#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
REGION="${REGION:-us-west1}"
BUCKET_NAME="${SAVE_BACKUP_BUCKET:-${PROJECT}-baroboys-save-backups}"
SA_EMAIL="vm-runtime@${PROJECT}.iam.gserviceaccount.com"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: GCP project not set. Run 'gcloud config set project ...' or export PROJECT."
  exit 1
fi

command -v gsutil >/dev/null || { echo "ERROR: gsutil not installed"; exit 1; }

gcloud services enable storage.googleapis.com iam.googleapis.com --project="$PROJECT"

if gsutil ls -b "gs://${BUCKET_NAME}" >/dev/null 2>&1; then
  echo "✔ Save-backup bucket already exists: gs://${BUCKET_NAME}"
else
  echo "➕ Creating save-backup bucket: gs://${BUCKET_NAME}"
  gsutil mb -p "$PROJECT" -l "$REGION" -b on "gs://${BUCKET_NAME}"
fi

echo "🔒 Enforcing uniform bucket-level access"
gsutil uniformbucketlevelaccess set on "gs://${BUCKET_NAME}"

LIFECYCLE_FILE="$(mktemp)"
trap 'rm -f "$LIFECYCLE_FILE"' EXIT
cat > "$LIFECYCLE_FILE" <<EOF
{
  "rule": [
    {
      "action": {"type": "Delete"},
      "condition": {"age": 3, "matchesPrefix": ["recent/"]}
    },
    {
      "action": {"type": "Delete"},
      "condition": {"age": 90, "matchesPrefix": ["daily/"]}
    }
  ]
}
EOF
echo "🧹 Applying save-backup lifecycle policy"
gsutil lifecycle set "$LIFECYCLE_FILE" "gs://${BUCKET_NAME}"

echo "🔑 Granting $SA_EMAIL permission to create backup objects"
gsutil iam ch "serviceAccount:${SA_EMAIL}:roles/storage.objectCreator" \
  "gs://${BUCKET_NAME}"

echo "✅ Save-backup bucket ready:"
echo "   gs://${BUCKET_NAME}"
echo "   recent/ objects expire after 3 days"
echo "   daily/ objects expire after 90 days"
