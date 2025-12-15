#!/bin/bash
set -eu

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

echo "=== BEFORE steamcmd ==="
id
echo "HOME=$HOME"
ls -la ~
ls -la ~/.steam ~/.local/share || true

# Warm steam to hopefully avoid intermittent failures.
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

echo "=== AFTER steamcmd ==="
ls -la ~/.steam ~/.local/share || true
find ~/.steam -maxdepth 3 -type f 2>/dev/null || true

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

printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "$VRISING_DIR/logs/VRisingServer.log"
chown bwinter_sc81:bwinter_sc81 "$VRISING_DIR/logs/VRisingServer.log"
chmod 644 "$VRISING_DIR/logs/VRisingServer.log"