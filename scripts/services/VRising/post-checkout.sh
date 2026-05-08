#!/usr/bin/env bash
# Interpolate into Configs
# SETUP: OPTIONAL
GAME_PASSWORD="$(gcloud secrets versions access latest --secret=server-password)"
export GAME_PASSWORD
export SAVE_NAME
export RCON_PASSWORD
export RCON_PORT

# Game-listen ports from the per-game tfvars.json (single source of truth
# — same file Terraform reads for firewall rules and shared/refresh.sh
# reads for the manifest). Exposed as env so envsubst can splice them
# into ServerHostSettings.json.
read -r GAME_PORT GAME_QUERY_PORT < <(python3 -c "
import json
udp = json.load(open('$BAROBOYS/terraform/game/VRising.tfvars.json')).get('game_ports_udp', [])
print(udp[0] if udp else '', udp[1] if len(udp) > 1 else '')
")
export GAME_PORT GAME_QUERY_PORT

HOST_JSON_IN="ServerHostSettings.json.template"
GAME_JSON_IN="ServerGameSettings.json.template"

HOST_JSON_OUT="VRisingServer_Data/StreamingAssets/Settings/ServerHostSettings.json"
GAME_JSON_OUT="VRisingServer_Data/StreamingAssets/Settings/ServerGameSettings.json"

HOST_JSON_IN="$GAME_DIR/$HOST_JSON_IN"
GAME_JSON_IN="$GAME_DIR/$GAME_JSON_IN"

HOST_JSON_OUT="$GAME_DIR/$HOST_JSON_OUT"
GAME_JSON_OUT="$GAME_DIR/$GAME_JSON_OUT"

envsubst < "$HOST_JSON_IN" > "$HOST_JSON_OUT"
envsubst < "$GAME_JSON_IN" > "$GAME_JSON_OUT"
