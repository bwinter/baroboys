#!/usr/bin/env bash
set -euxo pipefail

# Contract:
# - CLI: <game-name>
# - terraform/game/<name>.tfvars must exist
# - Only applies games, uses shared.tfvars

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <game-name>"
  exit 1
fi

GAME="$1"
TF_DIR="terraform"
TF_SHARED="$TF_DIR/shared.tfvars"
TF_FILE="$TF_DIR/game/$GAME.tfvars"

# Validate vars file exists
[[ -f "$TF_FILE" ]] || { echo "Missing Terraform vars file: $TF_FILE"; exit 1; }

# Apply
cd "$TF_DIR"
terraform init -backend-config="backend/${ENV}.hcl"
terraform apply -var-file="$TF_SHARED" -var-file="$TF_FILE"
