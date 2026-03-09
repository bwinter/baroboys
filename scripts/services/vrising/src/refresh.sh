#!/usr/bin/env bash
set -euxo pipefail

# Paths
VRISING_DIR="$HOME/baroboys/VRising"
SETTINGS_DIR="$VRISING_DIR/VRisingServer_Data/StreamingAssets/Settings"
ADMIN_LIST="$VRISING_DIR/Data/Settings/adminlist.txt"
BAN_LIST="$VRISING_DIR/Data/Settings/banlist.txt"
SAVE_DIR="$VRISING_DIR/Data/Saves/v4/TestWorld-1"
HOST_JSON_IN="$VRISING_DIR/ServerHostSettings.json.in"
GAME_JSON_IN="$VRISING_DIR/ServerGameSettings.json.in"
HOST_JSON="$SETTINGS_DIR/ServerHostSettings.json"
GAME_JSON="$SETTINGS_DIR/ServerGameSettings.json"

# Ensure save is uncompressed
cd "$SAVE_DIR"

# Find the latest uncompressed save (if any)
latest_save=$(find . -name 'AutoSave_*.save' | sed -E 's/.*AutoSave_([0-9]+)\.save/\1 \0/' | sort -n | tail -n1)
save_num=$(cut -d' ' -f1 <<< "$latest_save")
save_file=$(cut -d' ' -f2 <<< "$latest_save")

# Find the latest compressed save
latest_gz=$(find . -name 'AutoSave_*.save.gz' | sed -E 's/.*AutoSave_([0-9]+)\.save\.gz/\1 \0/' | sort -n | tail -n1)
gz_num=$(cut -d' ' -f1 <<< "$latest_gz")
gz_file=$(cut -d' ' -f2 <<< "$latest_gz")

# Decide if we need to decompress
if [[ -z "$gz_file" ]]; then
  echo "⚠️ No compressed autosaves found."
elif [[ -z "$save_file" || "$gz_num" -gt "$save_num" ]]; then
  echo "🗜 Decompressing newer autosave: $gz_file"
  gunzip -kf "$gz_file"
else
  echo "✅ Latest .save is up-to-date or newer than .gz"
fi

# Warm SteamCMD before the real install call.
# Without this, SteamCMD intermittently fails to start the installer correctly — likely a
# first-run initialization issue (depot cache, config, or update manifest setup). Running a
# bare login+quit first does a clean pave of whatever internal state SteamCMD needs, and
# the subsequent app_update call reliably succeeds. Root cause is unclear; workaround was
# found via community reports of similar intermittent SteamCMD failures.
/usr/games/steamcmd \
  +login anonymous \
  +quit

# Update game files via SteamCMD
/usr/games/steamcmd \
  +@sSteamCmdForcePlatformType windows \
  +force_install_dir "$VRISING_DIR" \
  +login anonymous \
  +app_update 1829350 validate \
  +quit

# Restore force-committed files that SteamCMD may have clobbered
cd "$HOME/baroboys"
git checkout -- \
  "$ADMIN_LIST" \
  "$BAN_LIST"

# Fetch the RCON password and interpolate config templates into Settings/
SERVER_PASSWORD="$(gcloud secrets versions access latest --secret=server-password)"
export SERVER_PASSWORD

envsubst < "$HOST_JSON_IN" > "$HOST_JSON"
envsubst < "$GAME_JSON_IN" > "$GAME_JSON"

# Ensure log paths are readable
mkdir -p "$VRISING_DIR/logs"
chmod o+rx "$HOME" "$HOME/baroboys" "$VRISING_DIR" "$VRISING_DIR/logs"
touch "$VRISING_DIR/logs/VRisingServer.log"

printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "$VRISING_DIR/logs/VRisingServer.log"
chown bwinter_sc81:bwinter_sc81 "$VRISING_DIR/logs/VRisingServer.log"
chmod 644 "$VRISING_DIR/logs/VRisingServer.log"