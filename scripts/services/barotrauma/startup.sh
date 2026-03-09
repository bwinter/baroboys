#!/usr/bin/env bash
set -euox pipefail

# shellcheck source=scripts/services/barotrauma/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/config.sh"

echo "🚀 Barotrauma launcher started at $(date)" >> "$LOG_FILE"

# Start the game process and capture its exit code
./DedicatedServer 1>>"$LOG_FILE" 2>>"$LOG_FILE"