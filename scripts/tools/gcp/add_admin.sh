#!/usr/bin/env bash
set -euxo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 user@example.com"
  exit 1
fi

EMAIL="$1"

if [[ -z "${PROJECT:-}" ]]; then
  echo "PROJECT must be set in the environment"
  exit 1
fi

ROLE="roles/compute.instanceAdmin.v1"

echo "Granting $ROLE to user:$EMAIL on project $PROJECT"

gcloud projects add-iam-policy-binding "$PROJECT" \
  --member="user:${EMAIL}" \
  --role="$ROLE" \
  --quiet

echo "✅ $EMAIL now has VM admin access via the GCP Console"
