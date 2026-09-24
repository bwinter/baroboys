#!/usr/bin/env bash
set -euo pipefail

PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: PROJECT not set and no gcloud default project."
  exit 1
fi

BOT_TOKEN="$(gcloud secrets versions access latest \
  --secret=discord-bot-token --project="$PROJECT")"
if [[ -z "$BOT_TOKEN" ]]; then
  echo "ERROR: Secret 'discord-bot-token' is empty."
  exit 1
fi
trap 'unset BOT_TOKEN' EXIT

COMMANDS_JSON='[
  {
    "name": "help",
    "description": "Show available game server commands"
  },
  {
    "name": "status",
    "description": "Check the game server"
  },
  {
    "name": "start",
    "description": "Start the game server"
  }
]'

IFS=';' read -ra LOCATIONS <<< "$DISCORD_ALLOWED_LOCATIONS"
for location in "${LOCATIONS[@]}"; do
  guild_id="${location%%:*}"
  if [[ -z "$guild_id" || "$guild_id" == "$location" ]]; then
    echo "ERROR: Invalid Discord location '$location'; expected guild_id:channel_id."
    exit 1
  fi

  url="https://discord.com/api/v10/applications/$DISCORD_APPLICATION_ID/guilds/$guild_id/commands"
  curl --fail-with-body --silent --show-error \
    --request PUT \
    --header "Authorization: Bot $BOT_TOKEN" \
    --header 'Content-Type: application/json' \
    --data "$COMMANDS_JSON" \
    "$url"
  echo
  echo "✅ Discord guild commands registered for $guild_id"
done
