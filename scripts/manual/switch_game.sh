#!/bin/bash
set -eux

GAMES=("vrising" "barotrauma")
CURRENT=$(grep ACTIVE_GAME .envrc 2>/dev/null | cut -d= -f2 || echo "none")

echo "Current game mode: $CURRENT"
echo "Available modes:"
select MODE in "${GAMES[@]}"; do
  if [[ " ${GAMES[*]} " == *" $MODE "* ]]; then
    # Safely update or append the ACTIVE_GAME line
    if grep -q '^export ACTIVE_GAME=' .envrc 2>/dev/null; then
      sed -i'' -e "s/^export ACTIVE_GAME=.*/export ACTIVE_GAME=$MODE/" .envrc
    else
      echo "export ACTIVE_GAME=$MODE" >> .envrc
    fi

    echo "Switched to: $MODE"

    if command -v direnv >/dev/null; then
      direnv allow .
    else
      echo "NOTE: You may need to run 'source .envrc' manually"
    fi

    git add .envrc
    git commit -m "Switch ACTIVE_GAME to $MODE"
    git push origin main

    break
  else
    echo "Invalid selection"
  fi
done
