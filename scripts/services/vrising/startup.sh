#!/usr/bin/env bash
set -euox pipefail

LOG_FILE="/var/log/baroboys/vrising.log"

echo "🚀 VRising launcher started at $(date)" >> "$LOG_FILE"

# Start the game process and capture its exit code
export WINEARCH=win64
export WINEPREFIX=/home/bwinter_sc81/.wine64
/opt/wine-stable/bin/wine64 VRisingServer.exe \
  -persistentDataPath ./Data \
  -logFile ./logs/VRisingServer.log