#!/usr/bin/env bash
# vm_checks.sh — internal smoke test, runs ON the VM.
# Self-identifying: reads /etc/baroboys/active-game (written by setup.sh) to determine
# which game is running. Sources env-vars.sh so all checks are game-aware.
# Exit code: 0 = all passed, 1 = one or more failed.
#
# Usage: bash ~/baroboys/scripts/tools/smoke_test/vm_checks.sh
set -uo pipefail

ACTIVE_GAME_FILE="/etc/baroboys/active-game"
if [[ ! -f "$ACTIVE_GAME_FILE" ]]; then
    echo "❌ $ACTIVE_GAME_FILE not found — setup.sh may not have run yet"
    exit 1
fi
GAME=$(cat "$ACTIVE_GAME_FILE")
REPO_DIR="$HOME/baroboys"
ENV_VARS="$REPO_DIR/scripts/services/$GAME/env-vars.sh"

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

# --- Source game env vars (chains to shared/env-vars.sh) ---
if [[ ! -f "$ENV_VARS" ]]; then
    echo "❌ env-vars.sh not found: $ENV_VARS"
    exit 1
fi
# shellcheck source=/dev/null
source "$ENV_VARS"

echo "=== VM Smoke Test: $GAME_NAME ==="
echo ""

# --- Services ---
echo "--- Services ---"
for svc in game-refresh.service game-startup.service admin-server-startup.service xvfb-startup.service; do
    state=$(systemctl is-active "$svc" 2>/dev/null)
    # xvfb only required for VRising
    if [[ "$svc" == "xvfb-startup.service" && "$GAME_NAME" != "VRising" ]]; then
        continue
    fi
    # game-setup is oneshot — "inactive" after successful completion is correct
    if [[ "$svc" == "game-refresh.service" ]]; then
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

# --- Game engine log (written directly by -logFile flag) ---
echo "--- Log Files ---"
if [[ -n "$GAME_ENGINE_LOG" && "$GAME_ENGINE_LOG" != "$LOG_FILE" ]]; then
    if [[ -f "$GAME_ENGINE_LOG" ]]; then
        check "game engine log" "pass" "$GAME_ENGINE_LOG exists"
    else
        check "game engine log" "fail" "$GAME_ENGINE_LOG not found — game may not have started"
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

# For Wine games (VRising), multiple processes match the pattern — pick the one
# with highest RSS to avoid selecting the Wine launcher (start.exe) over the game itself.
pid=$(pgrep -f "$PROCESS_NAME" | while read -r p; do
    rss=$(awk '/VmRSS/ {print $2}' "/proc/$p/status" 2>/dev/null || echo 0)
    echo "$rss $p"
done | sort -n | tail -1 | awk '{print $2}')

if [[ -z "$pid" ]]; then
    check "game process ($PROCESS_NAME)" "fail" "not found"
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
if [[ -f "$GAME_ENGINE_LOG" ]] && [[ $(wc -l < "$GAME_ENGINE_LOG") -gt 5 ]]; then
    check "game log has content" "pass" "$(wc -l < "$GAME_ENGINE_LOG") lines"
else
    check "game log has content" "fail" "$GAME_ENGINE_LOG missing or fewer than 5 lines — game may not have started"
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
