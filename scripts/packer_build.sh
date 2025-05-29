#!/bin/bash
set -eux

if [[ -z "$1" ]]; then
  echo "Usage: $0 <layer-name>"
  exit 1
fi

LAYER="$1"
TIMESTAMP="$(date +%Y%m%d-%H%M)"

# Paths
BUILD_DIR="terraform/packer/tmp"
LOG_DIR="${BUILD_DIR}/logs"
SCRIPT_DIR="scripts/setup"
PACKER_DIR="terraform/packer"

PACKER_VARS_FILE="terraform.pkrvars.hcl"
PACKER_VAR_DEFS_FILE="variables.pkr.hcl"
PACKER_TEMPLATE_FILE="packer-${LAYER}.pkr.hcl"
LOG_FILE_NAME="packer-${LAYER}-${USER}-${TIMESTAMP}.log"
ABS_LOG_PATH="$(pwd)/${LOG_DIR}/${LOG_FILE_NAME}"

# Prep
mkdir -p "${BUILD_DIR}/.secrets"
cp ".secrets/europan-world-terraform-key.json" "${BUILD_DIR}/.secrets/"

mkdir -p "${LOG_DIR}"

cp -f "${SCRIPT_DIR}/clone_repo.sh" "${BUILD_DIR}/clone_repo.sh"
cp -f "${PACKER_DIR}/${PACKER_TEMPLATE_FILE}" "${BUILD_DIR}/packer.pkr.hcl"
cp -f "terraform/terraform.tfvars" "${BUILD_DIR}/${PACKER_VARS_FILE}"
cp -f "terraform/variables.tf" "${BUILD_DIR}/${PACKER_VAR_DEFS_FILE}"

# Build
cd "${BUILD_DIR}"
packer init .
packer build -on-error=cleanup -force -var-file="${PACKER_VARS_FILE}" . | tee "${ABS_LOG_PATH}"

echo "✅ Log written to: ${ABS_LOG_PATH}"
