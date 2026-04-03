#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/VRising/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"

echo "🚀 VRising launcher started at $(date)"

# Start the game process and capture its exit code
export WINEARCH=win64
export WINEPREFIX
export WINESERVER=/opt/wine-stable/bin/wineserver
export WINEDEBUG=-all  # suppress verbose wine debug noise from logs
/opt/wine-stable/bin/wine VRisingServer.exe \
  -persistentDataPath ./Data \
  -logFile "$LOG_FILE"