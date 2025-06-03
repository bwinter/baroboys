#!/bin/bash
set -euo pipefail

# === CONFIGURATION ===
STATIC_NGINX="/opt/baroboys/static"
STATUS_JSON="$STATIC_NGINX/status.json"
IDLE_FLAG="/tmp/server_idle_since.flag"
COOLDOWN_MINUTES=30
CPU_THRESHOLD=15.0  # Example idle CPU threshold
STATUS_SOURCE="idle_checker"


# === METRICS ===
CPU_PERCENT=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}')
UPTIME_MINUTES=$(awk '{print int($1 / 60)}' /proc/uptime)
NOW_UNIX=$(date +%s)
NOW_ISO=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# === IDLE TRACKING ===
if (( $(echo "$CPU_PERCENT > $CPU_THRESHOLD" | bc -l) )); then
  # Server is active → clear idle flag
  rm -f "$IDLE_FLAG"
  IDLE_DURATION=0
else
  # Server is idle
  if [[ ! -f "$IDLE_FLAG" ]]; then
    echo "$NOW_UNIX" > "$IDLE_FLAG"
  fi
  IDLE_SINCE=$(cat "$IDLE_FLAG")
  IDLE_DURATION=$(( (NOW_UNIX - IDLE_SINCE) / 60 ))
fi

# === WRITE STATUS.JSON ===
cat <<EOF > "$STATUS_JSON"
{
  "timestamp_utc": "$NOW_ISO",
  "source": "$STATUS_SOURCE",
  "uptime_duration_minutes": $UPTIME_MINUTES,
  "cpu_percent": $CPU_PERCENT,
  "idle_duration_minutes": $IDLE_DURATION,
  "players": {
    "count": null,
    "list": []
  }
}
EOF

# === SHUTDOWN TRIGGER ===
if (( IDLE_DURATION >= COOLDOWN_MINUTES )); then
  echo "🕒 Idle for $IDLE_DURATION minutes. Triggering shutdown..."
  if ! /usr/bin/sudo systemctl start shutdown.service; then
    echo "⚠️  Failed to start shutdown.service" >&2
  fi
fi
