#!/usr/bin/env bash
# vm_checks.sh — internal smoke test, runs ON the VM.
# Sources config.sh so all checks are game-aware.
# Exit code: 0 = all passed, 1 = one or more failed.
#
# Usage: bash ~/baroboys/scripts/tools/smoke_test/vm_checks.sh <game>
#   e.g. bash ~/baroboys/scripts/tools/smoke_test/vm_checks.sh vrising
set -uo pipefail

GAME="${1:-vrising}"
REPO_DIR="$HOME/baroboys"
CONFIG="$REPO_DIR/scripts/services/$GAME/config.sh"

PASS=0
FAIL=1
results=()
exit_code=0

check() {
    local name="$1"
    local result="$2"
    local detail="${3:-}"
    if [[ "$result" == "pass" ]]; then
        results+=("  ✅ $name${detail:+ — $detail}")
    else
        results+=("  ❌ $name${detail:+ — $detail}")
        exit_code=1
    fi
}

# --- Source game config ---
if [[ ! -f "$CONFIG" ]]; then
    echo "❌ config.sh not found: $CONFIG"
    exit 1
fi
# shellcheck source=/dev/null
source "$CONFIG"

echo "=== VM Smoke Test: $GAME_NAME ==="
echo ""

# --- Services ---
echo "--- Services ---"
for svc in game-setup.service game-startup.service admin-server-startup.service xvfb-startup.service; do
    state=$(systemctl is-active "$svc" 2>/dev/null)
    # xvfb only required for vrising
    if [[ "$svc" == "xvfb-startup.service" && "$GAME_NAME" != "vrising" ]]; then
        continue
    fi
    # game-setup is oneshot — "inactive" after successful completion is correct
    if [[ "$svc" == "game-setup.service" ]]; then
        result_state=$(systemctl show "$svc" --property=Result --value 2>/dev/null)
        if [[ "$result_state" == "success" ]]; then
            check "$svc" "pass" "oneshot completed (result=success)"
        else
            check "$svc" "fail" "result=$result_state"
        fi
    else
        if [[ "$state" == "active" ]]; then
            check "$svc" "pass" "active"
        else
            check "$svc" "fail" "state=$state"
        fi
    fi
done

# --- Log symlink (VRising only) ---
echo "--- Log Files ---"
if [[ "$GAME_NAME" == "vrising" ]]; then
    SYMLINK="/var/log/baroboys/VRisingServer.log"
    EXPECTED_TARGET="$GAME_DIR/logs/VRisingServer.log"
    actual_target=$(readlink "$SYMLINK" 2>/dev/null || echo "")
    if [[ "$actual_target" == "$EXPECTED_TARGET" ]]; then
        check "VRisingServer.log symlink" "pass" "$SYMLINK -> $actual_target"
    else
        check "VRisingServer.log symlink" "fail" "expected -> $EXPECTED_TARGET, got -> $actual_target"
    fi
fi

# --- LOG_FILE exists and has content ---
if [[ -s "$LOG_FILE" ]]; then
    check "$GAME_NAME launcher log" "pass" "$LOG_FILE (non-empty)"
else
    check "$GAME_NAME launcher log" "fail" "$LOG_FILE missing or empty"
fi

# --- Game process + RAM ---
echo "--- Process ---"
PROCESS_PATTERN="${GAME_NAME}"
[[ "$GAME_NAME" == "vrising" ]] && PROCESS_PATTERN="VRisingServer.exe"
[[ "$GAME_NAME" == "barotrauma" ]] && PROCESS_PATTERN="DedicatedServer"

# For Wine games (VRising), multiple processes match the pattern — pick the one
# with highest RSS to avoid selecting the Wine launcher (start.exe) over the game itself.
pid=$(pgrep -f "$PROCESS_PATTERN" | while read -r p; do
    rss=$(awk '/VmRSS/ {print $2}' "/proc/$p/status" 2>/dev/null || echo 0)
    echo "$rss $p"
done | sort -n | tail -1 | awk '{print $2}')

if [[ -z "$pid" ]]; then
    check "game process ($PROCESS_PATTERN)" "fail" "not found"
else
    # RAM check: RSS in kB from /proc
    rss_kb=$(awk '/VmRSS/ {print $2}' "/proc/$pid/status" 2>/dev/null || echo 0)
    rss_mb=$((rss_kb / 1024))
    if (( rss_mb >= 500 && rss_mb <= 5632 )); then
        check "game process RAM" "pass" "${rss_mb}MB (expected 500–5632MB)"
    elif (( rss_mb < 500 )); then
        check "game process RAM" "fail" "${rss_mb}MB — below 500MB, game may not have loaded"
    else
        check "game process RAM" "fail" "${rss_mb}MB — above 5.5GB, OOM risk"
    fi
fi

# --- Admin server internal ping ---
echo "--- Admin Server ---"
ping_response=$(curl -s --max-time 5 http://localhost:5000/ping 2>/dev/null)
if [[ "$ping_response" == "pong" ]]; then
    check "Flask :5000 /ping" "pass"
else
    check "Flask :5000 /ping" "fail" "response: $ping_response"
fi

# --- Game log has real content (not just boot stub) ---
echo "--- Log Content ---"
game_log="/var/log/baroboys/VRisingServer.log"
[[ "$GAME_NAME" == "barotrauma" ]] && game_log="$LOG_FILE"

if [[ -f "$game_log" ]] && [[ $(wc -l < "$game_log") -gt 5 ]]; then
    check "game log has content" "pass" "$(wc -l < "$game_log") lines"
else
    check "game log has content" "fail" "log missing or fewer than 5 lines — game may not have started"
fi

# --- Print results ---
echo ""
for r in "${results[@]}"; do echo "$r"; done
echo ""

if (( exit_code == 0 )); then
    echo "✅ All checks passed."
else
    echo "❌ One or more checks failed."
fi

exit "$exit_code"
