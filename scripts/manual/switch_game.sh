#!/bin/bash
set -eu

GAMES=("vrising" "barotrauma")
CURRENT=$(grep ACTIVE_GAME .envrc 2>/dev/null | cut -d= -f2 || echo "none")

echo "Current game mode: $CURRENT"
echo "Available modes:"
select MODE in "${GAMES[@]}"; do
  if [[ " ${GAMES[*]} " == *" $MODE "* ]]; then
    echo "export ACTIVE_GAME=$MODE" > .envrc
    echo "Switched to: $MODE"
    if command -v direnv >/dev/null; then
      direnv allow .
    else
      echo "NOTE: You may need to run 'source .envrc' manually"
    fi
    break
  else
    echo "Invalid selection"
  fi
done
