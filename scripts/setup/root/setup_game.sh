#!/bin/bash
set -eux

# Load active game mode from repo-local env file
if [ -f "/root/baroboys/.envrc" ]; then
  source "/root/baroboys/.envrc"
fi

case "${ACTIVE_GAME:-}" in
  vrising)
    source "/root/baroboys/scripts/setup/root/setup_vrising.sh"
    ;;
  barotrauma)
    source "/root/baroboys/scripts/setup/root/setup_barotrauma.sh"
    ;;
  *)
    echo "ACTIVE_GAME not set or unrecognized: ${ACTIVE_GAME:-unset}" >&2
    exit 1
    ;;
esac
