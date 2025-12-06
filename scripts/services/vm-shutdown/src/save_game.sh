#!/bin/bash
set -eux

# Load the current mode
if [ -f "$HOME/baroboys/.envrc" ]; then
  source "$HOME/baroboys/.envrc"
fi

echo "🎮 Shut down: ${ACTIVE_GAME:-undefined}"

case "${ACTIVE_GAME:-}" in
  vrising)
    source "$HOME/baroboys/scripts/services/vrising/save.sh"
    ;;
  barotrauma)
    source "$HOME/baroboys/scripts/services/barotrauma/save.sh"
    ;;
  *)
    echo "ACTIVE_GAME not set or unrecognized: ${ACTIVE_GAME:-unset}" >&2
    exit 1
    ;;
esac
