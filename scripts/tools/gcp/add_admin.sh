#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: PROJECT not set and no gcloud default project."
  exit 1
fi

SA="baroboys-operators@${PROJECT}.iam.gserviceaccount.com"

EMAIL="${1:-}"

if [[ -z "$EMAIL" ]]; then
  read -rp "Enter admin email: " EMAIL
fi

if [[ -z "$EMAIL" ]]; then
  echo "ERROR: No email provided."
  exit 1
fi

[[ "$EMAIL" == *"@"* ]] || { echo "Invalid email"; exit 1; }

echo "➕ Adding admin: $EMAIL"

gcloud iam service-accounts add-iam-policy-binding "$SA" \
  --project "$PROJECT" \
  --member="user:${EMAIL}" \
  --role="roles/iam.serviceAccountUser"

echo "✅ $EMAIL added"
