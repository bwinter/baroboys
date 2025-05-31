#!/bin/bash
set -euo pipefail

cd "/home/bwinter_sc81/baroboys/VRising"

LOG_FILE="./logs/vrising_wrapper.log"
# Created in save_vrising.sh.
# Set right before sending shutdown command.
INTENTIONAL_FLAG="/tmp/vrising_intentional_shutdown"

echo "🚀 VRising launcher started at $(date)" >> "$LOG_FILE"

# If this file exists, we know the shutdown was intentional.
trap 'rm -f "$INTENTIONAL_FLAG"' EXIT

# If an intentional shutdown flag is present before we start,
# log and clear it to avoid confusion.
if [[ -f "$INTENTIONAL_FLAG" ]]; then
  echo "⚠️ Warning: intentional shutdown flag was present before launch. Deleting it." >> "$LOG_FILE"
  rm -f "$INTENTIONAL_FLAG"
fi

# Start the game. `exec` replaces this script's PID with Wine's.
exec /usr/bin/wine VRisingServer.exe \
  -persistentDataPath ./Data \
  -serverName "Mc's Playground" \
  -saveName "TestWorld-1" \
  -logFile ./logs/VRisingServer.log
