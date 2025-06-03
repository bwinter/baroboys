#!/bin/bash
set -euo pipefail

IDLE_FLAG="/tmp/server_idle_since.flag"
STATUS_JSON="/tmp/status.json"
COOLDOWN_MINUTES=30
CPU_THRESHOLD=15.0  # Idle if below this %

# Get current CPU usage for the game process (adjust name per game)
CPU_USAGE=$(ps -C VRisingServer.exe -o %cpu= | awk '{ total += $1 } END { printf "%.1f", total }')
NOW_EPOCH=$(date +%s)
NOW_ISO=$(date -u +'%Y-%m-%dT%H:%M:%SZ')

# Initialize status values
IDLE_MINUTES=0
SHUTDOWN_TRIGGERED=false
STATUS="active"

if (( $(echo "$CPU_USAGE > $CPU_THRESHOLD" | bc -l) )); then
  echo "🟢 CPU is active (${CPU_USAGE}%), clearing idle flag"
  rm -f "$IDLE_FLAG"
else
  echo "🟡 CPU is low (${CPU_USAGE}%), may be idle"
  if [[ ! -f "$IDLE_FLAG" ]]; then
    echo "$NOW_EPOCH" > "$IDLE_FLAG"
    echo "📌 Idle state started at $NOW_EPOCH"
  fi

  IDLE_SINCE=$(cat "$IDLE_FLAG")
  IDLE_MINUTES=$(( (NOW_EPOCH - IDLE_SINCE) / 60 ))
  STATUS="idle"

  if (( IDLE_MINUTES >= COOLDOWN_MINUTES )); then
    echo "🔴 Server idle for $IDLE_MINUTES min, triggering shutdown"
    STATUS="shutdown"
    SHUTDOWN_TRIGGERED=true
    if ! /usr/bin/sudo systemctl start vm-shutdown.service; then
      echo "❌ Failed to start vm-shutdown.service" >&2
    fi
  else
    echo "⏳ Idle duration: ${IDLE_MINUTES} min (waiting for $COOLDOWN_MINUTES)"
  fi
fi

# Write JSON status snapshot
cat <<EOF > "$STATUS_JSON"
{
  "timestamp": "$NOW_ISO",
  "cpu_percent": $CPU_USAGE,
  "idle_minutes": $IDLE_MINUTES,
  "idle_threshold": $COOLDOWN_MINUTES,
  "shutdown_scheduled": $SHUTDOWN_TRIGGERED,
  "game": "vrising",
  "status": "$STATUS"
}
EOF
