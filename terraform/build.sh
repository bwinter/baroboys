#!/usr/bin/env bash
set -euxo pipefail

# Contract:
# - CLI: <game-name> <env>
# - terraform/game/<name>.tfvars.json must exist (cross-language config:
#   Terraform reads it natively; bash readers parse with python3/jq).
# - Only applies games, uses shared.tfvars

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <game-name> <env>"
  exit 1
fi

GAME="$1"
ENV="$2"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$REPO_ROOT/terraform"
GAME_VARS="$TF_DIR/game/$GAME.tfvars.json"

[[ -f "$GAME_VARS" ]] || { echo "Missing per-game vars file: $GAME_VARS"; exit 1; }

# Change to terraform dir for apply
cd "$TF_DIR"

# Workspace per game — each game gets independent state.
WORKSPACE="$(echo "$GAME" | tr '[:upper:]' '[:lower:]')"

terraform init -backend-config="backend/${ENV}.hcl"
terraform workspace select "$WORKSPACE" || terraform workspace new "$WORKSPACE"
terraform apply -var-file="shared.tfvars" -var-file="game/$GAME.tfvars.json"

EXTERNAL_IP="$(terraform output -raw game_external_ip)"
PROJECT_ID="$(terraform output -raw terraform_project_id)"
"$REPO_ROOT/scripts/tools/duckdns/update_duckdns.sh" "$EXTERNAL_IP" "$PROJECT_ID"
