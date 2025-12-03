#!/bin/bash
set -eux

echo "🎮 Setting up game mode: ${ACTIVE_GAME:-undefined}"

# Load active game mode from repo-local env file
if [ -f "/root/baroboys/.envrc" ]; then
  source "/root/baroboys/.envrc"
fi

case "${ACTIVE_GAME:-}" in
  vrising)
    # Start xvfb
    source "/root/baroboys/scripts/services/xvfb/setup.sh"
    source "/root/baroboys/scripts/services/vrising/setup.sh"
    ;;
  barotrauma)
    source "/root/baroboys/scripts/setup/root/setup_barotrauma.sh"
    ;;
  *)
    echo "ACTIVE_GAME not set or unrecognized: ${ACTIVE_GAME:-unset}" >&2
    exit 1
    ;;
esac

source "/root/baroboys/scripts/services/idle_check/setup.sh"