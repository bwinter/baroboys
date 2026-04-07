#!/usr/bin/env bash
set -euxo pipefail

# Generates an SSH deploy key, adds it to GitHub, and stores the private
# key in GCP Secret Manager. Idempotent — safe to re-run (replaces the
# existing secret version, but the GitHub deploy key must be manually
# removed first if regenerating).

SECRET_NAME="github-deploy-key"
PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: PROJECT not set and no gcloud default project."
  exit 1
fi

command -v gh >/dev/null || { echo "ERROR: gh CLI not installed. brew install gh"; exit 1; }

# Generate key pair in a temp directory
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
KEY_FILE="$TMPDIR/$SECRET_NAME"

ssh-keygen -t ecdsa -b 521 -C "vm-github-access" -f "$KEY_FILE" -N ""

# Add public key to GitHub repo as a deploy key (write access needed for git push)
echo "Adding deploy key to GitHub..."
gh repo deploy-key add "$KEY_FILE.pub" --title "VM deploy key ($(date +%Y-%m-%d))" -w

# Store private key in Secret Manager
if gcloud secrets describe "$SECRET_NAME" --project="$PROJECT" >/dev/null 2>&1; then
  echo "Updating '$SECRET_NAME'..."
else
  echo "Creating '$SECRET_NAME'..."
  gcloud secrets create "$SECRET_NAME" \
    --project="$PROJECT" \
    --replication-policy=automatic
fi

gcloud secrets versions add "$SECRET_NAME" \
  --project="$PROJECT" \
  --data-file="$KEY_FILE"
echo "✅ Deploy key generated, added to GitHub, and stored in Secret Manager"
