#!/usr/bin/env bash
set -euxo pipefail

# === CONFIGURATION ===
STATIC_NGINX="/opt/baroboys/static"
STATUS_JSON="$STATIC_NGINX/status.json"
IDLE_FLAG="/tmp/server_idle_since.flag"
COOLDOWN_MINUTES=30
CPU_THRESHOLD=5.0
MANIFEST_PATH="/etc/baroboys/manifest.json"

# === DEPENDENCY CHECK ===
command -v mpstat >/dev/null 2>&1 || { echo >&2 "mpstat not found. Install with: sudo apt install sysstat"; exit 1; }

# === GAME MANIFEST ===
# The manifest tells us which process to look for and which services should
# be active. Parsed via python rather than jq to avoid an extra apt package.
# Falls back to defaults if manifest is missing (smoke-test before first
# game-refresh, or dev-stub scenarios).
read -r MANIFEST_GAME_NAME MANIFEST_PROCESS MANIFEST_USES_WINE MANIFEST_RAM_MIN_MB < <(python3 -c '
import json, sys
try:
    m = json.load(open("'"$MANIFEST_PATH"'"))
    print(m.get("game_name", "Unknown"),
          m.get("process_name", ""),
          str(m.get("uses_wine", False)).lower(),
          m.get("process_ram_mb_min", 200))
except (FileNotFoundError, json.JSONDecodeError):
    print("Unknown", "", "false", 200)
')

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

# === HEALTH: SERVICES ===
# Required services for any game; xvfb-* added when manifest says wine.
HEALTH_SERVICES=(infrastructure-refresh refresh-repo-refresh refresh-repo-startup
                 admin-server-refresh admin-server-startup
                 game-refresh game-startup)
[[ "$MANIFEST_USES_WINE" == "true" ]] && HEALTH_SERVICES+=(xvfb-refresh xvfb-startup)
SERVICES_HEALTHY=true
for svc in "${HEALTH_SERVICES[@]}"; do
  if [[ "$svc" == *-refresh ]]; then
    # oneshot: check Result=success rather than active (oneshots go inactive
    # after success and that's fine).
    result=$(systemctl show "$svc.service" --property=Result --value 2>/dev/null || echo "")
    [[ "$result" == "success" ]] || SERVICES_HEALTHY=false
  else
    state=$(systemctl is-active "$svc.service" 2>/dev/null || echo "")
    [[ "$state" == "active" ]] || SERVICES_HEALTHY=false
  fi
done

# === HEALTH: GAME PROCESS ===
# Pick the largest-RSS process matching the manifest's process_name — Wine games
# have multiple matches (start.exe, wineserver, the game proper), and we
# want the actual game.
PROCESS_ALIVE=false
PROCESS_RSS_MB=0
if [[ -n "$MANIFEST_PROCESS" ]]; then
  # `|| true` because pgrep returns 1 when no process matches, and that's
  # an expected state at the boot-time fire (game-startup hasn't completed
  # yet). Without this the pipeline-failure trips set -e.
  pid=$(pgrep -f "$MANIFEST_PROCESS" 2>/dev/null | while read -r p; do
    rss=$(awk '/VmRSS/ {print $2}' "/proc/$p/status" 2>/dev/null || echo 0)
    echo "$rss $p"
  done | sort -n | tail -1 | awk '{print $2}' || true)
  if [[ -n "$pid" ]]; then
    PROCESS_ALIVE=true
    rss_kb=$(awk '/VmRSS/ {print $2}' "/proc/$pid/status" 2>/dev/null || echo 0)
    PROCESS_RSS_MB=$((rss_kb / 1024))
  fi
fi

# === IDLE TRACKING ===
# /tmp on Debian 12 GCE images is on the root partition (no tmpfs), so files
# written during Packer build persist into the runtime image. Without this
# guard, a stale IDLE_FLAG from build time would compute IDLE_DURATION as
# (now - build_time) — potentially exceeding COOLDOWN_MINUTES on the very
# first boot-time fire and triggering shutdown of a brand-new VM.
boot_unix=$(date -d "$(uptime -s)" +%s)
if [[ -f "$IDLE_FLAG" ]] && (( $(stat -c %Y "$IDLE_FLAG") < boot_unix )); then
  echo "🧹 Discarding pre-boot IDLE_FLAG (mtime predates current uptime)"
  rm -f "$IDLE_FLAG"
fi

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
# Health fields self-report game state — admin panel and external smoke
# tests can poll status.json instead of SSHing in to run vm_checks.sh.
tee "$STATUS_JSON" > /dev/null <<EOF
{
  "timestamp_utc": "$NOW_ISO",
  "game_name": "$MANIFEST_GAME_NAME",
  "cpu_percent": $CPU_PERCENT,
  "mem_percent": $MEM_PERCENT,
  "services_healthy": $SERVICES_HEALTHY,
  "process_alive": $PROCESS_ALIVE,
  "process_rss_mb": $PROCESS_RSS_MB,
  "process_ram_mb_min": $MANIFEST_RAM_MIN_MB,
  "idle_flag_set": $IDLE_FLAG_SET,
  "idle_since": "$IDLE_SINCE_ISO",
  "idle_duration_minutes": $IDLE_DURATION
}
EOF

echo "📤 Wrote status to $STATUS_JSON"

# === SHUTDOWN TRIGGER ===
if (( IDLE_DURATION >= COOLDOWN_MINUTES )); then
  echo "🕒 Idle for $IDLE_DURATION minutes. Triggering shutdown..."
  if ! /usr/bin/sudo systemctl restart game-shutdown.service; then
    echo "⚠️  Failed to start game-shutdown.service" >&2
  fi
else
  echo "⏳ No shutdown triggered. Cooldown not yet reached ($IDLE_DURATION / $COOLDOWN_MINUTES min)"
fi
