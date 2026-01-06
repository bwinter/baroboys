#!/usr/bin/env bash
set -euxo pipefail

PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: PROJECT not set and no gcloud default project."
  exit 1
fi

SECRET_NAME="server-password"

# Prompt for the secret value interactively
read -s -rp "Enter value for ${SECRET_NAME}: " SECRET_VALUE
echo
if [[ -z "$SECRET_VALUE" ]]; then
  echo "ERROR: No secret value provided."
  exit 1
fi

# Check if the secret exists
if gcloud secrets describe "$SECRET_NAME" >/dev/null 2>&1; then
  echo "Secret '$SECRET_NAME' exists. Adding a new version..."
else
  echo "Secret '$SECRET_NAME' does not exist. Creating it..."
  gcloud secrets create "$SECRET_NAME" \
    --replication-policy=automatic
fi

# Add the new version
gcloud secrets versions add "$SECRET_NAME" --data-file=<(echo "$SECRET_VALUE")
echo "✅ Secret '$SECRET_NAME' updated"

echo "📝 Server requires restart for change to take effect."