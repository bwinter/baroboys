#!/usr/bin/env bash
# Guard: prevent re-execution when sourced by multiple scripts in the same process.
# setup.sh sources this directly, then sources game/env-vars.sh which also sources this.
[[ -n "${_SHARED_ENV_LOADED:-}" ]] && return 0
_SHARED_ENV_LOADED=1

# Repo location — single source of truth for both base- and game-layer scripts.
# Canonical single-clone lives in bwinter_sc81's home (mode 755 traversable by
# all users including root). Root-context scripts read from here without
# permission issues, bwinter owns the working tree for git ops + game saves.
export BAROBOYS="/home/bwinter_sc81/baroboys"

export LOG_PATH="/var/log/baroboys"
export LOG_FILE="${LOG_PATH}/game.log"

# Game-layer state. Optional — only set when /etc/baroboys/active-game exists.
# Base-layer scripts (refresh_repo, infrastructure, admin_server install, nginx)
# can source this file at packer build time, before active-game is written.
if [[ -f /etc/baroboys/active-game ]]; then
  GAME_NAME="$(cat /etc/baroboys/active-game)"
  if [[ -n "$GAME_NAME" ]]; then
    export GAME_NAME
    export GAME_DIR="$BAROBOYS/$GAME_NAME"
  fi
fi
