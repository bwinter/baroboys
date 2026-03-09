#!/usr/bin/env bash
set -euxo pipefail

LOG_FILE="/var/log/baroboys/vrising.log"

echo "🚀 VRising launcher started at $(date)" >> "$LOG_FILE"

# Start the game process and capture its exit code
export WINEARCH=win64
export WINEPREFIX=/home/bwinter_sc81/.wine64
export WINESERVER=/opt/wine-stable/bin/wineserver
export WINEDEBUG=-all  # suppress verbose wine debug noise from logs
/opt/wine-stable/bin/wine VRisingServer.exe \
  -persistentDataPath ./Data \
  -logFile ./logs/VRisingServer.log