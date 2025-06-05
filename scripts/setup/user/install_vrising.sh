#!/bin/bash
set -eux

# Fetch the RCON password from GCP Secret Manager
SERVER_PASSWORD="$(gcloud secrets versions access latest --secret=server-password)"
export SERVER_PASSWORD

# Paths
VRISING_DIR="$HOME/baroboys/VRising"
SAVE_DIR="$VRISING_DIR/Data/Saves/v4/TestWorld-1"
HOST_JSON="$VRISING_DIR/VRisingServer_Data/StreamingAssets/Settings/ServerHostSettings.json"
GAME_JSON="$VRISING_DIR/VRisingServer_Data/StreamingAssets/Settings/ServerGameSettings.json"

# Ensure save is uncompressed
cd "$SAVE_DIR"
if ! compgen -G "AutoSave_*.save" > /dev/null; then
  echo "🗜 No .save found, attempting to decompress most recent .save.gz..."
  latest_gz=$(find . -name 'AutoSave_*.save.gz' | sed -E 's/.*AutoSave_([0-9]+)\.save\.gz/\1 \0/' | sort -n | tail -n1 | cut -d' ' -f2)
  if [[ -n "$latest_gz" ]]; then
    gunzip -kf "$latest_gz"
    echo "✅ Decompressed: $latest_gz"
  else
    echo "⚠️ No compressed autosaves found to restore!"
  fi
fi

# Update game files via SteamCMD
/usr/games/steamcmd \
  +@sSteamCmdForcePlatformType windows \
  +force_install_dir "$VRISING_DIR" \
  +login anonymous \
  +app_update 1829350 validate \
  +quit

# Restore canonical server configs
cd "$HOME/baroboys"
git checkout -- \
  "$HOST_JSON" \
  "$GAME_JSON" \
  "$VRISING_DIR/Data/Settings/adminlist.txt" \
  "$VRISING_DIR/Data/Settings/banlist.txt"

envsubst < "$HOST_JSON" > "$HOST_JSON.tmp"
mv "$HOST_JSON.tmp" "$HOST_JSON"

# Ensure log paths are readable
mkdir -p "$VRISING_DIR/logs"
chmod o+rx "$HOME" "$HOME/baroboys" "$VRISING_DIR" "$VRISING_DIR/logs"
touch "$VRISING_DIR/logs/VRisingServer.log"
printf "\n==== %s ====\n" "$(date +%Y%m%d-%H%M)" >> "$VRISING_DIR/logs/VRisingServer.log"
chown bwinter_sc81:bwinter_sc81 "$VRISING_DIR/logs/VRisingServer.log"
chmod 644 "$VRISING_DIR/logs/VRisingServer.log"

# Ensure EDITOR is set for shell sessions
grep -qxF 'export EDITOR=vim' "$HOME/.profile" || echo 'export EDITOR=vim' >> "$HOME/.profile"
