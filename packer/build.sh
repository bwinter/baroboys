#!/usr/bin/env bash
set -euxo pipefail

# Contract:
# - CLI: <base|game>/<name>
# - packer/<meta>/<name>.pkr.hcl must exist
# - terraform/<meta>/<name>.tfvars must exist (may be empty)
# - No inference, no defaults

### ---- CLI parsing ----
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <base|game>/<name>"
  exit 1
fi

IFS=/ read -r META NAME EXTRA <<< "$1"
[[ -z "${EXTRA:-}" ]] || { echo "Invalid argument format. Expected <base|game>/<name>"; exit 1; }
[[ -n "${META:-}" && -n "${NAME:-}" ]] || { echo "Invalid argument format. Expected <base|game>/<name>"; exit 1; }

case "$META" in
  base|game) ;;
  *) echo "Invalid meta layer: $META"; exit 1 ;;
esac

### ---- Directories ----
PACKER_DIR="packer"
TERRAFORM_DIR="terraform"
SCRIPT_DIR="scripts/services/refresh_repo"
BUILD_DIR="packer/tmp"

### ---- Files ----
PACKER_TEMPLATE_FILE="${PACKER_DIR}/${META}/${NAME}.pkr.hcl"
TF_SHARED_VARS_FILE="${TERRAFORM_DIR}/shared.tfvars"
TF_VAR_DEFS_FILE="${TERRAFORM_DIR}/variables.tf"
PACKER_SHARED_VARS_FILE="shared.pkrvars.hcl"
PACKER_VAR_DEFS_FILE="variables.pkr.hcl"
REFRESH_SCRIPT_SRC="${SCRIPT_DIR}/src/refresh_repo.sh"

# Game-only vars
TF_VARS_FILE="${TERRAFORM_DIR}/${META}/${NAME}.tfvars"
PACKER_VARS_FILE="${META}-${NAME}.pkrvars.hcl"

### ---- Validation ----
for f in "$PACKER_TEMPLATE_FILE" "$REFRESH_SCRIPT_SRC" "$TF_SHARED_VARS_FILE" "$TF_VAR_DEFS_FILE" "$TF_VARS_FILE"; do
  [[ -f "$f" ]] || { echo "Missing file: $f"; exit 1; }
done

### ---- Prepare build dir ----
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

cp "$PACKER_TEMPLATE_FILE" "$BUILD_DIR/packer.pkr.hcl"
cp "$REFRESH_SCRIPT_SRC" "$BUILD_DIR/refresh_repo.sh"
chmod +x "$BUILD_DIR/refresh_repo.sh"

cp "$TF_SHARED_VARS_FILE" "$BUILD_DIR/$PACKER_SHARED_VARS_FILE"
cp "$TF_VAR_DEFS_FILE" "$BUILD_DIR/$PACKER_VAR_DEFS_FILE"
cp "$TF_VARS_FILE" "$BUILD_DIR/$PACKER_VARS_FILE"

### ---- Packer ----
cd "$BUILD_DIR"
packer init .

packer build --force \
  -var-file="$PACKER_SHARED_VARS_FILE" \
  -var-file="$PACKER_VARS_FILE" \
  .
