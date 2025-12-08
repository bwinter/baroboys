#!/bin/bash
set -euox pipefail

LOG_FILE="/var/log/baroboys/barotrauma.log"
INTENTIONAL_FLAG="/tmp/barotrauma_intentional_shutdown"

echo "🚀 Barotrauma launcher started at $(date)" >> "$LOG_FILE"

# If an intentional shutdown flag is present before we start,
# log and clear it to avoid confusion.
if [[ -f "$INTENTIONAL_FLAG" ]]; then
  echo "⚠️ Warning: intentional shutdown flag was present before launch. Deleting it." >> "$LOG_FILE"
  rm -f "$INTENTIONAL_FLAG"
fi

# Start the game process and capture its exit code
./DedicatedServer 1>>"$LOG_FILE" 2>>"$LOG_FILE"

exit_code=$?

# Detect whether it was an intentional shutdown
if [[ -f "$INTENTIONAL_FLAG" ]]; then
  echo "✅ Barotrauma shutdown was intentional. Exit code: $exit_code. Suppressing restart." >> "$LOG_FILE"
  rm -f "$INTENTIONAL_FLAG"
  exit 0
else
  echo "❌ Barotrauma exited unexpectedly with code $exit_code" >> "$LOG_FILE"
  exit "$exit_code"
fi