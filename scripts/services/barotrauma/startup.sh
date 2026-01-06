#!/usr/bin/env bash
set -euox pipefail

LOG_FILE="/var/log/baroboys/barotrauma.log"

echo "🚀 Barotrauma launcher started at $(date)" >> "$LOG_FILE"

# Start the game process and capture its exit code
./DedicatedServer 1>>"$LOG_FILE" 2>>"$LOG_FILE"