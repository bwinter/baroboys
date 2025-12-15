#!/bin/bash
set -eu

# Fetch the RCON password from GCP Secret Manager
SERVER_PASSWORD="$(gcloud secrets versions access latest --secret=server-password)"
export SERVER_PASSWORD

# Paths
BAROTRAUMA_DIR="${HOME}/baroboys/Barotrauma"
CLIENT_PERMISSIONS_XML="$BAROTRAUMA_DIR/Data/clientpermissions.xml"
SERVER_SETTINGS_XML="$BAROTRAUMA_DIR/serversettings.xml"

echo "=== BEFORE steamcmd ==="
id
echo "HOME=$HOME"
ls -la ~
ls -la ~/.steam ~/.local/share || true

# Warm steam to hopefully avoid intermittent failures.
/usr/games/steamcmd \
  +login anonymous \
  +quit

/usr/games/steamcmd \
  +force_install_dir "$BAROTRAUMA_DIR" \
  +login anonymous \
  +app_update 1026340 validate \
  +quit

echo "=== AFTER steamcmd ==="
ls -la ~/.steam ~/.local/share || true
find ~/.steam -maxdepth 3 -type f 2>/dev/null || true

# Restore canonical server configs
cd "$HOME/baroboys"
git checkout -- \
  "$CLIENT_PERMISSIONS_XML" \
  "$SERVER_SETTINGS_XML"

envsubst < "$SERVER_SETTINGS_XML" > "$SERVER_SETTINGS_XML.tmp"
mv "$SERVER_SETTINGS_XML.tmp" "$SERVER_SETTINGS_XML"

mkdir -p "$HOME/.local/share/Daedalic Entertainment GmbH/Barotrauma/"
ln -sf "$HOME/baroboys/Barotrauma/Multiplayer" "$HOME/.local/share/Daedalic Entertainment GmbH/Barotrauma"
ln -sf "$HOME/baroboys/Barotrauma/WorkshopMods" "$HOME/.local/share/Daedalic Entertainment GmbH/Barotrauma"