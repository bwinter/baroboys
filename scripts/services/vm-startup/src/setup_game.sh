#!/bin/bash
set -eux

# Load active game mode from repo-local env file
if [ -f "$HOME/baroboys/.envrc" ]; then
  source "$HOME/baroboys/.envrc"
fi

echo "🎮 Setting up game mode: ${ACTIVE_GAME:-undefined}"

case "${ACTIVE_GAME:-}" in
  vrising)
    # Start xvfb
    source "$HOME/baroboys/scripts/services/xvfb/setup.sh"
    source "$HOME/baroboys/scripts/services/vrising/setup.sh"
    ;;
  barotrauma)
    source "$HOME/baroboys/scripts/services/barotrauma/setup.sh"
    ;;
  *)
    echo "ACTIVE_GAME not set or unrecognized: ${ACTIVE_GAME:-unset}" >&2
    exit 1
    ;;
esac

source "$HOME/baroboys/scripts/services/idle_check/setup.sh"