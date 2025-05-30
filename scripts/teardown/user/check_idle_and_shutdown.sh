#!/bin/bash
set -eu

IDLE_FLAG="/tmp/server_idle_since.flag"
COOLDOWN_MINUTES=3

SERVER_PASS="$(gcloud secrets versions access latest --secret="server-password")"

# RCON check for players. Adjust command if your server reports differently.
PLAYERS_ONLINE=$(mcrcon -H 127.0.0.1 -P 25575 -p "$SERVER_PASS" "listusers" | grep -v "no players connected" | grep -E "[0-9]+ players connected" || true)

if [[ -n "$PLAYERS_ONLINE" ]]; then
  # Players are online, clear idle flag if exists
  rm -f "$IDLE_FLAG"
else
  # No players detected
  if [[ ! -f "$IDLE_FLAG" ]]; then
    # Mark the time when the server became idle
    date +%s > "$IDLE_FLAG"
  fi

  # Check idle duration
  IDLE_SINCE=$(cat "$IDLE_FLAG")
  NOW=$(date +%s)
  IDLE_DURATION=$(( (NOW - IDLE_SINCE) / 60 )) # minutes

  if (( IDLE_DURATION >= COOLDOWN_MINUTES )); then
    echo "Server has been idle for $IDLE_DURATION minutes, shutting down."
    systemctl start shutdown.service
  fi
fi
