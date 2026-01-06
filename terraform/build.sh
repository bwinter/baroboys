#!/usr/bin/env bash
set -euxo pipefail

# Contract:
# - CLI: <game-name>
# - terraform/game/<name>.tfvars must exist
# - Only applies games, uses shared.tfvars

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <game-name> <env>"
  exit 1
fi

GAME="$1"
ENV="$2"
TF_DIR="terraform"

# Validate vars file exists **relative to repo root**
[[ -f "$TF_DIR/game/$GAME.tfvars" ]] || { echo "Missing Terraform vars file: $TF_DIR/game/$GAME.tfvars"; exit 1; }

# Change to terraform dir for apply
cd "$TF_DIR"

# Now paths are relative to current directory
terraform init -backend-config="backend/${ENV}.hcl"
terraform apply -var-file="shared.tfvars" -var-file="game/$GAME.tfvars"
