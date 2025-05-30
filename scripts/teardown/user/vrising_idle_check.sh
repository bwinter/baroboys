#!/bin/bash
set -eu

IDLE_FLAG="/tmp/server_idle_since.flag"
COOLDOWN_MINUTES=30

SERVER_PASS="$(gcloud secrets versions access latest --secret="server-password" || true)"
if [[ -z "$SERVER_PASS" ]]; then
  echo "❌ Server password missing or empty" >&2
  exit 1
fi

# TODO: where are the actual mcrcon params. So werid.
#PLAYERS_ONLINE=$(
#  mcrcon -H 127.0.0.1 -P 25575 -p "$SERVER_PASS" "listusers" 2>/dev/null \
#    | grep -v "no players connected" \
#    | grep -E "[0-9]+ players connected" \
#    || true
#)
PLAYERS_ONLINE=0

if [[ -n "$PLAYERS_ONLINE" ]]; then
  rm -f "$IDLE_FLAG"
else
  if [[ ! -f "$IDLE_FLAG" ]]; then
    date +%s > "$IDLE_FLAG"
  fi

  IDLE_SINCE=$(cat "$IDLE_FLAG")
  NOW=$(date +%s)
  IDLE_DURATION=$(( (NOW - IDLE_SINCE) / 60 ))

  if (( IDLE_DURATION >= COOLDOWN_MINUTES )); then
    echo "Server has been idle for $IDLE_DURATION minutes, shutting down."
    if ! /usr/bin/sudo systemctl start shutdown.service; then
      echo "⚠️  Failed to start shutdown.service" >&2
    fi
  fi
fi
