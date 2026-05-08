#!/usr/bin/env bash
# Guard: prevent re-execution when sourced by multiple scripts in the same process.
# setup.sh sources this directly, then sources game/env-vars.sh which also sources this.
[[ -n "${_SHARED_ENV_LOADED:-}" ]] && return 0
_SHARED_ENV_LOADED=1

# Repo location — single source of truth for both base- and game-layer scripts.
# Currently $HOME-derived: refresh_repo dual-clones into /root/baroboys (root)
# and /home/bwinter_sc81/baroboys (bwinter), so each user resolves to its own
# clone. To migrate to a single canonical clone, change this one line to a
# fixed path like "/home/bwinter_sc81/baroboys" — every script that uses
# $BAROBOYS picks it up; only systemd unit files and Packer template strings
# remain hardcoded and need a separate sweep.
export BAROBOYS="$HOME/baroboys"

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
