#!/bin/bash
set -eux

# Load the current mode
if [ -f "$HOME/baroboys/.envrc" ]; then
  source "$HOME/baroboys/.envrc"
fi

case "${ACTIVE_GAME:-}" in
  vrising)
    "$HOME/baroboys/scripts/teardown/user/save_vrising.sh"
    ;;
  barotrauma)
    "$HOME/baroboys/scripts/teardown/user/save_barotrauma.sh"
    ;;
  *)
    echo "ACTIVE_GAME not set or unrecognized: ${ACTIVE_GAME:-unset}" >&2
    exit 1
    ;;
esac
