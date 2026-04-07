#!/usr/bin/env bash
# Interpolate into Configs
# SETUP: OPTIONAL:
GAME_PASSWORD="$(gcloud secrets versions access latest --secret=server-password)"
export GAME_PASSWORD

SERVER_SETTINGS_XML_IN="serversettings.xml.template"
SERVER_SETTINGS_XML_OUT="serversettings.xml"

SERVER_SETTINGS_XML_IN="$GAME_DIR/$SERVER_SETTINGS_XML_IN"
SERVER_SETTINGS_XML_OUT="$GAME_DIR/$SERVER_SETTINGS_XML_OUT"

envsubst < "$SERVER_SETTINGS_XML_IN" > "$SERVER_SETTINGS_XML_OUT"

# SETUP: OPTIONAL --- DECOMPRESS SAVE
# Decompress all .gz saves matching the prefix. Same path for all games.
# -k: keep the .gz; -f: overwrite existing uncompressed files.
if [[ -d "${SAVE_FILE_PATH:-}" && -n "${SAVE_FILE_PREFIX:-}" ]]; then
  find "$SAVE_FILE_PATH" -maxdepth 1 -name "${SAVE_FILE_PREFIX}*.gz" -exec gunzip -kf {} \;
fi