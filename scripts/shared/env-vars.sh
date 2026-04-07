#!/usr/bin/env bash
# Guard: prevent re-execution when sourced by multiple scripts in the same process.
# setup.sh sources this directly, then sources game/env-vars.sh which also sources this.
[[ -n "${_SHARED_ENV_LOADED:-}" ]] && return 0
_SHARED_ENV_LOADED=1

export BAROBOYS="$HOME/baroboys"

GAME_NAME="$(cat /etc/baroboys/active-game)"
export GAME_NAME
export GAME_DIR="$BAROBOYS/$GAME_NAME"

export LOG_PATH="/var/log/baroboys"
export LOG_FILE="${LOG_PATH}/game.log"
