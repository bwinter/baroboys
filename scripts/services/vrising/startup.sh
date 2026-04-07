#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/VRising/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"

echo "🚀 VRising launcher started at $(date)"

# Start the game process and capture its exit code
export WINEARCH=win64  # must match prefix created at build time (see wine/src/setup.sh)
export WINESERVER=/opt/wine-stable/bin/wineserver
export WINEDEBUG=-all  # suppress verbose wine debug noise from logs
# -logFile is relative to WorkingDirectory ($GAME_DIR) set in game-startup.service.
# Engine log goes to $GAME_DIR/logs/VRisingServer.log, symlinked into /var/log/baroboys/
# by config.sh for the admin panel. LOG_FILE (game.log) captures launcher stdout only.
/opt/wine-stable/bin/wine VRisingServer.exe \
  -persistentDataPath ./Data \
  -logFile ./logs/VRisingServer.log