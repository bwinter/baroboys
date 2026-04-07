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
