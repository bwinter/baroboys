#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/barotrauma/config.sh
source "$(dirname "${BASH_SOURCE[0]}")/../config.sh"

# Paths (GAME_DIR from config.sh)
CLIENT_PERMISSIONS_XML="$GAME_DIR/Data/clientpermissions.xml"
PERMISSION_PRESETS_XML="$GAME_DIR/Data/permissionpresets_player.xml"
SERVER_SETTINGS_XML_IN="$GAME_DIR/serversettings.xml.in"
SERVER_SETTINGS_XML="$GAME_DIR/serversettings.xml"

# Warm login before the real app_update. This works around intermittent SteamCMD failures
# that occur when the depot cache or config hasn't been initialised yet. Root cause is
# unknown; removing this call makes builds flaky. Do not simplify.
/usr/games/steamcmd \
  +login anonymous \
  +quit

/usr/games/steamcmd \
  +force_install_dir "$GAME_DIR" \
  +login anonymous \
  +app_update "$STEAM_APP_ID" validate \
  +quit

# Restore canonical server configs
cd "$HOME/baroboys"
git checkout -- \
  "$CLIENT_PERMISSIONS_XML" \
  "$PERMISSION_PRESETS_XML" \
  "$SERVER_SETTINGS_XML_IN"

# Fetch the RCON password from GCP Secret Manager
SERVER_PASSWORD="$(gcloud secrets versions access latest --secret=server-password)"
export SERVER_PASSWORD

envsubst < "$SERVER_SETTINGS_XML_IN" > "$SERVER_SETTINGS_XML"

mkdir -p "$HOME/.local/share/Daedalic Entertainment GmbH/Barotrauma/"
ln -sf "$GAME_DIR/Multiplayer" "$HOME/.local/share/Daedalic Entertainment GmbH/Barotrauma"
ln -sf "$GAME_DIR/WorkshopMods" "$HOME/.local/share/Daedalic Entertainment GmbH/Barotrauma"