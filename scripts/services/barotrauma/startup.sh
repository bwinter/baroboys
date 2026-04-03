#!/usr/bin/env bash
set -euox pipefail

# shellcheck source=scripts/services/Barotrauma/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"

echo "🚀 Barotrauma launcher started at $(date)"

# Start the game process and capture its exit code
./DedicatedServer