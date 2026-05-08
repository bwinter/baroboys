#!/usr/bin/env bash
# Interpolate into Configs
# SETUP: OPTIONAL
GAME_PASSWORD="$(gcloud secrets versions access latest --secret=server-password)"
export GAME_PASSWORD
export SAVE_NAME
export RCON_PASSWORD
export RCON_PORT

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
