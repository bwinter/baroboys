#!/bin/bash
set -euo pipefail

# === CONFIGURATION ===
STATIC_NGINX="/opt/baroboys/static"
STATUS_JSON="$STATIC_NGINX/status.json"
IDLE_FLAG="/tmp/server_idle_since.flag"
COOLDOWN_MINUTES=30
CPU_THRESHOLD=5.0

# === DEPENDENCY CHECK ===
command -v mpstat >/dev/null 2>&1 || { echo >&2 "mpstat not found. Install with: sudo apt install sysstat"; exit 1; }

# === TIMING METRICS ===
NOW_UNIX=$(date +%s)
NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# === CPU USAGE ===
CPU_IDLE=$(mpstat 1 1 | awk '/Average:/ {print $NF}')
CPU_PERCENT=$(awk "BEGIN {print 100 - $CPU_IDLE}")

# === MEMORY USAGE ===
MEM_USED=$(free | awk '/Mem:/ {print $3}')
MEM_TOTAL=$(free | awk '/Mem:/ {print $2}')
MEM_PERCENT=$(awk -v used="$MEM_USED" -v total="$MEM_TOTAL" \
    'BEGIN { printf("%.2f", (used/total) * 100) }')

# === IDLE TRACKING ===
IDLE_FLAG_SET=false
IDLE_DURATION=0
IDLE_SINCE_ISO=""

if awk "BEGIN {exit !($CPU_PERCENT > $CPU_THRESHOLD)}"; then
  echo "💡 CPU usage at ${CPU_PERCENT}%. Above threshold → active."
  rm -f "$IDLE_FLAG"
else
  IDLE_FLAG_SET=true
  if [[ ! -f "$IDLE_FLAG" ]]; then
    echo "$NOW_UNIX" > "$IDLE_FLAG"
    echo "💤 CPU below threshold. Marking start of idle period."
  else
    IDLE_SINCE=$(cat "$IDLE_FLAG")
    IDLE_DURATION=$(( (NOW_UNIX - IDLE_SINCE) / 60 ))
    IDLE_SINCE_ISO=$(date -u -d "@$IDLE_SINCE" +"%Y-%m-%dT%H:%M:%SZ")
    echo "💤 CPU below threshold. Idle duration: $IDLE_DURATION minutes"
  fi
fi

# === WRITE STATUS.JSON ===
sudo tee "$STATUS_JSON" > /dev/null <<EOF
{
  "timestamp_utc": "$NOW_ISO",
  "cpu_percent": $CPU_PERCENT,
  "mem_percent": $MEM_PERCENT,
  "idle_flag_set": $IDLE_FLAG_SET,
  "idle_since": "$IDLE_SINCE_ISO",
  "idle_duration_minutes": $IDLE_DURATION
}
EOF

echo "📤 Wrote status to $STATUS_JSON"

# === SHUTDOWN TRIGGER ===
if (( IDLE_DURATION >= COOLDOWN_MINUTES )); then
  echo "🕒 Idle for $IDLE_DURATION minutes. Triggering shutdown..."
  if ! /usr/bin/sudo systemctl start game-shutdown.service; then
    echo "⚠️  Failed to start game-shutdown.service" >&2
  fi
else
  echo "⏳ No shutdown triggered. Cooldown not yet reached ($IDLE_DURATION / $COOLDOWN_MINUTES min)"
fi
