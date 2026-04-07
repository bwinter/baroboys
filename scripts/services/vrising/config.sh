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

# SETUP: OPTIONAL --- DECOMPRESS SAVE
# Decompress all .gz saves matching the prefix. Same path for all games.
# -k: keep the .gz; -f: overwrite existing uncompressed files.
if [[ -d "${SAVE_FILE_PATH:-}" && -n "${SAVE_FILE_PREFIX:-}" ]]; then
  find "$SAVE_FILE_PATH" -maxdepth 1 -name "${SAVE_FILE_PREFIX}*.gz" -exec gunzip -kf {} \;
fi
