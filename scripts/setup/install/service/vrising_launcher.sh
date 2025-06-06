#!/bin/bash
set -euo pipefail

cd "/home/bwinter_sc81/baroboys/VRising"

LOG_FILE="./logs/vrising_wrapper.log"
INTENTIONAL_FLAG="/tmp/vrising_intentional_shutdown"

echo "🚀 VRising launcher started at $(date)" >> "$LOG_FILE"

# If an intentional shutdown flag is present before we start,
# log and clear it to avoid confusion.
if [[ -f "$INTENTIONAL_FLAG" ]]; then
  echo "⚠️ Warning: intentional shutdown flag was present before launch. Deleting it." >> "$LOG_FILE"
  rm -f "$INTENTIONAL_FLAG"
fi

# Start the game process and capture its exit code
export WINEARCH=win64
export WINEPREFIX=/home/bwinter_sc81/.wine64
/opt/wine-stable/bin/wine64 VRisingServer.exe \
  -persistentDataPath ./Data \
  -serverName "Mc's Playground" \
  -saveName "TestWorld-1" \
  -logFile ./logs/VRisingServer.log

exit_code=$?

# Detect whether it was an intentional shutdown
if [[ -f "$INTENTIONAL_FLAG" ]]; then
  echo "✅ VRising shutdown was intentional. Exit code: $exit_code. Suppressing restart." >> "$LOG_FILE"
  rm -f "$INTENTIONAL_FLAG"
  exit 0
else
  echo "❌ VRising exited unexpectedly with code $exit_code" >> "$LOG_FILE"
  exit "$exit_code"
fi
