#!/usr/bin/env bash
set -euxo pipefail

# =========================
# CONFIG
# =========================

PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: GCP project not set. Run 'gcloud config set project ...' or export PROJECT."
  exit 1
fi

BUCKET_NAME="tf-state-baroboys"
REGION="us-west1"

# =========================
# PRE-FLIGHT CHECKS
# =========================
command -v gcloud >/dev/null || { echo "gcloud not installed"; exit 1; }
command -v gsutil >/dev/null || { echo "gsutil not installed"; exit 1; }

gcloud config set project "$PROJECT" >/dev/null

# =========================
# CREATE BUCKET (IF NEEDED)
# =========================
if gsutil ls -b "gs://${BUCKET_NAME}" >/dev/null 2>&1; then
  echo "✔ Bucket already exists: gs://${BUCKET_NAME}"
else
  echo "➕ Creating bucket: gs://${BUCKET_NAME}"
  gsutil mb \
    -p "$PROJECT" \
    -l "$REGION" \
    -b on \
    "gs://${BUCKET_NAME}"
fi

# =========================
# ENABLE VERSIONING
# =========================
echo "🔁 Enabling object versioning"
gsutil versioning set on "gs://${BUCKET_NAME}"

# =========================
# ENFORCE UNIFORM ACCESS
# =========================
echo "🔒 Enforcing uniform bucket-level access"
gsutil uniformbucketlevelaccess set on "gs://${BUCKET_NAME}"

# =========================
# OPTIONAL: ENV LAYOUT HINT
# =========================
echo "📁 Creating placeholder for prod env layout"
echo "Terraform state lives under terraform/<env>/terraform.tfstate" \
  | gsutil cp - "gs://${BUCKET_NAME}/terraform/prod/README.txt" \
  >/dev/null 2>&1 || true

# =========================
# DONE
# =========================
echo "✅ Terraform state bucket ready:"
echo "   gs://${BUCKET_NAME}"
echo "   Layout: terraform/<env>/terraform.tfstate"
