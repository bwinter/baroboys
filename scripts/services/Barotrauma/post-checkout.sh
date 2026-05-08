#!/usr/bin/env bash
# Interpolate into Configs
# SETUP: OPTIONAL:
GAME_PASSWORD="$(gcloud secrets versions access latest --secret=server-password)"
export GAME_PASSWORD

# Game-listen ports from the per-game tfvars.json (single source of truth
# — same file Terraform reads for firewall rules).
read -r GAME_PORT GAME_QUERY_PORT < <(python3 -c "
import json
udp = json.load(open('$BAROBOYS/terraform/game/Barotrauma.tfvars.json')).get('game_ports_udp', [])
print(udp[0] if udp else '', udp[1] if len(udp) > 1 else '')
")
export GAME_PORT GAME_QUERY_PORT

SERVER_SETTINGS_XML_IN="serversettings.xml.template"
SERVER_SETTINGS_XML_OUT="serversettings.xml"

SERVER_SETTINGS_XML_IN="$GAME_DIR/$SERVER_SETTINGS_XML_IN"
SERVER_SETTINGS_XML_OUT="$GAME_DIR/$SERVER_SETTINGS_XML_OUT"

envsubst < "$SERVER_SETTINGS_XML_IN" > "$SERVER_SETTINGS_XML_OUT"
