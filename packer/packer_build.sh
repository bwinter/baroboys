#!/usr/bin/env bash
set -euxo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <layer-name> <GAME>"
  exit 1
fi

LAYER="$1"
GAME="$2"

case "$GAME" in
  barotrauma|vrising) ;;
  *)
    echo "Invalid GAME: $GAME"
    exit 1
    ;;
esac

# Directories
PACKER_DIR="packer"
TERRAFORM_DIR="terraform"
SCRIPT_DIR="scripts/services/refresh_repo"
BUILD_DIR="packer/tmp"

# Files
PACKER_TEMPLATE_FILE="packer-${LAYER}.pkr.hcl"

TF_SHARED_VARS_FILE="${TERRAFORM_DIR}/shared.tfvars"
TF_GAME_VARS_FILE="${TERRAFORM_DIR}/game/${GAME}.tfvars"
TF_VAR_DEFS_FILE="${TERRAFORM_DIR}/variables.tf"

PACKER_SHARED_VARS_FILE="shared.pkrvars.hcl"
PACKER_ENV_VARS_FILE="${GAME}.pkrvars.hcl"
PACKER_VAR_DEFS_FILE="variables.pkr.hcl"

# Validate required files exist
for f in \
  "${PACKER_DIR}/${PACKER_TEMPLATE_FILE}" \
  "${SCRIPT_DIR}/src/refresh_repo.sh" \
  "${TF_SHARED_VARS_FILE}" \
  "${TF_GAME_VARS_FILE}" \
  "${TF_VAR_DEFS_FILE}"
do
  [[ -f "$f" ]] || { echo "Missing file: $f"; exit 1; }
done

# Prepare build directory
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Copy necessary files
cp "${PACKER_DIR}/${PACKER_TEMPLATE_FILE}" "${BUILD_DIR}/packer.pkr.hcl"
cp "${SCRIPT_DIR}/src/refresh_repo.sh" "${BUILD_DIR}/refresh_repo.sh"

cp "${TF_SHARED_VARS_FILE}" "${BUILD_DIR}/${PACKER_SHARED_VARS_FILE}"
cp "${TF_GAME_VARS_FILE}" "${BUILD_DIR}/${PACKER_ENV_VARS_FILE}"
cp "${TF_VAR_DEFS_FILE}" "${BUILD_DIR}/${PACKER_VAR_DEFS_FILE}"

chmod +x "${BUILD_DIR}/refresh_repo.sh"

# Run Packer
cd "${BUILD_DIR}"
packer init .
packer build \
  --force \
  -var-file="${PACKER_SHARED_VARS_FILE}" \
  -var-file="${PACKER_ENV_VARS_FILE}" \
  .
